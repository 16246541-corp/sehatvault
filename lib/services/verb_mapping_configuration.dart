import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/follow_up_item.dart';

class VerbMappingConfiguration {
  static final VerbMappingConfiguration _instance = VerbMappingConfiguration._internal();

  factory VerbMappingConfiguration() {
    return _instance;
  }

  VerbMappingConfiguration._internal();

  /// Constructor for testing purposes.
  @visibleForTesting
  VerbMappingConfiguration.forTesting([Map<String, FollowUpCategory>? initialMap]) {
    if (initialMap != null) {
      _verbToCategoryMap = initialMap;
      _isLoaded = true;
    }
  }

  Map<String, FollowUpCategory> _verbToCategoryMap = {};
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

  /// Loads the verb mapping configuration from assets.
  Future<void> load() async {
    if (_isLoaded) return;

    try {
      final jsonString = await rootBundle.loadString('assets/data/verb_mapping.json');
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);

      final Map<String, FollowUpCategory> tempMap = {};
      
      for (var entry in jsonMap.entries) {
        final verb = entry.key.toLowerCase();
        final categoryString = entry.value.toString();
        
        try {
          final category = FollowUpCategory.values.firstWhere(
            (e) => e.name == categoryString,
          );
          tempMap[verb] = category;
        } catch (e) {
          print('Warning: Unknown category "$categoryString" for verb "$verb" in verb_mapping.json');
        }
      }

      _verbToCategoryMap = tempMap;
      _isLoaded = true;
    } catch (e) {
      print('Error loading verb mapping configuration: $e');
    }
  }

  /// Returns all mapped verbs.
  List<String> get allVerbs {
    if (!_isLoaded) {
      print('Warning: VerbMappingConfiguration not loaded yet.');
      return [];
    }
    return _verbToCategoryMap.keys.toList();
  }

  /// Returns the category for a given verb, or null if not found.
  FollowUpCategory? getCategoryForVerb(String verb) {
    if (!_isLoaded) {
      print('Warning: VerbMappingConfiguration not loaded yet.');
    }
    return _verbToCategoryMap[verb.toLowerCase()];
  }
}
