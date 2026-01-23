import '../lib/services/medical_field_extractor.dart';

void main() {
  // Sample medical text from a lab report
  final sampleText = '''
    Patient Lab Report
    Date: 15 Jan 2024
    Test Date: January 12, 2024
    
    Complete Blood Count:
    Hemoglobin: 14.5 g/dL
    WBC: 7500 cells/µL
    RBC: 4.8 x10^6/µL
    Platelets: 250000 cells/µL
    
    Metabolic Panel:
    Glucose: 95 mg/dL
    Creatinine: 1.1 mg/dL
    Sodium: 140 mEq/L
    Potassium: 4.2 mEq/L
    
    Lipid Profile:
    Total Cholesterol: 180 mg/dL
    LDL: 110 mg/dL
    HDL: 55 mg/dL
    Triglycerides: 120 mg/dL
    
    Medications Prescribed:
    Metformin 500mg twice daily
    Lisinopril 10mg once daily
    Atorvastatin 20mg at bedtime
    Aspirin 81mg daily
    
    Next Visit: 2024-02-15
  ''';

  print('=== Medical Field Extractor Examples ===\n');

  // Example 1: Extract Lab Values
  print('1. Extracting Lab Values:');
  final labValues = MedicalFieldExtractor.extractLabValues(sampleText);
  print('   Found ${labValues['count']} lab values');
  print('   Categories: ${(labValues['categories'] as Map).keys.join(', ')}');
  
  // Show blood category values
  final bloodValues = (labValues['categories'] as Map)['blood'] as List?;
  if (bloodValues != null && bloodValues.isNotEmpty) {
    print('\n   Blood Tests:');
    for (var value in bloodValues) {
      final v = value as Map<String, String>;
      print('   - ${v['field']}: ${v['value']} ${v['unit']}');
    }
  }
  
  // Show metabolic values
  final metabolicValues = (labValues['categories'] as Map)['metabolic'] as List?;
  if (metabolicValues != null && metabolicValues.isNotEmpty) {
    print('\n   Metabolic Tests:');
    for (var value in metabolicValues) {
      final v = value as Map<String, String>;
      print('   - ${v['field']}: ${v['value']} ${v['unit']}');
    }
  }

  // Example 2: Extract Medications
  print('\n2. Extracting Medications:');
  final medications = MedicalFieldExtractor.extractMedications(sampleText);
  print('   Found ${medications['count']} medications');
  print('   Dosage units used: ${(medications['dosageUnits'] as List).join(', ')}');
  
  print('\n   Medications List:');
  for (var med in medications['medications'] as List) {
    final m = med as Map<String, String>;
    final freq = m['frequency']!.isNotEmpty ? ' - ${m['frequency']}' : '';
    print('   - ${m['name']} ${m['dosage']}$freq');
  }

  // Example 3: Extract Dates
  print('\n3. Extracting Dates:');
  final dates = MedicalFieldExtractor.extractDates(sampleText);
  print('   Found ${dates['count']} dates');
  print('   Formats detected: ${(dates['formats'] as List).join(', ')}');
  
  print('\n   Dates Found:');
  for (var date in dates['dates'] as List) {
    final d = date as Map<String, String>;
    print('   - ${d['value']} (format: ${d['format']})');
  }

  // Example 4: Extract All Fields at Once
  print('\n4. Extracting All Fields:');
  final allData = MedicalFieldExtractor.extractAll(sampleText);
  final summary = allData['summary'] as Map<String, dynamic>;
  
  print('   Summary:');
  print('   - Lab Values: ${summary['totalLabValues']}');
  print('   - Medications: ${summary['totalMedications']}');
  print('   - Dates: ${summary['totalDates']}');
  print('   - Has Data: ${summary['hasData']}');

  // Example 5: Working with Individual Extractions
  print('\n5. Accessing Structured Data:');
  
  // Get specific lab value
  final allLabValues = (allData['labValues'] as Map)['values'] as List;
  try {
    final glucoseValue = allLabValues.firstWhere(
      (v) => (v as Map)['field'].toString().toLowerCase().contains('glucose'),
    ) as Map<String, String>;
    print('   Glucose Level: ${glucoseValue['value']} ${glucoseValue['unit']}');
  } catch (e) {
    print('   Glucose value not found');
  }

  // Get specific medication
  final allMeds = (allData['medications'] as Map)['medications'] as List;
  try {
    final metformin = allMeds.firstWhere(
      (m) => (m as Map)['name'].toString().toLowerCase().contains('metformin'),
    ) as Map<String, String>;
    print('   Metformin Dosage: ${metformin['dosage']}');
  } catch (e) {
    print('   Metformin not found');
  }

  print('\n=== End of Examples ===');
}
