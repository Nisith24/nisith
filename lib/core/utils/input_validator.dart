class InputValidator {
  /// Sanitize input for Firestore to prevent NoSQL injection-like behavior
  /// (though Firestore is generally safe from SQLi, we avoid special chars in IDs)
  static String sanitizeFirestoreInput(String input) {
    // Remove characters that might be problematic in custom IDs or paths
    return input.replaceAll(RegExp(r'[~/\.\[\]]'), '');
  }

  /// Validate if a string is a valid ID (alphanumeric + underscores/hyphens)
  static bool isValidId(String id) {
    return RegExp(r'^[a-zA-Z0-9_-]{1,100}$').hasMatch(id);
  }

  /// Sanitize display text to prevent potential rendering issues (basic XSS prevention)
  /// Flutter renders text safely by default, but this adds an extra layer for rich text
  static String sanitizeDisplayText(String text) {
    return text.replaceAll(RegExp(r'<[^>]*>'), '');
  }

  /// Validate email format
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}
