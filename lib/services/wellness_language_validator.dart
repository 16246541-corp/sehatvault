import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class WellnessLanguageValidator {
  static final WellnessLanguageValidator _instance =
      WellnessLanguageValidator._internal();

  factory WellnessLanguageValidator() => _instance;

  WellnessLanguageValidator._internal();

  List<WellnessReplacement> _replacements = [];
  Set<String> _exceptions = {};
  bool _isLoaded = false;

  Future<void> load() async {
    if (_isLoaded) return;
    try {
      final jsonString =
          await rootBundle.loadString('assets/data/wellness_terminology.json');
      final data = json.decode(jsonString);

      if (data['replacements'] != null) {
        _replacements = (data['replacements'] as List)
            .map((e) => WellnessReplacement.fromJson(e))
            .toList();
      }

      if (data['exceptions'] != null) {
        _exceptions = Set<String>.from(
            data['exceptions'].map((e) => (e as String).toLowerCase()));
      }

      _isLoaded = true;
    } catch (e) {
      debugPrint('Error loading wellness terminology: $e');
    }
  }

  String validate(String text) {
    if (!_isLoaded || text.isEmpty) return text;

    String processedText = text;

    final Map<String, String> placeholders = {};
    int placeholderIndex = 0;

    final sortedExceptions = _exceptions.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final exception in sortedExceptions) {
      final exceptionPattern =
          RegExp(RegExp.escape(exception), caseSensitive: false);
      if (exceptionPattern.hasMatch(processedText)) {
        processedText =
            processedText.replaceAllMapped(exceptionPattern, (match) {
          final placeholder = '__WELLNESS_EXCEPTION_${placeholderIndex++}__';
          placeholders[placeholder] = match.group(0)!;
          return placeholder;
        });
      }
    }

    for (final replacement in _replacements) {
      final pattern = RegExp(r'\b' + RegExp.escape(replacement.term) + r'\b',
          caseSensitive: false);

      if (pattern.hasMatch(processedText)) {
        processedText = processedText.replaceAllMapped(pattern, (match) {
          final matchText = match.group(0)!;

          String replacementText = replacement.replacement;
          if (matchText.isNotEmpty &&
              matchText[0].toUpperCase() == matchText[0]) {
            replacementText =
                replacementText[0].toUpperCase() + replacementText.substring(1);
          }

          return replacementText;
        });
      }
    }

    placeholders.forEach((placeholder, original) {
      processedText = processedText.replaceAll(placeholder, original);
    });

    return processedText;
  }

  List<WellnessReplacement> getSuggestions(String text) {
    if (!_isLoaded || text.isEmpty) return [];

    List<WellnessReplacement> suggestions = [];
    for (final replacement in _replacements) {
      final pattern = RegExp(r'\b' + RegExp.escape(replacement.term) + r'\b',
          caseSensitive: false);
      if (pattern.hasMatch(text)) {
        suggestions.add(replacement);
      }
    }
    return suggestions;
  }
}

class WellnessReplacement {
  final String term;
  final String replacement;
  final String context;
  final String severity;

  WellnessReplacement(
      {required this.term,
      required this.replacement,
      required this.context,
      required this.severity});

  factory WellnessReplacement.fromJson(Map<String, dynamic> json) {
    return WellnessReplacement(
      term: json['term'],
      replacement: json['replacement'],
      context: json['context'],
      severity: json['severity'] ?? 'low',
    );
  }
}
