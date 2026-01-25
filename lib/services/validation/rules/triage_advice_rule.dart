import '../validation_rule.dart';

class TriageAdviceRule implements ValidationRule {
  @override
  String get id => 'triage_advice';

  @override
  int get priority => 2;

  @override
  bool get enabled => true;

  @override
  Future<ValidationResult> validate(String content) async {
    // Detects urgency or triage advice
    // Examples: "Go to ER", "Call 911", "Immediate attention"
    final pattern = RegExp(
      r'\b(go to the er|call 911|emergency room|immediate medical attention)\b',
      caseSensitive: false,
    );

    if (pattern.hasMatch(content)) {
      return ValidationResult.modified(
        content,
        warning:
            "This appears to be a medical emergency. Please call emergency services immediately.",
      );
    }

    return ValidationResult.valid(content);
  }
}
