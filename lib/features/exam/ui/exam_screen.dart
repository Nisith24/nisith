import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../providers/exam_provider.dart';
import 'widgets/score_report.dart';

/// ExamScreen - Test flow controller
/// Matches React Native (tabs)/exam.tsx
class ExamScreen extends ConsumerWidget {
  const ExamScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final examState = ref.watch(examStateProvider);

    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: examState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : examState.error != null
                ? _ErrorView(error: examState.error!, ref: ref)
                : switch (examState.testStatus) {
                    TestStatus.idle => _MockSetupView(
                        onStart: () =>
                            ref.read(examStateProvider.notifier).startTest(),
                      ),
                    TestStatus.running =>
                      _MockTestView(examState: examState, ref: ref),
                    TestStatus.completed =>
                      ScoreReportView(examState: examState, ref: ref),
                  },
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final WidgetRef ref;

  const _ErrorView({required this.error, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.errorColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(LucideIcons.alertTriangle,
                  color: context.errorColor, size: 48),
            ),
            const SizedBox(height: 24),
            Text(
              'Oops!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: context.textColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: context.textSecondaryColor),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: () => ref.read(examStateProvider.notifier).reset(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.textColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Back to Setup'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MockSetupView extends StatelessWidget {
  final VoidCallback onStart;

  const _MockSetupView({required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Text(
            'Mock Test',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: context.textColor,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Challenge yourself with a timed exam session. Pick your mode and subjects in the Learn tab to get started.',
            style: TextStyle(
              fontSize: 16,
              color: context.textSecondaryColor,
              height: 1.5,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: context.cardSurfaceColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: context.borderColor),
            ),
            child: Column(
              children: [
                _buildInfoRow(
                    context, LucideIcons.checkCircle2, 'Accurate scoring'),
                const SizedBox(height: 16),
                _buildInfoRow(
                    context, LucideIcons.timer, 'Mode-based time limits'),
                const SizedBox(height: 16),
                _buildInfoRow(context, LucideIcons.barChart,
                    'Detailed performance report'),
              ],
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: onStart,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
                elevation: 0,
              ),
              child: const Text(
                'Start Quick Test',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: context.primaryColor, size: 24),
        const SizedBox(width: 16),
        Text(
          text,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: context.textColor,
          ),
        ),
      ],
    );
  }
}

class _MockTestView extends StatelessWidget {
  final ExamState examState;
  final WidgetRef ref;

  const _MockTestView({required this.examState, required this.ref});

  @override
  Widget build(BuildContext context) {
    if (examState.currentQuestions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final currentQuestion = examState.currentQuestions[examState.questionIndex];
    final isLast =
        examState.questionIndex == examState.currentQuestions.length - 1;

    return Column(
      children: [
        // Top Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              IconButton(
                onPressed: () => _showExitDialog(context),
                icon: Icon(LucideIcons.x, color: context.textColor),
              ),
              const Spacer(),
              _TimerWidget(
                remaining: examState.remainingSeconds,
                total: examState.totalSeconds,
                mode: examState.testMode,
              ),
              const Spacer(),
              TextButton(
                onPressed: () => _showFinishDialog(context),
                child: Text(
                  'Finish',
                  style: TextStyle(
                    color: context.primaryColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Progress & Navigator
        _QuestionNavigator(
          currentIndex: examState.questionIndex,
          total: examState.currentQuestions.length,
          userAnswers: examState.userAnswers,
          questions: examState.currentQuestions,
          onJump: (index) =>
              ref.read(examStateProvider.notifier).goToQuestion(index),
        ),

        // Question Content
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                Text(
                  currentQuestion.question,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: context.textColor,
                    height: 1.4,
                  ),
                ),
                if (currentQuestion.imageUrl != null) ...[
                  const SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      currentQuestion.imageUrl!,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
                const SizedBox(height: 32),

                // Options
                ...currentQuestion.options.asMap().entries.map((entry) {
                  final index = entry.key;
                  final option = entry.value;
                  final isSelected =
                      examState.userAnswers[currentQuestion.id] == index;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Material(
                      color: isSelected
                          ? context.primaryColor.withValues(alpha: 0.1)
                          : context.cardSurfaceColor,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          ref
                              .read(examStateProvider.notifier)
                              .submitAnswer(currentQuestion.id, index);
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? context.primaryColor
                                  : context.borderColor,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? context.primaryColor
                                      : context.borderColor
                                          .withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  String.fromCharCode(65 + index),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: isSelected
                                        ? Colors.white
                                        : context.textSecondaryColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  option,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    color: context.textColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),

        // Bottom Navigation
        Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          decoration: BoxDecoration(
            color: context.backgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Row(
            children: [
              if (examState.questionIndex > 0)
                IconButton(
                  onPressed: () =>
                      ref.read(examStateProvider.notifier).previousQuestion(),
                  icon: Icon(LucideIcons.chevronLeft, color: context.textColor),
                ),
              const Spacer(),
              SizedBox(
                width: 140,
                height: 54,
                child: ElevatedButton(
                  onPressed: isLast
                      ? () => _showFinishDialog(context)
                      : () =>
                          ref.read(examStateProvider.notifier).nextQuestion(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.textColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isLast ? 'Review' : 'Next',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      if (!isLast) ...[
                        const SizedBox(width: 8),
                        const Icon(LucideIcons.chevronRight, size: 18),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quit Test?'),
        content: const Text('Your progress will be lost. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(examStateProvider.notifier).reset();
            },
            child: const Text('Quit', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showFinishDialog(BuildContext context) {
    final unanswered =
        examState.currentQuestions.length - examState.userAnswers.length;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finish Test?'),
        content: Text(unanswered > 0
            ? 'You have $unanswered unanswered questions. Submit anyway?'
            : 'Ready to see your results?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(examStateProvider.notifier).completeTest();
            },
            child: Text('Submit',
                style: TextStyle(
                    color: context.primaryColor, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _TimerWidget extends StatelessWidget {
  final int? remaining;
  final int? total;
  final String mode;

  const _TimerWidget({this.remaining, this.total, required this.mode});

  @override
  Widget build(BuildContext context) {
    if (mode == 'calm') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: context.borderColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.coffee, color: context.successColor, size: 14),
            const SizedBox(width: 6),
            const Text(
              'Untimed',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );
    }

    final isLow = (remaining ?? 0) <= 5;
    final color = isLow ? context.errorColor : context.textColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.timer, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            '${remaining ?? 0}s',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionNavigator extends StatelessWidget {
  final int currentIndex;
  final int total;
  final Map<String, int> userAnswers;
  final List<dynamic> questions;
  final Function(int) onJump;

  const _QuestionNavigator({
    required this.currentIndex,
    required this.total,
    required this.userAnswers,
    required this.questions,
    required this.onJump,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      margin: const EdgeInsets.only(top: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: total,
        itemBuilder: (context, index) {
          final qId = questions[index].id;
          final isAnswered = userAnswers.containsKey(qId);
          final isCurrent = index == currentIndex;

          return GestureDetector(
            onTap: () => onJump(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 40,
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
              decoration: BoxDecoration(
                color: isCurrent
                    ? context.textColor
                    : isAnswered
                        ? context.primaryColor.withValues(alpha: 0.2)
                        : context.cardSurfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isCurrent
                      ? context.textColor
                      : isAnswered
                          ? context.primaryColor
                          : context.borderColor,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isCurrent
                      ? context.cardSurfaceColor
                      : isAnswered
                          ? context.primaryColor
                          : context.textSecondaryColor,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// _ScoreReportView is now in widgets/score_report.dart
