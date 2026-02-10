import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../core/utils/input_validator.dart';

import '../../../core/models/models.dart';
import '../../../core/storage/local_storage_service.dart';

/// Subject weights for balanced MCQ selection (matching original)
const Map<String, int> subjectWeights = {
  'Medicine': 30,
  'Surgery': 30,
  'OBG': 25,
  'Pediatrics': 25,
  'Anesthesia': 20,
  'Pharmacology': 20,
  'Psychiatry': 15,
  'ENT': 15,
  'Anatomy': 10,
  'Physiology': 10,
  'Biochemistry': 10,
  'Pathology': 15,
  'Microbiology': 10,
  'Forensic Medicine': 5,
  'SPM': 10,
  'Ophthalmology': 10,
  'Orthopedics': 10,
  'Dermatology': 5,
  'Radiology': 5,
};

/// MCQ Repository - Local-First Data Access Layer
///
/// The UI ONLY interacts with this repository.
/// It abstracts away the decision of whether to use local cache or Firebase.
class MCQRepository {
  static MCQRepository? _instance;
  static MCQRepository get instance => _instance ??= MCQRepository._();

  MCQRepository._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalStorageService _localStorage = LocalStorageService.instance;

  // In-memory cache for current session (faster than Hive reads)
  List<MCQ>? _sessionCache;

  // ══════════════════════════════════════════════════════════════════════════
  // Public API - Used by Providers
  // ══════════════════════════════════════════════════════════════════════════

  /// Get MCQs for the deck (Local-First)
  /// Returns cached MCQs. If cache empty, returns empty list.
  /// The BackgroundSyncService will populate the cache asynchronously.
  Future<List<MCQ>> getAllMCQs() async {
    // 1. Check session cache first (fastest)
    if (_sessionCache != null && _sessionCache!.isNotEmpty) {
      return _sessionCache!;
    }

    // 2. Check local Hive cache
    final localMcqs = await _localStorage.getAllCachedMCQs();
    if (localMcqs.isNotEmpty) {
      _sessionCache = localMcqs;
      debugPrint(
        '[MCQRepository] Loaded ${localMcqs.length} MCQs from local cache',
      );
      return localMcqs;
    }

    // 3. If no local cache, fetch from Firebase (blocking on first use only)
    debugPrint('[MCQRepository] No local cache, fetching from Firebase...');
    await performFullSync();

    return _sessionCache ?? [];
  }

  /// Get MCQs for a specific subject (Local-First)
  Future<List<MCQ>> getMCQsBySubject(String subject) async {
    // Sanitize input
    if (!InputValidator.isValidId(subject)) {
      debugPrint('[MCQRepository] Invalid subject ID: $subject');
      return [];
    }

    // Try local first
    final localMcqs = await _localStorage.getMCQsForSubject(subject);
    if (localMcqs.isNotEmpty) {
      return localMcqs;
    }

    // Fallback to fetching that subject from Firebase
    await _fetchSubjectFromFirebase(subject);
    return await _localStorage.getMCQsForSubject(subject);
  }

  /// Get weighted selection of MCQs for the deck
  Future<List<MCQ>> getWeightedMCQs({
    required int count,
    String? subjectFilter,
    Set<String>? viewedIds,
  }) async {
    final allMcqs = await getAllMCQs();
    if (allMcqs.isEmpty) return [];

    final viewed = viewedIds ?? _localStorage.getViewedMcqIds().toSet();

    // Filter out viewed first
    var pool = allMcqs.where((q) => !viewed.contains(q.id)).toList();

    // If we've viewed most, allow repeats
    if (pool.length < count) {
      pool = List.from(allMcqs);
    }

    // Apply subject filter if specified
    if (subjectFilter != null) {
      final subjectPool = pool
          .where((q) => q.subject == subjectFilter)
          .toList();
      final unviewedSubject = subjectPool
          .where((q) => !viewed.contains(q.id))
          .toList();

      pool = unviewedSubject.length >= count ? unviewedSubject : subjectPool;

      // Simple shuffle and take for single subject
      pool.shuffle(Random());
      return pool.take(count).toList();
    }

    // Weighted selection across subjects
    return _performWeightedSelection(pool, count);
  }

  /// Mark MCQ as viewed (writes to local, queues for Firebase sync)
  Future<void> markAsViewed(String mcqId) async {
    await _localStorage.addViewedMcqId(mcqId);
  }

  /// Get all viewed MCQ IDs
  Set<String> getViewedIds() {
    return _localStorage.getViewedMcqIds().toSet();
  }

  /// Add bookmark (local-first)
  Future<void> addBookmark(MCQ mcq) async {
    await _localStorage.addBookmark(mcq);
  }

  /// Remove bookmark (local-first)
  Future<void> removeBookmark(String mcqId) async {
    await _localStorage.removeBookmark(mcqId);
  }

  /// Get all bookmarked MCQs
  List<MCQ> getBookmarks() {
    return _localStorage.getBookmarkedMcqs();
  }

  /// Check if bookmarked
  bool isBookmarked(String mcqId) {
    return _localStorage.isBookmarked(mcqId);
  }

  /// Get questions for Mock Test
  Future<List<MCQ>> getQuestionsForMockTest({
    required int count,
    List<String>? subjects,
  }) async {
    final allMcqs = await getAllMCQs();
    if (allMcqs.isEmpty) return [];

    List<MCQ> pool;
    if (subjects != null && subjects.isNotEmpty) {
      pool = allMcqs.where((q) => subjects.contains(q.subject)).toList();
    } else {
      pool = List.from(allMcqs);
    }

    if (pool.isEmpty) return [];

    pool.shuffle(Random());
    return pool.take(count).toList();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Sync Operations (Called by BackgroundSyncService)
  // ══════════════════════════════════════════════════════════════════════════

  /// Perform full sync - fetches all subjects from Firebase and caches locally
  Future<void> performFullSync() async {
    debugPrint('[MCQRepository] Starting full sync...');

    try {
      // Fetch all question packs
      final snapshot = await _firestore.collection('question_packs').get();

      // Group MCQs by subject
      final bySubject = <String, List<MCQ>>{};

      for (final doc in snapshot.docs) {
        final pack = QuestionPack.fromJson(doc.data(), doc.id);

        for (final mcq in pack.questions) {
          final subject = mcq.subject ?? 'General';
          bySubject.putIfAbsent(subject, () => []).add(mcq);
        }
      }

      // Store each subject's MCQs locally (max 40 per subject for efficiency)
      for (final entry in bySubject.entries) {
        final subject = entry.key;
        var mcqs = entry.value;

        // Limit to 40 per subject as per spec
        if (mcqs.length > 40) {
          mcqs.shuffle(Random());
          mcqs = mcqs.take(40).toList();
        }

        await _localStorage.storeMCQsForSubject(subject, mcqs);
      }

      // Update session cache
      _sessionCache = await _localStorage.getAllCachedMCQs();

      debugPrint(
        '[MCQRepository] Full sync complete: ${_sessionCache!.length} MCQs across ${bySubject.length} subjects',
      );
    } catch (e) {
      debugPrint('[MCQRepository] Full sync failed: $e');
      rethrow;
    }
  }

  /// Fetch a single subject from Firebase
  Future<void> _fetchSubjectFromFirebase(String subject) async {
    try {
      final snapshot = await _firestore.collection('question_packs').get();

      final mcqs = <MCQ>[];
      for (final doc in snapshot.docs) {
        final pack = QuestionPack.fromJson(doc.data(), doc.id);
        mcqs.addAll(pack.questions.where((q) => q.subject == subject));
      }

      if (mcqs.length > 40) {
        mcqs.shuffle(Random());
      }

      await _localStorage.storeMCQsForSubject(subject, mcqs.take(40).toList());
    } catch (e) {
      debugPrint('[MCQRepository] Subject fetch failed: $e');
    }
  }

  /// Refresh session cache from local storage
  Future<void> refreshSessionCache() async {
    _sessionCache = await _localStorage.getAllCachedMCQs();
  }

  /// Clear all caches
  Future<void> clearCache() async {
    _sessionCache = null;
    await _localStorage.clearMcqCache();
  }

  /// Clear memory cache only (for logout)
  void clearMemoryCache() {
    _sessionCache = null;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Private Helpers
  // ══════════════════════════════════════════════════════════════════════════

  List<MCQ> _performWeightedSelection(List<MCQ> pool, int count) {
    // Group by subject
    final bySubject = <String, List<MCQ>>{};
    for (final q in pool) {
      final subject = q.subject ?? 'General';
      bySubject.putIfAbsent(subject, () => []).add(q);
    }

    final subjects = bySubject.keys.toList();
    final totalWeight = subjects.fold<int>(
      0,
      (total, s) => total + (subjectWeights[s] ?? 5),
    );

    final selected = <MCQ>[];
    final random = Random();

    for (var i = 0; i < count && selected.length < pool.length; i++) {
      var r = random.nextDouble() * totalWeight;
      String? chosenSubject;

      for (final sub in subjects) {
        r -= subjectWeights[sub] ?? 5;
        if (r <= 0) {
          chosenSubject = sub;
          break;
        }
      }

      chosenSubject ??= subjects.isNotEmpty ? subjects.first : null;
      if (chosenSubject == null) break;

      final subjectPool = bySubject[chosenSubject];
      if (subjectPool != null && subjectPool.isNotEmpty) {
        final randomIndex = random.nextInt(subjectPool.length);
        final question = subjectPool.removeAt(randomIndex);
        selected.add(question);

        if (subjectPool.isEmpty) {
          bySubject.remove(chosenSubject);
          subjects.remove(chosenSubject);
        }
      }
    }

    selected.shuffle(random);
    return selected;
  }
}
