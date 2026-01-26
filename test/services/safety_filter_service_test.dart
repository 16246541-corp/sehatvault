import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sehatlocker/services/safety_filter_service.dart';
import 'dart:io';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SafetyFilterService service;

  setUpAll(() async {
    final tempDir = await Directory.systemTemp.createTemp();
    Hive.init(tempDir.path);
    if (!Hive.isBoxOpen('settings')) await Hive.openBox('settings');
  });

  setUp(() {
    service = SafetyFilterService();
  });

  group('SafetyFilterService', () {
    test('passes through safe text unchanged', () {
      const text = 'Hello, how are you today? The weather is nice.';
      expect(service.sanitize(text), equals(text));
    });

    test('replaces "you have" pattern', () {
      const input = 'You have diabetes.';
      final output = service.sanitize(input);
      expect(
          output,
          contains(
              'Some people with similar concerns have discussed with their doctors: diabetes.'));
      expect(output, isNot(contains('You have diabetes')));
    });

    test('replaces "diagnosis" pattern', () {
      const input = 'The diagnosis is hypertension.';
      final output = service.sanitize(input);
      expect(
          output,
          contains(
              'Some people with similar concerns have discussed with their doctors: is hypertension.'));
    });

    test('replaces "likely condition" pattern', () {
      const input = 'The likely condition is asthma.';
      final output = service.sanitize(input);
      expect(
          output,
          contains(
              'Some people with similar concerns have discussed with their doctors: is asthma.'));
    });

    test('replaces "suffer from" pattern', () {
      const input = 'You suffer from migraines.';
      final output = service.sanitize(input);
      expect(
          output,
          contains(
              'Some people with similar concerns have discussed with their doctors: migraines.'));
    });

    test('replaces "symptoms indicate" pattern', () {
      const input = 'Your symptoms indicate flu.';
      final output = service.sanitize(input);
      expect(
          output,
          contains(
              'Some people with similar concerns have discussed with their doctors: flu.'));
    });

    test('replaces "medical opinion" pattern', () {
      const input = 'My medical opinion is that you need rest.';
      final output = service.sanitize(input);
      expect(
          output,
          contains(
              'Some people with similar concerns have discussed with their doctors: is that you need rest.'));
    });

    test('replaces "it seems you have" pattern', () {
      const input = 'It seems you have a fracture.';
      final output = service.sanitize(input);
      expect(
          output,
          contains(
              'Some people with similar concerns have discussed with their doctors: a fracture.'));
    });

    test('replaces "i suspect" pattern', () {
      const input = 'I suspect infection.';
      final output = service.sanitize(input);
      expect(
          output,
          contains(
              'Some people with similar concerns have discussed with their doctors: infection.'));
    });

    test('handles multiple sentences correctly', () {
      const input = 'Hello. You have diabetes. Take care.';
      final output = service.sanitize(input);
      expect(output, contains('Hello.'));
      expect(
          output,
          contains(
              'Some people with similar concerns have discussed with their doctors: diabetes.'));
      expect(output, contains('Take care.'));
    });

    test('handles complex punctuation', () {
      const input = 'Wait! You have fever? Check it.';
      final output = service.sanitize(input);
      expect(output, contains('Wait!'));
      expect(
          output,
          contains(
              'Some people with similar concerns have discussed with their doctors: fever.')); // ? replaced by . in template or preserved?
      // My implementation replaces ending punctuation of topic with . if using template
      // "Some people... : fever."
      // The split keeps delimiters attached to the sentence.
    });

    test('performance is acceptable', () {
      final stopwatch = Stopwatch()..start();
      final input = 'You have ' * 100; // Stress test
      service.sanitize(input);
      stopwatch.stop();
      expect(
          stopwatch.elapsedMilliseconds,
          lessThan(
              500)); // Allow some buffer for test env, requirement is 50ms for typical input
    });

    test('handles empty input', () {
      expect(service.sanitize(''), isEmpty);
    });

    test('handles input with no topic', () {
      const input = 'You have.';
      final output = service.sanitize(input);
      expect(
          output,
          contains(
              'Some people with similar concerns have discussed this with their doctors.'));
    });
  });
}
