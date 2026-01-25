import 'pipeline_context.dart';

/// Abstract base class for all pipeline stages.
abstract class PipelineStage {
  /// Unique identifier for the stage.
  String get id;
  
  /// Whether the stage is currently enabled.
  bool get enabled => true;
  
  /// Priority for ordering (lower runs first).
  int get priority => 100;

  /// Processes the content in the context.
  Future<void> process(PipelineContext context);
}

/// A stage that can run multiple sub-stages in parallel.
class ParallelPipelineStage extends PipelineStage {
  final String _id;
  final List<PipelineStage> _stages;
  final int _priority;

  ParallelPipelineStage(this._id, this._stages, {int priority = 100}) : _priority = priority;

  @override
  String get id => _id;

  @override
  int get priority => _priority;

  @override
  Future<void> process(PipelineContext context) async {
    final enabledStages = _stages.where((s) => s.enabled).toList();
    if (enabledStages.isEmpty) return;

    await Future.wait(enabledStages.map((s) async {
      final stopwatch = Stopwatch()..start();
      try {
        await s.process(context);
      } finally {
        stopwatch.stop();
        context.addMetric(s.id, stopwatch.elapsedMilliseconds.toDouble());
      }
    }));
  }
}
