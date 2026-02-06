import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
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

  void _onPanStart(DragStartDetails details) {
    if (!widget.enabled || widget.index != widget.activeIndex) return;
    _controller.stop(); // Stop any ongoing animation
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!widget.enabled || widget.index != widget.activeIndex) return;
    setState(() {
      // Accumulate drag
      _dragOffset += details.delta;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (!widget.enabled || widget.index != widget.activeIndex) return;

    final velocity = details.velocity.pixelsPerSecond;
    final dy = _dragOffset.dy;

    // Thresholds
    const flingVelocity = 800.0;
    const distanceThreshold = 150.0;

    bool shouldDismiss = false;
    bool isUp = false;

    // Check velocity or distance
    if (velocity.dy < -flingVelocity || dy < -distanceThreshold) {
      shouldDismiss = true;
      isUp = true;
    } else if (velocity.dy > flingVelocity || dy > distanceThreshold) {
      shouldDismiss = true;
      isUp = false;
    }

    if (shouldDismiss) {
      HapticFeedback.mediumImpact();
      _animateOut(velocity, isUp);
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

  Future<void> _animateOut(Offset pixelsPerSecond, bool up) async {
    // Fly off screen
    final endY = up ? -1000.0 : 1000.0;
    // Calculate end X based on trajectory to feel natural
    final endX = _dragOffset.dx + (pixelsPerSecond.dx * 0.3);

    _animation = Tween<Offset>(
      begin: _dragOffset,
      end: Offset(endX, endY),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.duration = const Duration(milliseconds: 300);
    await _controller.forward(from: 0);

    if (mounted) {
      if (up) {
        widget.onSwipeUp?.call();
      } else {
        widget.onSwipeDown?.call();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isActive = widget.index == widget.activeIndex;
    final int stackIndex = widget.index - widget.activeIndex;

    // Visual calculations for stack effect
    // Top card (0) -> scale 1.0, y 0
    // Next card (1) -> scale 0.95, y 20
    // Next card (2) -> scale 0.90, y 40

    // If we are dragging the top card, the cards behind should animate slightly forward
    // but for simplicity, let's keep them static or just basic positional offset first to fix the "hell" behavior.

    final scale = (1.0 - (stackIndex * 0.05)).clamp(0.8, 1.0);
    final offsetY = stackIndex * 15.0; // Vertical stacking offset

    // For the active card, we add the drag offset
    final transformX = isActive ? _dragOffset.dx : 0.0;
    final transformY = isActive ? _dragOffset.dy : 0.0;

    // Rotation based on X drag (only for active card)
    final rotation = isActive ? (_dragOffset.dx * 0.001).clamp(-0.2, 0.2) : 0.0;

    return Transform.translate(
      offset: Offset(transformX, transformY + offsetY),
      child: Transform.scale(
        scale: scale,
        alignment: Alignment
            .bottomCenter, // Stack from bottom looks better often, or center
        child: Transform.rotate(
          angle: rotation,
          child: GestureDetector(
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            // Important to allow touches to pass through to buttons when not dragging
            behavior: HitTestBehavior.deferToChild,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
