import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../providers/exam_provider.dart';

class ScoreReportView extends StatelessWidget {
  final ExamState examState;
  final WidgetRef ref;

  const ScoreReportView({
    super.key,
    required this.examState,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate results
    int correct = 0;
    int wrong = 0;
    int skipped = 0;

    for (final q in examState.currentQuestions) {
      final answer = examState.userAnswers[q.id];
      if (answer == null) {
        skipped++;
      } else if (answer == q.correctAnswerIndex) {
        correct++;
      } else {
        wrong++;
      }
    }

    final total = examState.currentQuestions.length;
    final percentage = total > 0 ? (correct / total * 100).round() : 0;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 60),

            // Score Header
            _buildScoreHeader(context, percentage),

            // Stats Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatItem(
                    label: 'Correct',
                    value: '$correct',
                    color: context.successColor,
                  ),
                  _StatItem(
                    label: 'Wrong',
                    value: '$wrong',
                    color: context.errorColor,
                  ),
                  _StatItem(
                    label: 'Skipped',
                    value: '$skipped',
                    color: context.textSecondaryColor,
                  ),
                ],
              ),
            ),

            // Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          ref.read(examStateProvider.notifier).reset(),
                      icon: Icon(LucideIcons.home, color: context.textColor),
                      label: Text(
                        'Home',
                        style: TextStyle(color: context.textColor),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        side: BorderSide(color: context.borderColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          ref.read(examStateProvider.notifier).reset(),
                      icon: const Icon(LucideIcons.rotateCcw),
                      label: const Text('New Test'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Question Review
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Question Review',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: context.textColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 40),
              child: Column(
                children: examState.currentQuestions.asMap().entries.map((
                  entry,
                ) {
                  final index = entry.key;
                  final q = entry.value;
                  final userAnswer = examState.userAnswers[q.id];

                  return _ReviewItem(
                    index: index + 1,
                    question: q,
                    userAnswer: userAnswer,
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreHeader(BuildContext context, int percentage) {
    Color borderColor = percentage >= 70
        ? context.successColor
        : percentage >= 40
        ? context.warningColor
        : context.errorColor;

    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: 8),
            color: context.cardSurfaceColor,
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$percentage%',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: context.textColor,
                ),
              ),
              Text(
                'SCORE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: context.textSecondaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: context.textSecondaryColor),
        ),
      ],
    );
  }
}

class _ReviewItem extends StatefulWidget {
  final int index;
  final dynamic question; // MCQ
  final int? userAnswer;

  const _ReviewItem({
    required this.index,
    required this.question,
    required this.userAnswer,
  });

  @override
  State<_ReviewItem> createState() => _ReviewItemState();
}

class _ReviewItemState extends State<_ReviewItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    final correctIndex = q.correctAnswerIndex;
    final isCorrect = widget.userAnswer == correctIndex;
    final isSkipped = widget.userAnswer == null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.cardSurfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        children: [
          // Header (Clickable)
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Status Icon
                  if (isSkipped)
                    Icon(
                      LucideIcons.minusCircle,
                      color: context.textSecondaryColor,
                      size: 24,
                    )
                  else if (isCorrect)
                    Icon(
                      LucideIcons.checkCircle,
                      color: context.successColor,
                      size: 24,
                    )
                  else
                    Icon(
                      LucideIcons.xCircle,
                      color: context.errorColor,
                      size: 24,
                    ),

                  const SizedBox(width: 12),

                  // Summary
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Question ${widget.index}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: context.textSecondaryColor,
                          ),
                        ),
                        Text(
                          q.question,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: context.textColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Icon(
                    _isExpanded
                        ? LucideIcons.chevronUp
                        : LucideIcons.chevronDown,
                    color: context.textSecondaryColor,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // Expanded Content
          if (_isExpanded)
            Container(
              padding: const EdgeInsets.all(16),
              color: context.isDark ? Colors.black12 : Colors.grey[50],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    q.question,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: context.textColor,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Options
                  ...List.generate(q.options.length, (i) {
                    final isOptCorrect = i == correctIndex;
                    final isOptSelected = widget.userAnswer == i;

                    Color bgColor = Colors.transparent;
                    Color borderColor = context.borderColor;

                    if (isOptCorrect) {
                      bgColor = context.successColor.withValues(alpha: 0.1);
                      borderColor = context.successColor;
                    } else if (isOptSelected && !isOptCorrect) {
                      bgColor = context.errorColor.withValues(alpha: 0.1);
                      borderColor = context.errorColor;
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '${String.fromCharCode(65 + i)}.',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: isOptCorrect
                                  ? context.successColor
                                  : context.textSecondaryColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              q.options[i],
                              style: TextStyle(
                                color: isOptCorrect
                                    ? context.successColor
                                    : context.textColor,
                                fontWeight: isOptCorrect
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (isOptCorrect)
                            Icon(
                              LucideIcons.check,
                              size: 16,
                              color: context.successColor,
                            ),
                          if (isOptSelected && !isOptCorrect)
                            Icon(
                              LucideIcons.x,
                              size: 16,
                              color: context.errorColor,
                            ),
                        ],
                      ),
                    );
                  }),

                  if (q.explanation != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: context.cardSurfaceColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border(
                          left: BorderSide(
                            color: context.primaryColor,
                            width: 4,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Explanation:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: context.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            q.explanation!,
                            style: TextStyle(
                              fontSize: 14,
                              color: context.textSecondaryColor,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
