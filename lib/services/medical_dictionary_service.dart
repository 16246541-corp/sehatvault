import 'package:flutter/services.dart';
import '../models/medical_test.dart';
import 'medical_dictionary_registry.dart';

export '../models/medical_test.dart';
export 'medical_dictionary_registry.dart';

class MedicalDictionaryService {
  static final MedicalDictionaryService _instance = MedicalDictionaryService._internal();

  factory MedicalDictionaryService() {
    return _instance;
  }

  MedicalDictionaryService._internal();

  final MedicalDictionaryRegistry _registry = MedicalDictionaryRegistry();

  bool get isLoaded => _registry.isLoaded;

  /// Loads the medical dictionary from assets.
  /// Should be called during app initialization.
  Future<void> load() async {
    if (isLoaded) return;
    try {
      final jsonString = await rootBundle.loadString('assets/data/medical_dictionary.json');
      _registry.loadFromJsonString(jsonString);
    } catch (e) {
      print('Error loading medical dictionary: $e');
      // Initialize with empty data handled by loadFromJsonString internally if malformed,
      // but here we might fail to read file.
    }
  }
  
  // Delegate methods to registry
  
  MedicalTestDefinition? findTest(String name) => _registry.findTest(name);

  String expandAbbreviation(String abbr) => _registry.expandAbbreviation(abbr);

  bool isValidUnit(String unit) => _registry.isValidUnit(unit);

  List<MedicalTestDefinition> getAllTests() => _registry.getAllTests();

  List<String> getCategories() => _registry.getCategories();
  
  /// Expose loadFromJsonString for testing convenience via the service facade if needed,
  /// though usually one would use the Registry directly for pure dart tests.
  void loadFromJsonString(String jsonString) => _registry.loadFromJsonString(jsonString);
}
