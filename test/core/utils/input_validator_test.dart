import 'package:flutter_test/flutter_test.dart';
import 'package:neetflow_flutter/core/utils/input_validator.dart';

void main() {
  group('InputValidator', () {
    test('isValidId rejects invalid characters', () {
      expect(InputValidator.isValidId('valid_id-123'), isTrue);
      expect(InputValidator.isValidId('invalid id'), isFalse);
      expect(InputValidator.isValidId('invalid@id'), isFalse);
    });

    test('sanitizeDisplayText removes HTML tags', () {
      expect(
        InputValidator.sanitizeDisplayText(
          '<script>alert("xss")</script>Hello',
        ),
        'alert("xss")Hello',
      );
      expect(InputValidator.sanitizeDisplayText('<b>Bold</b>'), 'Bold');
      expect(InputValidator.sanitizeDisplayText('No tags'), 'No tags');
    });

    test('sanitizeFirestoreInput removes restricted characters', () {
      expect(InputValidator.sanitizeFirestoreInput('users/123'), 'users123');
      expect(InputValidator.sanitizeFirestoreInput('..'), '');
      expect(InputValidator.sanitizeFirestoreInput('safe_path'), 'safe_path');
    });

    test('isValidEmail validates email format', () {
      expect(InputValidator.isValidEmail('test@example.com'), isTrue);
      expect(InputValidator.isValidEmail('invalid-email'), isFalse);
      expect(InputValidator.isValidEmail('missing@domain'), isFalse);
    });
  });
}
