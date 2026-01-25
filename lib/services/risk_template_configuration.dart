import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class RiskTemplate {
  final String id;
  final List<String> keywords;
  final String riskLevel;
  final String template;

  RiskTemplate({
    required this.id,
    required this.keywords,
    required this.riskLevel,
    required this.template,
  });

  factory RiskTemplate.fromJson(Map<String, dynamic> json) {
    return RiskTemplate(
      id: json['id'],
      keywords: List<String>.from(json['keywords']),
      riskLevel: json['risk_level'],
      template: json['template'],
    );
  }
}

class RiskTemplateConfiguration {
  static final RiskTemplateConfiguration _instance =
      RiskTemplateConfiguration._internal();

  factory RiskTemplateConfiguration() {
    return _instance;
  }

  RiskTemplateConfiguration._internal();

  @visibleForTesting
  RiskTemplateConfiguration.forTesting(this._templates) : _isLoaded = true;

  List<RiskTemplate> _templates = [];
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

  /// Loads the risk templates from assets.
  Future<void> load() async {
    if (_isLoaded) return;

    try {
      final jsonString =
          await rootBundle.loadString('assets/data/risk_templates.json');
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);

      // Default to 'en' for now
      final List<dynamic> list = jsonMap['en'] ?? [];

      _templates = list.map((e) => RiskTemplate.fromJson(e)).toList();
      _isLoaded = true;
    } catch (e) {
      print('Error loading risk templates: $e');
    }
  }

  List<RiskTemplate> get templates => _templates;
}
