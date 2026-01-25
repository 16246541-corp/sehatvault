import '../validation/validation_rule.dart';
import '../../models/citation.dart';

/// Context object passed through the AI output processing pipeline.
class PipelineContext {
  /// The original user prompt.
  final String originalPrompt;
  
  /// Conversation history for context-aware processing.
  final List<Map<String, String>> history;
  
  /// The current content being processed (modified by stages).
  String content;
  
  /// Results from validation rules.
  final List<ValidationResult> validationResults = [];
  
  /// Citations generated during processing.
  final List<Citation> citations = [];
  
  /// Custom metadata shared between stages.
  final Map<String, dynamic> metadata = {};
  
  /// Performance metrics (stage ID -> duration in ms).
  final Map<String, double> performanceMetrics = {};
  
  /// Whether the output has been blocked by a safety filter.
  bool isBlocked = false;
  
  /// The reason for blocking, if applicable.
  String? blockReason;

  PipelineContext({
    required this.originalPrompt,
    this.history = const [],
    required this.content,
  });

  /// Adds a performance metric for a specific stage.
  void addMetric(String stageId, double durationMs) {
    performanceMetrics[stageId] = (performanceMetrics[stageId] ?? 0) + durationMs;
  }
}
