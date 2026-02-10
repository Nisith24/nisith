# Codebase Audit Report

This document outlines critical errors, bugs, inefficiencies, and code quality issues identified in the current NeetFlow Flutter codebase.

## 1. Critical Issues (Must Fix)

### 1.1 Firestore Batch Crash in Background Sync (High Severity)
**Files:**
- `lib/core/services/background_sync_service.dart`
- `lib/features/auth/providers/auth_provider.dart`

**Issue:**
Both `BackgroundSyncService.syncToFirebase` and `AuthNotifier._performBackgroundSync` attempt to modify the same document (`users/{uid}`) multiple times within a single `WriteBatch`.
Specifically, they call `batch.set(userRef, ...)` potentially three times (for `viewedMcqIds`, `bookmarkedMcqIds` (add), and `bookmarkedMcqIds` (remove)).

**Impact:**
Firestore SDK throws an exception if the same document reference is included more than once in a batch. **Sync will fail completely** if there are pending updates for more than one category (e.g., viewed a card AND bookmarked a card).

**Recommendation:**
Consolidate all updates into a single `batch.set(..., SetOptions(merge: true))` or `batch.update(...)` call, or execute them as separate operations (sequentially).

### 1.2 Race Condition & Logic Duplication
**Files:**
- `lib/core/services/background_sync_service.dart`
- `lib/features/auth/providers/auth_provider.dart`

**Issue:**
Both classes implement background syncing logic with their own timers (`_periodicSyncTimer` vs `_syncTimer`).
- `BackgroundSyncService` runs every 5 minutes.
- `AuthNotifier` runs every 2 minutes.

**Impact:**
This causes race conditions, redundant writes to Firestore, and potentially conflicting state if one sync succeeds and the other fails or if they interleave. It also wastes device battery and data.

**Recommendation:**
Remove the sync logic from `AuthNotifier` entirely and rely solely on `BackgroundSyncService` as the single source of truth for synchronization.

### 1.3 Weighted Selection Logic Flaw
**File:** `lib/features/mcq/repositories/mcq_repository.dart`

**Issue:**
In `_performWeightedSelection`:
```dart
var r = random.nextDouble() * totalWeight;
// ...
// subjects list shrinks as pools are exhausted
```
The `totalWeight` is calculated once at the start. However, if a subject's pool is exhausted and removed from the `subjects` list, `totalWeight` is **not recalculated**.
This means `r` can be generated based on the original total weight, but the available subjects' weights sum to less than that.

**Impact:**
`chosenSubject` becomes `null` (or defaults to the first subject), heavily biasing selection towards the first subject in the list or failing to select the requested number of questions properly.

## 2. Major Inefficiencies (Performance & Scalability)

### 2.1 Full Collection Fetch on Every Sync
**File:** `lib/features/mcq/repositories/mcq_repository.dart`

**Issue:**
`performFullSync` calls:
```dart
await _firestore.collection('question_packs').get();
```
This fetches **every single document** in the `question_packs` collection.
Similarly, `_fetchSubjectFromFirebase` also fetches the **entire collection** just to filter for one subject in memory.

**Impact:**
- **Extreme Data Usage:** Users will download the entire database every time they sync or open a subject they haven't cached.
- **Scalability:** As content grows, this will become exponentially slower and more expensive (Firestore read costs).
- **Memory Pressure:** Loading all packs into memory to filter them can crash the app on lower-end devices.

**Recommendation:**
- Implement pagination or `lastUpdated` timestamp-based incremental sync.
- Structure Firestore data to allow querying by subject (e.g., `where('subject', isEqualTo: 'Anatomy')`).

### 2.2 JSON Serialization in Local Storage
**File:** `lib/core/storage/local_storage_service.dart`

**Issue:**
MCQs are stored as JSON strings:
```dart
await box.put(mcq.id, jsonEncode(mcq.toJson()));
```
And lists are read/written in their entirety:
```dart
final current = getViewedMcqIds(); // Reads entire list
current.add(mcqId);
await _progressBox.put(..., current); // Writes entire list
```

**Impact:**
- **CPU Overhead:** Constant encoding/decoding of JSON strings on the UI thread (or even background) is CPU intensive.
- **I/O Overhead:** Writing the entire list of viewed IDs (which can grow to thousands) for *every single card swipe* is extremely inefficient and will cause UI jank (frame drops).

**Recommendation:**
- Use Hive `TypeAdapter` to store `MCQ` objects directly.
- Use a `LazyBox` for large datasets.
- For viewed IDs, consider a separate box where the Key is the MCQ ID and Value is a boolean/timestamp, preventing the need to read/write a massive list.

### 2.3 Main Thread Blocking
**General:**
Extensive JSON decoding/encoding and list manipulation (e.g., `_localStorage.getAllCachedMCQs()` iterates and decodes potentially thousands of items) happens on the main isolate.

**Impact:**
The app will freeze or drop frames during sync or initial load.

## 3. Code Quality & Maintenance

### 3.1 Hardcoded Strings & Magic Numbers
**Files:** `lib/core/storage/hive_service.dart`, `lib/core/storage/local_storage_service.dart`

**Issue:**
Box names (`neetflow_general`, `neetflow_mcq_`) are hardcoded strings in multiple places. While `StorageKeys` exists, it's not consistently used for box names.

### 3.2 Type Safety
**File:** `lib/features/exam/ui/exam_screen.dart` (implied from code review)

**Issue:**
`_QuestionNavigator` accepts `List<dynamic> questions` but assumes they have an `.id` property.

**Recommendation:**
Use strict typing: `List<MCQ> questions`.

### 3.3 Flawed "Run Out of Questions" Logic
**File:** `lib/features/mcq/repositories/mcq_repository.dart`

**Issue:**
```dart
if (pool.length < count) {
  pool = List.from(allMcqs); // Resets to ALL questions, including viewed
}
```
If the user needs 10 questions but only 5 unviewed remain, the system resets the pool and might pick 10 *viewed* questions, ignoring the 5 unviewed ones completely (due to random shuffle).

**Recommendation:**
Take all available unviewed questions first, then fill the remainder with viewed questions.

## 4. UI/UX Issues

### 4.1 Timer Logic
**File:** `lib/features/exam/providers/exam_provider.dart`

**Issue:**
`_tick()` decreases `remainingSeconds`. If it hits 0, it calls `nextQuestion()`.
In `nextQuestion`, it resets the timer:
```dart
if (state.testMode != 'calm') {
  _initTimerForMode(state.testMode);
}
```
However, `_initTimerForMode` cancels the old timer and starts a new one. This is fine, but if the user manually answers, `nextQuestion` is called, which resets the timer.
The issue is `_handleTimeUp` calls `nextQuestion`. `nextQuestion` resets the timer.
BUT `_handleTimeUp` is called *inside* the timer callback.
Wait, `nextQuestion` calls `_initTimerForMode` which cancels `_timer`.
This seems okay, but there's a risk of race conditions if `_tick` is running while `nextQuestion` is processing.
More importantly, `remainingSeconds` is nullable. Code checks `state.remainingSeconds! <= 0`. If `state.remainingSeconds` is null (e.g. calm mode), it crashes?
Ah, `_tick` has a check: `if (state.remainingSeconds == null || state.remainingSeconds! <= 0) return;`. So it's safe.

## Summary
The most critical issue is the **Firestore Batch Crash** and the **Full Collection Fetch**. These will directly impact app reliability and cost. The local storage inefficiencies will degrade performance as the user attempts more questions.
