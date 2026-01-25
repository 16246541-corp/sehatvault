import 'package:flutter/foundation.dart';
import '../main_common.dart' show storageService;
import 'local_storage_service.dart';
import 'wellness_language_validator.dart';

class SafetyFilterService {
  static SafetyFilterService _instance = SafetyFilterService._internal();

  factory SafetyFilterService() {
    return _instance;
  }

  @visibleForTesting
  static void setMockInstance(SafetyFilterService instance) {
    _instance = instance;
  }

  final WellnessLanguageValidator _wellnessValidator;
  final LocalStorageService _storageService;

  SafetyFilterService._internal({
    WellnessLanguageValidator? wellnessValidator,
    LocalStorageService? storageServiceInstance,
  })  : _wellnessValidator = wellnessValidator ?? WellnessLanguageValidator(),
        _storageService = storageServiceInstance ?? storageService {
    if (wellnessValidator == null) {
      _initWellnessValidator();
    }
  }

  Future<void> _initWellnessValidator() async {
    await _wellnessValidator.load();
  }

  // Prohibited phrases map to regex pattern for flexible matching
  final Map<String, RegExp> _prohibitedPatterns = {
    'you have': RegExp(r'\b(you|u)\s+have\b', caseSensitive: false),
    'diagnosis': RegExp(r'\bdiagnosis\b', caseSensitive: false),
    'likely condition': RegExp(r'\blikely\s+condition\b', caseSensitive: false),
    'suffer from': RegExp(r'\bsuffer\s+from\b', caseSensitive: false),
    'symptoms indicate':
        RegExp(r'\bsymptoms\s+indicate\b', caseSensitive: false),
    // Additional similar diagnostic terminology
    'medical opinion': RegExp(r'\bmedical\s+opinion\b', caseSensitive: false),
    'it seems you have':
        RegExp(r'\bit\s+seems\s+(you|u)\s+have\b', caseSensitive: false),
    'i suspect': RegExp(r'\bi\s+suspect\b', caseSensitive: false),
  };

  /// Scans the input text and replaces prohibited diagnostic language with educational alternatives.
  ///
  /// Returns the sanitized text.
  /// Logs triggers in debug mode.
  String sanitize(String text) {
    if (text.isEmpty) return text;

    final stopwatch = Stopwatch()..start();
    String processedText = text;

    // 1. Wellness Language Validation
    final settings = _storageService.getAppSettings();
    if (settings.enableWellnessLanguageChecks) {
      final wellnessStart = Stopwatch()..start();
      processedText = _wellnessValidator.validate(processedText);
      wellnessStart.stop();

      if (settings.showWellnessDebugInfo && kDebugMode) {
        print('Wellness Validator took ${wellnessStart.elapsedMilliseconds}ms');
      }
    }

    bool triggered = false;

    // We process sentence by sentence to maintain context and apply replacements correctly
    // This is a simple split; for more complex cases, a robust tokenizer might be needed
    // but for this requirement, splitting by punctuation is a good start.
    // We keep delimiters to reconstruct the text.
    final sentences = _splitWithDelimiters(text);
    final buffer = StringBuffer();

    for (String sentence in sentences) {
      String sanitizedSentence = sentence;
      bool sentenceModified = false;

      for (final entry in _prohibitedPatterns.entries) {
        final pattern = entry.value;
        if (pattern.hasMatch(sanitizedSentence)) {
          final match = pattern.firstMatch(sanitizedSentence);
          if (match != null) {
            // Log the trigger
            if (kDebugMode) {
              print(
                  'SafetyFilterService: Triggered by "${entry.key}" in text: "$sentence"');
            }
            triggered = true;
            sentenceModified = true;

            // Extract topic
            // Strategy: The topic is generally what follows the trigger phrase in the sentence.
            // We strip the trigger and any leading verbs/prepositions if they are part of the match context
            // and use the rest of the sentence.

            // Example: "You have diabetes" -> Match "You have" -> Topic "diabetes"
            // Example: "The diagnosis is flu" -> Match "diagnosis" -> Topic "is flu" -> maybe clean "is"?

            // For now, we'll take the substring after the match end.
            String topic = sanitizedSentence.substring(match.end).trim();

            // Clean up topic
            // Remove trailing punctuation from the topic if it exists in the original sentence split
            // (The splitWithDelimiters keeps punctuation attached or separate depending on impl)
            // Here we assume 'sentence' includes the punctuation.

            // Remove common connecting words if they start the topic (optional, but improves quality)
            // e.g. "You have a cold" -> topic "a cold". "You have been diagnosed with X" -> "been diagnosed with X"

            // Construct replacement
            // "Some people with similar concerns have discussed with their doctors: [topic]"

            // If the topic is empty (e.g. sentence ends with trigger), we handle it gracefully?
            // "You have." -> Topic empty.
            if (topic.isNotEmpty) {
              // Remove trailing punctuation for the topic insertion
              String cleanTopic =
                  topic.replaceAll(RegExp(r'[.!?]+$'), '').trim();

              // If cleanTopic is empty after stripping punctuation, fallback?
              if (cleanTopic.isEmpty) {
                sanitizedSentence =
                    "Some people with similar concerns have discussed this with their doctors.";
              } else {
                sanitizedSentence =
                    "Some people with similar concerns have discussed with their doctors: $cleanTopic.";
              }
            } else {
              sanitizedSentence =
                  "Some people with similar concerns have discussed this with their doctors.";
            }

            // We break after the first match in a sentence to avoid double replacement chaos
            break;
          }
        }
      }
      buffer.write(sanitizedSentence);
    }

    if (triggered && kDebugMode) {
      // Additional debug info if needed
    }

    stopwatch.stop();
    if (stopwatch.elapsedMilliseconds > 50) {
      if (kDebugMode) {
        print(
            'SafetyFilterService warning: Processing took ${stopwatch.elapsedMilliseconds}ms');
      }
    }

    return buffer.toString();
  }

  List<String> _splitWithDelimiters(String text) {
    // Split by . ! ? but keep them.
    // Using lookahead/lookbehind is tricky in Dart JS (web) but fine for mobile.
    // A simpler approach is to replace delimiters with delimiter+unique_separator, then split.
    // Or iterate through characters.

    // Pattern: ([.!?]+)(\s+|$)
    // We want to keep the sentence structure.
    // "Hello. World." -> ["Hello.", " World."]

    List<String> parts = [];
    RegExp exp = RegExp(r'([^.!?]+[.!?]+)(\s+|$)|([^.!?]+$)');
    Iterable<Match> matches = exp.allMatches(text);

    if (matches.isEmpty && text.isNotEmpty) {
      return [text];
    }

    for (final m in matches) {
      parts.add(m.group(0)!);
    }

    return parts;
  }
}
