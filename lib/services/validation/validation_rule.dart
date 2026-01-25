abstract class ValidationRule {
  String get id;
  int get priority;
  bool get enabled;

  /// Validates the content. Returns null if valid, or a modified string/replacement if invalid.
  /// Throws [ValidationException] if the content should be blocked entirely.
  Future<ValidationResult> validate(String content);
}

class ValidationResult {
  final bool isValid;
  final String content;
  final bool isModified;
  final String? warning;

  ValidationResult({
    required this.isValid,
    required this.content,
    this.isModified = false,
    this.warning,
  });

  factory ValidationResult.valid(String content) => ValidationResult(
        isValid: true,
        content: content,
      );

  factory ValidationResult.modified(String content, {String? warning}) =>
      ValidationResult(
        isValid: true,
        content: content,
        isModified: true,
        warning: warning,
      );

  factory ValidationResult.blocked(String reason) => ValidationResult(
        isValid: false,
        content: reason,
      );
}

class ValidationException implements Exception {
  final String message;
  ValidationException(this.message);
}
