import 'pipeline_context.dart';
import 'pipeline_stage.dart';
import '../../utils/secure_logger.dart';

/// Orchestrates the AI output processing pipeline.
class OutputPipeline {
  final List<PipelineStage> _stages = [];

  /// Adds a stage to the pipeline and maintains order.
  void addStage(PipelineStage stage) {
    _stages.add(stage);
    _stages.sort((a, b) => a.priority.compareTo(b.priority));
  }

  /// Runs the full pipeline on the given content.
  Future<PipelineContext> process(
    String prompt,
    String content, {
    List<Map<String, String>> history = const [],
  }) async {
    final context = PipelineContext(
      originalPrompt: prompt,
      content: content,
      history: history,
    );

    for (final stage in _stages) {
      if (!stage.enabled) continue;
      if (context.isBlocked) break;

      final stopwatch = Stopwatch()..start();
      try {
        await stage.process(context);
      } catch (e) {
        SecureLogger.log("Pipeline stage ${stage.id} failed: $e");
        // Graceful degradation: continue to next stage unless it's a critical error
      }
      stopwatch.stop();
      context.addMetric(stage.id, stopwatch.elapsedMilliseconds.toDouble());
    }

    return context;
  }

  /// Gets the performance report for the last run.
  Map<String, double> getPerformanceMetrics(PipelineContext context) {
    return context.performanceMetrics;
  }

  /// Clears all stages from the pipeline.
  void clear() {
    _stages.clear();
  }
}
