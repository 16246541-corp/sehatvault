import 'dart:io';
// ignore: avoid_relative_lib_imports
import '../lib/services/medical_dictionary_registry.dart';

Future<void> main() async {
  print('=== Medical Dictionary Registry Example (Pure Dart) ===');

  // 1. Read the JSON file from assets
  var filePath = 'assets/data/medical_dictionary.json';

  // If run from examples/ folder, adjust path
  if (!File(filePath).existsSync()) {
    if (File('../$filePath').existsSync()) {
      filePath = '../$filePath';
    } else {
      print('Error: JSON asset not found at $filePath');
      return;
    }
  }

  print('Reading dictionary from: $filePath');
  final file = File(filePath);
  final jsonString = await file.readAsString();

  // 2. Load into registry
  final registry = MedicalDictionaryRegistry();
  registry.loadFromJsonString(jsonString);

  if (!registry.isLoaded) {
    print('Failed to load registry.');
    return;
  }

  // 3. Demonstrate Usage
  print('\nStatistics:');
  print('- Total Tests: ${registry.getAllTests().length}');
  final categories = registry.getCategories();
  print('- Categories (${categories.length}): ${categories.join(', ')}');

  // Lookup Examples
  print('\n--- Test Lookup Examples ---');
  _lookupAndPrint(registry, 'Hb');
  _lookupAndPrint(registry, 'Hemoglobin');
  _lookupAndPrint(registry, 'Hgb');
  _lookupAndPrint(registry, 'WBC');
  _lookupAndPrint(registry, 'TLC');
  _lookupAndPrint(registry, 'Platelets');
  _lookupAndPrint(registry, 'Vitamin D');
  _lookupAndPrint(registry, 'Cholesterol');
  _lookupAndPrint(registry, 'Glucose Fasting');
  _lookupAndPrint(registry, 'Unknown Test');

  // Abbreviation Expansion
  print('\n--- Abbreviation Expansion ---');
  _expandAndPrint(registry, 'HDL');
  _expandAndPrint(registry, 'LFT');
  _expandAndPrint(registry, 'HbA1c');
  _expandAndPrint(registry, 'BUN');
  _expandAndPrint(registry, 'CBC');

  // Unit Validation
  print('\n--- Unit Validation ---');
  _validateUnit(registry, 'mg/dL');
  _validateUnit(registry, 'g/dL');
  _validateUnit(registry, 'mmol/L');
  _validateUnit(registry, 'kg/m2');
}

void _lookupAndPrint(MedicalDictionaryRegistry registry, String query) {
  final result = registry.findTest(query);
  if (result != null) {
    print('✅ Found "$query":');
    print('   Canonical: ${result.canonicalName}');
    print('   Category:  ${result.category}');
    print('   Units:     ${result.commonUnits.join(", ")}');
  } else {
    print('❌ Not found: "$query"');
  }
}

void _expandAndPrint(MedicalDictionaryRegistry registry, String abbr) {
  final expanded = registry.expandAbbreviation(abbr);
  if (expanded != abbr) {
    print('✅ $abbr -> $expanded');
  } else {
    print('ℹ️ $abbr (No expansion found)');
  }
}

void _validateUnit(MedicalDictionaryRegistry registry, String unit) {
  final isValid = registry.isValidUnit(unit);
  print('${isValid ? "✅" : "❌"} "$unit" is ${isValid ? "valid" : "unknown"}');
}
