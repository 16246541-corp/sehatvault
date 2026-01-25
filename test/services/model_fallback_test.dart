import 'package:flutter_test/flutter_test.dart';
import 'package:sehatlocker/services/model_fallback_service.dart';
import 'package:sehatlocker/services/llm_engine.dart';
import 'package:sehatlocker/models/model_option.dart';
import 'package:sehatlocker/models/model_metadata.dart';

void main() {
  group('ModelFallbackService Tests', () {
    late ModelFallbackService service;

    final mockModelHigh = ModelOption(
      id: 'high_res',
      name: 'High Res Model',
      ramRequired: 8.0,
      storageRequired: 4.0,
      description: 'Test High',
      metadata: ModelMetadata(
        version: '1.0.0',
        checksum: 'sha256:abc',
        releaseDate: DateTime.now(),
      ),
    );

    setUp(() {
      service = ModelFallbackService();
    });

    test('should trigger fallback on memory pressure', () async {
      final error = LLMEngineException(
        'Out of memory',
        code: 'OUT_OF_MEMORY',
        isRecoverable: false,
      );

      final fallback =
          await service.evaluateFallback(mockModelHigh, error: error);

      expect(fallback, isNotNull);
      expect(fallback!.ramRequired, lessThan(mockModelHigh.ramRequired));
      expect(service.history.last.trigger, FallbackTrigger.memoryPressure);
    });

    test('should trigger fallback on performance degradation', () async {
      final metrics = ModelMetrics(
        loadTimeMs: 1000,
        tokensPerSecond: 0.5, // Below 1.0 threshold
      );

      final fallback =
          await service.evaluateFallback(mockModelHigh, metrics: metrics);

      expect(fallback, isNotNull);
      expect(
          service.history.last.trigger, FallbackTrigger.performanceDegradation);
    });

    test('should NOT trigger fallback if disabled', () async {
      service.setAutoFallback(false);

      final error = LLMEngineException(
        'Out of memory',
        code: 'OUT_OF_MEMORY',
      );

      final fallback =
          await service.evaluateFallback(mockModelHigh, error: error);

      expect(fallback, isNull);
      service.setAutoFallback(true);
    });
  });
}
