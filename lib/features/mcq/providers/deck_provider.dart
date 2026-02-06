import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/models.dart';
import '../../../core/services/background_sync_service.dart';
import '../repositories/mcq_repository.dart';

/// Deck State
class DeckState {
  final List<MCQ> cards;
  final int activeIndex;
  final bool isLoading;
  final String? selectedSubject;

  const DeckState({
    this.cards = const [],
    this.activeIndex = 0,
    this.isLoading = true,
    this.selectedSubject,
  });

  DeckState copyWith({
    List<MCQ>? cards,
    int? activeIndex,
    bool? isLoading,
    String? selectedSubject,
    bool clearSubject = false,
  }) {
    return DeckState(
      cards: cards ?? this.cards,
      activeIndex: activeIndex ?? this.activeIndex,
      isLoading: isLoading ?? this.isLoading,
      selectedSubject:
          clearSubject ? null : (selectedSubject ?? this.selectedSubject),
    );
  }
}

/// Deck Notifier - Local-First Implementation
/// Uses MCQRepository for all data access
class DeckNotifier extends StateNotifier<DeckState> {
  final Ref ref;
  final MCQRepository _repository = MCQRepository.instance;
  final BackgroundSyncService _syncService = BackgroundSyncService.instance;

  // Configuration (optimized numbers)
  static const int _initialBatchSize = 15;
  static const int _refillBatchSize = 15;
  static const int _preloadThreshold = 7;

  DeckNotifier(this.ref) : super(const DeckState()) {
    _loadInitialCards();
  }

  /// Refresh the deck
  void refresh() {
    state = state.copyWith(isLoading: true, activeIndex: 0, cards: []);
    _loadInitialCards();
  }

  /// Set subject filter
  void setSubjectFilter(String? subject) {
    if (state.selectedSubject == subject) return;

    state = state.copyWith(
      isLoading: true,
      activeIndex: 0,
      cards: [],
      selectedSubject: subject,
      clearSubject: subject == null,
    );
    _loadInitialCards();
  }

  /// Load initial cards from repository (local-first)
  Future<void> _loadInitialCards() async {
    try {
      final viewedIds = _repository.getViewedIds();

      final questions = await _repository.getWeightedMCQs(
        count: _initialBatchSize,
        subjectFilter: state.selectedSubject,
        viewedIds: viewedIds,
      );

      if (mounted) {
        state = state.copyWith(
          cards: questions,
          isLoading: false,
        );
      }

      debugPrint('[Deck] Loaded ${questions.length} initial cards');
    } catch (e) {
      debugPrint('[Deck] Error loading: $e');
      if (mounted) {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  /// Called when a card is swiped away
  void nextCard() {
    final nextIndex = state.activeIndex + 1;

    // Mark as viewed (local-first, instant)
    if (state.activeIndex < state.cards.length) {
      final currentCard = state.cards[state.activeIndex];
      _repository.markAsViewed(currentCard.id);

      // Notify sync service for batch tracking
      _syncService.onCardViewed();
    }

    // Optimistic update
    state = state.copyWith(activeIndex: nextIndex);

    // Check if we need to load more
    if (state.cards.length - nextIndex <= _preloadThreshold) {
      _loadMoreCards();
    }
  }

  /// Load more cards when running low
  Future<void> _loadMoreCards() async {
    final viewedIds = _repository.getViewedIds();

    final moreQuestions = await _repository.getWeightedMCQs(
      count: _refillBatchSize,
      subjectFilter: state.selectedSubject,
      viewedIds: viewedIds,
    );

    // Filter duplicates
    final currentIds = state.cards.map((e) => e.id).toSet();
    final unique =
        moreQuestions.where((q) => !currentIds.contains(q.id)).toList();

    if (unique.isNotEmpty && mounted) {
      state = state.copyWith(
        cards: [...state.cards, ...unique],
      );
      debugPrint('[Deck] Loaded ${unique.length} more cards');
    }
  }
}

/// Provider
final deckProvider = StateNotifierProvider<DeckNotifier, DeckState>((ref) {
  return DeckNotifier(ref);
});
