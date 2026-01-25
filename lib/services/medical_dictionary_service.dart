import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class MedicalDictionaryService {
  static final MedicalDictionaryService _instance =
      MedicalDictionaryService._internal();

  factory MedicalDictionaryService({Map<String, dynamic>? initialData}) {
    if (initialData != null) {
      _instance._configure(initialData);
    }
    return _instance;
  }

  MedicalDictionaryService._internal();

  @visibleForTesting
  MedicalDictionaryService.forTesting(Map<String, dynamic> initialData) {
    _configure(initialData);
  }

  void _configure(Map<String, dynamic>? initialData) {
    if (initialData != null) {
      _data = initialData;
      _parseData();
    }
  }

  static const String _assetPath = 'assets/data/medical_dictionary.json';

  Map<String, dynamic>? _data;
  final Map<String, String> _medications = {};
  final Map<String, String> _tests = {};
  final Map<String, String> _specialists = {};
  final Map<String, String> _procedures = {};
  final Map<String, String> _bodyParts = {};

  bool get isLoaded => _data != null;

  Future<void> load() async {
    if (isLoaded) return;

    try {
      final jsonString = await rootBundle.loadString(_assetPath);
      _data = json.decode(jsonString);
      _parseData();
    } catch (e) {
      print('Error loading medical dictionary: $e');
    }
  }

  void _parseData() {
    if (_data == null) return;

    // Medications
    if (_data!.containsKey('medications')) {
      for (var item in _data!['medications']) {
        final canonical = item['canonical_name'] as String;
        _medications[canonical.toLowerCase()] = canonical;
        if (item['aliases'] != null) {
          for (var alias in item['aliases']) {
            _medications[(alias as String).toLowerCase()] = canonical;
          }
        }
      }
    }

    // Tests
    if (_data!.containsKey('tests')) {
      for (var item in _data!['tests']) {
        final canonical = item['canonical_name'] as String;
        _tests[canonical.toLowerCase()] = canonical;
        if (item['aliases'] != null) {
          for (var alias in item['aliases']) {
            _tests[(alias as String).toLowerCase()] = canonical;
          }
        }
      }
    }

    // Specialists
    if (_data!.containsKey('specialists')) {
      for (var item in _data!['specialists']) {
        final name = item as String;
        _specialists[name.toLowerCase()] = name;
      }
    }

    // Procedures
    if (_data!.containsKey('procedures')) {
      for (var item in _data!['procedures']) {
        final name = item as String;
        _procedures[name.toLowerCase()] = name;
      }
    }

    // Body Parts
    if (_data!.containsKey('body_parts')) {
      for (var item in _data!['body_parts']) {
        final name = item as String;
        _bodyParts[name.toLowerCase()] = name;
      }
    }
  }

  String? findMedication(String text) {
    return _findMatch(text, _medications);
  }

  String? findTest(String text) {
    return _findMatch(text, _tests);
  }

  String? findSpecialist(String text) {
    return _findMatch(text, _specialists);
  }

  String? findProcedure(String text) {
    return _findMatch(text, _procedures);
  }

  String? findBodyPart(String text) {
    return _findMatch(text, _bodyParts);
  }

  String? findAny(String text) {
    String? match;
    match = findMedication(text);
    if (match != null) return match;
    match = findTest(text);
    if (match != null) return match;
    match = findSpecialist(text);
    if (match != null) return match;
    match = findProcedure(text);
    if (match != null) return match;
    match = findBodyPart(text);
    return match;
  }

  Set<String> findAllTerms(String text) {
    final Set<String> found = {};
    _collectMatches(text, _medications, found);
    _collectMatches(text, _tests, found);
    _collectMatches(text, _specialists, found);
    _collectMatches(text, _procedures, found);
    _collectMatches(text, _bodyParts, found);
    return found;
  }

  void _collectMatches(
      String text, Map<String, String> dictionary, Set<String> found) {
    final lowerText = text.toLowerCase();
    for (final key in dictionary.keys) {
      if (key.length < 3) continue;
      final pattern = RegExp(r'\b' + RegExp.escape(key) + r'\b');
      if (pattern.hasMatch(lowerText)) {
        found.add(dictionary[key]!);
      }
    }
  }

  // Helper to find longest matching phrase in the dictionary within the text
  String? _findMatch(String text, Map<String, String> dictionary) {
    final lowerText = text.toLowerCase();

    // Sort dictionary keys by length descending to match longest phrases first
    final sortedKeys = dictionary.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final key in sortedKeys) {
      // Check for whole word match
      final pattern = RegExp(r'\b' + RegExp.escape(key) + r'\b');
      if (pattern.hasMatch(lowerText)) {
        // Return the canonical name
        return dictionary[key];
      }
    }
    return null;
  }
}
