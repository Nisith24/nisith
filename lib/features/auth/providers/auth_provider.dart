import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/user_profile.dart';
import '../../../core/storage/hive_service.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../mcq/repositories/mcq_repository.dart';

/// Auth state - matches React Native AuthContext
class AuthState {
  final User? user;
  final UserProfile? userProfile;
  final bool isLoading;

  const AuthState({this.user, this.userProfile, this.isLoading = true});

  AuthState copyWith({User? user, UserProfile? userProfile, bool? isLoading}) {
    return AuthState(
      user: user ?? this.user,
      userProfile: userProfile ?? this.userProfile,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Auth state provider
final authStateProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<AuthState>>((ref) {
      return AuthNotifier();
    });

/// Convenience providers
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).valueOrNull?.user;
});

final userProfileProvider = Provider<UserProfile?>((ref) {
  return ref.watch(authStateProvider).valueOrNull?.userProfile;
});

class AuthNotifier extends StateNotifier<AsyncValue<AuthState>> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalStorageService _storage = LocalStorageService.instance;
  final MCQRepository _mcqRepo = MCQRepository.instance;

  StreamSubscription<User?>? _authSubscription;
  Timer? _syncTimer;
  static const _syncInterval = Duration(minutes: 2);

  AuthNotifier() : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    _authSubscription = _auth.authStateChanges().listen(_onAuthStateChanged);
    // Start background sync timer
    _syncTimer = Timer.periodic(_syncInterval, (_) => _performBackgroundSync());
  }

  Future<void> _onAuthStateChanged(User? user) async {
    if (user == null) {
      state = const AsyncValue.data(
        AuthState(user: null, userProfile: null, isLoading: false),
      );
      HiveService.setBool(StorageKeys.authState, false);
      HiveService.removeString(StorageKeys.cachedUserProfile);
      await _storage.clearUserProgress();
      _mcqRepo.clearMemoryCache();
      return;
    }

    state = AsyncValue.data(AuthState(user: user, isLoading: true));
    HiveService.setBool(StorageKeys.authState, true);

    try {
      UserProfile? profile;

      // Try cached profile first
      final cachedProfile = HiveService.getJson(StorageKeys.cachedUserProfile);
      if (cachedProfile != null) {
        try {
          final tempProfile = UserProfile.fromJson(cachedProfile);
          if (tempProfile.uid == user.uid) {
            profile = tempProfile;
          } else {
            // Wrong user cached! Clear everything immediately
            await _storage.clearUserProgress();
            _mcqRepo.clearMemoryCache();
          }
        } catch (e) {
          debugPrint('Error parsing cached profile: $e');
        }
      } else {
        // No cache, clear storage to prevent ghost data from previous session
        await _storage.clearUserProgress();
        _mcqRepo.clearMemoryCache();
      }

      // Fetch fresh profile from Firestore
      if (profile == null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          profile = UserProfile.fromJson(doc.data()!);
        } else {
          // Create default profile
          profile = UserProfile.createDefault(
            uid: user.uid,
            email: user.email,
            displayName: user.displayName,
          );
          // Wait for profile creation
          await _firestore
              .collection('users')
              .doc(user.uid)
              .set(profile.toJson());
        }
      }

      // Cache profile
      await HiveService.setJson(
        StorageKeys.cachedUserProfile,
        profile.toJson(),
      );

      // HYDRATE LOCAL STORAGE from Profile
      // This ensures UserStatsProvider has the correct initial data
      await _storage.setViewedMcqIds(profile.viewedMcqIds);
      await _storage.setBookmarkedMcqIds(profile.bookmarkedMcqIds);

      // Trigger full MCQ sync if needed
      if (_storage.isCacheStale()) {
        _mcqRepo.performFullSync().ignore();
      }

      state = AsyncValue.data(
        AuthState(user: user, userProfile: profile, isLoading: false),
      );
    } catch (e, stack) {
      debugPrint('Auth State Change Error: $e\n$stack');
      state = AsyncValue.error(e, stack);
    }
  }

  /// Sign in with email and password
  Future<void> signIn(String email, String password) async {
    try {
      state = const AsyncValue.loading();
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      debugPrint('SignIn Error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('SignIn Unexpected Error: $e');
      rethrow;
    }
  }

  /// Sign up with email and password
  Future<void> signUp(String email, String password, String name) async {
    try {
      state = const AsyncValue.loading();
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await credential.user?.updateDisplayName(name);

      final profile = UserProfile.createDefault(
        uid: credential.user!.uid,
        email: email,
        displayName: name,
      );

      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .set(profile.toJson());
    } on FirebaseAuthException catch (e) {
      debugPrint('SignUp Error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('SignUp Unexpected Error: $e');
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _performBackgroundSync(); // Sync before signout
      await _auth.signOut();
      await HiveService.removeString(StorageKeys.cachedUserProfile);
      await _storage.clearUserProgress(); // Clear local user data
      _mcqRepo.clearMemoryCache();
    } catch (e) {
      debugPrint('SignOut Error: $e');
    }
  }

  /// Mark MCQ as viewed - Uses Local Repository for instant update
  void markMcqViewed(String mcqId) {
    _mcqRepo.markAsViewed(mcqId);

    // Also update local state for consistency if needed
    // But mostly purely relies on Hive now via UserStatsProvider
  }

  /// Sync viewed and bookmarked MCQs to Firebase
  Future<void> _performBackgroundSync() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || !_storage.hasPendingSync()) return;

    try {
      final batch = _firestore.batch();
      final userRef = _firestore.collection('users').doc(uid);
      bool hasUpdates = false;

      // 1. Sync Viewed
      final viewedToAdd = _storage.getPendingViewedSync();
      if (viewedToAdd.isNotEmpty) {
        // Chunk if necessary, but for now simple union
        batch.set(userRef, {
          'viewedMcqIds': FieldValue.arrayUnion(viewedToAdd),
          'lastActive': DateTime.now().millisecondsSinceEpoch,
        }, SetOptions(merge: true));
        hasUpdates = true;
      }

      // 2. Sync Bookmarks Add
      final bookmarksToAdd = _storage.getPendingBookmarkAddSync();
      if (bookmarksToAdd.isNotEmpty) {
        batch.set(userRef, {
          'bookmarkedMcqIds': FieldValue.arrayUnion(bookmarksToAdd),
        }, SetOptions(merge: true));
        hasUpdates = true;
      }

      // 3. Sync Bookmarks Remove
      final bookmarksToRemove = _storage.getPendingBookmarkRemoveSync();
      if (bookmarksToRemove.isNotEmpty) {
        batch.set(userRef, {
          'bookmarkedMcqIds': FieldValue.arrayRemove(bookmarksToRemove),
        }, SetOptions(merge: true));
        hasUpdates = true;
      }

      if (hasUpdates) {
        await batch.commit();

        // Clear queues on success
        if (viewedToAdd.isNotEmpty) {
          await _storage.clearSyncQueue(LocalKeys.syncQueueViewed);
        }
        if (bookmarksToAdd.isNotEmpty) {
          await _storage.clearSyncQueue(LocalKeys.syncQueueBookmarksAdd);
        }
        if (bookmarksToRemove.isNotEmpty) {
          await _storage.clearSyncQueue(LocalKeys.syncQueueBookmarksRemove);
        }

        debugPrint('[AuthNotifier] Background sync completed successfully');
      }
    } catch (e) {
      debugPrint('[AuthNotifier] Background sync failed: $e');
    }
  }

  /// Update user profile locally (optimistic)
  void updateUserProfileLocally(UserProfile Function(UserProfile?) updater) {
    final current = state.valueOrNull;
    if (current == null) return;

    final updated = updater(current.userProfile);
    state = AsyncValue.data(current.copyWith(userProfile: updated));

    HiveService.setJson(StorageKeys.cachedUserProfile, updated.toJson());
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _syncTimer?.cancel();
    super.dispose();
  }
}
