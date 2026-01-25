import 'package:flutter/foundation.dart';
import '../services/ai_service.dart';
import '../services/risk_template_configuration.dart';
import '../services/safety_filter_service.dart';
import '../services/medical_dictionary_service.dart';
import '../utils/secure_logger.dart';

class RiskMitigationService extends AIService {
  static final RiskMitigationService _instance =
      RiskMitigationService._internal();

  factory RiskMitigationService() => _instance;

  final RiskTemplateConfiguration _templateConfig;
  final SafetyFilterService _safetyFilter;
  final MedicalDictionaryService _medicalDictionary;

  RiskMitigationService._internal()
      : _templateConfig = RiskTemplateConfiguration(),
        _safetyFilter = SafetyFilterService(),
        _medicalDictionary = MedicalDictionaryService(),
        super.internal();

  @visibleForTesting
  RiskMitigationService.forTesting({
    required RiskTemplateConfiguration templateConfig,
    required SafetyFilterService safetyFilter,
    required MedicalDictionaryService medicalDictionary,
  })  : _templateConfig = templateConfig,
        _safetyFilter = safetyFilter,
        _medicalDictionary = medicalDictionary,
        super.internal();

  Future<void> init() async {
    await _templateConfig.load();
    await _medicalDictionary.load();
  }

  /// Generates risk mitigation questions based on the transcript.
  ///
  /// Returns a list of localized questions/prompts.
  Future<List<String>> generateRiskMitigationQuestions(
      String transcript) async {
    if (transcript.isEmpty) return [];

    // Ensure config is loaded
    if (!_templateConfig.isLoaded) {
      await init();
    }

    final questions = <String>[];
    final stopwatch = Stopwatch()..start();

    try {
      final lowerTranscript = transcript.toLowerCase();
      final templates = _templateConfig.templates;

      for (final template in templates) {
        bool matchFound = false;
        String? matchedKeyword;

        for (final keyword in template.keywords) {
          if (lowerTranscript.contains(keyword.toLowerCase())) {
            matchFound = true;
            matchedKeyword = keyword;
            break;
          }
        }

        if (matchFound && matchedKeyword != null) {
          String question =
              template.template.replaceAll('{keyword}', matchedKeyword);

          // Apply Safety Filter as complementary layer
          question = _safetyFilter.sanitize(question);

          questions.add(question);

          // Log usage
          _logTemplateUsage(template.id, matchedKeyword);
        }
      }

      if (questions.isEmpty) {
        final fallbackTemplates =
            templates.where((template) => template.riskLevel == 'fallback');

        for (final template in fallbackTemplates) {
          final question = _safetyFilter.sanitize(template.template);
          questions.add(question);
        }
      }
    } catch (e) {
      SecureLogger.log('Error generating risk questions: $e');
      // Graceful degradation
    } finally {
      stopwatch.stop();
      if (stopwatch.elapsedMilliseconds > 100) {
        SecureLogger.log(
            'RiskMitigationService: Generation took ${stopwatch.elapsedMilliseconds}ms');
      }
    }

    return questions;
  }

  void _logTemplateUsage(String templateId, String keyword) {
    // Simulate analytics
    if (kDebugMode) {
      print('RiskTemplate used: $templateId (keyword: $keyword)');
    }
  }
}
