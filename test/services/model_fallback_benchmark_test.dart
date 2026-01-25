import 'package:flutter_test/flutter_test.dart';
import 'package:sehatlocker/services/model_fallback_service.dart';
import 'package:sehatlocker/services/llm_engine.dart';
import 'package:sehatlocker/models/model_option.dart';
import 'package:sehatlocker/models/model_metadata.dart';

void main() {
  group('Model Fallback Benchmarks', () {
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

    test('Benchmark: Fallback evaluation latency', () async {
      final stopwatch = Stopwatch()..start();
      
      const iterations = 1000;
      for (var i = 0; i < iterations; i++) {
        await service.evaluateFallback(
          mockModelHigh,
          error: LLMEngineException('Memory pressure', code: 'OUT_OF_MEMORY'),
        );
      }
      
      stopwatch.stop();
      final avgLatency = stopwatch.elapsedMicroseconds / iterations;
      
      print('Average fallback evaluation latency: ${avgLatency.toStringAsFixed(2)}μs');
      expect(avgLatency, lessThan(5000)); // Should be under 5ms
    });

    test('Benchmark: Context preservation latency', () {
      final engine = LLMEngine();
      final stopwatch = Stopwatch()..start();
      
      const iterations = 1000;
      for (var i = 0; i < iterations; i++) {
        service.captureContext(engine);
      }
      
      stopwatch.stop();
      final avgLatency = stopwatch.elapsedMicroseconds / iterations;
      
      print('Average context capture latency: ${avgLatency.toStringAsFixed(2)}μs');
      expect(avgLatency, lessThan(1000)); // Should be under 1ms
    });
  });
}
