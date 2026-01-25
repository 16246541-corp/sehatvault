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
      // For now, we rewrite it to be safer instead of blocking, or block if it's too direct.
      // The spec says "ValidationRule" with implementations.
      // Let's replace the recommendation with a disclaimer.

      return ValidationResult.modified(
        "I cannot provide specific treatment recommendations. Please consult your doctor for a treatment plan.",
        warning: "Treatment recommendation blocked.",
      );
    }

    return ValidationResult.valid(content);
  }
}
