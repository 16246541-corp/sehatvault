import 'pipeline_context.dart';
import 'pipeline_stage.dart';
import '../../utils/secure_logger.dart';
import '../ai_analytics_service.dart';
import '../llm_engine.dart';

/// Orchestrates the AI output processing pipeline.
class OutputPipeline {
  final List<PipelineStage> _stages = [];
  final AIAnalyticsService _analytics = AIAnalyticsService();

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
    Map<String, dynamic> initialMetadata = const {},
  }) async {
    final context = PipelineContext(
      originalPrompt: prompt,
      content: content,
      history: history,
    );
    if (initialMetadata.isNotEmpty) {
      context.metadata.addAll(initialMetadata);
    }

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

    // Log pipeline performance to analytics
    await _logPipelineMetrics(context);

    return context;
  }

  /// Logs pipeline performance metrics to AIAnalyticsService.
  Future<void> _logPipelineMetrics(PipelineContext context) async {
    final totalTime = context.performanceMetrics.values.isEmpty
        ? 0.0
        : context.performanceMetrics.values.reduce((a, b) => a + b);

    final metadata = context.performanceMetrics.map(
      (key, value) => MapEntry(key, '${value.toStringAsFixed(1)}ms'),
    );

    await _analytics.logMetric(
      ModelMetrics(loadTimeMs: totalTime),
      LLMEngine().currentModel?.id ?? 'unknown',
      operationType: 'pipeline_processing',
      isSuccessful: !context.isBlocked,
      metadata: metadata,
    );
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
