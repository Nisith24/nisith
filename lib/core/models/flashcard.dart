/// Flashcard Model - Matches React Native types
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
      id: json['id']?.toString() ?? '',
      front: json['front']?.toString() ?? '',
      back: json['back']?.toString() ?? '',
      subject: json['subject']?.toString() ?? 'General',
      topic: json['topic']?.toString(),
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
