import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/model_option.dart';
import 'llm_engine.dart';
import 'analytics_service.dart';
import 'desktop_notification_service.dart';

/// Types of model failures that can trigger a fallback.
enum FallbackTrigger {
  initializationFailed,
  inferenceError,
  performanceDegradation, // e.g., low TPS
  memoryPressure,
  manualOverride,
}

/// Information about a fallback event.
class FallbackEvent {
  final ModelOption fromModel;
  final ModelOption toModel;
  final FallbackTrigger trigger;
  final String? reason;
  final DateTime timestamp;

  FallbackEvent({
    required this.fromModel,
    required this.toModel,
    required this.trigger,
    this.reason,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Service responsible for managing model fallbacks and state preservation.
class ModelFallbackService extends ChangeNotifier {
  static ModelFallbackService _instance = ModelFallbackService._internal();
  factory ModelFallbackService() => _instance;
  ModelFallbackService._internal();

  @visibleForTesting
  static void setMockInstance(ModelFallbackService mock) {
    _instance = mock;
  }

  final List<FallbackEvent> _history = [];
  bool _isAutoFallbackEnabled = true;

  List<FallbackEvent> get history => List.unmodifiable(_history);
  bool get isAutoFallbackEnabled => _isAutoFallbackEnabled;

  /// Sets whether automatic fallback is enabled.
  void setAutoFallback(bool enabled) {
    _isAutoFallbackEnabled = enabled;
    notifyListeners();
  }

  /// Evaluates if a fallback is needed based on the current engine state and error.
  Future<ModelOption?> evaluateFallback(
    ModelOption currentModel, {
    LLMEngineException? error,
    ModelMetrics? metrics,
  }) async {
    if (!_isAutoFallbackEnabled) return null;

    FallbackTrigger? trigger;
    String? reason;

    if (error != null) {
      if (error.code == 'INSUFFICIENT_RAM' || error.code == 'OUT_OF_MEMORY') {
        trigger = FallbackTrigger.memoryPressure;
        reason = 'Insufficient memory for ${currentModel.name}';
      } else if (error.isRecoverable == false) {
        trigger = FallbackTrigger.initializationFailed;
        reason = 'Critical error in ${currentModel.name}: ${error.message}';
      } else {
        trigger = FallbackTrigger.inferenceError;
        reason = 'Inference error: ${error.message}';
      }
    } else if (metrics != null) {
      if (metrics.tokensPerSecond < 1.0 && metrics.tokensPerSecond > 0) {
        trigger = FallbackTrigger.performanceDegradation;
        reason =
            'Low performance (TPS: ${metrics.tokensPerSecond.toStringAsFixed(2)})';
      }
    }

    if (trigger != null) {
      return _findFallbackModel(currentModel, trigger, reason);
    }

    return null;
  }

  /// Finds the next best model to fallback to.
  ModelOption? _findFallbackModel(
    ModelOption currentModel,
    FallbackTrigger trigger,
    String? reason,
  ) {
    final available = ModelOption.availableModels;

    // Find models with lower RAM requirements than the current one
    final fallbacks = available
        .where((m) => m.ramRequired < currentModel.ramRequired)
        .toList()
      ..sort((a, b) =>
          b.ramRequired.compareTo(a.ramRequired)); // Best available first

    if (fallbacks.isNotEmpty) {
      final target = fallbacks.first;
      _handleFallback(currentModel, target, trigger, reason);
      return target;
    }

    return null;
  }

  /// Executes the fallback logic, logging and notifying the user.
  Future<void> _handleFallback(
    ModelOption from,
    ModelOption to,
    FallbackTrigger trigger,
    String? reason,
  ) async {
    final event = FallbackEvent(
      fromModel: from,
      toModel: to,
      trigger: trigger,
      reason: reason,
    );

    _history.add(event);

    // Log to analytics
    AnalyticsService().logEvent('model_fallback', parameters: {
      'from_model': from.id,
      'to_model': to.id,
      'trigger': trigger.name,
      'reason': reason ?? 'Unknown',
    });

    // Notify user - wrap in a try-catch for tests where Hive isn't initialized
    try {
      await DesktopNotificationService().showModelStatus(
        title: 'Model Fallback Active',
        message:
            'Switched from ${from.name} to ${to.name} due to ${trigger.name.replaceAll(RegExp(r"(?<=[a-z])(?=[A-Z])"), " ").toLowerCase()}.',
      );
    } catch (e) {
      debugPrint('Notification failed: $e');
    }

    notifyListeners();
  }

  /// Preserves the session context when switching models.
  /// This can be used by AIService to re-inject context into the new model.
  Map<String, dynamic> captureContext(LLMEngine engine) {
    // In a real implementation, this would capture the last N turns,
    // system prompts, and any specific state.
    return {
      'last_model_id': engine.metrics?.contextTokens ?? 0,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}
