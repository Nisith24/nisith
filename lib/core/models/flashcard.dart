/// Model representing a Flashcard for active recall learning
class Flashcard {
  final String id;
  final String front;
  final String back;
  final String subject;
  final String? topic;

  const Flashcard({
    required this.id,
    required this.front,
    required this.back,
    required this.subject,
    this.topic,
  });

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    return Flashcard(
      id: json['id'] as String,
      front: json['front'] as String,
      back: json['back'] as String,
      subject: json['subject'] as String? ?? 'General',
      topic: json['topic'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'front': front,
        'back': back,
        'subject': subject,
        'topic': topic,
      };
}
