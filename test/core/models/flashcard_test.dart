import 'package:flutter_test/flutter_test.dart';
import 'package:neetflow_flutter/core/models/flashcard.dart';

void main() {
  group('Flashcard Model Tests', () {
    test('fromJson creates a valid instance', () {
      final json = {
        'id': '1',
        'front': 'Front text',
        'back': 'Back text',
        'subject': 'Anatomy',
        'topic': 'Bones',
      };

      final flashcard = Flashcard.fromJson(json);

      expect(flashcard.id, '1');
      expect(flashcard.front, 'Front text');
      expect(flashcard.back, 'Back text');
      expect(flashcard.subject, 'Anatomy');
      expect(flashcard.topic, 'Bones');
    });

    test('fromJson handles missing topic', () {
      final json = {
        'id': '2',
        'front': 'Front',
        'back': 'Back',
        'subject': 'Physiology',
      };

      final flashcard = Flashcard.fromJson(json);

      expect(flashcard.topic, isNull);
    });

    test('fromJson defaults subject to General if missing', () {
      final json = {
        'id': '3',
        'front': 'Front',
        'back': 'Back',
      };

      final flashcard = Flashcard.fromJson(json);

      expect(flashcard.subject, 'General');
    });

    test('fromJson handles integer ID by converting to String', () {
      final json = {
        'id': 123,
        'front': 'Front',
        'back': 'Back',
      };

      final flashcard = Flashcard.fromJson(json);

      expect(flashcard.id, '123');
    });

    test('fromJson handles missing required fields gracefully', () {
      final json = <String, dynamic>{};

      final flashcard = Flashcard.fromJson(json);

      expect(flashcard.id, isEmpty);
      expect(flashcard.front, isEmpty);
      expect(flashcard.back, isEmpty);
      expect(flashcard.subject, 'General');
      expect(flashcard.topic, isNull);
    });

    test('toJson returns correct map', () {
      const flashcard = Flashcard(
        id: '1',
        front: 'Front',
        back: 'Back',
        subject: 'Subject',
        topic: 'Topic',
      );

      final json = flashcard.toJson();

      expect(json, {
        'id': '1',
        'front': 'Front',
        'back': 'Back',
        'subject': 'Subject',
        'topic': 'Topic',
      });
    });
  });
}
