import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/models.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../bookmarks/providers/bookmark_provider.dart';
import '../providers/deck_provider.dart';
import 'widgets/swipeable_card.dart';
import 'widgets/mcq_card.dart';
import '../../../core/utils/constants.dart';

/// DeckScreen - Main swipeable MCQ card screen
class DeckScreen extends ConsumerStatefulWidget {
  const DeckScreen({super.key});

  @override
  ConsumerState<DeckScreen> createState() => _DeckScreenState();
}

class _DeckScreenState extends ConsumerState<DeckScreen> {
  // Local debouncer
  bool _isSwiping = false;

  void _handleSwipeComplete(bool isUp, DeckState deckState) async {
    if (_isSwiping) return;
    _isSwiping = true;

    final currentCard = deckState.cards[deckState.activeIndex];

    // Mark as viewed
    ref.read(authStateProvider.notifier).markMcqViewed(currentCard.id);

    // Notify provider to advance
    ref.read(deckProvider.notifier).nextCard();

    // Unlock swipe after a brief buffer
    await Future.delayed(const Duration(milliseconds: 200));
    _isSwiping = false;
  }

  void _handleToggleBookmark(MCQ mcq) {
    final userId = ref.read(currentUserProvider)?.uid;
    final bookmarks = ref.read(bookmarkStateProvider.notifier);

    if (bookmarks.isBookmarked(mcq.id)) {
      bookmarks.removeBookmark(mcq.id, userId);
    } else {
      bookmarks.addBookmark(mcq, userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final deckState = ref.watch(deckProvider);
    final cards = deckState.cards;
    final activeIndex = deckState.activeIndex;
    final isLoading = deckState.isLoading;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(
                    'Deck',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ),
            ),

            // Card stack
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : cards.isEmpty
                      ? _buildEmptyState()
                      : _buildCardStack(cards, activeIndex, deckState),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: context.successColor,
          ),
          const SizedBox(height: 16),
          Text(
            'All caught up!',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Come back later for more questions',
            style: TextStyle(color: context.textSecondaryColor),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // This would likely need a method in provider to force reload or reset
              // For now, we assume provider handles this if empty
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardStack(
      List<MCQ> cards, int activeIndex, DeckState deckState) {
    // Render up to 10 cards ahead for smoothness
    final visibleCount = 10;

    // We only take what is available
    final available = cards.skip(activeIndex).take(visibleCount).toList();

    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 40),
      child: Stack(
        children: available
            .asMap()
            .entries
            .map((entry) {
              final index = entry.key; // 0 to 9 ideally
              final mcq = entry.value;
              final isBookmarked = ref.watch(isBookmarkedProvider(mcq.id));

              // We only render the first 4 fully interactive or visible
              // The rest can be simplified or hidden to save resources, but
              // keeping them in the tree prevents "pop-in" of state.
              // SwipeableCard will handle the visual stacking logic using 'index'

              return SwipeableCard(
                key: ValueKey(mcq.id),
                index: index,
                activeIndex: 0, // In this sub-list, the top card is always 0
                onSwipeUp: () => _handleSwipeComplete(true, deckState),
                onSwipeDown: () => _handleSwipeComplete(false, deckState),
                // Only enable touch for the top card
                enabled: index == 0,
                child: MCQCard(
                  mcq: mcq,
                  mode: MCQCardMode.learn,
                  isBookmarked: isBookmarked,
                  onToggleBookmark: () => _handleToggleBookmark(mcq),
                  onNext: () => _handleSwipeComplete(true, deckState),
                ),
              );
            })
            .toList()
            .reversed // Stack: last in list is top visually if using Z-order?
            // NO. In Stack, last child is ON TOP.
            // So we must reverse: index 0 (Top card) should be LAST child.
            // List is [0, 1, 2...]. Reversed is [..., 2, 1, 0].
            // 0 is last -> 0 is Top. Correct.
            .toList(),
      ),
    );
  }
}
