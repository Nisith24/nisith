import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/models.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../bookmarks/providers/bookmark_provider.dart';
import '../../mcq/providers/question_pack_provider.dart';
import 'widgets/swipeable_card.dart';
import 'widgets/mcq_card.dart';
import '../../../core/utils/constants.dart';

/// DeckScreen - Main swipeable MCQ card screen
/// Matches React Native (tabs)/index.tsx
class DeckScreen extends ConsumerStatefulWidget {
  const DeckScreen({super.key});

  @override
  ConsumerState<DeckScreen> createState() => _DeckScreenState();
}

class _DeckScreenState extends ConsumerState<DeckScreen> {
  int _activeIndex = 0;
  List<MCQ> _cards = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    try {
      debugPrint('_loadCards: Starting...');
      // Ensure packs are loaded from Firebase
      final packs = await ref.read(questionPacksProvider.future);
      debugPrint('_loadCards: Loaded ${packs.length} packs');

      if (!mounted) return;

      // Get weighted MCQs
      final questions = ref.read(weightedMCQsProvider(10));
      debugPrint('_loadCards: Loaded ${questions.length} questions');

      setState(() {
        _cards = questions;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading cards: $e');
      if (mounted) {
        setState(() {
          _cards = [];
          _isLoading = false;
        });
      }
    }
  }

  void _handleSwipeComplete(bool isUp) {
    final currentCard = _cards[_activeIndex];

    // Mark as viewed
    ref.read(authStateProvider.notifier).markMcqViewed(currentCard.id);

    setState(() {
      _activeIndex++;

      // Load more cards if running low
      if (_activeIndex >= _cards.length - 3) {
        _loadMoreCards();
      }
    });
  }

  Future<void> _loadMoreCards() async {
    final moreQuestions = ref.read(weightedMCQsProvider(5));
    setState(() {
      _cards.addAll(moreQuestions);
    });
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
                    'Practice',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const Spacer(),
                  if (_cards.isNotEmpty) _buildProgressIndicator(),
                ],
              ),
            ),

            // Card stack
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _cards.isEmpty
                      ? _buildEmptyState()
                      : _buildCardStack(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: context.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${_activeIndex + 1} / ${_cards.length}',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: context.primaryColor,
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
              setState(() => _isLoading = true);
              _loadCards();
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

  Widget _buildCardStack() {
    // Show 3 cards in stack
    final visibleCards = _cards.skip(_activeIndex).take(3).toList();

    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 40),
      child: Stack(
        children: visibleCards
            .asMap()
            .entries
            .map((entry) {
              final index = entry.key;
              final mcq = entry.value;
              final isBookmarked = ref.watch(isBookmarkedProvider(mcq.id));

              return SwipeableCard(
                key: ValueKey(mcq.id),
                index: index,
                activeIndex: 0,
                onSwipeUp: () => _handleSwipeComplete(true),
                onSwipeDown: () => _handleSwipeComplete(false),
                child: MCQCard(
                  mcq: mcq,
                  mode: MCQCardMode.learn,
                  isBookmarked: isBookmarked,
                  onToggleBookmark: () => _handleToggleBookmark(mcq),
                  onNext: () => _handleSwipeComplete(true),
                ),
              );
            })
            .toList()
            .reversed
            .toList(),
      ),
    );
  }
}
