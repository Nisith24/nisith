import 'mcq.dart';

/// Model representing a collection of MCQs within a subject or exam pack
class QuestionPack {
  final String id;
  final String packId;
  final String title;
  final String subject;
  final bool isMixed;
  final List<MCQ> questions;
  final List<String>? examTags;

  const QuestionPack({
    required this.id,
    required this.packId,
    required this.title,
    required this.subject,
    required this.isMixed,
    required this.questions,
    this.examTags,
  });

  factory QuestionPack.fromJson(Map<String, dynamic> json, String docId) {
    final packSubject = json['subject'] as String? ?? 'General';
    final packTags = (json['exam_tags'] as List<dynamic>?)?.cast<String>();

    final rawQuestions = json['questions'] as List<dynamic>? ?? [];
    final cleanedQuestions = rawQuestions.asMap().entries.map((entry) {
      final q = entry.value as Map<String, dynamic>;
      return MCQ.fromJson(
        {
          ...q,
          'subject': q['subject'] ?? packSubject,
          'exam_tags': q['exam_tags'] ?? packTags,
        },
        packId: docId,
        index: entry.key,
      );
    }).toList();

    return QuestionPack(
      id: docId,
      packId: json['pack_id'] as String? ?? docId,
      title: json['title'] as String? ?? 'Untitled Pack',
      subject: packSubject,
      isMixed: json['is_mixed'] as bool? ?? false,
      questions: cleanedQuestions,
      examTags: packTags,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'pack_id': packId,
        'title': title,
        'subject': subject,
        'is_mixed': isMixed,
        'questions': questions.map((q) => q.toJson()).toList(),
        'exam_tags': examTags,
      };
}
