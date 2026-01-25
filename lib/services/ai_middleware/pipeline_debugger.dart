import 'pipeline_context.dart';
import '../../utils/secure_logger.dart';
import 'package:flutter/foundation.dart';

/// Provides debugging and visualization tools for the AI output pipeline.
class PipelineDebugger {
  /// Logs the pipeline execution details in a readable format.
  static void logPipelineExecution(PipelineContext context) {
    if (!kDebugMode) return;

    final buffer = StringBuffer();
    buffer.writeln('=== AI Output Pipeline Execution ===');
    buffer.writeln('Prompt: ${context.originalPrompt}');
    buffer.writeln('Status: ${context.isBlocked ? "BLOCKED" : "COMPLETED"}');
    if (context.isBlocked) {
      buffer.writeln('Block Reason: ${context.blockReason}');
    }

    buffer.writeln('--- Performance Metrics ---');
    context.performanceMetrics.forEach((stage, duration) {
      buffer.writeln('$stage: ${duration.toStringAsFixed(2)}ms');
    });

    buffer.writeln('--- Validation Results ---');
    for (var i = 0; i < context.validationResults.length; i++) {
      final res = context.validationResults[i];
      buffer.writeln('Rule $i: ${res.isValid ? "PASS" : "FAIL"} (Modified: ${res.isModified})');
      if (res.warning != null) buffer.writeln('  Warning: ${res.warning}');
    }

    buffer.writeln('--- Citations ---');
    buffer.writeln('Count: ${context.citations.length}');

    buffer.writeln('--- Final Content ---');
    buffer.writeln(context.content);
    buffer.writeln('====================================');

    SecureLogger.log(buffer.toString());
  }

  /// Generates a simple text-based visualization of the pipeline stages and their state.
  static String getPipelineSummary(PipelineContext context) {
    final stages = context.performanceMetrics.keys.toList();
    return 'Pipeline: ${stages.join(' -> ')} (${context.performanceMetrics.values.reduce((a, b) => a + b).toStringAsFixed(1)}ms total)';
  }
}
