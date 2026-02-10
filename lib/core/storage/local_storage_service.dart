import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/models.dart';

/// Subject constants for box naming
class SubjectKeys {
  static const List<String> all = [
    'anatomy',
    'physiology',
    'biochemistry',
    'pharmacology',
    'pathology',
    'microbiology',
    'forensic_medicine',
    'spm',
    'ent',
    'ophthalmology',
    'medicine',
    'surgery',
    'obg',
    'pediatrics',
    'orthopedics',
    'psychiatry',
    'dermatology',
    'radiology',
    'anesthesia',
  ];

  /// Convert display name to storage key
  static String toKey(String displayName) {
    return displayName.toLowerCase().replaceAll(' ', '_');
  }

  /// Convert storage key to display name
  static String toDisplayName(String key) {
    return key
        .split('_')
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }
}

/// Local Storage Keys
class LocalKeys {
  // Progress tracking
  static const viewedMcqIds = 'viewed_mcq_ids';
  static const bookmarkedMcqIds = 'bookmarked_mcq_ids';
  static const bookmarkedMcqs = 'bookmarked_mcqs';

  // Sync queue
  static const syncQueueViewed = 'sync_queue_viewed';
  static const syncQueueBookmarksAdd = 'sync_queue_bookmarks_add';
  static const syncQueueBookmarksRemove = 'sync_queue_bookmarks_remove';

  // Cache metadata
  static const lastFullSyncTime = 'last_full_sync_time';
  static const cacheVersion = 'cache_version';

  // Stats
  static const statsData = 'stats_data';
}

/// Industry-standard Local Storage Service
/// Manages subject-specific MCQ boxes + progress tracking
class LocalStorageService {
  static LocalStorageService? _instance;
  static LocalStorageService get instance =>
      _instance ??= LocalStorageService._();

  LocalStorageService._();

  // Subject-specific boxes (40 MCQs per subject)
  final Map<String, Box<String>> _subjectBoxes = {};

  // Progress & meta boxes
  late Box<List<String>> _progressBox;
  late Box<String> _metaBox;
  late Box<String> _syncQueueBox;

  bool _initialized = false;

  /// Initialize all boxes
  Future<void> init() async {
    if (_initialized) return;

    // Open progress box (stores viewedIds, bookmarkIds as lists)
    _progressBox = await Hive.openBox<List<String>>('neetflow_progress');

    // Open meta box (stores cache timestamps, versions)
    _metaBox = await Hive.openBox<String>('neetflow_meta');

    // Open sync queue box (stores pending sync items as JSON strings)
    _syncQueueBox = await Hive.openBox<String>('neetflow_sync_queue');

    // Open subject boxes lazily (will open on first access)
    _initialized = true;
    debugPrint('[LocalStorage] Initialized core boxes');
  }

  /// Get or open a subject-specific box
  Future<Box<String>> _getSubjectBox(String subjectKey) async {
    if (_subjectBoxes.containsKey(subjectKey)) {
      return _subjectBoxes[subjectKey]!;
    }

    final boxName = 'neetflow_mcq_$subjectKey';
    final box = await Hive.openBox<String>(boxName);
    _subjectBoxes[subjectKey] = box;
    return box;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // MCQ Storage (Per Subject)
  // ══════════════════════════════════════════════════════════════════════════

  /// Store MCQs for a subject (Merging/Appending by default)
  /// Set [clearFirst] to true to replace entire cache for this subject
  Future<void> storeMCQsForSubject(
    String subject,
    List<MCQ> mcqs, {
    bool clearFirst = false,
  }) async {
    final key = SubjectKeys.toKey(subject);
    final box = await _getSubjectBox(key);

    if (clearFirst) {
      await box.clear();
    }

    // Store each MCQ as JSON string with ID as key
    // This performs an UPSERT (Update if exists, Insert if new)
    for (final mcq in mcqs) {
      await box.put(mcq.id, jsonEncode(mcq.toJson()));
    }

    debugPrint(
      '[LocalStorage] Stored ${mcqs.length} MCQs for $subject (Total: ${box.length})',
    );
  }

  /// Clear cache for a specific subject
  Future<void> clearSubjectCache(String subject) async {
    final key = SubjectKeys.toKey(subject);
    final box = await _getSubjectBox(key);
    await box.clear();
  }

  /// Get all MCQs for a subject
  Future<List<MCQ>> getMCQsForSubject(String subject) async {
    final key = SubjectKeys.toKey(subject);
    final box = await _getSubjectBox(key);

    final mcqs = <MCQ>[];
    for (final jsonStr in box.values) {
      try {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        mcqs.add(MCQ.fromJson(map));
      } catch (e) {
        debugPrint('[LocalStorage] Failed to parse MCQ: $e');
      }
    }

    return mcqs;
  }

  /// Get all cached MCQs across all subjects
  Future<List<MCQ>> getAllCachedMCQs() async {
    final allMcqs = <MCQ>[];

    for (final subjectKey in SubjectKeys.all) {
      final mcqs = await getMCQsForSubject(
        SubjectKeys.toDisplayName(subjectKey),
      );
      allMcqs.addAll(mcqs);
    }

    return allMcqs;
  }

  /// Check if subject has cached MCQs
  Future<bool> hasSubjectCache(String subject) async {
    final key = SubjectKeys.toKey(subject);
    final box = await _getSubjectBox(key);
    return box.isNotEmpty;
  }

  /// Check if full cache exists
  Future<bool> hasFullCache() async {
    for (final key in SubjectKeys.all) {
      final box = await _getSubjectBox(key);
      if (box.isEmpty) return false;
    }
    return true;
  }

  /// Get MCQ count per subject
  Future<Map<String, int>> getCacheStats() async {
    final stats = <String, int>{};
    for (final key in SubjectKeys.all) {
      final box = await _getSubjectBox(key);
      stats[key] = box.length;
    }
    return stats;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Progress Tracking (ViewedIds, BookmarkIds)
  // ══════════════════════════════════════════════════════════════════════════

  /// Get viewed MCQ IDs
  List<String> getViewedMcqIds() {
    return _progressBox.get(LocalKeys.viewedMcqIds) ?? [];
  }

  /// Add viewed MCQ ID (local-first, instant)
  Future<void> addViewedMcqId(String mcqId) async {
    final current = getViewedMcqIds();
    if (!current.contains(mcqId)) {
      current.add(mcqId);
      await _progressBox.put(LocalKeys.viewedMcqIds, current);

      // Add to sync queue
      await _addToSyncQueue(LocalKeys.syncQueueViewed, mcqId);
    }
  }

  /// Bulk add viewed MCQ IDs (for initial sync from Firebase)
  Future<void> setViewedMcqIds(List<String> ids) async {
    await _progressBox.put(LocalKeys.viewedMcqIds, ids);
  }

  /// Bulk set bookmarked MCQ IDs (for initial sync from Firebase)
  Future<void> setBookmarkedMcqIds(List<String> ids) async {
    await _progressBox.put(LocalKeys.bookmarkedMcqIds, ids);
  }

  /// Get bookmarked MCQ IDs
  List<String> getBookmarkedMcqIds() {
    return _progressBox.get(LocalKeys.bookmarkedMcqIds) ?? [];
  }

  /// Add bookmark (local-first)
  Future<void> addBookmark(MCQ mcq) async {
    // Add to ID list
    final currentIds = getBookmarkedMcqIds();
    if (!currentIds.contains(mcq.id)) {
      currentIds.add(mcq.id);
      await _progressBox.put(LocalKeys.bookmarkedMcqIds, currentIds);
    }

    // Store full MCQ for offline access
    final bookmarksJson = _metaBox.get(LocalKeys.bookmarkedMcqs) ?? '[]';
    final bookmarks = (jsonDecode(bookmarksJson) as List)
        .map((e) => MCQ.fromJson(e as Map<String, dynamic>))
        .toList();

    if (!bookmarks.any((b) => b.id == mcq.id)) {
      bookmarks.add(mcq);
      await _metaBox.put(
        LocalKeys.bookmarkedMcqs,
        jsonEncode(bookmarks.map((b) => b.toJson()).toList()),
      );
    }

    // Add to sync queue
    await _addToSyncQueue(LocalKeys.syncQueueBookmarksAdd, mcq.id);
  }

  /// Remove bookmark (local-first)
  Future<void> removeBookmark(String mcqId) async {
    // Remove from ID list
    final currentIds = getBookmarkedMcqIds();
    currentIds.remove(mcqId);
    await _progressBox.put(LocalKeys.bookmarkedMcqIds, currentIds);

    // Remove from stored MCQs
    final bookmarksJson = _metaBox.get(LocalKeys.bookmarkedMcqs) ?? '[]';
    final bookmarks = (jsonDecode(bookmarksJson) as List)
        .map((e) => MCQ.fromJson(e as Map<String, dynamic>))
        .where((b) => b.id != mcqId)
        .toList();
    await _metaBox.put(
      LocalKeys.bookmarkedMcqs,
      jsonEncode(bookmarks.map((b) => b.toJson()).toList()),
    );

    // Add to sync queue
    await _addToSyncQueue(LocalKeys.syncQueueBookmarksRemove, mcqId);
  }

  /// Get full bookmarked MCQs
  List<MCQ> getBookmarkedMcqs() {
    final json = _metaBox.get(LocalKeys.bookmarkedMcqs) ?? '[]';
    try {
      return (jsonDecode(json) as List)
          .map((e) => MCQ.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Check if MCQ is bookmarked
  bool isBookmarked(String mcqId) {
    return getBookmarkedMcqIds().contains(mcqId);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Sync Queue Management
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _addToSyncQueue(String queueKey, String item) async {
    final current = _getSyncQueue(queueKey);
    if (!current.contains(item)) {
      current.add(item);
      await _syncQueueBox.put(queueKey, jsonEncode(current));
    }
  }

  List<String> _getSyncQueue(String queueKey) {
    final json = _syncQueueBox.get(queueKey) ?? '[]';
    return List<String>.from(jsonDecode(json) as List);
  }

  /// Get pending viewed IDs to sync
  List<String> getPendingViewedSync() =>
      _getSyncQueue(LocalKeys.syncQueueViewed);

  /// Get pending bookmark additions to sync
  List<String> getPendingBookmarkAddSync() =>
      _getSyncQueue(LocalKeys.syncQueueBookmarksAdd);

  /// Get pending bookmark removals to sync
  List<String> getPendingBookmarkRemoveSync() =>
      _getSyncQueue(LocalKeys.syncQueueBookmarksRemove);

  /// Clear sync queue after successful sync
  Future<void> clearSyncQueue(String queueKey) async {
    await _syncQueueBox.delete(queueKey);
  }

  /// Check if there are pending syncs
  bool hasPendingSync() {
    return getPendingViewedSync().isNotEmpty ||
        getPendingBookmarkAddSync().isNotEmpty ||
        getPendingBookmarkRemoveSync().isNotEmpty;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Cache Metadata
  // ══════════════════════════════════════════════════════════════════════════

  /// Get last full sync timestamp
  DateTime? getLastFullSyncTime() {
    final ms = _metaBox.get(LocalKeys.lastFullSyncTime);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(int.parse(ms));
  }

  /// Set last full sync timestamp
  Future<void> setLastFullSyncTime(DateTime time) async {
    await _metaBox.put(
      LocalKeys.lastFullSyncTime,
      time.millisecondsSinceEpoch.toString(),
    );
  }

  /// Check if cache is stale (older than 24 hours)
  bool isCacheStale() {
    final lastSync = getLastFullSyncTime();
    if (lastSync == null) return true;
    return DateTime.now().difference(lastSync).inHours > 24;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Stats Storage
  // ══════════════════════════════════════════════════════════════════════════

  /// Store stats data locally
  Future<void> setStatsData(Map<String, dynamic> stats) async {
    await _metaBox.put(LocalKeys.statsData, jsonEncode(stats));
  }

  /// Get local stats data
  Map<String, dynamic>? getStatsData() {
    final json = _metaBox.get(LocalKeys.statsData);
    if (json == null) return null;
    return jsonDecode(json) as Map<String, dynamic>;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Cleanup
  // ══════════════════════════════════════════════════════════════════════════

  /// Clear all MCQ caches (keeps progress)
  Future<void> clearMcqCache() async {
    for (final box in _subjectBoxes.values) {
      await box.clear();
    }
    await _metaBox.delete(LocalKeys.lastFullSyncTime);
  }

  /// Clear everything (for logout)
  Future<void> clearAll() async {
    await clearUserProgress();
    for (final box in _subjectBoxes.values) {
      await box.clear();
    }
  }

  /// Clear ONLY user progress (Viewed, Bookmarks, Stats) - Keeps MCQ Content
  Future<void> clearUserProgress() async {
    await _progressBox.clear();
    await _syncQueueBox.clear();
    // Clear specific meta keys related to user
    await _metaBox.delete(LocalKeys.statsData);
    await _metaBox.delete(LocalKeys.bookmarkedMcqs);
    // Note: We keep lastFullSyncTime and cacheVersion as they are global/content related
  }
}
