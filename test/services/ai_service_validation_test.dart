import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sehatlocker/services/validation/validation_rule.dart';
import 'package:sehatlocker/services/validation/rules/diagnostic_language_rule.dart';
import 'package:sehatlocker/services/validation/rules/treatment_recommendation_rule.dart';
import 'package:sehatlocker/services/validation/rules/triage_advice_rule.dart';
import 'dart:io';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final tempDir = await Directory.systemTemp.createTemp();
    Hive.init(tempDir.path);
    if (!Hive.isBoxOpen('settings')) await Hive.openBox('settings');
  });

  group('AIService Validation Tests', () {
    test('Treatment Recommendation Rule triggers replacement', () async {
      final rule = TreatmentRecommendationRule();
      final result =
          await rule.validate('You should take 500mg ibuprofen daily.');
      expect(result.isValid, isFalse);
      expect(result.content, contains('Treatment recommendation blocked'));
    });

    test('Triage Advice Rule triggers warning', () async {
      final rule = TriageAdviceRule();
      const input = 'Go to the ER.';
      final result = await rule.validate(input);
      expect(result.isValid, isTrue);
      expect(result.isModified, isTrue);
      expect(result.warning, contains('medical emergency'));
      expect(result.content, contains('Go to the ER'));
    });

    test('Diagnostic Language Rule triggers rewrite', () async {
      final rule = DiagnosticLanguageRule();
      final result = await rule.validate('You have a fracture.');
      expect(result.isValid, isTrue);
      expect(result.isModified, isTrue);
      expect(result.warning, contains('diagnostic language'));
      expect(result.content, contains('Some people with similar concerns'));
    });

    test('Safe content passes through unmodified', () async {
      const input = 'Hello, how are you today?';
      final rule = DiagnosticLanguageRule();
      final result = await rule.validate(input);
      expect(result.isValid, isTrue);
      expect(result.isModified, isFalse);
      expect(result.content, equals(input));
    });
  });
}
