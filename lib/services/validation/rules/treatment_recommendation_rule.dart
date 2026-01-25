import '../validation_rule.dart';

class TreatmentRecommendationRule implements ValidationRule {
  @override
  String get id => 'treatment_recommendation';

  @override
  int get priority => 1; // High priority

  @override
  bool get enabled => true;

  @override
  Future<ValidationResult> validate(String content) async {
    // Regex to detect treatment recommendations
    // Examples: "You should take", "I prescribe", "Start taking"
    final pattern = RegExp(
      r'\b(you should take|start taking|prescription|dose of|mg of)\b',
      caseSensitive: false,
    );

    if (pattern.hasMatch(content)) {
      return ValidationResult.blocked(
        "Treatment recommendation blocked. I cannot provide specific treatment advice. Please consult your doctor.",
      );
    }

    return ValidationResult.valid(content);
  }
}
