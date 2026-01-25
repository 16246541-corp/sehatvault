import '../validation_rule.dart';
import '../../safety_filter_service.dart';

class DiagnosticLanguageRule implements ValidationRule {
  final SafetyFilterService _safetyFilter = SafetyFilterService();

  @override
  String get id => 'diagnostic_language';

  @override
  int get priority => 3;

  @override
  bool get enabled => true;

  @override
  Future<ValidationResult> validate(String content) async {
    // Use the existing SafetyFilterService which already handles diagnostic language
    final sanitized = _safetyFilter.sanitize(content);

    if (sanitized != content) {
      return ValidationResult.modified(
        sanitized,
        warning: "Content modified to avoid diagnostic language.",
      );
    }

    return ValidationResult.valid(content);
  }
}
