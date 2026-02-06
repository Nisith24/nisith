import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/user_profile.dart';
import '../../../core/storage/hive_service.dart';

/// Auth state - matches React Native AuthContext
class AuthState {
  final User? user;
  final UserProfile? userProfile;
  final bool isLoading;

  const AuthState({
    this.user,
    this.userProfile,
    this.isLoading = true,
  });

  AuthState copyWith({
    User? user,
    UserProfile? userProfile,
    bool? isLoading,
  }) {
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

  StreamSubscription<User?>? _authSubscription;

  // Viewed MCQ batching - matches React Native implementation
  final List<String> _viewedQueue = [];
  Timer? _syncTimer;
  static const _batchSize = 25;
  static const _syncInterval = Duration(minutes: 5);

  AuthNotifier() : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    _authSubscription = _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? user) async {
    if (user == null) {
      state = const AsyncValue.data(
          AuthState(user: null, userProfile: null, isLoading: false));
      HiveService.setBool(StorageKeys.authState, false);
      return;
    }

    state = AsyncValue.data(AuthState(user: user, isLoading: true));
    HiveService.setBool(StorageKeys.authState, true);

    try {
      // Try cached profile first
      final cachedProfile = HiveService.getJson(StorageKeys.cachedUserProfile);
      if (cachedProfile != null) {
        try {
          final profile = UserProfile.fromJson(cachedProfile);
          if (profile.uid == user.uid) {
            state = AsyncValue.data(
                AuthState(user: user, userProfile: profile, isLoading: false));
          }
        } catch (e) {
          debugPrint('Error parsing cached profile: $e');
        }
      }

      // Fetch fresh profile
      final doc = await _firestore.collection('users').doc(user.uid).get();
      UserProfile profile;

      if (doc.exists) {
        profile = UserProfile.fromJson(doc.data()!);
      } else {
        // Create default profile
        profile = UserProfile.createDefault(
          uid: user.uid,
          email: user.email,
          displayName: user.displayName,
        );
        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(profile.toJson());
      }

      // Cache profile
      await HiveService.setJson(
          StorageKeys.cachedUserProfile, profile.toJson());

      state = AsyncValue.data(
          AuthState(user: user, userProfile: profile, isLoading: false));

      // Sync any pending viewed MCQs
      _syncViewedToFirebase();
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
      await _syncViewedToFirebase();
      await _auth.signOut();
      await HiveService.removeString(StorageKeys.cachedUserProfile);
    } catch (e) {
      debugPrint('SignOut Error: $e');
    }
  }

  /// Mark MCQ as viewed - batched for performance
  void markMcqViewed(String mcqId) {
    _viewedQueue.add(mcqId);

    // Optimistic local update
    final current = state.valueOrNull;
    if (current?.userProfile != null) {
      final updatedProfile = current!.userProfile!.copyWith(
        viewedMcqIds: [...current.userProfile!.viewedMcqIds, mcqId],
      );
      state = AsyncValue.data(current.copyWith(userProfile: updatedProfile));
    }

    // Sync if batch size reached
    if (_viewedQueue.length >= _batchSize) {
      _syncViewedToFirebase();
    } else {
      // Schedule sync
      _syncTimer?.cancel();
      _syncTimer = Timer(_syncInterval, _syncViewedToFirebase);
    }
  }

  /// Sync viewed MCQs to Firebase
  Future<void> _syncViewedToFirebase() async {
    final uid = state.valueOrNull?.user?.uid;
    if (uid == null || _viewedQueue.isEmpty) return;

    final toSync = List<String>.from(_viewedQueue);
    _viewedQueue.clear();

    try {
      // Chunk large arrays (Firestore limit)
      const chunkSize = 400;
      for (var i = 0; i < toSync.length; i += chunkSize) {
        final chunk =
            toSync.sublist(i, (i + chunkSize).clamp(0, toSync.length));
        await _firestore.collection('users').doc(uid).set({
          'viewedMcqIds': FieldValue.arrayUnion(chunk),
          'lastActive': DateTime.now().millisecondsSinceEpoch,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      // Re-add to queue on failure
      debugPrint('Sync Error: $e');
      _viewedQueue.insertAll(0, toSync);
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
