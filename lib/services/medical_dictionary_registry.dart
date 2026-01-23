import 'dart:convert';
import '../models/medical_test.dart';

/// Pure Dart registry for medical dictionary logic.
/// Independent of Flutter dependencies.
class MedicalDictionaryRegistry {
  Map<String, dynamic>? _data;
  List<MedicalTestDefinition> _tests = [];
  Map<String, String> _abbreviations = {};
  Set<String> _commonUnits = {};
  
  // Cache for fast lookups
  final Map<String, MedicalTestDefinition> _testLookupCache = {};

  bool get isLoaded => _data != null;

  /// Loads the medical dictionary from a JSON string.
  void loadFromJsonString(String jsonString) {
    try {
      _data = json.decode(jsonString);
      _parseData();
    } catch (e) {
      print('Error parsing medical dictionary JSON: $e');
      _data = {};
      _tests = [];
      _abbreviations = {};
      _commonUnits = {};
    }
  }

  void _parseData() {
    if (_data == null) return;

    if (_data!.containsKey('tests')) {
      final testsList = _data!['tests'] as List;
      _tests = testsList.map((t) => MedicalTestDefinition.fromJson(t)).toList();
      
      // Build lookup cache (lowercase keys)
      for (var test in _tests) {
        _testLookupCache[test.canonicalName.toLowerCase()] = test;
        for (var alias in test.aliases) {
          _testLookupCache[alias.toLowerCase()] = test;
        }
      }
    }

    if (_data!.containsKey('abbreviations')) {
      _abbreviations = Map<String, String>.from(_data!['abbreviations']);
    }

    if (_data!.containsKey('common_units')) {
      _commonUnits = Set<String>.from(_data!['common_units']);
    }
  }

  /// Finds a test definition by name (canonical or alias).
  /// Case-insensitive.
  MedicalTestDefinition? findTest(String name) {
    if (!isLoaded) return null;
    return _testLookupCache[name.toLowerCase().trim()];
  }

  /// Expands an abbreviation if found.
  /// Returns the original string if not found.
  String expandAbbreviation(String abbr) {
    if (!isLoaded) return abbr;
    return _abbreviations[abbr] ?? abbr;
  }

  /// Checks if a unit string is a known common unit.
  bool isValidUnit(String unit) {
    if (!isLoaded) return false;
    return _commonUnits.contains(unit);
  }

  /// Returns all test definitions.
  List<MedicalTestDefinition> getAllTests() {
    return List.unmodifiable(_tests);
  }

  /// Returns all categories.
  List<String> getCategories() {
    if (_data != null && _data!.containsKey('categories')) {
      return List<String>.from(_data!['categories']);
    }
    return _tests.map((t) => t.category).toSet().toList();
  }
}
