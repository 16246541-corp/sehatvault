# Reference Range Service API Documentation

## Overview

The `ReferenceRangeService` provides comprehensive lab test reference range lookup and evaluation capabilities. It contains embedded reference ranges for 50+ common medical lab tests across 6 categories, with support for gender-specific ranges.

## Features

- ✅ **50+ Lab Tests**: Comprehensive coverage of common medical tests
- ✅ **6 Categories**: Blood, Metabolic, Lipid, Liver, Thyroid, Vitamin tests
- ✅ **Gender-Specific Ranges**: Automatic handling of male/female differences
- ✅ **Smart Matching**: Intelligent test name matching with priority system
- ✅ **Batch Processing**: Evaluate multiple lab values at once
- ✅ **Structured Results**: Detailed evaluation with status, ranges, and messages

## Quick Start

```dart
import 'package:sehatlocker/services/reference_range_service.dart';

// Evaluate a single lab value
final result = ReferenceRangeService.evaluateLabValue(
  testName: 'Cholesterol',
  value: 210.0,
  unit: 'mg/dL',
);

print(result['status']);  // 'high', 'normal', or 'low'
print(result['message']); // Human-readable interpretation
```

## API Reference

### 1. lookupReferenceRange()

Find reference ranges for a given test name.

```dart
static List<Map<String, dynamic>> lookupReferenceRange(String testName)
```

**Parameters:**
- `testName` (String): Name of the lab test (e.g., "Cholesterol", "Hemoglobin", "TSH")

**Returns:**
- List of matching reference ranges (may include multiple entries for gender-specific tests)

**Example:**
```dart
final ranges = ReferenceRangeService.lookupReferenceRange('Hemoglobin');
// Returns both male and female hemoglobin ranges

for (var range in ranges) {
  print('${range['description']}: ${range['normalRange']['min']}-${range['normalRange']['max']} ${range['unit']}');
}
// Output:
// Hemoglobin (Male): 13.5-17.5 g/dL
// Hemoglobin (Female): 12.0-15.5 g/dL
```

### 2. evaluateLabValue()

Evaluate a single lab value against its reference range.

```dart
static Map<String, dynamic> evaluateLabValue({
  required String testName,
  required double value,
  String? unit,
  String? gender,
})
```

**Parameters:**
- `testName` (String, required): Name of the lab test
- `value` (double, required): Numeric value to evaluate
- `unit` (String, optional): Unit of measurement (for display purposes)
- `gender` (String, optional): Patient gender ('male' or 'female') for gender-specific ranges

**Returns:**
- Map containing:
  - `matched` (bool): Whether a reference range was found
  - `status` (String): 'normal', 'low', 'high', or 'unknown'
  - `referenceRange` (Map): The matched reference range data
  - `message` (String): Human-readable interpretation
  - `value` (double): The input value
  - `testName` (String): The input test name
  - `normalRange` (Map): Min and max values
  - `unit` (String): Standard unit for this test

**Example:**
```dart
// Evaluate cholesterol
final result = ReferenceRangeService.evaluateLabValue(
  testName: 'Total Cholesterol',
  value: 220.0,
  unit: 'mg/dL',
);

if (result['matched']) {
  print('Status: ${result['status']}');
  print('Message: ${result['message']}');
  print('Normal Range: ${result['normalRange']['min']}-${result['normalRange']['max']} ${result['unit']}');
}

// Evaluate gender-specific test
final hbResult = ReferenceRangeService.evaluateLabValue(
  testName: 'Hemoglobin',
  value: 13.0,
  gender: 'female',
);
// Uses female reference range (12.0-15.5 g/dL)
```

### 3. evaluateMultipleLabValues()

Evaluate multiple lab values at once with summary statistics.

```dart
static Map<String, dynamic> evaluateMultipleLabValues({
  required List<Map<String, dynamic>> labValues,
  String? gender,
})
```

**Parameters:**
- `labValues` (List, required): List of maps, each containing:
  - `field` (String): Test name
  - `value` (String): Numeric value as string
  - `unit` (String, optional): Unit of measurement
- `gender` (String, optional): Patient gender for gender-specific ranges

**Returns:**
- Map containing:
  - `results` (List): Individual evaluation results for each lab value
  - `summary` (Map): Overall statistics:
    - `total` (int): Total number of tests
    - `normal` (int): Count of normal values
    - `low` (int): Count of low values
    - `high` (int): Count of high values
    - `unknown` (int): Count of unmatched values
    - `hasAbnormal` (bool): Whether any abnormal values were found

**Example:**
```dart
final labValues = [
  {'field': 'Cholesterol', 'value': '210', 'unit': 'mg/dL'},
  {'field': 'Glucose', 'value': '95', 'unit': 'mg/dL'},
  {'field': 'Hemoglobin', 'value': '14.2', 'unit': 'g/dL'},
];

final evaluation = ReferenceRangeService.evaluateMultipleLabValues(
  labValues: labValues,
  gender: 'male',
);

print('Total: ${evaluation['summary']['total']}');
print('Normal: ${evaluation['summary']['normal']}');
print('Abnormal: ${evaluation['summary']['hasAbnormal']}');

// Process individual results
for (var result in evaluation['results']) {
  if (result['status'] != 'normal') {
    print('⚠️ ${result['message']}');
  }
}
```

### 4. getReferenceRangesByCategory()

Get all reference ranges for a specific category.

```dart
static List<Map<String, dynamic>> getReferenceRangesByCategory(String category)
```

**Parameters:**
- `category` (String): Category name ('blood', 'metabolic', 'lipid', 'liver', 'thyroid', 'vitamin')

**Returns:**
- List of reference ranges in that category

**Example:**
```dart
final lipidTests = ReferenceRangeService.getReferenceRangesByCategory('lipid');

print('Lipid Panel Tests:');
for (var test in lipidTests) {
  print('- ${test['description']}: ${test['normalRange']['min']}-${test['normalRange']['max']} ${test['unit']}');
}
```

### 5. getAllTestNames()

Get a list of all available test names.

```dart
static List<String> getAllTestNames()
```

**Returns:**
- Sorted list of all test names (including aliases)

**Example:**
```dart
final allTests = ReferenceRangeService.getAllTestNames();
print('Available tests: ${allTests.length}');
print(allTests.take(10).join(', '));
```

### 6. getAllCategories()

Get a list of all available categories.

```dart
static List<String> getAllCategories()
```

**Returns:**
- Sorted list of category names

**Example:**
```dart
final categories = ReferenceRangeService.getAllCategories();
print('Categories: ${categories.join(', ')}');
// Output: blood, lipid, liver, metabolic, thyroid, vitamin
```

## Supported Lab Tests

### Blood Count Tests (8 tests)
- Hemoglobin (Hb, HGB) - gender-specific
- White Blood Cell Count (WBC, Leukocyte)
- Red Blood Cell Count (RBC, Erythrocyte) - gender-specific
- Platelet Count (PLT)
- Hematocrit (HCT, PCV) - gender-specific
- Mean Corpuscular Volume (MCV)
- Mean Corpuscular Hemoglobin (MCH)
- Mean Corpuscular Hemoglobin Concentration (MCHC)

### Metabolic Panel (10 tests)
- Fasting Glucose (Blood Sugar)
- HbA1c (A1C, Glycated Hemoglobin)
- Creatinine - gender-specific
- Blood Urea Nitrogen (BUN)
- Urea
- Sodium (Na)
- Potassium (K)
- Chloride (Cl)
- Calcium (Ca)

### Lipid Panel (6 tests)
- Total Cholesterol
- LDL Cholesterol (Low Density Lipoprotein)
- HDL Cholesterol (High Density Lipoprotein) - gender-specific
- Triglycerides
- VLDL Cholesterol

### Liver Function Tests (8 tests)
- Total Bilirubin
- Direct Bilirubin (Conjugated Bilirubin)
- AST (SGOT, Aspartate Aminotransferase)
- ALT (SGPT, Alanine Aminotransferase)
- Alkaline Phosphatase (ALP)
- Albumin
- Total Protein
- GGT (Gamma-Glutamyl Transferase)

### Thyroid Function Tests (5 tests)
- TSH (Thyroid Stimulating Hormone)
- T3 (Triiodothyronine)
- T4 (Thyroxine)
- Free T3 (FT3)
- Free T4 (FT4)

### Vitamins & Minerals (6 tests)
- Vitamin D (25-OH Vitamin D)
- Vitamin B12 (Cobalamin)
- Folate (Folic Acid, Vitamin B9)
- Iron - gender-specific
- Ferritin - gender-specific

## Test Name Matching

The service uses an intelligent matching algorithm with three priority levels:

1. **Exact Match** (Highest Priority): Test name exactly matches one of the aliases
   - Example: "hemoglobin" matches "hemoglobin"

2. **Word Boundary Match**: All words in the search term match complete words in the test name
   - Example: "free t3" matches "free triiodothyronine"

3. **Partial Match** (Lowest Priority): Substring matching, sorted by specificity
   - Example: "cholesterol" matches "total cholesterol", "ldl cholesterol", etc.

This prevents false matches like "hemoglobin" matching "mean corpuscular hemoglobin" (MCH).

## Gender-Specific Ranges

The following tests have different reference ranges for males and females:

- **Hemoglobin**: Male 13.5-17.5 g/dL, Female 12.0-15.5 g/dL
- **RBC**: Male 4.5-5.9 x10^6/µL, Female 4.1-5.1 x10^6/µL
- **Hematocrit**: Male 38.8-50.0%, Female 34.9-44.5%
- **HDL Cholesterol**: Male ≥40 mg/dL, Female ≥50 mg/dL
- **Creatinine**: Male 0.7-1.3 mg/dL, Female 0.6-1.1 mg/dL
- **Iron**: Male 60-170 µg/dL, Female 50-150 µg/dL
- **Ferritin**: Male 24-336 ng/mL, Female 11-307 ng/mL

Always specify the `gender` parameter when evaluating these tests for accurate results.

## Integration with MedicalFieldExtractor

The ReferenceRangeService works seamlessly with the MedicalFieldExtractor:

```dart
import 'package:sehatlocker/services/medical_field_extractor.dart';
import 'package:sehatlocker/services/reference_range_service.dart';

// Extract lab values from OCR text
final extractedData = MedicalFieldExtractor.extractLabValues(ocrText);
final labValues = extractedData['values'] as List<Map<String, String>>;

// Evaluate all extracted values
final evaluation = ReferenceRangeService.evaluateMultipleLabValues(
  labValues: labValues,
  gender: 'female',
);

// Process results
final summary = evaluation['summary'];
print('Found ${summary['high']} high values and ${summary['low']} low values');
```

See `examples/integrated_extraction_example.dart` for a complete workflow example.

## Important Notes

1. **Medical Disclaimer**: This service provides reference ranges for informational purposes only. Always consult with qualified healthcare professionals for medical advice, diagnosis, and treatment.

2. **Reference Range Variations**: Normal ranges may vary between laboratories and populations. The ranges provided are general guidelines based on common clinical standards.

3. **Age Considerations**: Current ranges are for adults. Pediatric and geriatric ranges may differ.

4. **Clinical Context**: Lab values should always be interpreted in the context of the patient's overall clinical picture, symptoms, and medical history.

5. **Units**: Ensure values are in the correct units. The service expects standard units (e.g., mg/dL, g/dL, mEq/L).

## Examples

See the following example files for detailed usage:
- `examples/reference_range_example.dart` - Comprehensive service demonstration
- `examples/integrated_extraction_example.dart` - Integration with MedicalFieldExtractor

## Version

Current version: 1.0.0 (2026-01-23)
