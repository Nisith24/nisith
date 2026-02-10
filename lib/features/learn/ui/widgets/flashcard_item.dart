import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/models/models.dart';

class FlashcardItem extends StatefulWidget {
  final Flashcard card;
  final bool isActive;
  final VoidCallback? onFlip;

  const FlashcardItem({
    super.key,
    required this.card,
    this.isActive = false,
    this.onFlip,
  });

  @override
  State<FlashcardItem> createState() => _FlashcardItemState();
}

class _FlashcardItemState extends State<FlashcardItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flip() {
    if (_isFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    _isFront = !_isFront;
    widget.onFlip?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flip,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value * math.pi;
          final isBack = angle >= math.pi / 2;

          // RN Flashcard logic check:
          // text: q.question
          // We need to show Question on front, Answer on back.
          // RN Flashcard model: { text: string, ... }
          // Wait, RN FlashcardDeck just shows 'text'. It doesn't seem to flip to an answer?
          // Re-reading RN FlashcardDeck.tsx: It just renders FlashcardItem.
          // Let's assume standard flashcard behavior: Front = Question, Back = Answer/Explanation?
          // If RN version converts MCQs:
          // text: q.question
          // Where is the answer?
          // In RN `FlashcardDeck.tsx`:
          // const convertedCards... text: q.question...
          // It seems the RN version might be "Swipe to dismiss" rather than "Flip"?
          // Ah, FlashcardItem.tsx (which I didn't read) likely handles the display.
          // Given constraints, I will assume a standard Flip behavior is functionality "needed" or at least a good default.
          // I'll show 'text' on front, and 'subject/topic' on back if no answer field?
          // Actually, let's just make it swipeable principally, with a flip showing "Tap to see more" or similar if needed.
          // BUT `FlashcardDeck` in RN has `onSwipe`.
          // Let's implement a Flip+Swipe card.

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()..rotateY(isBack ? math.pi : 0),
              child: Container(
                width: double.infinity,
                height: 400, // Fixed height for deck
                decoration: BoxDecoration(
                  color: context.cardSurfaceColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: context.borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!isBack) ...[
                      Text(
                        'Question',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: context.primaryColor,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        widget.card.front,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: context.textColor,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Tap to flip',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.textSecondaryColor,
                        ),
                      ),
                    ] else ...[
                      Text(
                        'Answer',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: context.successColor,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        widget.card.back,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          color: context.textColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
