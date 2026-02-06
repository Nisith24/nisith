import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/models.dart';
import '../../../core/storage/hive_service.dart';

/// Bookmark state provider - matches React Native bookmarkStore
final bookmarkStateProvider = StateNotifierProvider<BookmarkNotifier, List<MCQ>>((ref) {
  return BookmarkNotifier();
});

class BookmarkNotifier extends StateNotifier<List<MCQ>> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  BookmarkNotifier() : super([]) {
    _loadFromStorage();
  }

  /// Load bookmarks from local storage
  Future<void> _loadFromStorage() async {
    final stored = HiveService.getJson(StorageKeys.bookmarksData);
    if (stored != null && stored['questions'] is List) {
      final questions = (stored['questions'] as List).map((q) {
        // Safe cast from Hive dynamic type
        final map = Map<String, dynamic>.from(q as Map);
        return MCQ.fromJson(map);
      }).toList();
      state = questions;
    }
  }

  /// Save to local storage
  Future<void> _saveToStorage() async {
    await HiveService.setJson(StorageKeys.bookmarksData, {
      'questions': state.map((q) => q.toJson()).toList(),
    });
  }

  /// Add bookmark
  Future<void> addBookmark(MCQ question, String? userId) async {
    // Check if already bookmarked
    if (state.any((q) => q.id == question.id)) return;

    // Optimistic update
    state = [...state, question];
    await _saveToStorage();

    // Sync to Firestore
    if (userId != null) {
      try {
        await _firestore.collection('users').doc(userId).set({
          'bookmarked_ids': FieldValue.arrayUnion([question.id]),
        }, SetOptions(merge: true));
      } catch (e) {
        // Silent fail - offline-first approach
      }
    }
  }

  /// Remove bookmark
  Future<void> removeBookmark(String questionId, String? userId) async {
    // Optimistic update
    state = state.where((q) => q.id != questionId).toList();
    await _saveToStorage();

    // Sync to Firestore
    if (userId != null) {
      try {
        await _firestore.collection('users').doc(userId).set({
          'bookmarked_ids': FieldValue.arrayRemove([questionId]),
        }, SetOptions(merge: true));
      } catch (e) {
        // Silent fail
      }
    }
  }

  /// Check if bookmarked
  bool isBookmarked(String questionId) {
    return state.any((q) => q.id == questionId);
  }

  /// Clear all bookmarks
  Future<void> clearBookmarks() async {
    state = [];
    await HiveService.removeString(StorageKeys.bookmarksData);
  }
}

/// Check if specific question is bookmarked
final isBookmarkedProvider = Provider.family<bool, String>((ref, questionId) {
  final bookmarks = ref.watch(bookmarkStateProvider);
  return bookmarks.any((q) => q.id == questionId);
});
