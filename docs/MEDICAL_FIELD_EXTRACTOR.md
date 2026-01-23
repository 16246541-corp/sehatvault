# MedicalFieldExtractor Service

A dedicated service for extracting structured medical data from text documents (OCR output, lab reports, prescriptions, etc.).

## Overview

The `MedicalFieldExtractor` provides granular extraction methods that return structured maps with detailed metadata. Each method is designed to extract specific medical fields and return comprehensive information about what was found.

## API Reference

### `extractLabValues(String text)`

Extracts laboratory test results from medical text.

**Returns:**
```dart
{
  'values': List<Map<String, String>>,  // List of lab results
  'count': int,                          // Total number of values found
  'categories': Map<String, List>        // Values grouped by category
}
```

**Each value contains:**
- `field`: Name of the lab test (e.g., "Hemoglobin", "Glucose")
- `value`: Numeric value
- `unit`: Unit of measurement (e.g., "g/dL", "mg/dL")
- `rawText`: Original matched text

**Categories:**
- `blood`: Hemoglobin, WBC, RBC, Platelets, Hematocrit, etc.
- `metabolic`: Glucose, HbA1c, Creatinine, Urea, Sodium, Potassium, etc.
- `lipid`: Cholesterol, LDL, HDL, Triglycerides, VLDL
- `liver`: Bilirubin, SGOT, SGPT, ALT, AST, ALP, Albumin, etc.
- `thyroid`: TSH, T3, T4, FT3, FT4
- `vitamin`: Vitamin D, B12, Folate, Iron, Ferritin
- `other`: Uncategorized values

**Example:**
```dart
final result = MedicalFieldExtractor.extractLabValues(text);
print('Found ${result['count']} lab values');

// Access blood test results
final bloodTests = result['categories']['blood'] as List;
for (var test in bloodTests) {
  print('${test['field']}: ${test['value']} ${test['unit']}');
}
```

---

### `extractMedications(String text)`

Extracts medication names, dosages, and frequencies from medical text.

**Returns:**
```dart
{
  'medications': List<Map<String, String>>,  // List of medications
  'count': int,                               // Total number found
  'dosageUnits': List<String>                 // Unique dosage units
}
```

**Each medication contains:**
- `name`: Medication name
- `dosage`: Dosage amount and unit (e.g., "500 mg")
- `frequency`: Frequency if detected (e.g., "twice daily", "bid", "prn")
- `rawText`: Original matched text

**Supported frequency patterns:**
- Common terms: once, twice, thrice, daily, weekly, monthly
- Medical abbreviations: bid, tid, qid, od, bd, td, qd, prn
- Numeric patterns: 1x, 2x, 3x, every N hours

**Example:**
```dart
final result = MedicalFieldExtractor.extractMedications(text);
print('Found ${result['count']} medications');

for (var med in result['medications']) {
  print('${med['name']} ${med['dosage']} - ${med['frequency']}');
}
```

---

### `extractDates(String text)`

Extracts dates in multiple formats with automatic format detection.

**Returns:**
```dart
{
  'dates': List<Map<String, String>>,  // List of dates
  'count': int,                         // Total number found
  'formats': List<String>               // Detected format types
}
```

**Each date contains:**
- `value`: The date string
- `format`: Detected format type
- `rawText`: Original matched text

**Supported formats:**
- `numeric_slash`: DD/MM/YYYY, MM/DD/YYYY, DD-MM-YYYY
- `iso_date`: YYYY-MM-DD
- `day_month_year`: 12 Jan 2024, 15 Feb 2023
- `month_day_year`: Jan 12, 2024, February 15, 2023
- `day_fullmonth_year`: 12 January 2024

**Example:**
```dart
final result = MedicalFieldExtractor.extractDates(text);
print('Found ${result['count']} dates');

for (var date in result['dates']) {
  print('${date['value']} (${date['format']})');
}
```

---

### `extractAll(String text)`

Comprehensive extraction combining all methods with summary statistics.

**Returns:**
```dart
{
  'labValues': Map,      // Result from extractLabValues()
  'medications': Map,    // Result from extractMedications()
  'dates': Map,          // Result from extractDates()
  'summary': {
    'totalLabValues': int,
    'totalMedications': int,
    'totalDates': int,
    'hasData': bool
  }
}
```

**Example:**
```dart
final result = MedicalFieldExtractor.extractAll(text);
final summary = result['summary'];

print('Lab Values: ${summary['totalLabValues']}');
print('Medications: ${summary['totalMedications']}');
print('Dates: ${summary['totalDates']}');
print('Has Data: ${summary['hasData']}');
```

## Usage Examples

### Basic Extraction

```dart
import 'package:sehatlocker/services/medical_field_extractor.dart';

final text = '''
  Lab Report - 15 Jan 2024
  Hemoglobin: 14.5 g/dL
  Glucose: 95 mg/dL
  Medications: Metformin 500mg twice daily
''';

// Extract lab values
final labs = MedicalFieldExtractor.extractLabValues(text);
print('Found ${labs['count']} lab values');

// Extract medications
final meds = MedicalFieldExtractor.extractMedications(text);
print('Found ${meds['count']} medications');

// Extract dates
final dates = MedicalFieldExtractor.extractDates(text);
print('Found ${dates['count']} dates');
```

### Integration with OCR Pipeline

```dart
import 'package:sehatlocker/services/ocr_service.dart';
import 'package:sehatlocker/services/medical_field_extractor.dart';

// Process document
final extraction = await OCRService().processDocument(imageFile);
final ocrText = extraction.extractedText;

// Extract structured medical data
final medicalData = MedicalFieldExtractor.extractAll(ocrText);

// Store in DocumentExtraction.structuredData
extraction.structuredData = medicalData;
```

### Clinical Decision Support

```dart
final result = MedicalFieldExtractor.extractAll(text);

// Check for elevated cholesterol
final lipidValues = result['labValues']['categories']['lipid'];
for (var value in lipidValues) {
  if (value['field'].contains('LDL')) {
    final ldl = double.parse(value['value']);
    if (ldl > 100) {
      print('⚠️ Elevated LDL: $ldl ${value['unit']}');
    }
  }
}

// Check medication compliance
final meds = result['medications']['medications'];
final onStatin = meds.any((m) => 
  m['name'].toLowerCase().contains('atorvastatin')
);
print(onStatin ? '✓ On statin therapy' : '⚠️ Consider statin');
```

## Pattern Matching Details

### Lab Values
- Matches: `FieldName: Value Unit` or `FieldName Value Unit`
- Field name: 3-30 characters
- Value: Numeric with optional decimal
- Units: Extended medical units (g/dL, mg/dL, µg/dL, cells/µL, etc.)

### Medications
- Matches: `DrugName Dosage Unit`
- Drug name: 4-30 characters
- Dosage: Numeric with optional decimal
- Units: mg, mcg, µg, g, ml, tab, caps, units, IU, drops
- Excludes common false positives (time, date, test, etc.)

### Dates
- Multiple format support with automatic detection
- Deduplication of identical dates
- Format metadata for each match

## Best Practices

1. **Preprocess text**: Normalize whitespace before extraction
2. **Validate results**: Check counts and categories for data quality
3. **Use categories**: Group related lab values for analysis
4. **Handle empty results**: All methods return empty structures for invalid input
5. **Combine with OCR**: Use after OCR text cleaning for best results

## See Also

- `DataExtractionService`: Legacy extraction service with private methods
- `OCRService`: Text extraction from images
- `DocumentExtraction`: Model for storing extraction results
