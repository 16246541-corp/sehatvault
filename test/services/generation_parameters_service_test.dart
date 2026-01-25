import 'package:flutter_test/flutter_test.dart';
import 'package:sehatlocker/models/generation_parameters.dart';
import 'package:sehatlocker/services/generation_parameters_service.dart';

void main() {
  group('GenerationParameters', () {
    test('Default values are correct', () {
      final params = GenerationParameters();
      expect(params.temperature, 0.7);
      expect(params.topP, 0.9);
      expect(params.topK, 40);
      expect(params.maxTokens, 1024);
    });

    test('Balanced preset is correct', () {
      final params = GenerationParameters.balanced();
      expect(params.temperature, 0.7);
      expect(params.topP, 0.9);
    });

    test('Creative preset is correct', () {
      final params = GenerationParameters.creative();
      expect(params.temperature, 0.9);
      expect(params.topP, 0.95);
    });

    test('Precise preset is correct', () {
      final params = GenerationParameters.precise();
      expect(params.temperature, 0.2);
      expect(params.topP, 0.5);
    });

    test('copyWith works correctly', () {
      final params = GenerationParameters();
      final updated = params.copyWith(temperature: 1.0, maxTokens: 2048);
      expect(updated.temperature, 1.0);
      expect(updated.maxTokens, 2048);
      expect(updated.topP, 0.9); // Unchanged
    });
  });

  group('GenerationParametersService Validation', () {
    final service = GenerationParametersService();

    test('Valid parameters return no warnings', () {
      final params = GenerationParameters.balanced();
      final warnings = service.validateParameters(params);
      expect(warnings.isEmpty, true);
    });

    test('High temperature returns warning', () {
      final params = GenerationParameters(temperature: 1.5);
      final warnings = service.validateParameters(params);
      expect(warnings.containsKey('temperature'), true);
      expect(warnings['temperature'], contains('High temperature'));
    });

    test('Low temperature returns warning', () {
      final params = GenerationParameters(temperature: 0.05);
      final warnings = service.validateParameters(params);
      expect(warnings.containsKey('temperature'), true);
      expect(warnings['temperature'], contains('Very low temperature'));
    });

    test('High Top-P returns warning', () {
      final params = GenerationParameters(topP: 0.99);
      final warnings = service.validateParameters(params);
      expect(warnings.containsKey('topP'), true);
    });

    test('High Top-K returns warning', () {
      final params = GenerationParameters(topK: 150);
      final warnings = service.validateParameters(params);
      expect(warnings.containsKey('topK'), true);
    });

    test('High max tokens returns warning', () {
      final params = GenerationParameters(maxTokens: 5000);
      final warnings = service.validateParameters(params);
      expect(warnings.containsKey('maxTokens'), true);
    });
  });
}
