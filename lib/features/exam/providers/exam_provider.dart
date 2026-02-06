import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/models.dart';


/// Test status enum
enum TestStatus { idle, running, completed }

/// Filter mode enum
enum FilterMode { subject, exam, mixed }

/// Exam state - matches React Native examStore
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
    );
  }
}

/// Exam state provider
final examStateProvider = StateNotifierProvider<ExamNotifier, ExamState>((ref) {
  return ExamNotifier();
});

class ExamNotifier extends StateNotifier<ExamState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  ExamNotifier() : super(const ExamState());

  /// Fetch next question pack
  Future<void> fetchNextPack() async {
    if (state.isLoading) return;
    
    state = state.copyWith(isLoading: true, error: null);

    try {
      Query query = _firestore.collection('question_packs');
      
      // Apply filter
      if (state.filterMode == FilterMode.subject && state.selectedFilter != null) {
        query = query.where('subject', isEqualTo: state.selectedFilter);
      } else if (state.filterMode == FilterMode.exam && state.selectedFilter != null) {
        query = query.where('exam_tags', arrayContains: state.selectedFilter);
      }
      
      // Exclude already fetched (limited to 10 for Firestore constraint)
      // Note: Firestore 'not-in' requires excludeIds to be non-empty
      // We handle this by fetching and filtering client-side if needed
      
      query = query.limit(1);
      
      final snapshot = await query.get();
      
      if (snapshot.docs.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          error: 'No more packs available for this filter',
        );
        return;
      }
      
      // Find first pack not already fetched
      DocumentSnapshot? packDoc;
      for (final doc in snapshot.docs) {
        if (!state.fetchedPackIds.contains(doc.id)) {
          packDoc = doc;
          break;
        }
      }
      
      if (packDoc == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'No more packs available',
        );
        return;
      }
      
      final packData = packDoc.data() as Map<String, dynamic>;
      final pack = QuestionPack.fromJson(packData, packDoc.id);
      
      state = state.copyWith(
        currentQuestions: pack.questions,
        currentPackId: packDoc.id,
        questionIndex: 0,
        fetchedPackIds: [...state.fetchedPackIds, packDoc.id],
        isLoading: false,
        error: null,
        testStatus: TestStatus.idle,
        userAnswers: {},
        testStartTime: null,
        testEndTime: null,
      );
      
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to fetch questions. Please try again.',
      );
    }
  }

  /// Set filter
  void setFilter(FilterMode mode, [String? value]) {
    state = ExamState(
      filterMode: mode,
      selectedFilter: value,
    );
  }

  /// Start test
  void startTest() {
    state = state.copyWith(
      testStatus: TestStatus.running,
      userAnswers: {},
      testStartTime: DateTime.now().millisecondsSinceEpoch,
      testEndTime: null,
      questionIndex: 0,
    );
  }

  /// Submit answer
  void submitAnswer(String questionId, int optionIndex) {
    state = state.copyWith(
      userAnswers: {...state.userAnswers, questionId: optionIndex},
    );
  }

  /// Complete test
  void completeTest() {
    state = state.copyWith(
      testStatus: TestStatus.completed,
      testEndTime: DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Next question
  void nextQuestion() {
    if (state.questionIndex < state.currentQuestions.length - 1) {
      state = state.copyWith(questionIndex: state.questionIndex + 1);
    }
  }

  /// Previous question
  void previousQuestion() {
    if (state.questionIndex > 0) {
      state = state.copyWith(questionIndex: state.questionIndex - 1);
    }
  }

  /// Go to specific question
  void goToQuestion(int index) {
    if (index >= 0 && index < state.currentQuestions.length) {
      state = state.copyWith(questionIndex: index);
    }
  }

  /// Reset state
  void reset() {
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
