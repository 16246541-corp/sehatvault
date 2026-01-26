import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sehatlocker/services/risk_mitigation_service.dart';
import 'package:sehatlocker/services/risk_template_configuration.dart';
import 'package:sehatlocker/services/safety_filter_service.dart';
import 'package:sehatlocker/services/medical_dictionary_service.dart';
import 'dart:io';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late RiskMitigationService service;
  late RiskTemplateConfiguration templateConfig;
  late SafetyFilterService safetyFilter;
  late MedicalDictionaryService medicalDictionary;

  setUpAll(() async {
    final tempDir = await Directory.systemTemp.createTemp();
    Hive.init(tempDir.path);
    if (!Hive.isBoxOpen('settings')) await Hive.openBox('settings');
  });

  setUp(() {
    templateConfig = RiskTemplateConfiguration.forTesting([
      RiskTemplate(
        id: 'test_template',
        keywords: ['side effect', 'dizzy'],
        riskLevel: 'medium',
        template: 'You mentioned {keyword}. Consult your doctor.',
      ),
    ]);

    safetyFilter = SafetyFilterService();
    medicalDictionary = MedicalDictionaryService.forTesting({});

    service = RiskMitigationService.forTesting(
      templateConfig: templateConfig,
      safetyFilter: safetyFilter,
      medicalDictionary: medicalDictionary,
    );
  });

  test('generates questions when keywords match', () async {
    const transcript = "I feel a bit dizzy after taking the pill.";
    final questions = await service.generateRiskMitigationQuestions(transcript);

    expect(questions.length, 1);
    expect(questions.first, contains('dizzy'));
    expect(questions.first, contains('Consult your doctor'));
  });

  test('returns empty list when no keywords match', () async {
    const transcript = "I am feeling great.";
    final questions = await service.generateRiskMitigationQuestions(transcript);

    expect(questions, isEmpty);
  });

  test('sanitizes output via SafetyFilterService', () async {
    // Setup a template that produces something SafetyFilter might catch
    // Note: SafetyFilter catches specific phrases like "You have".
    templateConfig = RiskTemplateConfiguration.forTesting([
      RiskTemplate(
        id: 'unsafe_template',
        keywords: ['trigger'],
        riskLevel: 'high',
        template: 'You have a condition related to {keyword}.',
      ),
    ]);

    service = RiskMitigationService.forTesting(
      templateConfig: templateConfig,
      safetyFilter: safetyFilter,
      medicalDictionary: medicalDictionary,
    );

    final questions =
        await service.generateRiskMitigationQuestions("This is a trigger.");

    expect(questions, isNotEmpty);
    // SafetyFilter should sanitize "You have"
    expect(questions.first, isNot(contains('You have a condition')));
  });
}
