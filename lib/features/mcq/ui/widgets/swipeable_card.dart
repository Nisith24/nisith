import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

/// SwipeableCard - Smoother, physics-based swipe card
class SwipeableCard extends StatefulWidget {
  final Widget child;
  final int index;
  final int activeIndex;
  final VoidCallback? onSwipeUp;
  final VoidCallback? onSwipeDown;
  final bool enabled;

  const SwipeableCard({
    super.key,
    required this.child,
    required this.index,
    required this.activeIndex,
    this.onSwipeUp,
    this.onSwipeDown,
    this.enabled = true,
  });

  @override
  State<SwipeableCard> createState() => _SwipeableCardState();
}

class _SwipeableCardState extends State<SwipeableCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // The current drag offset
  Offset _dragOffset = Offset.zero;

  // Animation state
  Animation<Offset>? _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _controller.addListener(() {
      if (_animation != null) {
        setState(() {
          _dragOffset = _animation!.value;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDragStart(DragStartDetails details) {
    if (!widget.enabled || widget.index != widget.activeIndex) return;
    _controller.stop();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!widget.enabled || widget.index != widget.activeIndex) return;
    setState(() {
      _dragOffset += Offset(details.primaryDelta ?? 0, 0);
    });
  }

  void _onDragEnd(DragEndDetails details) {
    if (!widget.enabled || widget.index != widget.activeIndex) return;

    final velocity = details.primaryVelocity ?? 0;
    final dx = _dragOffset.dx;

    const flingVelocity = 800.0;
    const distanceThreshold = 80.0;

    bool shouldDismiss = false;

    // Check horizontal only
    if (velocity.abs() > flingVelocity || dx.abs() > distanceThreshold) {
      shouldDismiss = true;
    }

    if (shouldDismiss) {
      HapticFeedback.mediumImpact();
      _animateOut(Offset(velocity, 0));
    } else {
      _animateBack();
    }
  }

  void _animateBack() {
    // Use Curve for spring-back effect since we track the offset ourselves
    _animation = Tween<Offset>(
      begin: _dragOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.duration = const Duration(milliseconds: 400);
    _controller.forward(from: 0);
  }

  Future<void> _animateOut(Offset pixelsPerSecond) async {
    // Horizontal Exit
    final endX = _dragOffset.dx > 0 ? 1000.0 : -1000.0;
    // Slight vertical drift based on random or previous momentum?
    // Since we track 0 Y, let's keep it straight or slightly arc-ed?
    // Straight is cleaner for "Next".
    final endY = 0.0;

    _animation = Tween<Offset>(
      begin: _dragOffset,
      end: Offset(endX, endY),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.duration = const Duration(milliseconds: 300);
    await _controller.forward(from: 0);

    if (mounted) {
      // Always Next?
      // User asked for "Sidewise". Left vs Right.
      // Usually Right = Like/Next, Left = Nope/Next.
      // We map both to "Next" in this app provided callbacks.
      // But wait, the callbacks are onSwipeUp/Down.
      // I should probably check direction?
      // Current deck_screen uses SwipeUp for Next.
      // Let's just call onSwipeUp (Next) for ANY horizontal dismissal for now, or map Right->Up, Left->Down?
      // Previous turn logic: Horizontal -> Next (Up).
      widget.onSwipeUp?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isActive = widget.index == widget.activeIndex;
    final int stackIndex = widget.index - widget.activeIndex;

    // Optimization: Hide cards far down the stack to save resources but keep them ready
    // We keep up to index 3 visible (4 cards total).
    if (stackIndex > 3) {
      return Offstage(offstage: true, child: widget.child);
    }

    // Visual calculations for stack effect
    // Top card (0) -> scale 1.0, y 0
    // Next card (1) -> scale 0.95, y 20
    // Next card (2) -> scale 0.90, y 40

    // Clamp scale to not get too small
    final scale = (1.0 - (stackIndex * 0.05)).clamp(0.85, 1.0);
    final offsetY = stackIndex * 15.0; // Vertical stacking offset

    // For the active card, we add the drag offset
    final transformX = isActive ? _dragOffset.dx : 0.0;
    final transformY = isActive ? _dragOffset.dy : 0.0;

    // Rotation based on X drag (only for active card)
    final rotation = isActive ? (_dragOffset.dx * 0.001).clamp(-0.2, 0.2) : 0.0;

    // Singularity Effect:
    // The card at index 3 (bottom visible) should be fully opaque but scaled down.
    // When swipes happen, index 4 (Offstage) becomes index 3 (Visible).
    // Flutter's widget reuse might make it pop in.
    // To make it smooth, maybe we allow index 3 to have opacity animated?
    // Let's keep it simple first: Offstage -> Onstage.
    // Index 3 is at the bottom of the visible stack.

    return AnimatedScale(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      scale: scale,
      alignment: Alignment.bottomCenter,
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        tween: Tween<double>(end: offsetY),
        builder: (context, animatedOffsetY, child) {
          return Transform.translate(
            offset: Offset(transformX, transformY + animatedOffsetY),
            child: Transform.rotate(
              angle: rotation,
              child: GestureDetector(
                onHorizontalDragStart: _onDragStart,
                onHorizontalDragUpdate: _onDragUpdate,
                onHorizontalDragEnd: _onDragEnd,
                behavior: HitTestBehavior
                    .translucent, // Allow touches to pass if needed? No, deferToChild is standard.
                // deferToChild is default. But we want to claim Horizontal eagerly?
                // Actually if specific HorizontalDrag is used, it should complete orthogonally to VerticalDrag.
                child: widget.child,
              ),
            ),
          );
        },
      ),
    );
  }
}
