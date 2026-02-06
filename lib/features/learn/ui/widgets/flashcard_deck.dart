import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/models/models.dart';
import '../../../mcq/ui/widgets/swipeable_card.dart';
import '../../../mcq/providers/question_pack_provider.dart';
import 'flashcard_item.dart';

class FlashcardDeck extends ConsumerStatefulWidget {
  final VoidCallback onBack;

  const FlashcardDeck({super.key, required this.onBack});

  @override
  ConsumerState<FlashcardDeck> createState() => _FlashcardDeckState();
}

class _FlashcardDeckState extends ConsumerState<FlashcardDeck> {
  List<Flashcard> _cards = [];
  bool _isLoading = true;
  int _completed = 0;
  int _activeIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    // Real loading logic without delay

    // Convert MCQs to Flashcards (Fallback logic from RN)
    final allQuestions = ref.read(allQuestionsProvider);

    final converted = allQuestions
        .map((q) => Flashcard(
              id: q.id,
              front: q.question,
              back: q.options[
                  q.correctAnswerIndex], // Use correct option as answer
              subject: q.subject ?? 'General',
              topic: q.topic,
            ))
        .toList();

    converted.shuffle(); // Shuffle as per RN

    if (mounted) {
      setState(() {
        _cards = converted.take(20).toList(); // Limit to 20 for now
        _isLoading = false;
      });
    }
  }

  void _handleSwipe() {
    setState(() {
      _completed++;
      if (_activeIndex < _cards.length - 1) {
        _activeIndex++;
      } else {
        // Deck complete
      }
    });
  }

  void _reset() {
    setState(() {
      _activeIndex = 0;
      _completed = 0;
      _cards.shuffle();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoading && (_cards.isEmpty || _completed >= _cards.length)) {
      return _buildCompletedView();
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: widget.onBack,
                    icon: Icon(LucideIcons.arrowLeft, color: context.textColor),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '$_completed / ${_cards.length}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: context.textSecondaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value:
                                _cards.isEmpty ? 0 : _completed / _cards.length,
                            backgroundColor: context.borderColor,
                            valueColor:
                                AlwaysStoppedAnimation(context.primaryColor),
                            minHeight: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 48), // Balance header
                ],
              ),
            ),

            // Card Stack
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildCardStack(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardStack() {
    // Show top card only for flashcards, maybe 1 bg card
    // Using simple stack logic

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background card placeholder
          if (_activeIndex < _cards.length - 1)
            Transform.translate(
              offset: const Offset(0, 10),
              child: Transform.scale(
                scale: 0.95,
                child: Opacity(
                  opacity: 0.5,
                  child: FlashcardItem(
                    card: _cards[_activeIndex + 1],
                  ),
                ),
              ),
            ),

          // Active card
          SwipeableCard(
            key: ValueKey(_cards[_activeIndex].id),
            index: 0,
            activeIndex: 0,
            onSwipeUp: _handleSwipe,
            onSwipeDown: _handleSwipe,
            child: FlashcardItem(
              card: _cards[_activeIndex],
              isActive: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedView() {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.checkCircle,
                  size: 72, color: context.successColor),
              const SizedBox(height: 24),
              const Text(
                'Deck Complete!',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'You reviewed $_completed cards',
                style:
                    TextStyle(fontSize: 16, color: context.textSecondaryColor),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _reset,
                icon: const Icon(LucideIcons.rotateCcw, size: 18),
                label: const Text('Start Over'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: widget.onBack,
                child: const Text('Back to Learn'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
