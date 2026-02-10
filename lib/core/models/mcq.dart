/// MCQ Model - Matches React Native types/index.ts
class MCQ {
  final String id;
  final String? subject;
  final String? topic;
  final String question;
  final List<String> options;
  final int correctAnswerIndex;
  final String? explanation;
  final List<String>? examTags;
  final String? imageUrl;

  const MCQ({
    required this.id,
    this.subject,
    this.topic,
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    this.explanation,
    this.examTags,
    this.imageUrl,
  });

  factory MCQ.fromJson(
    Map<String, dynamic> json, {
    String? packId,
    int? index,
  }) {
    // Handle both 'question' and 'text' fields
    final rawText = json['question'] ?? json['text'] ?? 'Question text missing';
    final cleanedText = _sanitizeText(rawText as String);

    // Normalize correct answer index
    int correctIndex = 0;
    if (json['correctAnswerIndex'] is int) {
      correctIndex = json['correctAnswerIndex'] as int;
    } else if (json['correct_index'] is int) {
      correctIndex = json['correct_index'] as int;
    }

    // Generate unique ID
    String id;
    if (json['id'] != null && packId != null) {
      id = '${packId}_${json['id']}';
    } else if (packId != null && index != null) {
      id = '${packId}_q_$index';
    } else {
      id =
          json['id']?.toString() ??
          'unknown_${DateTime.now().millisecondsSinceEpoch}';
    }

    return MCQ(
      id: id,
      subject: json['subject'] as String?,
      topic: json['topic'] as String?,
      question: cleanedText,
      options: (json['options'] as List<dynamic>?)?.cast<String>() ?? [],
      correctAnswerIndex: correctIndex,
      explanation: json['explanation'] as String?,
      examTags: (json['exam_tags'] as List<dynamic>?)?.cast<String>(),
      imageUrl: json['imageUrl'] as String? ?? json['image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'subject': subject,
    'topic': topic,
    'question': question,
    'options': options,
    'correctAnswerIndex': correctAnswerIndex,
    'explanation': explanation,
    'exam_tags': examTags,
    'imageUrl': imageUrl,
  };

  /// Sanitize question text - remove trailing options/answers
  static String _sanitizeText(String text) {
    if (text.isEmpty) return 'Question text missing';

    // Remove "Options:" prefix or "A. ..." block at the end
    String clean = text
        .replaceAll(RegExp(r'(\n|\s)+(Options:|A\.|a\))[\s\S]*$'), '')
        .trim();

    // Remove trailing "Answer:" key
    clean = clean
        .replaceAll(
          RegExp(r'(\n|\s)+(Answer:|Ans:|Correct Answer:)[\s\S]*$'),
          '',
        )
        .trim();

    return clean;
  }

  MCQ copyWith({
    String? id,
    String? subject,
    String? topic,
    String? question,
    List<String>? options,
    int? correctAnswerIndex,
    String? explanation,
    List<String>? examTags,
    String? imageUrl,
  }) {
    return MCQ(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      topic: topic ?? this.topic,
      question: question ?? this.question,
      options: options ?? this.options,
      correctAnswerIndex: correctAnswerIndex ?? this.correctAnswerIndex,
      explanation: explanation ?? this.explanation,
      examTags: examTags ?? this.examTags,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
