import '../pipeline_stage.dart';
import '../pipeline_context.dart';
import '../../hallucination_validation_service.dart';
import '../../validation/validation_rule.dart';

/// Pipeline stage that validates AI content for potential hallucinations.
class HallucinationValidationStage extends PipelineStage {
  final HallucinationValidationService _validationService;
  final String contentType;

  HallucinationValidationStage(
    this._validationService, {
    this.contentType = 'default',
  });

  @override
  String get id => 'hallucination_validation';

  @override
  int get priority => 25; // Run after general validation

  @override
  Future<void> process(PipelineContext context) async {
    final result = await _validationService.validate(
      context.content,
      contentType: contentType,
    );

    if (result.isSuspicious) {
      // If high level hallucination, we might want to block or flag it
      if (result.level == HallucinationLevel.high) {
        context.isBlocked = true;
        context.blockReason =
            'Potential factual inaccuracy detected in AI response.';
      } else {
        // For lower levels, we might just add a warning or note
        context.validationResults.add(ValidationResult(
          isValid: true,
          content: context.content,
          warning:
              'Note: Some information in this response may need verification.',
        ));
      }
    }
  }
}

// Re-using ValidationResult structure if possible, but let's check its definition first.
// I saw ValidationResult being used in AIService. Let's find its definition.
