import 'package:flutter_test/flutter_test.dart';
import 'package:sehatlocker/services/ai_recovery_service.dart';
import 'package:sehatlocker/services/llm_engine.dart';

void main() {
  group('AIRecoveryService Tests', () {
    late AIRecoveryService service;

    setUp(() {
      service = AIRecoveryService();
      service.resetRetryCount();
    });

    test('should classify memory pressure error correctly', () {
      final error = LLMEngineException(
        'Out of memory',
        code: 'OUT_OF_MEMORY',
      );

      final classified = service.classifyError(error);

      expect(classified.type, AIErrorType.memoryPressure);
      expect(classified.userFriendlyMessage, contains('low on memory'));
    });

    test('should classify initialization failure correctly', () {
      final error = LLMEngineException(
        'Failed to init backend',
        code: 'BACKEND_INIT_FAILED',
      );

      final classified = service.classifyError(error);

      expect(classified.type, AIErrorType.initializationFailed);
      expect(classified.userFriendlyMessage, contains('failed to start'));
    });

    test('should classify inference failure correctly', () {
      final error = LLMEngineException(
        'Inference failed',
        code: 'INFERENCE_FAILED',
      );

      final classified = service.classifyError(error);

      expect(classified.type, AIErrorType.inferenceFailed);
      expect(classified.userFriendlyMessage, contains('generating a response'));
    });

    test('should provide correct recovery actions for memory pressure', () {
      final error = AIError(
        type: AIErrorType.memoryPressure,
        message: 'OOM',
        userFriendlyMessage: 'Low memory',
      );

      final actions = service.getRecoveryActions(error, onSwitchModel: () {});

      expect(actions.length, 1);
      expect(actions.first.type, RecoveryActionType.switchModel);
    });

    test('should implement exponential backoff retry logic', () async {
      // First attempt
      final shouldRetry1 = await service.shouldRetryWithBackoff();
      expect(shouldRetry1, isTrue);

      // Second attempt
      final shouldRetry2 = await service.shouldRetryWithBackoff();
      expect(shouldRetry2, isTrue);

      // Third attempt
      final shouldRetry3 = await service.shouldRetryWithBackoff();
      expect(shouldRetry3, isTrue);

      // Fourth attempt (exceeds maxRetries = 3)
      final shouldRetry4 = await service.shouldRetryWithBackoff();
      expect(shouldRetry4, isFalse);
    });

    test('should provide graceful degradation response', () {
      final error = AIError(
        type: AIErrorType.inferenceFailed,
        message: 'Fail',
        userFriendlyMessage: 'Error',
      );

      final response = service.getGracefulDegradationResponse(error);

      expect(response, contains('I apologize'));
      expect(response, contains('inferenceFailed'));
    });
  });
}
