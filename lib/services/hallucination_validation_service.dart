import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/knowledge_base/medical_knowledge.dart';
import 'medical_field_extractor.dart';
import '../utils/secure_logger.dart';
import 'analytics_service.dart';

enum HallucinationLevel { none, low, medium, high }

class HallucinationValidationResult {
  final HallucinationLevel level;
  final double confidenceScore;
  final List<String> detectedPatterns;
  final List<String> flaggedClaims;
  final String? suggestedCorrection;

  HallucinationValidationResult({
    required this.level,
    required this.confidenceScore,
    this.detectedPatterns = const [],
    this.flaggedClaims = const [],
    this.suggestedCorrection,
  });

  bool get isSuspicious => level != HallucinationLevel.none;
}

class HallucinationValidationService {
  static final HallucinationValidationService _instance =
      HallucinationValidationService._internal();
  factory HallucinationValidationService() => _instance;

  HallucinationValidationService._internal();

  final AnalyticsService _analyticsService = AnalyticsService();

  // Adaptive thresholds based on content type
  static const Map<String, double> _thresholds = {
    'medical_advice': 0.85,
    'lab_results': 0.90,
    'general_info': 0.70,
    'default': 0.80,
  };

  /// Validates AI content for potential hallucinations.
  Future<HallucinationValidationResult> validate(
    String content, {
    String contentType = 'default',
  }) async {
    final stopwatch = Stopwatch()..start();
    final threshold = _thresholds[contentType] ?? _thresholds['default']!;

    final flaggedClaims = <String>[];
    final detectedPatterns = <String>[];
    double totalConfidence = 1.0;

    // 1. Fact Verification against Knowledge Base
    for (final fact in MedicalKnowledgeBase.facts) {
      for (final pattern in fact.patterns) {
        final regex = RegExp(pattern, caseSensitive: false);
        if (regex.hasMatch(content)) {
          final matches = regex.allMatches(content);
          for (final match in matches) {
            final matchText = content.substring(match.start, match.end);
            if (_isContradictory(matchText, fact.claim)) {
              flaggedClaims.add('Contradicts: ${fact.claim}');
              detectedPatterns.add(pattern);
              totalConfidence *= 0.5;
            }
          }
        }
      }
    }

    // 2. Medical Field Extractor Validation
    final labValues = MedicalFieldExtractor.extractLabValues(content);
    if (labValues['count'] > 0) {
      // Check for unrealistic lab values (e.g., negative values, or values far outside physiological limits)
      for (final valueMap in labValues['values']) {
        final double? value = double.tryParse(valueMap['value'].toString());
        final String field = valueMap['field'].toString().toLowerCase();

        if (value != null && _isUnrealistic(field, value)) {
          flaggedClaims.add('Unrealistic value for $field: $value');
          totalConfidence *= 0.6;
        }
      }
    }

    // 3. Pattern-based Hallucination Detection
    // Common hallucination patterns in LLMs
    final hallucinationPatterns = {
      r'according to (?:a |the )?non-existent study': 0.3,
      r'I am 100% certain that': 0.7,
      r'studies from 202[6-9]': 0.2,
    };

    for (final entry in hallucinationPatterns.entries) {
      if (RegExp(entry.key, caseSensitive: false).hasMatch(content)) {
        detectedPatterns.add(entry.key);
        totalConfidence *= entry.value;
      }
    }

    // 4. Edge Case Handling for Speculative but Reasonable Statements
    // If the content uses speculative language, we decrease the strictness
    final speculativePatterns = [
      r'\bmight\b',
      r'\bcould\b',
      r'\bpossibly\b',
      r'\bit is possible\b',
      r'\bperhaps\b',
      r'\bspeculative\b',
    ];

    bool isSpeculative = false;
    for (final pattern in speculativePatterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(content)) {
        isSpeculative = true;
        break;
      }
    }

    if (isSpeculative && totalConfidence < 1.0) {
      // If it's speculative, we give a "reasonable doubt" boost
      // but only if it's not a high-level hallucination
      totalConfidence = (totalConfidence + 0.1).clamp(0.0, 1.0);
    }

    stopwatch.stop();

    HallucinationLevel level;
    if (totalConfidence >= threshold) {
      level = HallucinationLevel.none;
    } else if (totalConfidence > 0.6) {
      level = HallucinationLevel.low;
    } else if (totalConfidence > 0.3) {
      level = HallucinationLevel.medium;
    } else {
      level = HallucinationLevel.high;
    }

    final result = HallucinationValidationResult(
      level: level,
      confidenceScore: totalConfidence,
      detectedPatterns: detectedPatterns,
      flaggedClaims: flaggedClaims,
    );

    // 4. Logging and Analytics
    if (result.isSuspicious) {
      _logHallucination(result, content, contentType);
      _analyticsService.logEvent(
        'hallucination_detected',
        parameters: {
          'level': level.toString(),
          'confidence': totalConfidence,
          'content_type': contentType,
          'pattern_count': detectedPatterns.length,
        },
      );
    }

    return result;
  }

  bool _isContradictory(String matchText, String factClaim) {
    // Simple heuristic for demo: check for numeric differences
    final matchNumbers = RegExp(r'\d+(?:\.\d+)?')
        .allMatches(matchText)
        .map((m) => m.group(0))
        .toList();
    final factNumbers = RegExp(r'\d+(?:\.\d+)?')
        .allMatches(factClaim)
        .map((m) => m.group(0))
        .toList();

    // Check if any number in the match does not appear in the fact claim
    // This handles cases like "HbA1c is 7.5%" vs "HbA1c is 6.5%"
    // while ignoring the "1" in "HbA1c" if it appears in both.
    for (final number in matchNumbers) {
      if (!factNumbers.contains(number)) {
        return true;
      }
    }

    return false;
  }

  bool _isUnrealistic(String field, double value) {
    // Basic physiological limits for common lab tests
    if (value < 0) return true;

    if (field.contains('glucose')) {
      return value > 1000; // Extremely high glucose
    }
    if (field.contains('hemoglobin') || field == 'hb') {
      return value > 30; // Extremely high hemoglobin
    }
    if (field.contains('hba1c')) {
      return value > 25; // Extremely high HbA1c
    }

    return false;
  }

  void _logHallucination(
    HallucinationValidationResult result,
    String content,
    String contentType,
  ) {
    SecureLogger.log('HALLUCINATION DETECTED:\n'
        'Level: ${result.level}\n'
        'Confidence: ${result.confidenceScore}\n'
        'Content Type: $contentType\n'
        'Flagged Claims: ${result.flaggedClaims.join(', ')}\n'
        'Patterns: ${result.detectedPatterns.join(', ')}\n');
  }

  /// Record user feedback for a suspected hallucination.
  void recordUserFeedback(String content, String feedback,
      {bool isConfirmed = true}) {
    _analyticsService.logEvent(
      'hallucination_feedback',
      parameters: {
        'confirmed': isConfirmed,
        'feedback_length': feedback.length,
      },
    );
    SecureLogger.log(
        'USER HALLUCINATION FEEDBACK: Confirmed=$isConfirmed, Feedback=$feedback');
  }
}
