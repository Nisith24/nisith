import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/models/models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/constants.dart';
import '../../mcq/ui/widgets/mcq_card.dart';
import '../../mcq/ui/widgets/swipeable_card.dart';
import '../providers/bookmark_provider.dart';

class BookmarkDeckScreen extends ConsumerStatefulWidget {
  final String? subjectFilter;

  const BookmarkDeckScreen({super.key, this.subjectFilter});

  @override
  ConsumerState<BookmarkDeckScreen> createState() => _BookmarkDeckScreenState();
}

class _BookmarkDeckScreenState extends ConsumerState<BookmarkDeckScreen> {
  int _currentIndex = 0;
  bool _isFinished = false;

  @override
  Widget build(BuildContext context) {
    final allBookmarks = ref.watch(bookmarkStateProvider);

    // Filter by subject if provided
    final cards = widget.subjectFilter != null
        ? allBookmarks.where((q) => q.subject == widget.subjectFilter).toList()
        : allBookmarks;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.arrowLeft),
                    onPressed: () => context.pop(),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          widget.subjectFilter ?? 'All Bookmarks',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (!_isFinished && cards.isNotEmpty)
                          Text(
                            '${_currentIndex + 1} of ${cards.length}',
                            style: TextStyle(
                              color: context.textSecondaryColor,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 48), // Balance spacing
                ],
              ),
            ),

            // Deck Area
            Expanded(
              child: cards.isEmpty
                  ? Center(
                      child: Text(
                        'No bookmarks found',
                        style: TextStyle(color: context.textSecondaryColor),
                      ),
                    )
                  : _isFinished
                  ? _buildFinishedView(context)
                  : IndexedStack(
                      index: 0,
                      children: [
                        // Current Card with swipe logic
                        _buildCardStack(cards),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardStack(List<MCQ> cards) {
    if (_currentIndex >= cards.length) return const SizedBox.shrink();

    final card = cards[_currentIndex];
    // Show next card behind for depth (if exists)
    final nextCard = (_currentIndex + 1 < cards.length)
        ? cards[_currentIndex + 1]
        : null;

    return Stack(
      children: [
        if (nextCard != null)
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Transform.scale(
                scale: 0.95,
                child: Opacity(
                  opacity: 0.6,
                  child: MCQCard(
                    key: ValueKey(nextCard.id),
                    mcq: nextCard,
                    mode: MCQCardMode.learn,
                  ),
                ),
              ),
            ),
          ),
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SwipeableCard(
              key: ValueKey(card.id),
              index: 0,
              activeIndex: 0,
              onSwipeUp: () {
                setState(() {
                  if (_currentIndex < cards.length - 1) {
                    _currentIndex++;
                  } else {
                    _isFinished = true;
                  }
                });
              },
              child: MCQCard(
                mcq: card,
                mode: MCQCardMode.learn,
                isBookmarked: true,
                onToggleBookmark: () {
                  ref
                      .read(bookmarkStateProvider.notifier)
                      .removeBookmark(card.id, null);
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFinishedView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.checkCircle, size: 64, color: context.successColor),
          const SizedBox(height: 16),
          const Text(
            'Review Complete!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.pop(),
            child: const Text('Back to List'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _currentIndex = 0;
                _isFinished = false;
              });
            },
            child: const Text('Review Again'),
          ),
        ],
      ),
    );
  }
}
