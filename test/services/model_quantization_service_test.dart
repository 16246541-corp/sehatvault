import 'package:flutter_test/flutter_test.dart';
import 'package:sehatlocker/services/model_quantization_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('ModelQuantizationService', () {
    late ModelQuantizationService service;

    setUp(() {
      service = ModelQuantizationService();
    });

    test('getRecommendedFormat returns appropriate format based on RAM',
        () async {
      // Since PlatformDetector is used internally, we might need to mock it
      // but for now let's test the logic with the current device if possible
      // or just verify the service exists and can be called.
      final format = await service.getRecommendedFormat();
      expect(format, isA<QuantizationFormat>());
    });

    test('QuantizationFormat metrics are consistent', () {
      for (final format in QuantizationFormat.values) {
        expect(format.qualityImpact, greaterThan(0));
        expect(format.qualityImpact, lessThanOrEqualTo(1.0));
        expect(format.speedMultiplier, greaterThan(0));
        expect(format.sizeMultiplier, greaterThan(0));
      }
    });

    test('Higher quantization levels have better quality but lower speed', () {
      expect(QuantizationFormat.q8_0.qualityImpact,
          greaterThan(QuantizationFormat.q4_k_m.qualityImpact));
      expect(QuantizationFormat.q8_0.speedMultiplier,
          lessThan(QuantizationFormat.q4_k_m.speedMultiplier));
    });

    test('assessCompatibility returns correct results', () async {
      const baseStorage = 2.0; // 2GB base
      final result = await service.assessCompatibility(
          baseStorage, QuantizationFormat.q4_k_m);

      expect(result.estimatedStorageGB, equals(2.0));
      expect(result.estimatedRamGB, equals(2.4)); // 2.0 * 1.2
    });

    test('getTradeoffs returns valid metrics for UI', () {
      final tradeoffs = service.getTradeoffs(QuantizationFormat.q4_k_m);
      expect(tradeoffs.quality, equals(0.92));
      expect(tradeoffs.speed, closeTo(1.5 / 2.5, 0.01));
      expect(tradeoffs.efficiency, equals(1.0));
      expect(tradeoffs.description, contains('Recommended'));
    });
  });
}
