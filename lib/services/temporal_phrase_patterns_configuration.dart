import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class TemporalPhrasePatternsConfiguration {
  static final TemporalPhrasePatternsConfiguration _instance = TemporalPhrasePatternsConfiguration._internal();

  factory TemporalPhrasePatternsConfiguration() {
    return _instance;
  }

  TemporalPhrasePatternsConfiguration._internal();

  /// Constructor for testing purposes.
  @visibleForTesting
  TemporalPhrasePatternsConfiguration.forTesting([Map<String, List<String>>? initialPatterns]) {
    if (initialPatterns != null) {
      _patterns = initialPatterns;
      _isLoaded = true;
    }
  }

  Map<String, List<String>> _patterns = {};
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

  /// Loads the temporal phrase patterns configuration from assets.
  Future<void> load() async {
    if (_isLoaded) return;

    try {
      final jsonString = await rootBundle.loadString('assets/data/temporal_phrase_patterns.json');
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);

      final Map<String, List<String>> tempMap = {};

      for (var entry in jsonMap.entries) {
        final key = entry.key;
        final value = entry.value;

        if (value is List) {
          tempMap[key] = value.map((e) => e.toString()).toList();
        }
      }

      _patterns = tempMap;
      _isLoaded = true;
    } catch (e) {
      print('Error loading temporal phrase patterns configuration: $e');
    }
  }

  /// Returns the patterns for a given category (deadline, frequency, anchor).
  List<String> getPatterns(String category) {
    if (!_isLoaded) {
      print('Warning: TemporalPhrasePatternsConfiguration not loaded yet.');
    }
    return _patterns[category] ?? [];
  }
  
  /// Returns all deadline patterns
  List<String> get deadlinePatterns => getPatterns('deadline');
  
  /// Returns all frequency patterns
  List<String> get frequencyPatterns => getPatterns('frequency');
  
  /// Returns all anchor patterns
  List<String> get anchorPatterns => getPatterns('anchor');
}
