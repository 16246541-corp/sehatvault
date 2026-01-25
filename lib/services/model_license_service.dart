import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/model_option.dart';
import '../utils/secure_logger.dart';

class ModelLicense {
  final String modelId;
  final String modelName;
  final String licenseName;
  final String fullText;
  final List<String> keyRestrictions;
  final List<String> attributionRequirements;
  final String plainLanguageSummary;
  final String version;
  final DateTime lastReviewed;

  const ModelLicense({
    required this.modelId,
    required this.modelName,
    required this.licenseName,
    required this.fullText,
    required this.keyRestrictions,
    required this.attributionRequirements,
    required this.plainLanguageSummary,
    required this.version,
    required this.lastReviewed,
  });
}

class ModelLicenseService {
  static final ModelLicenseService _instance = ModelLicenseService._internal();
  factory ModelLicenseService() => _instance;
  ModelLicenseService._internal();

  final Map<String, ModelLicense> _licenses = {
    'tiny_llama_1b': ModelLicense(
      modelId: 'tiny_llama_1b',
      modelName: 'TinyLlama-1.1B',
      licenseName: 'Apache License 2.0',
      version: '2.0',
      lastReviewed: DateTime(2024, 1, 15),
      plainLanguageSummary: 'A permissive license that allows you to use, modify, and distribute the model for any purpose, including commercial ones, provided you include the original license and copyright notice.',
      keyRestrictions: [
        'Must include a copy of the license in any redistribution',
        'Must include clear attribution to the original authors',
        'Cannot use authors\' names for promotion without permission',
      ],
      attributionRequirements: [
        'Include Apache 2.0 license text',
        'Retain all copyright, patent, trademark, and attribution notices',
      ],
      fullText: '''Apache License
Version 2.0, January 2004
http://www.apache.org/licenses/

TERMS AND CONDITIONS FOR USE, REPRODUCTION, AND DISTRIBUTION

1. Definitions.
... [Full Apache 2.0 Text Content] ...
''',
    ),
    'med_gemma_4b': ModelLicense(
      modelId: 'med_gemma_4b',
      modelName: 'MedGemma-4B',
      licenseName: 'Gemma Terms of Use',
      version: '1.1',
      lastReviewed: DateTime(2024, 3, 10),
      plainLanguageSummary: 'Custom open-weights license by Google. Allows commercial use and distribution with specific restrictions on prohibited use cases (e.g., generating illegal content or violating privacy).',
      keyRestrictions: [
        'Usage must comply with Google\'s Prohibited Use Policy',
        'Redistribution must include a copy of the Gemma Terms of Use',
        'Cannot use the model to improve other AI models (distillation) except as permitted',
      ],
      attributionRequirements: [
        'Include "Gemma is a trademark of Google LLC"',
        'Link to the official Gemma Terms of Use',
      ],
      fullText: '''Gemma Terms of Use
... [Full Gemma Terms Text Content] ...
''',
    ),
    'advanced_8b': ModelLicense(
      modelId: 'advanced_8b',
      modelName: 'Advanced-8B',
      licenseName: 'Llama 3 Community License',
      version: '1.0',
      lastReviewed: DateTime(2024, 5, 20),
      plainLanguageSummary: 'Meta\'s Llama 3 license. Permissive for most users and commercial entities with fewer than 700 million monthly active users.',
      keyRestrictions: [
        'Commercial use limited to entities with <700M monthly active users',
        'Must include "Built with Meta Llama 3" in relevant materials',
        'Cannot use for specific prohibited medical diagnostic purposes without additional validation',
      ],
      attributionRequirements: [
        'Include "Built with Meta Llama 3"',
        'Provide a copy of the Llama 3 Community License Agreement',
      ],
      fullText: '''Meta Llama 3 Community License Agreement
... [Full Llama 3 License Text Content] ...
''',
    ),
    'research_13b': ModelLicense(
      modelId: 'research_13b',
      modelName: 'Research-13B',
      licenseName: 'Apache License 2.0',
      version: '2.0',
      lastReviewed: DateTime(2024, 6, 5),
      plainLanguageSummary: 'Permissive license allowing research and commercial use. Ideal for deep medical analysis.',
      keyRestrictions: [
        'Must include a copy of the license in any redistribution',
        'Retain all attribution notices',
      ],
      attributionRequirements: [
        'Include Apache 2.0 license text',
        'Retain all copyright notices',
      ],
      fullText: '''Apache License
Version 2.0, January 2004
... [Full Apache 2.0 Text Content] ...
''',
    ),
  };

  ModelLicense? getLicense(String modelId) {
    SecureLogger.log('Accessing license for model: $modelId');
    return _licenses[modelId];
  }

  List<ModelLicense> getAllLicenses() {
    return _licenses.values.toList();
  }

  Future<String> exportComplianceDocumentation(ModelLicense license) async {
    SecureLogger.log('Exporting compliance documentation for: ${license.modelName}');
    
    final content = '''
SEHAT LOCKER - MODEL COMPLIANCE DOCUMENTATION
Generated: ${DateTime.now().toIso8601String()}

MODEL INFORMATION
Name: ${license.modelName}
ID: ${license.modelId}
License Type: ${license.licenseName}
License Version: ${license.version}
Last Legal Review: ${license.lastReviewed.toIso8601String()}

PLAIN LANGUAGE SUMMARY
${license.plainLanguageSummary}

KEY RESTRICTIONS
${license.keyRestrictions.map((r) => "- $r").join('\n')}

ATTRIBUTION REQUIREMENTS
${license.attributionRequirements.map((a) => "- $a").join('\n')}

FULL LICENSE TEXT
-------------------------------------------------------------------------------
${license.fullText}
-------------------------------------------------------------------------------

Generated by Sehat Locker Compliance System.
''';

    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/compliance_${license.modelId}_${DateTime.now().millisecondsSinceEpoch}.txt';
      final file = File(filePath);
      await file.writeAsString(content);
      SecureLogger.log('Compliance documentation exported to: $filePath');
      return filePath;
    } catch (e) {
      SecureLogger.log('Failed to export compliance documentation: $e');
      rethrow;
    }
  }

  List<ModelLicense> searchLicenses(String query) {
    if (query.isEmpty) return getAllLicenses();
    
    final lowerQuery = query.toLowerCase();
    return _licenses.values.where((l) {
      return l.modelName.toLowerCase().contains(lowerQuery) ||
             l.licenseName.toLowerCase().contains(lowerQuery) ||
             l.plainLanguageSummary.toLowerCase().contains(lowerQuery) ||
             l.fullText.toLowerCase().contains(lowerQuery);
    }).toList();
  }
}
