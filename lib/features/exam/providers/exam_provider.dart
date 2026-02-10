import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/models.dart';
import '../../mcq/repositories/mcq_repository.dart';

/// Test status enum
enum TestStatus { idle, running, completed }

/// Filter mode enum
enum FilterMode { subject, exam, mixed }

/// State object for the Exam session
class ExamState {
  final List<MCQ> currentQuestions;
  final String? currentPackId;
  final int questionIndex;
  final FilterMode filterMode;
  final String? selectedFilter;
  final bool isLoading;
  final List<String> fetchedPackIds;
  final String? error;

  // Test state
  final TestStatus testStatus;
  final Map<String, int> userAnswers; // questionId -> selectedOptionIndex
  final int? testStartTime;
  final int? testEndTime;

  // Timer state
  final String testMode; // blaze, rapid, calm
  final int? remainingSeconds;
  final int? totalSeconds;

  const ExamState({
    this.currentQuestions = const [],
    this.currentPackId,
    this.questionIndex = 0,
    this.filterMode = FilterMode.mixed,
    this.selectedFilter,
    this.isLoading = false,
    this.fetchedPackIds = const [],
    this.error,
    this.testStatus = TestStatus.idle,
    this.userAnswers = const {},
    this.testStartTime,
    this.testEndTime,
    this.testMode = 'calm',
    this.remainingSeconds,
    this.totalSeconds,
  });

  ExamState copyWith({
    List<MCQ>? currentQuestions,
    String? currentPackId,
    int? questionIndex,
    FilterMode? filterMode,
    String? selectedFilter,
    bool? isLoading,
    List<String>? fetchedPackIds,
    String? error,
    TestStatus? testStatus,
    Map<String, int>? userAnswers,
    int? testStartTime,
    int? testEndTime,
    String? testMode,
    int? remainingSeconds,
    int? totalSeconds,
  }) {
    return ExamState(
      currentQuestions: currentQuestions ?? this.currentQuestions,
      currentPackId: currentPackId ?? this.currentPackId,
      questionIndex: questionIndex ?? this.questionIndex,
      filterMode: filterMode ?? this.filterMode,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      isLoading: isLoading ?? this.isLoading,
      fetchedPackIds: fetchedPackIds ?? this.fetchedPackIds,
      error: error,
      testStatus: testStatus ?? this.testStatus,
      userAnswers: userAnswers ?? this.userAnswers,
      testStartTime: testStartTime ?? this.testStartTime,
      testEndTime: testEndTime ?? this.testEndTime,
      testMode: testMode ?? this.testMode,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      totalSeconds: totalSeconds ?? this.totalSeconds,
    );
  }
}

/// Exam state provider
final examStateProvider = StateNotifierProvider<ExamNotifier, ExamState>((ref) {
  return ExamNotifier(ref);
});

class ExamNotifier extends StateNotifier<ExamState> {
  Timer? _timer;

  ExamNotifier(Ref ref) : super(const ExamState());

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Start test with Custom Config (Mode, Count, Subjects)
  Future<void> startTestWithConfig(Map<String, dynamic> config) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final count = config['count'] as int? ?? 10;
      final subjects = config['subjects'] as List<String>?;
      final mode = config['mode'] as String? ?? 'calm';

      final questions = await MCQRepository.instance.getQuestionsForMockTest(
        count: count,
        subjects: subjects,
      );

      if (questions.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          error: 'No questions found for the selected configuration.',
        );
        return;
      }

      state = ExamState(
        currentQuestions: questions,
        testStatus: TestStatus.running,
        testStartTime: DateTime.now().millisecondsSinceEpoch,
        isLoading: false,
        testMode: mode,
      );

      _initTimerForMode(mode);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to start test: $e',
      );
    }
  }

  void _initTimerForMode(String mode) {
    _timer?.cancel();
    int? seconds;
    if (mode == 'blaze') seconds = 10;
    if (mode == 'rapid') seconds = 30;

    if (seconds != null) {
      state = state.copyWith(remainingSeconds: seconds, totalSeconds: seconds);
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) => _tick());
    }
  }

  void _tick() {
    if (state.remainingSeconds == null || state.remainingSeconds! <= 0) {
      if (state.testMode != 'calm') {
        _handleTimeUp();
      }
      return;
    }

    state = state.copyWith(remainingSeconds: state.remainingSeconds! - 1);

    if (state.remainingSeconds == 0) {
      _handleTimeUp();
    }
  }

  void _handleTimeUp() {
    if (state.questionIndex < state.currentQuestions.length - 1) {
      // Auto move to next question
      nextQuestion();
    } else {
      // End test
      completeTest();
    }
  }

  /// Start test with specific Question Pack
  void startTestWithPack(QuestionPack pack) {
    if (pack.questions.isEmpty) {
      state = state.copyWith(error: 'This pack has no questions.');
      return;
    }

    state = ExamState(
      currentPackId: pack.id,
      currentQuestions: pack.questions,
      testStatus: TestStatus.running,
      testStartTime: DateTime.now().millisecondsSinceEpoch,
      testMode: 'calm',
    );
  }

  /// Start test (Current questions)
  void startTest() {
    if (state.currentQuestions.isEmpty) {
      fetchNextPack().then((_) {
        startTest();
      });
      return;
    }

    state = state.copyWith(
      testStatus: TestStatus.running,
      userAnswers: {},
      testStartTime: DateTime.now().millisecondsSinceEpoch,
      testEndTime: null,
      questionIndex: 0,
      testMode: 'calm',
    );
  }

  /// Fetch next question pack (Legacy/Fallback)
  Future<void> fetchNextPack() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final questions = await MCQRepository.instance.getWeightedMCQs(count: 10);

      if (questions.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          error: 'No more questions available.',
        );
        return;
      }

      state = state.copyWith(
        currentQuestions: questions,
        questionIndex: 0,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to fetch questions.',
      );
    }
  }

  /// Submit answer
  void submitAnswer(String questionId, int optionIndex) {
    if (state.testStatus != TestStatus.running) return;

    state = state.copyWith(
      userAnswers: {...state.userAnswers, questionId: optionIndex},
    );

    // If in Blaze/Rapid, maybe Auto-next after a short delay?
    // Let's keep it manual for now but maybe faster.
  }

  /// Complete test
  void completeTest() {
    if (state.testStatus == TestStatus.completed) {
      return; // Prevent double submission
    }

    _timer?.cancel();
    state = state.copyWith(
      testStatus: TestStatus.completed,
      testEndTime: DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Next question
  void nextQuestion() {
    if (state.questionIndex < state.currentQuestions.length - 1) {
      state = state.copyWith(questionIndex: state.questionIndex + 1);
      // Reset timer if blaze/rapid
      if (state.testMode != 'calm') {
        _initTimerForMode(state.testMode);
      }
    } else {
      completeTest();
    }
  }

  /// Previous question
  void previousQuestion() {
    if (state.questionIndex > 0) {
      state = state.copyWith(questionIndex: state.questionIndex - 1);
      // Reset timer? Probably not for previous, or yes?
      // In RN it usually resets for the current question space.
      if (state.testMode != 'calm') {
        _initTimerForMode(state.testMode);
      }
    }
  }

  /// Go to specific question
  void goToQuestion(int index) {
    if (index >= 0 && index < state.currentQuestions.length) {
      state = state.copyWith(questionIndex: index);
      if (state.testMode != 'calm') {
        _initTimerForMode(state.testMode);
      }
    }
  }

  /// Reset state
  void reset() {
    _timer?.cancel();
    state = const ExamState();
  }
}

/// Current question provider
final currentQuestionProvider = Provider<MCQ?>((ref) {
  final exam = ref.watch(examStateProvider);
  if (exam.currentQuestions.isEmpty) return null;
  if (exam.questionIndex >= exam.currentQuestions.length) return null;
  return exam.currentQuestions[exam.questionIndex];
});
