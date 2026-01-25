import '../pipeline_stage.dart';
import '../pipeline_context.dart';
import '../../validation/validation_rule.dart';

/// Pipeline stage that runs existing validation rules.
class ValidationStage extends PipelineStage {
  final List<ValidationRule> _rules;

  ValidationStage(this._rules);

  @override
  String get id => 'validation_rules';

  @override
  int get priority => 20; // Run after safety filter

  @override
  Future<void> process(PipelineContext context) async {
    // Run all rules in parallel
    final results =
        await Future.wait(_rules.where((r) => r.enabled).map((rule) async {
      final result = await rule.validate(context.content);
      return MapEntry(rule, result);
    }));

    for (final entry in results) {
      final result = entry.value;
      context.validationResults.add(result);

      if (result.isModified || !result.isValid) {
        // If multiple rules modify content, they will apply in order of rules list
        // but they all validated against the same initial content.
        // This is a tradeoff for parallelism.
        context.content = result.content;

        if (!result.isValid) {
          context.isBlocked = true;
          context.blockReason = result.warning ?? result.content;
          break; // Stop at first blocking rule (already evaluated)
        }
      }
    }
  }
}
