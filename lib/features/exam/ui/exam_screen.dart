import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      body: SafeArea(
        child: switch (examState.testStatus) {
          TestStatus.idle => _MockSetupView(
              onStart: () => ref.read(examStateProvider.notifier).startTest(),
            ),
          TestStatus.running => _MockTestView(examState: examState, ref: ref),
          TestStatus.completed =>
            ScoreReportView(examState: examState, ref: ref),
        },
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mock Test',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Test your knowledge with timed questions',
            style: TextStyle(color: context.textSecondaryColor),
          ),

          const Spacer(),

          // Quick start button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onStart,
              child: const Text('Start Test'),
            ),
          ),

          const SizedBox(height: 80), // Space for floating nav
        ],
      ),
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

    return Column(
      children: [
        // Progress header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                'Question ${examState.questionIndex + 1}/${examState.currentQuestions.length}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              TextButton(
                onPressed: () =>
                    ref.read(examStateProvider.notifier).completeTest(),
                child: const Text('Finish'),
              ),
            ],
          ),
        ),

        // Progress bar
        LinearProgressIndicator(
          value:
              (examState.questionIndex + 1) / examState.currentQuestions.length,
          backgroundColor: context.borderColor,
          valueColor: AlwaysStoppedAnimation(context.primaryColor),
        ),

        // Question display (simplified - would use MCQCard in full implementation)
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentQuestion.question,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 24),

                // Options
                ...currentQuestion.options.asMap().entries.map((entry) {
                  final index = entry.key;
                  final option = entry.value;
                  final isSelected =
                      examState.userAnswers[currentQuestion.id] == index;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Material(
                      color: isSelected
                          ? context.primaryColor.withValues(alpha: 0.1)
                          : context.cardSurfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        onTap: () => ref
                            .read(examStateProvider.notifier)
                            .submitAnswer(currentQuestion.id, index),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? context.primaryColor
                                  : context.borderColor,
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
                                      : context.borderColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  String.fromCharCode(65 + index),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? Colors.white
                                        : context.textSecondaryColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Text(option)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),

        // Navigation buttons
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (examState.questionIndex > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        ref.read(examStateProvider.notifier).previousQuestion(),
                    child: const Text('Previous'),
                  ),
                ),
              if (examState.questionIndex > 0) const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: examState.questionIndex <
                          examState.currentQuestions.length - 1
                      ? () =>
                          ref.read(examStateProvider.notifier).nextQuestion()
                      : () =>
                          ref.read(examStateProvider.notifier).completeTest(),
                  child: Text(
                    examState.questionIndex <
                            examState.currentQuestions.length - 1
                        ? 'Next'
                        : 'Submit',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// _ScoreReportView is now in widgets/score_report.dart
