import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/models.dart';
import '../../mcq/repositories/mcq_repository.dart';

import '../../auth/providers/auth_provider.dart';

/// Bookmark state provider - Local-First Implementation
/// Uses MCQRepository for all data access
final bookmarkStateProvider =
    StateNotifierProvider<BookmarkNotifier, List<MCQ>>((ref) {
      // Watch auth state to trigger rebuild on user change
      ref.watch(authStateProvider);
      return BookmarkNotifier();
    });

class BookmarkNotifier extends StateNotifier<List<MCQ>> {
  final MCQRepository _repository = MCQRepository.instance;

  BookmarkNotifier() : super([]) {
    _loadFromStorage();
  }

  /// Load bookmarks from local storage
  void _loadFromStorage() {
    state = _repository.getBookmarks();
  }

  /// Add bookmark (local-first, instant)
  Future<void> addBookmark(MCQ question, String? userId) async {
    // Check if already bookmarked
    if (state.any((q) => q.id == question.id)) return;

    // Optimistic update
    state = [...state, question];

    // Store locally (queues for Firebase sync automatically)
    await _repository.addBookmark(question);
  }

  /// Remove bookmark (local-first, instant)
  Future<void> removeBookmark(String questionId, String? userId) async {
    // Optimistic update
    state = state.where((q) => q.id != questionId).toList();

    // Remove locally (queues for Firebase sync automatically)
    await _repository.removeBookmark(questionId);
  }

  /// Check if bookmarked
  bool isBookmarked(String questionId) {
    return _repository.isBookmarked(questionId);
  }

  /// Clear all bookmarks
  Future<void> clearBookmarks() async {
    state = [];
    // Note: Would need to implement in repository if needed
  }

  /// Refresh from local storage
  void refresh() {
    _loadFromStorage();
  }
}

/// Check if specific question is bookmarked
final isBookmarkedProvider = Provider.family<bool, String>((ref, questionId) {
  final bookmarks = ref.watch(bookmarkStateProvider);
  return bookmarks.any((q) => q.id == questionId);
});
