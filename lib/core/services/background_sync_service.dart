import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/local_storage_service.dart';
import '../../features/mcq/repositories/mcq_repository.dart';
import '../../features/auth/providers/auth_provider.dart';

/// Background Sync Service
/// Handles:
/// 1. 30-second delayed initial deep fetch
/// 2. Batched Firestore writes (every 20 cards or app minimize)
/// 3. Retry logic for failed syncs
class BackgroundSyncService with WidgetsBindingObserver {
  static BackgroundSyncService? _instance;
  static BackgroundSyncService get instance =>
      _instance ??= BackgroundSyncService._();

  BackgroundSyncService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalStorageService _localStorage = LocalStorageService.instance;

  Timer? _initialSyncTimer;
  Timer? _periodicSyncTimer;
  bool _isInitialSyncDone = false;
  bool _isSyncing = false;

  WidgetRef? _ref;

  // Configuration
  static const _initialSyncDelay = Duration(seconds: 30);
  static const _batchSyncThreshold = 20; // Sync after 20 viewed cards
  static const _periodicSyncInterval = Duration(minutes: 5);

  int _viewedSinceLastSync = 0;

  /// Initialize the sync service
  void init(WidgetRef ref) {
    _ref = ref;
    WidgetsBinding.instance.addObserver(this);

    // Schedule initial deep sync after 30 seconds
    _scheduleInitialSync();

    // Start periodic sync timer
    _startPeriodicSync();

    debugPrint('[BackgroundSync] Service initialized');
  }

  /// Dispose resources
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _initialSyncTimer?.cancel();
    _periodicSyncTimer?.cancel();
    _ref = null;
  }

  /// Handle app lifecycle changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // App minimized - trigger immediate sync
        debugPrint('[BackgroundSync] App paused, triggering sync');
        syncToFirebase();
        break;
      case AppLifecycleState.resumed:
        // App resumed - check if we need to refresh cache
        if (_localStorage.isCacheStale()) {
          debugPrint('[BackgroundSync] Cache stale, scheduling refresh');
          _performDeepFetch();
        }
        break;
      default:
        break;
    }
  }

  /// Schedule the 30-second delayed initial sync
  void _scheduleInitialSync() {
    _initialSyncTimer?.cancel();
    _initialSyncTimer = Timer(_initialSyncDelay, () {
      if (!_isInitialSyncDone) {
        _performDeepFetch();
      }
    });
    debugPrint('[BackgroundSync] Initial sync scheduled in 30 seconds');
  }

  /// Start periodic sync timer
  void _startPeriodicSync() {
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = Timer.periodic(_periodicSyncInterval, (_) {
      syncToFirebase();
    });
  }

  /// Called when a card is viewed - tracks for batch sync
  void onCardViewed() {
    _viewedSinceLastSync++;

    if (_viewedSinceLastSync >= _batchSyncThreshold) {
      debugPrint('[BackgroundSync] Batch threshold reached, syncing');
      syncToFirebase();
      _viewedSinceLastSync = 0;
    }
  }

  /// Perform the deep fetch (30 seconds after login)
  /// Fetches all 19 subjects × 40 MCQs and stores locally
  Future<void> _performDeepFetch() async {
    if (_isSyncing) return;
    _isSyncing = true;

    debugPrint('[BackgroundSync] Starting deep fetch...');

    try {
      final mcqRepo = MCQRepository.instance;
      await mcqRepo.performFullSync();

      _isInitialSyncDone = true;
      await _localStorage.setLastFullSyncTime(DateTime.now());

      debugPrint('[BackgroundSync] Deep fetch complete');
    } catch (e) {
      debugPrint('[BackgroundSync] Deep fetch failed: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Sync local changes to Firebase
  Future<void> syncToFirebase() async {
    if (_isSyncing) return;
    if (!_localStorage.hasPendingSync()) return;

    _isSyncing = true;

    final userId = _ref?.read(currentUserProvider)?.uid;
    if (userId == null) {
      _isSyncing = false;
      return;
    }

    debugPrint('[BackgroundSync] Syncing to Firebase...');

    try {
      final batch = _firestore.batch();
      final userRef = _firestore.collection('users').doc(userId);

      // Sync viewed MCQs
      final pendingViewed = _localStorage.getPendingViewedSync();
      if (pendingViewed.isNotEmpty) {
        // Chunk large arrays (Firestore limit is 500 per operation)
        for (var i = 0; i < pendingViewed.length; i += 400) {
          final chunk = pendingViewed.sublist(
            i,
            (i + 400).clamp(0, pendingViewed.length),
          );
          batch.set(userRef, {
            'viewedMcqIds': FieldValue.arrayUnion(chunk),
            'lastActive': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      }

      // Sync bookmark additions
      final pendingBookmarkAdd = _localStorage.getPendingBookmarkAddSync();
      if (pendingBookmarkAdd.isNotEmpty) {
        batch.set(userRef, {
          'bookmarked_ids': FieldValue.arrayUnion(pendingBookmarkAdd),
        }, SetOptions(merge: true));
      }

      // Sync bookmark removals
      final pendingBookmarkRemove = _localStorage
          .getPendingBookmarkRemoveSync();
      if (pendingBookmarkRemove.isNotEmpty) {
        batch.set(userRef, {
          'bookmarked_ids': FieldValue.arrayRemove(pendingBookmarkRemove),
        }, SetOptions(merge: true));
      }

      // Commit batch
      await batch.commit();

      // Clear sync queues on success
      await _localStorage.clearSyncQueue(LocalKeys.syncQueueViewed);
      await _localStorage.clearSyncQueue(LocalKeys.syncQueueBookmarksAdd);
      await _localStorage.clearSyncQueue(LocalKeys.syncQueueBookmarksRemove);

      debugPrint(
        '[BackgroundSync] Sync complete: ${pendingViewed.length} viewed, ${pendingBookmarkAdd.length} bookmarks added',
      );
    } catch (e) {
      debugPrint('[BackgroundSync] Sync failed (will retry): $e');
      // Queue stays intact for retry
    } finally {
      _isSyncing = false;
    }
  }

  /// Force immediate sync (call on logout)
  Future<void> forceSync() async {
    _viewedSinceLastSync = 0;
    await syncToFirebase();
  }

  /// Check if initial sync is complete
  bool get isInitialSyncComplete => _isInitialSyncDone;
}

/// Provider for the sync service
final backgroundSyncServiceProvider = Provider<BackgroundSyncService>((ref) {
  return BackgroundSyncService.instance;
});
