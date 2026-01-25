import 'package:flutter/foundation.dart';
import '../models/model_option.dart';
import 'llm_engine.dart';
import 'model_fallback_service.dart';
import 'session_manager.dart';
import '../utils/secure_logger.dart';

/// Classification of AI failure modes.
enum AIErrorType {
  initializationFailed,
  inferenceFailed,
  memoryPressure,
  contextOverflow,
  safetyBlocked,
  networkRequired, // For future remote models
  unknown,
}

/// Detailed error classification for AI operations.
class AIError {
  final AIErrorType type;
  final String message;
  final String userFriendlyMessage;
  final bool isRecoverable;
  final dynamic originalError;

  AIError({
    required this.type,
    required this.message,
    required this.userFriendlyMessage,
    this.isRecoverable = true,
    this.originalError,
  });

  @override
  String toString() => 'AIError(type: $type, message: $message)';
}

/// Recovery options available to the user.
enum RecoveryActionType {
  retry,
  switchModel,
  clearMemory,
  contactSupport,
}

class RecoveryAction {
  final String label;
  final RecoveryActionType type;
  final VoidCallback onAction;

  RecoveryAction({
    required this.label,
    required this.type,
    required this.onAction,
  });
}

/// Service responsible for AI error recovery strategies.
class AIRecoveryService extends ChangeNotifier {
  static final AIRecoveryService _instance = AIRecoveryService._internal();
  factory AIRecoveryService() => _instance;
  AIRecoveryService._internal();

  int _retryCount = 0;
  final int _maxRetries = 3;

  /// Classifies an error into a structured [AIError].
  AIError classifyError(dynamic error) {
    if (error is LLMEngineException) {
      if (error.code == 'INSUFFICIENT_RAM' || error.code == 'OUT_OF_MEMORY') {
        return AIError(
          type: AIErrorType.memoryPressure,
          message: error.message,
          userFriendlyMessage: 'Your device is low on memory. Try closing other apps or using a lighter AI model.',
          isRecoverable: true,
          originalError: error,
        );
      } else if (error.code == 'BACKEND_INIT_FAILED' || error.code == 'NOT_INITIALIZED') {
        return AIError(
          type: AIErrorType.initializationFailed,
          message: error.message,
          userFriendlyMessage: 'The AI engine failed to start. We can try restarting it for you.',
          isRecoverable: true,
          originalError: error,
        );
      } else if (error.code == 'INFERENCE_FAILED') {
        return AIError(
          type: AIErrorType.inferenceFailed,
          message: error.message,
          userFriendlyMessage: 'The AI encountered an error while generating a response. Let\'s try again.',
          isRecoverable: true,
          originalError: error,
        );
      }
    }

    return AIError(
      type: AIErrorType.unknown,
      message: error.toString(),
      userFriendlyMessage: 'An unexpected AI error occurred. Please try again or switch models.',
      isRecoverable: true,
      originalError: error,
    );
  }

  /// Provides recovery actions based on the classified error.
  List<RecoveryAction> getRecoveryActions(AIError error, {VoidCallback? onRetry, VoidCallback? onSwitchModel}) {
    final actions = <RecoveryAction>[];

    switch (error.type) {
      case AIErrorType.initializationFailed:
      case AIErrorType.inferenceFailed:
      case AIErrorType.unknown:
        if (onRetry != null) {
          actions.add(RecoveryAction(
            label: 'Try Again',
            type: RecoveryActionType.retry,
            onAction: onRetry,
          ));
        }
        break;
      case AIErrorType.memoryPressure:
        if (onSwitchModel != null) {
          actions.add(RecoveryAction(
            label: 'Switch to Lighter Model',
            type: RecoveryActionType.switchModel,
            onAction: onSwitchModel,
          ));
        }
        break;
      case AIErrorType.contextOverflow:
        actions.add(RecoveryAction(
          label: 'Clear Conversation Memory',
          type: RecoveryActionType.clearMemory,
          onAction: () {
            // Logic to clear memory for the current session
            SecureLogger.log('Recovery: Clearing memory due to context overflow');
          },
        ));
        break;
      default:
        break;
    }

    return actions;
  }

  /// Implements exponential backoff for retry attempts.
  Future<bool> shouldRetryWithBackoff() async {
    if (_retryCount >= _maxRetries) {
      _retryCount = 0; // Reset for next failure sequence
      return false;
    }

    _retryCount++;
    // Exponential backoff: 1s, 2s, 4s...
    final waitDuration = Duration(seconds: 1 << (_retryCount - 1));
    SecureLogger.log('Recovery: Retrying in ${waitDuration.inSeconds}s (Attempt $_retryCount/$_maxRetries)');
    await Future.delayed(waitDuration);
    return true;
  }

  /// Resets the retry counter.
  void resetRetryCount() {
    _retryCount = 0;
  }

  /// Graceful degradation for partial functionality.
  /// Returns a simplified response when full generation fails.
  String getGracefulDegradationResponse(AIError error) {
    SecureLogger.log('Recovery: Providing graceful degradation response for ${error.type}');
    return 'I apologize, but I am currently having trouble generating a full response due to a technical issue (${error.type.name}). You can try again or switch to a different model in settings.';
  }
}
