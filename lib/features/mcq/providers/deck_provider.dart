import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/models.dart';
import 'question_pack_provider.dart';

/// Deck State
class DeckState {
  final List<MCQ> cards;
  final int activeIndex;
  final bool isLoading;

  const DeckState({
    this.cards = const [],
    this.activeIndex = 0,
    this.isLoading = true,
  });

  DeckState copyWith({
    List<MCQ>? cards,
    int? activeIndex,
    bool? isLoading,
  }) {
    return DeckState(
      cards: cards ?? this.cards,
      activeIndex: activeIndex ?? this.activeIndex,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Deck Notifier - Centralized management for the infinite deck
class DeckNotifier extends StateNotifier<DeckState> {
  final Ref ref;

  // Configuration
  static const int _batchSize = 10;
  static const int _preloadThreshold = 5;

  DeckNotifier(this.ref) : super(const DeckState()) {
    _loadInitialCards();
  }

  Future<void> _loadInitialCards() async {
    try {
      state = state.copyWith(isLoading: true);

      // Ensure packs are loaded
      await ref.read(questionPacksProvider.future);

      // Initial fetch
      final questions =
          ref.read(weightedMCQsProvider(_batchSize * 2)); // Load 20 initially

      if (mounted) {
        state = state.copyWith(
          cards: questions,
          isLoading: false,
        );
      }
    } catch (e) {
      debugPrint('Error loading deck: $e');
      if (mounted) {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  /// Called when a card is fully swiped away
  void nextCard() {
    final nextIndex = state.activeIndex + 1;

    // Optimistic update
    state = state.copyWith(activeIndex: nextIndex);

    // Check if we need to load more
    if (state.cards.length - nextIndex <= _preloadThreshold) {
      _loadMoreCards();
    }
  }

  Future<void> _loadMoreCards() async {
    // Avoid multiple concurrent fetches if one isn't finished?
    // Actually basic weightedMCQsProvider is synchronous in generation from the provided list,
    // so it's cheap. We just append.

    final moreQuestions = ref.read(weightedMCQsProvider(_batchSize));

    // Filter duplicates
    final currentIds = state.cards.map((e) => e.id).toSet();
    final unique =
        moreQuestions.where((q) => !currentIds.contains(q.id)).toList();

    if (unique.isNotEmpty && mounted) {
      state = state.copyWith(
        cards: [...state.cards, ...unique],
      );
    }
  }
}

/// Provider
final deckProvider = StateNotifierProvider<DeckNotifier, DeckState>((ref) {
  return DeckNotifier(ref);
});
