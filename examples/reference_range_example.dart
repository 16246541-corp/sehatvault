import 'package:sehatlocker/services/reference_range_service.dart';

/// Example demonstrating the ReferenceRangeService functionality.
///
/// This example shows:
/// 1. Looking up reference ranges for specific tests
/// 2. Evaluating single lab values
/// 3. Evaluating multiple lab values at once
/// 4. Handling gender-specific ranges
void main() {
  print('=== Reference Range Service Examples ===\n');

  // Example 1: Simple lookup
  example1_SimpleLookup();

  // Example 2: Single value evaluation
  example2_SingleValueEvaluation();

  // Example 3: Multiple values evaluation
  example3_MultipleValuesEvaluation();

  // Example 4: Gender-specific ranges
  example4_GenderSpecificRanges();

  // Example 5: Category-based lookup
  example5_CategoryLookup();

  // Example 6: Real-world scenario - Processing OCR extracted data
  example6_RealWorldScenario();
}

void example1_SimpleLookup() {
  print('--- Example 1: Simple Reference Range Lookup ---');

  final ranges = ReferenceRangeService.lookupReferenceRange('Cholesterol');

  print('Found ${ranges.length} reference range(s) for "Cholesterol":');
  for (var range in ranges) {
    print(
        '  - ${range['description']}: ${range['normalRange']['min']}-${range['normalRange']['max']} ${range['unit']}');
  }
  print('');
}

void example2_SingleValueEvaluation() {
  print('--- Example 2: Single Lab Value Evaluation ---');

  // Normal cholesterol
  var result = ReferenceRangeService.evaluateLabValue(
    testName: 'Cholesterol',
    value: 180.0,
    unit: 'mg/dL',
  );
  print('Test: ${result['testName']}');
  print('Status: ${result['status']}');
  print('Message: ${result['message']}\n');

  // High cholesterol
  result = ReferenceRangeService.evaluateLabValue(
    testName: 'Cholesterol',
    value: 250.0,
    unit: 'mg/dL',
  );
  print('Test: ${result['testName']}');
  print('Status: ${result['status']}');
  print('Message: ${result['message']}\n');

  // Low hemoglobin
  result = ReferenceRangeService.evaluateLabValue(
    testName: 'Hemoglobin',
    value: 10.5,
    unit: 'g/dL',
  );
  print('Test: ${result['testName']}');
  print('Status: ${result['status']}');
  print('Message: ${result['message']}\n');
}

void example3_MultipleValuesEvaluation() {
  print('--- Example 3: Multiple Lab Values Evaluation ---');

  final labValues = [
    {'field': 'Cholesterol', 'value': '210', 'unit': 'mg/dL'},
    {'field': 'Glucose', 'value': '95', 'unit': 'mg/dL'},
    {'field': 'Hemoglobin', 'value': '14.2', 'unit': 'g/dL'},
    {'field': 'TSH', 'value': '2.5', 'unit': 'µIU/mL'},
    {'field': 'Vitamin D', 'value': '25', 'unit': 'ng/mL'},
  ];

  final evaluation = ReferenceRangeService.evaluateMultipleLabValues(
    labValues: labValues,
  );

  print('Evaluated ${evaluation['summary']['total']} lab values:');
  print('  Normal: ${evaluation['summary']['normal']}');
  print('  High: ${evaluation['summary']['high']}');
  print('  Low: ${evaluation['summary']['low']}');
  print('  Unknown: ${evaluation['summary']['unknown']}');
  print('  Has Abnormal: ${evaluation['summary']['hasAbnormal']}\n');

  print('Detailed Results:');
  for (var result in evaluation['results']) {
    final status = result['status'];
    final icon = status == 'normal'
        ? '✓'
        : status == 'high'
            ? '↑'
            : status == 'low'
                ? '↓'
                : '?';
    print('  $icon ${result['message']}');
  }
  print('');
}

void example4_GenderSpecificRanges() {
  print('--- Example 4: Gender-Specific Reference Ranges ---');

  const hemoglobinValue = 13.0;

  // Evaluate for male
  var result = ReferenceRangeService.evaluateLabValue(
    testName: 'Hemoglobin',
    value: hemoglobinValue,
    gender: 'male',
  );
  print('Hemoglobin $hemoglobinValue g/dL for MALE:');
  print('  Status: ${result['status']}');
  print(
      '  Range: ${result['normalRange']['min']}-${result['normalRange']['max']} ${result['unit']}\n');

  // Evaluate for female
  result = ReferenceRangeService.evaluateLabValue(
    testName: 'Hemoglobin',
    value: hemoglobinValue,
    gender: 'female',
  );
  print('Hemoglobin $hemoglobinValue g/dL for FEMALE:');
  print('  Status: ${result['status']}');
  print(
      '  Range: ${result['normalRange']['min']}-${result['normalRange']['max']} ${result['unit']}\n');
}

void example5_CategoryLookup() {
  print('--- Example 5: Category-Based Lookup ---');

  final categories = ReferenceRangeService.getAllCategories();
  print('Available categories: ${categories.join(', ')}\n');

  final lipidTests =
      ReferenceRangeService.getReferenceRangesByCategory('lipid');
  print('Lipid Panel Tests (${lipidTests.length} tests):');
  for (var test in lipidTests) {
    print(
        '  - ${test['description']}: ${test['normalRange']['min']}-${test['normalRange']['max']} ${test['unit']}');
  }
  print('');
}

void example6_RealWorldScenario() {
  print('--- Example 6: Real-World Scenario - Processing OCR Data ---');
  print('Simulating lab report extraction and evaluation...\n');

  // Simulated OCR extracted text
  const ocrText = '''
    COMPREHENSIVE METABOLIC PANEL
    
    Patient: John Doe
    Date: 2026-01-23
    
    Test Results:
    Glucose: 105 mg/dL
    Cholesterol: 220 mg/dL
    HDL: 45 mg/dL
    LDL: 140 mg/dL
    Triglycerides: 175 mg/dL
    Hemoglobin: 14.5 g/dL
    TSH: 3.2 µIU/mL
    Vitamin D: 28 ng/mL
    Creatinine: 1.1 mg/dL
  ''';

  // In a real scenario, you would use MedicalFieldExtractor to parse this
  // For this example, we'll manually create the extracted values
  final extractedValues = [
    {'field': 'Glucose', 'value': '105', 'unit': 'mg/dL'},
    {'field': 'Cholesterol', 'value': '220', 'unit': 'mg/dL'},
    {'field': 'HDL', 'value': '45', 'unit': 'mg/dL'},
    {'field': 'LDL', 'value': '140', 'unit': 'mg/dL'},
    {'field': 'Triglycerides', 'value': '175', 'unit': 'mg/dL'},
    {'field': 'Hemoglobin', 'value': '14.5', 'unit': 'g/dL'},
    {'field': 'TSH', 'value': '3.2', 'unit': 'µIU/mL'},
    {'field': 'Vitamin D', 'value': '28', 'unit': 'ng/mL'},
    {'field': 'Creatinine', 'value': '1.1', 'unit': 'mg/dL'},
  ];

  // Evaluate all values (assuming male patient)
  final evaluation = ReferenceRangeService.evaluateMultipleLabValues(
    labValues: extractedValues,
    gender: 'male',
  );

  print('📊 Lab Report Summary:');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('Total Tests: ${evaluation['summary']['total']}');
  print('✓ Normal: ${evaluation['summary']['normal']}');
  print('↑ High: ${evaluation['summary']['high']}');
  print('↓ Low: ${evaluation['summary']['low']}');
  print('? Unknown: ${evaluation['summary']['unknown']}');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

  // Show abnormal values first
  final abnormalResults = (evaluation['results'] as List)
      .where((r) => r['status'] != 'normal' && r['status'] != 'unknown')
      .toList();

  if (abnormalResults.isNotEmpty) {
    print('⚠️  ABNORMAL VALUES:');
    for (var result in abnormalResults) {
      final icon = result['status'] == 'high' ? '↑' : '↓';
      print('  $icon ${result['message']}');
    }
    print('');
  }

  // Show normal values
  final normalResults = (evaluation['results'] as List)
      .where((r) => r['status'] == 'normal')
      .toList();

  if (normalResults.isNotEmpty) {
    print('✓ NORMAL VALUES:');
    for (var result in normalResults) {
      print('  ✓ ${result['testName']}: ${result['value']} ${result['unit']}');
    }
    print('');
  }

  // Provide recommendations
  if (evaluation['summary']['hasAbnormal']) {
    print('💡 RECOMMENDATIONS:');
    for (var result in abnormalResults) {
      final testName = result['testName'];
      final status = result['status'];

      if (testName.toLowerCase().contains('cholesterol') && status == 'high') {
        print(
            '  • Consider dietary changes and consult with your doctor about cholesterol management');
      } else if (testName.toLowerCase().contains('glucose') &&
          status == 'high') {
        print(
            '  • Monitor blood sugar levels and consider lifestyle modifications');
      } else if (testName.toLowerCase().contains('vitamin d') &&
          status == 'low') {
        print(
            '  • Consider vitamin D supplementation and increased sun exposure');
      } else if (testName.toLowerCase().contains('triglycerides') &&
          status == 'high') {
        print('  • Reduce sugar and refined carbohydrate intake');
      }
    }
  }
}
