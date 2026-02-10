import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/models/models.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/constants.dart';

/// MCQCard - Premium card that expands into a full-screen Focus Mode in a singular motion
class MCQCard extends ConsumerStatefulWidget {
  final MCQ mcq;
  final MCQCardMode mode;
  final void Function(int)? onAnswer;
  final VoidCallback? onToggleBookmark;
  final VoidCallback? onNext;
  final bool isBookmarked;

  const MCQCard({
    super.key,
    required this.mcq,
    this.mode = MCQCardMode.learn,
    this.onAnswer,
    this.onToggleBookmark,
    this.onNext,
    this.isBookmarked = false,
  });

  @override
  ConsumerState<MCQCard> createState() => _MCQCardState();
}

class _MCQCardState extends ConsumerState<MCQCard>
    with TickerProviderStateMixin {
  bool _revealed = false;
  int? _selectedOption;

  late AnimationController _hintController;

  @override
  void initState() {
    super.initState();

    _hintController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    if (widget.mode == MCQCardMode.test || widget.mode == MCQCardMode.review) {
      _revealed = true;
    }
  }

  @override
  void dispose() {
    _hintController.dispose();
    super.dispose();
  }

  void _handleTapToReveal() {
    if (widget.mode == MCQCardMode.learn && !_revealed) {
      HapticFeedback.selectionClick();
      setState(() => _revealed = true);
    }
  }

  void _handleOptionTap(int index) {
    if (_selectedOption != null && widget.mode != MCQCardMode.test) return;

    HapticFeedback.lightImpact();
    setState(() {
      _selectedOption = index;
    });

    widget.onAnswer?.call(index);
  }

  void _openFocusMode() async {
    HapticFeedback.mediumImpact();

    final shouldNext = await Navigator.of(context).push(
      PageRouteBuilder<bool>(
        opaque: false,
        transitionDuration: const Duration(milliseconds: 500),
        reverseTransitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (context, animation, secondaryAnimation) {
          return _FocusModeScreen(
            mcq: widget.mcq,
            selectedOption: _selectedOption,
            isBookmarked: widget.isBookmarked,
            onToggleBookmark: widget.onToggleBookmark,
          );
        },
      ),
    );

    if (shouldNext == true) {
      widget.onNext?.call();
    }
  }

  bool get _hasAnswered => _selectedOption != null;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'card_bg_${widget.mcq.id}',
      child: GestureDetector(
        onTap: () {
          if (!_revealed) {
            _handleTapToReveal();
          } else if (_hasAnswered) {
            _openFocusMode();
          }
        },
        behavior: HitTestBehavior.opaque,
        child: Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: context.cardSurfaceColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: context.borderColor, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOutCubic,
                          textAlign: _revealed
                              ? TextAlign.start
                              : TextAlign.center,
                          style: TextStyle(
                            fontSize: _revealed ? 17 : 24,
                            fontWeight: _revealed
                                ? FontWeight.w500
                                : FontWeight.w600,
                            color: context.textColor,
                            height: _revealed ? 1.5 : 1.3,
                            letterSpacing: _revealed ? 0 : -0.5,
                            fontFamily: Theme.of(
                              context,
                            ).textTheme.bodyLarge?.fontFamily,
                          ),
                          child: Text(widget.mcq.question),
                        ),
                        const SizedBox(height: 20),
                        if (!_revealed)
                          _buildTapToReveal(context)
                        else
                          _buildOptions(context),
                        if (_hasAnswered) ...[
                          const SizedBox(height: 24),
                          FadeInWidget(
                            child: Center(
                              child: _ActionButton(
                                icon: LucideIcons.maximize2,
                                label: 'Tap to see explanation',
                                onTap: _openFocusMode,
                                color: context.primaryColor,
                                isPrimary: true,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.borderColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: context.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.mcq.subject ?? 'General',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: context.primaryColor,
                    ),
                  ),
                ),
                if (widget.mcq.topic != null) ...[
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Text(
                      widget.mcq.topic!,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.textSecondaryColor,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2, // More geometric feel
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: widget.onToggleBookmark,
            icon: Icon(
              widget.isBookmarked
                  ? LucideIcons.bookmarkMinus
                  : LucideIcons.bookmark,
              color: widget.isBookmarked
                  ? context.primaryColor
                  : context.iconColor,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTapToReveal(BuildContext context) {
    return GestureDetector(
      onTap: _handleTapToReveal,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 32),
        alignment: Alignment.center,
        child: AnimatedBuilder(
          animation: _hintController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _hintController.value * 6),
              child: Opacity(
                opacity: 0.5 + _hintController.value * 0.5,
                child: Column(
                  children: [
                    Icon(
                      LucideIcons.mousePointer2,
                      size: 40,
                      color: context.primaryColor,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Tap to reveal',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildOptions(BuildContext context) {
    return Column(
      children: List.generate(widget.mcq.options.length, (index) {
        return _MCQOptionItem(
          index: index,
          text: widget.mcq.options[index],
          isSelected: _selectedOption == index,
          isCorrect: index == widget.mcq.correctAnswerIndex,
          showResult: _hasAnswered && widget.mode != MCQCardMode.test,
          onTap: () => _handleOptionTap(index),
        );
      }),
    );
  }
}

class _FocusModeScreen extends StatefulWidget {
  final MCQ mcq;
  final int? selectedOption;
  final bool isBookmarked;
  final VoidCallback? onToggleBookmark;

  const _FocusModeScreen({
    required this.mcq,
    this.selectedOption,
    required this.isBookmarked,
    this.onToggleBookmark,
  });

  @override
  State<_FocusModeScreen> createState() => _FocusModeScreenState();
}

class _FocusModeScreenState extends State<_FocusModeScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Hero(
        tag: 'card_bg_${widget.mcq.id}',
        child: Material(
          color: context.cardSurfaceColor,
          child: Stack(
            children: [
              Column(
                children: [
                  // Full Screen Header
                  SafeArea(
                    bottom: false,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(LucideIcons.chevronLeft),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Text(
                            'Detailed Explanation',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: widget.onToggleBookmark,
                            icon: Icon(
                              widget.isBookmarked
                                  ? LucideIcons.bookmarkMinus
                                  : LucideIcons.bookmark,
                              color: widget.isBookmarked
                                  ? context.primaryColor
                                  : context.iconColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Content Area
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
                      child: FadeTransition(
                        opacity: _fadeController,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Question (Contextual)
                            Text(
                              widget.mcq.question,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: context.textColor,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 32),

                            // 2. Explanation (Hero Section)
                            _buildExplanationCard(context),
                            const SizedBox(height: 32),

                            // 3. Options (Review Mode)
                            Text(
                              'OPTIONS REVIEW',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                                color: context.textColor.withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildReviewOptions(context),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Floating Bottom Controls
              Positioned(
                bottom: 30,
                left: 0,
                right: 0,
                child: FadeTransition(
                  opacity: _fadeController,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Subtle Back Button
                      TextButton.icon(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          foregroundColor: context.textSecondaryColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        icon: const Icon(LucideIcons.arrowLeft, size: 20),
                        label: const Text('Back'),
                      ),

                      // Next Action Button
                      _ActionButton(
                        icon: LucideIcons.arrowRight,
                        color: context.primaryColor,
                        onTap: () => Navigator.pop(context, true),
                        label: 'Next Question',
                        isPrimary: true,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExplanationCard(BuildContext context) {
    final isCorrect = widget.selectedOption == widget.mcq.correctAnswerIndex;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isCorrect
                      ? context.successColor.withValues(alpha: 0.1)
                      : context.errorColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      isCorrect
                          ? LucideIcons.checkCheck
                          : LucideIcons.alertCircle,
                      color: isCorrect
                          ? context.successColor
                          : context.errorColor,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isCorrect
                          ? 'Correct Explanation'
                          : 'Conceptual Breakdown',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: isCorrect
                            ? context.successColor
                            : context.errorColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            widget.mcq.explanation ??
                'No detailed explanation provided for this question.',
            style: TextStyle(
              fontSize: 18,
              color: context.textColor,
              height: 1.6,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: context.primaryColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewOptions(BuildContext context) {
    return Column(
      children: List.generate(widget.mcq.options.length, (index) {
        final isSelected = widget.selectedOption == index;
        final isCorrect = index == widget.mcq.correctAnswerIndex;
        // Only show relevant options clearly, dim the rest significantly
        final opacity = (isSelected || isCorrect) ? 1.0 : 0.3;

        return Opacity(
          opacity: opacity,
          child: _MCQOptionItem(
            index: index,
            text: widget.mcq.options[index],
            isSelected: isSelected,
            isCorrect: isCorrect,
            showResult: true,
            isCompact: true,
            onTap: () {},
          ),
        );
      }),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  final bool isPrimary;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FadeInWidget extends StatefulWidget {
  final Widget child;
  const FadeInWidget({super.key, required this.child});
  @override
  State<FadeInWidget> createState() => _FadeInWidgetState();
}

class _FadeInWidgetState extends State<FadeInWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: ScaleTransition(scale: _anim, child: widget.child),
    );
  }
}

class _MCQOptionItem extends StatelessWidget {
  final int index;
  final String text;
  final bool isSelected;
  final bool isCorrect;
  final bool showResult;
  final bool isCompact;
  final VoidCallback onTap;

  const _MCQOptionItem({
    required this.index,
    required this.text,
    required this.isSelected,
    required this.isCorrect,
    required this.showResult,
    this.isCompact = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color borderColor = context.borderColor;
    if (showResult && isCorrect) {
      borderColor = context.successColor;
    } else if (showResult && isSelected && !isCorrect) {
      borderColor = context.errorColor;
    } else if (isSelected) {
      borderColor = context.primaryColor;
    }

    final double padding = isCompact ? 10 : 16;
    final double indicatorSize = isCompact ? 24 : 32;
    final double fontSize = isCompact ? 13 : 15;

    return Container(
      margin: EdgeInsets.only(bottom: isCompact ? 8 : 12),
      decoration: BoxDecoration(
        color: (!isCompact && showResult && isCorrect)
            ? context.successColor.withValues(alpha: 0.05)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(isCompact ? 10 : 16),
        border: Border.all(
          color: isCompact && !isSelected && !isCorrect
              ? context.borderColor.withValues(alpha: 0.5)
              : borderColor,
          width: isCompact ? 1.0 : 1.5,
        ),
      ),
      child: InkWell(
        onTap: showResult ? null : onTap,
        borderRadius: BorderRadius.circular(isCompact ? 10 : 16),
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Row(
            children: [
              Container(
                width: indicatorSize,
                height: indicatorSize,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: (isSelected || (showResult && isCorrect))
                      ? borderColor
                      : context.borderColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(isCompact ? 6 : 10),
                ),
                child: Text(
                  String.fromCharCode(65 + index),
                  style: TextStyle(
                    color: (isSelected || (showResult && isCorrect))
                        ? Colors.white
                        : context.textSecondaryColor,
                    fontWeight: FontWeight.w700,
                    fontSize: isCompact ? 11 : 13,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: (isCompact && !isSelected && !isCorrect)
                        ? context.textColor.withValues(alpha: 0.7)
                        : context.textColor,
                  ),
                ),
              ),
              if (showResult && isCorrect)
                Icon(
                  LucideIcons.check,
                  color: context.successColor,
                  size: isCompact ? 16 : 20,
                )
              else if (showResult && isSelected && !isCorrect)
                Icon(
                  LucideIcons.x,
                  color: context.errorColor,
                  size: isCompact ? 16 : 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
