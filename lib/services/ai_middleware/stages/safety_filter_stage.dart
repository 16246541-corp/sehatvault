import '../pipeline_stage.dart';
import '../pipeline_context.dart';
import '../../safety_filter_service.dart';

/// Pipeline stage for safety filtering and sanitization.
class SafetyFilterStage extends PipelineStage {
  final SafetyFilterService _safetyFilter;

  SafetyFilterStage(this._safetyFilter);

  @override
  String get id => 'safety_filter';

  @override
  int get priority => 10; // Run early to catch issues before other processing

  @override
  Future<void> process(PipelineContext context) async {
    // SafetyFilterService.sanitize returns the sanitized text.
    // In this simplified implementation, we assume if it's modified, it might be a safety trigger.
    final original = context.content;
    final sanitized = _safetyFilter.sanitize(original);
    
    if (original != sanitized) {
      context.metadata['safety_triggered'] = true;
      // We don't block by default in SafetyFilterService, it just sanitizes.
      // But we can add logic here if we want to block certain patterns.
    }
    
    context.content = sanitized;
  }
}
