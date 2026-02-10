import 'package:flutter_test/flutter_test.dart';
import 'package:neetflow_flutter/core/models/mcq.dart';

void main() {
  group('MCQ Model Tests', () {
    const validJson = {
      'id': '101',
      'subject': 'Anatomy',
      'topic': 'Upper Limb',
      'question': 'What is the nerve supply of the deltoid muscle?',
      'options': ['Axillary nerve', 'Radial nerve', 'Ulnar nerve', 'Median nerve'],
      'correctAnswerIndex': 0,
      'explanation': 'The axillary nerve supplies the deltoid and teres minor.',
      'exam_tags': ['NEET-PG 2023'],
      'imageUrl': 'https://example.com/deltoid.png',
    };

    test('supports value comparisons', () {
      final mcq1 = MCQ.fromJson(validJson);
      final mcq2 = MCQ.fromJson(validJson);
      expect(mcq1, equals(mcq2));
    });

    test('toJson returns valid map', () {
      final mcq = MCQ.fromJson(validJson);
      final json = mcq.toJson();
      expect(json['id'], '101'); // ID is preserved as is because no packId/index passed
      expect(json['subject'], 'Anatomy');
      expect(json['correctAnswerIndex'], 0);
      expect(json['exam_tags'], ['NEET-PG 2023']);
    });

    group('fromJson Parsing', () {
      test('parses valid JSON correctly', () {
        final mcq = MCQ.fromJson(validJson);
        expect(mcq.id, '101');
        expect(mcq.subject, 'Anatomy');
        expect(mcq.question, 'What is the nerve supply of the deltoid muscle?');
        expect(mcq.options, hasLength(4));
        expect(mcq.correctAnswerIndex, 0);
        expect(mcq.examTags, contains('NEET-PG 2023'));
        expect(mcq.imageUrl, 'https://example.com/deltoid.png');
      });

      test('handles "text" field as fallback for "question"', () {
        final json = Map<String, dynamic>.from(validJson)..remove('question');
        json['text'] = 'Fallback question text';
        final mcq = MCQ.fromJson(json);
        expect(mcq.question, 'Fallback question text');
      });

      test('handles "correct_index" field as fallback for "correctAnswerIndex"', () {
        final json = Map<String, dynamic>.from(validJson)..remove('correctAnswerIndex');
        json['correct_index'] = 2;
        final mcq = MCQ.fromJson(json);
        expect(mcq.correctAnswerIndex, 2);
      });

      test('handles "image_url" field as fallback for "imageUrl"', () {
        final json = Map<String, dynamic>.from(validJson)..remove('imageUrl');
        json['image_url'] = 'https://fallback.com/image.png';
        final mcq = MCQ.fromJson(json);
        expect(mcq.imageUrl, 'https://fallback.com/image.png');
      });

      test('handles missing optional fields', () {
        final json = {
          'question': 'Simple question',
          'options': ['A', 'B'],
          'correctAnswerIndex': 1,
        };
        final mcq = MCQ.fromJson(json);
        expect(mcq.subject, isNull);
        expect(mcq.topic, isNull);
        expect(mcq.explanation, isNull);
        expect(mcq.examTags, isNull);
        expect(mcq.imageUrl, isNull);
      });
    });

    group('Text Sanitization', () {
      test('removes "Options:" block at end', () {
        final json = Map<String, dynamic>.from(validJson);
        json['question'] = 'Question text.\n\nOptions:\nA. Op1\nB. Op2';
        final mcq = MCQ.fromJson(json);
        expect(mcq.question, 'Question text.');
      });

      test('removes "A." block at end', () {
        final json = Map<String, dynamic>.from(validJson);
        json['question'] = 'Question text.\n\nA. Op1\nB. Op2';
        final mcq = MCQ.fromJson(json);
        expect(mcq.question, 'Question text.');
      });

      test('removes "Answer:" key at end', () {
        final json = Map<String, dynamic>.from(validJson);
        json['question'] = 'Question text.\nAnswer: A';
        final mcq = MCQ.fromJson(json);
        expect(mcq.question, 'Question text.');
      });

      test('removes "Correct Answer:" key at end', () {
        final json = Map<String, dynamic>.from(validJson);
        json['question'] = 'Question text.\nCorrect Answer: B';
        final mcq = MCQ.fromJson(json);
        expect(mcq.question, 'Question text.');
      });

       test('handles empty text gracefully', () {
        final json = Map<String, dynamic>.from(validJson);
        json['question'] = '';
        final mcq = MCQ.fromJson(json);
        expect(mcq.question, 'Question text missing');
      });
    });

    group('ID Generation Logic', () {
      test('uses "packId_id" when both id and packId provided', () {
        final mcq = MCQ.fromJson(validJson, packId: 'pack123');
        expect(mcq.id, 'pack123_101');
      });

      test('uses "packId_q_index" when packId and index provided but no id in json', () {
        final json = Map<String, dynamic>.from(validJson)..remove('id');
        final mcq = MCQ.fromJson(json, packId: 'pack123', index: 5);
        expect(mcq.id, 'pack123_q_5');
      });

      test('generates random ID if no id, packId, or index available', () {
         final json = Map<String, dynamic>.from(validJson)..remove('id');
         final mcq = MCQ.fromJson(json);
         expect(mcq.id, startsWith('unknown_'));
      });

      test('uses json["id"] if packId is missing', () {
         final mcq = MCQ.fromJson(validJson);
         expect(mcq.id, '101');
      });
    });

    group('copyWith', () {
      test('copies object with modified fields', () {
        final mcq = MCQ.fromJson(validJson);
        final copy = mcq.copyWith(question: 'New Question');
        expect(copy.question, 'New Question');
        expect(copy.id, mcq.id); // Other fields remain same
        expect(copy.options, mcq.options);
      });

      test('copies object with no changes if arguments are null', () {
        final mcq = MCQ.fromJson(validJson);
        final copy = mcq.copyWith();
        expect(copy, equals(mcq));
      });
    });
  });
}
