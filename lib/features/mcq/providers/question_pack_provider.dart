import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/models.dart';
import '../../auth/providers/auth_provider.dart';

/// Subject weights for balanced MCQ selection
const Map<String, int> subjectWeights = {
  'Medicine': 30,
  'Surgery': 30,
  'OBG': 25,
  'Pediatrics': 25,
  'Anesthesia': 20,
  'Pharmacology': 20,
  'Psychiatry': 15,
  'ENT': 15,
  'Anatomy': 10,
  'Physiology': 10,
};

/// Question packs provider - replaces React Native questionPackStore + useQuestionPacksQuery
final questionPacksProvider = FutureProvider<List<QuestionPack>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final snapshot =
      await FirebaseFirestore.instance.collection('question_packs').get();

  return snapshot.docs
      .map((doc) => QuestionPack.fromJson(doc.data(), doc.id))
      .toList();
});

/// Selected pack provider
final selectedPackProvider = StateProvider<QuestionPack?>((ref) => null);

/// All questions provider - flattens all packs
final allQuestionsProvider = Provider<List<MCQ>>((ref) {
  final packs = ref.watch(questionPacksProvider);
  return packs.maybeWhen(
    data: (packs) => packs.expand((p) => p.questions).toList(),
    orElse: () => [],
  );
});

/// Weighted MCQ selection - matches React Native getSubjectWeightedMCQs
final weightedMCQsProvider =
    Provider.family<List<MCQ>, int>((ref, questionCount) {
  final allQuestions = ref.watch(allQuestionsProvider);
  final userProfile = ref.watch(userProfileProvider);

  if (allQuestions.isEmpty) return [];

  final viewedIds = userProfile?.viewedMcqIds.toSet() ?? {};
  final unviewed =
      allQuestions.where((q) => !viewedIds.contains(q.id)).toList();
  final pool = unviewed.length >= questionCount ? unviewed : allQuestions;

  // Group by subject
  final bySubject = <String, List<MCQ>>{};
  for (final q in pool) {
    final subject = q.subject ?? 'General';
    bySubject.putIfAbsent(subject, () => []).add(q);
  }

  final subjects = bySubject.keys.toList();
  final totalWeight =
      subjects.fold<int>(0, (total, s) => total + (subjectWeights[s] ?? 5));

  final selected = <MCQ>[];
  final random = Random();

  for (var i = 0; i < questionCount && selected.length < pool.length; i++) {
    var r = random.nextDouble() * totalWeight;
    String? chosenSubject;

    for (final sub in subjects) {
      r -= subjectWeights[sub] ?? 5;
      if (r <= 0) {
        chosenSubject = sub;
        break;
      }
    }

    chosenSubject ??= subjects.first;

    final subjectPool = bySubject[chosenSubject];
    if (subjectPool != null && subjectPool.isNotEmpty) {
      final randomIndex = random.nextInt(subjectPool.length);
      final question = subjectPool.removeAt(randomIndex);
      selected.add(question);

      if (subjectPool.isEmpty) {
        bySubject.remove(chosenSubject);
        subjects.remove(chosenSubject);
      }
    }
  }

  // Shuffle result
  selected.shuffle(random);
  return selected;
});

/// Questions from specific pack
List<MCQ> getQuestionsFromPack(List<QuestionPack> packs, String packId) {
  final pack = packs.firstWhere(
    (p) => p.id == packId || p.packId == packId,
    orElse: () => throw Exception('Pack not found'),
  );
  return pack.questions;
}
