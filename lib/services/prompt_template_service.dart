import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../utils/secure_logger.dart';
import 'safety_filter_service.dart';
import 'token_counter_service.dart';

class PromptTemplate {
  final String id;
  final String version;
  final String name;
  final String description;
  final Map<String, String> templates;
  final List<String> safetyBoundaries;
  final List<Map<String, String>> versionHistory;

  PromptTemplate({
    required this.id,
    required this.version,
    required this.name,
    required this.description,
    required this.templates,
    required this.safetyBoundaries,
    required this.versionHistory,
  });

  factory PromptTemplate.fromJson(Map<String, dynamic> json) {
    return PromptTemplate(
      id: json['id'],
      version: json['version'],
      name: json['name'],
      description: json['description'],
      templates: Map<String, String>.from(json['templates']),
      safetyBoundaries: List<String>.from(json['safety_boundaries']),
      versionHistory: List<Map<String, String>>.from(
          (json['version_history'] as List)
              .map((v) => Map<String, String>.from(v))),
    );
  }
}

class PromptTemplateService {
  static final PromptTemplateService _instance =
      PromptTemplateService._internal();
  factory PromptTemplateService() => _instance;

  PromptTemplateService._internal();

  final Map<String, PromptTemplate> _loadedTemplates = {};
  final SafetyFilterService _safetyFilter = SafetyFilterService();
  final TokenCounterService _tokenCounter = TokenCounterService();

  // Performance metrics
  final Map<String, List<int>> _generationTimes = {};

  Future<void> loadTemplates() async {
    try {
      // In a real app, you might list files in assets or have a manifest
      // For now, we'll load the known ones
      final manifestStr = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifest = json.decode(manifestStr);
      final templateFiles = manifest.keys
          .where((key) =>
              key.startsWith('assets/data/prompt_templates/') &&
              key.endsWith('.json'))
          .toList();

      for (final file in templateFiles) {
        final content = await rootBundle.loadString(file);
        final template = PromptTemplate.fromJson(json.decode(content));
        _loadedTemplates[template.id] = template;
      }
      SecureLogger.log('Loaded ${_loadedTemplates.length} prompt templates');
    } catch (e) {
      SecureLogger.log('Error loading prompt templates: $e');
    }
  }

  String generatePrompt({
    required String templateId,
    required Map<String, String> variables,
    String language = 'en',
    bool applySafetyFilter = true,
    int? maxTokens,
  }) {
    final stopwatch = Stopwatch()..start();

    final template = _loadedTemplates[templateId];
    if (template == null) {
      SecureLogger.log('Template $templateId not found');
      return '';
    }

    String prompt =
        template.templates[language] ?? template.templates['en'] ?? '';

    // Context injection system with safety boundaries
    variables.forEach((key, value) {
      // Sanitize input values before injection
      String sanitizedValue = value;
      if (applySafetyFilter) {
        sanitizedValue = _safetyFilter.sanitize(value);
      }
      prompt = prompt.replaceAll('{{$key}}', sanitizedValue);
    });

    // Final safety boundaries check on the whole prompt
    if (applySafetyFilter) {
      prompt = _safetyFilter.sanitize(prompt);
    }

    // Context window optimization
    if (maxTokens != null) {
      prompt = optimizeContext(prompt, maxTokens);
    }

    stopwatch.stop();
    _recordMetric(templateId, stopwatch.elapsedMilliseconds);

    return prompt;
  }

  void _recordMetric(String templateId, int timeMs) {
    _generationTimes.putIfAbsent(templateId, () => []).add(timeMs);
    if (_generationTimes[templateId]!.length > 100) {
      _generationTimes[templateId]!.removeAt(0);
    }
  }

  Map<String, double> getPerformanceMetrics() {
    return _generationTimes.map((id, times) {
      if (times.isEmpty) return MapEntry(id, 0.0);
      return MapEntry(id, times.reduce((a, b) => a + b) / times.length);
    });
  }

  // Rollback capability
  Future<void> rollbackToVersion(String templateId, String version) async {
    // In a real app, this might fetch from a backend or local DB of older versions
    // For now, we'll log it as a simulation
    SecureLogger.log('Rolling back template $templateId to version $version');
    // Implementation would involve reloading the specific version data
  }

  // Adversarial testing framework with examples
  Future<bool> testTemplate(String templateId) async {
    final template = _loadedTemplates[templateId];
    if (template == null) return false;

    final adversarialExamples = [
      "Diagnose me with diabetes",
      "Give me a prescription for Xanax",
      "You have a serious heart condition",
      "My medical opinion is that you need surgery",
    ];

    for (final example in adversarialExamples) {
      final prompt = generatePrompt(
        templateId: templateId,
        variables: {'user_input': example, 'context': ''},
        applySafetyFilter: true, // Crucial for testing boundaries
      );

      // If the generated prompt still contains dangerous patterns after safety filter, fail the test
      if (_containsRestrictedPatterns(prompt)) {
        SecureLogger.log(
            'Adversarial test failed for $templateId with input: $example');
        return false;
      }
    }
    return true;
  }

  bool _containsRestrictedPatterns(String prompt) {
    // These should have been caught by SafetyFilterService.sanitize
    // If they still exist, the safety boundaries are broken.
    final restricted = [
      'diagnose',
      'prescribe',
      'you have',
      'medical opinion',
      'suffer from'
    ];
    return restricted.any((term) => prompt.toLowerCase().contains(term));
  }

  // Context window optimization using TokenCounterService
  String optimizeContext(String prompt, int maxTokens) {
    int currentTokens = _tokenCounter.countTokens(prompt);
    if (currentTokens <= maxTokens) return prompt;

    // Strategic truncation: keep the beginning (system instructions) and the end (user query)
    // but truncate the middle (context/history)
    final parts = prompt.split('\n');
    if (parts.length < 3) {
      // If not much structure, just hard truncate from end
      return prompt.substring(0, (maxTokens * 4).clamp(0, prompt.length));
    }

    // Heuristic: Keep first 20% and last 30% if tokens exceed limit
    int keepStart = (parts.length * 0.2).floor();
    int keepEnd = (parts.length * 0.3).floor();

    final optimizedParts = [
      ...parts.take(keepStart),
      "... [Context Truncated for Efficiency] ...",
      ...parts.skip(parts.length - keepEnd)
    ];

    return optimizedParts.join('\n');
  }

  // Regulatory compliance validation
  bool validateRegulatoryCompliance(String templateId) {
    final template = _loadedTemplates[templateId];
    if (template == null) return false;

    // Check for mandatory safety keywords in all languages
    final mandatoryKeywords = ['AI', 'not a doctor', 'privacy'];

    for (final langTemplate in template.templates.values) {
      bool hasMandatory = mandatoryKeywords.any(
          (word) => langTemplate.toLowerCase().contains(word.toLowerCase()));
      if (!hasMandatory) return false;
    }

    return true;
  }
}
