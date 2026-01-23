import 'dart:io';
import '../lib/services/ocr_service.dart';
import '../lib/services/medical_field_extractor.dart';

/// Example demonstrating integration of MedicalFieldExtractor with OCR pipeline
void main() async {
  print('=== Medical Field Extractor Integration Example ===\n');
  
  // Simulated OCR text output (in real usage, this comes from OCRService)
  final ocrText = '''
    MEDICAL LABORATORY REPORT
    Patient ID: 12345
    Report Date: 23/01/2024
    Collection Date: January 20, 2024
    
    COMPLETE BLOOD COUNT (CBC)
    ================================
    Hemoglobin (Hb): 13.8 g/dL
    White Blood Cells (WBC): 8200 cells/µL
    Red Blood Cells (RBC): 4.5 x10^6/µL
    Platelets: 245000 cells/µL
    Hematocrit: 42.5 %
    
    LIPID PROFILE
    ================================
    Total Cholesterol: 195 mg/dL
    LDL Cholesterol: 125 mg/dL
    HDL Cholesterol: 48 mg/dL
    Triglycerides: 135 mg/dL
    VLDL: 27 mg/dL
    
    LIVER FUNCTION TEST
    ================================
    SGOT (AST): 28 U/L
    SGPT (ALT): 32 U/L
    Bilirubin Total: 0.8 mg/dL
    Albumin: 4.2 g/dL
    
    THYROID PROFILE
    ================================
    TSH: 2.4 µIU/mL
    Free T4: 1.2 ng/dL
    
    CURRENT MEDICATIONS
    ================================
    1. Atorvastatin 20mg once daily
    2. Metformin 500mg twice daily (bid)
    3. Lisinopril 10mg once daily (od)
    4. Aspirin 81mg daily as needed (prn)
    
    Next Follow-up: 2024-03-15
  ''';

  // Example 1: Extract all fields at once
  print('1. COMPREHENSIVE EXTRACTION');
  print('=' * 50);
  final allData = MedicalFieldExtractor.extractAll(ocrText);
  final summary = allData['summary'] as Map<String, dynamic>;
  
  print('Summary Statistics:');
  print('  • Lab Values Found: ${summary['totalLabValues']}');
  print('  • Medications Found: ${summary['totalMedications']}');
  print('  • Dates Found: ${summary['totalDates']}');
  print('  • Contains Medical Data: ${summary['hasData']}');
  
  // Example 2: Detailed lab value analysis
  print('\n2. LAB VALUES BY CATEGORY');
  print('=' * 50);
  final labData = allData['labValues'] as Map<String, dynamic>;
  final categories = labData['categories'] as Map<String, dynamic>;
  
  for (var category in categories.keys) {
    final values = categories[category] as List;
    if (values.isNotEmpty) {
      print('\n$category Tests (${values.length}):');
      for (var value in values) {
        final v = value as Map<String, String>;
        print('  • ${v['field']}: ${v['value']} ${v['unit']}');
      }
    }
  }
  
  // Example 3: Medication schedule
  print('\n3. MEDICATION SCHEDULE');
  print('=' * 50);
  final medData = allData['medications'] as Map<String, dynamic>;
  final medications = medData['medications'] as List;
  
  for (var i = 0; i < medications.length; i++) {
    final med = medications[i] as Map<String, String>;
    final frequency = med['frequency']!.isNotEmpty ? ' - ${med['frequency']}' : '';
    print('${i + 1}. ${med['name']} ${med['dosage']}$frequency');
  }
  
  // Example 4: Date timeline
  print('\n4. DATE TIMELINE');
  print('=' * 50);
  final dateData = allData['dates'] as Map<String, dynamic>;
  final dates = dateData['dates'] as List;
  
  for (var date in dates) {
    final d = date as Map<String, String>;
    print('  • ${d['value']} (${d['format']})');
  }
  
  // Example 5: Clinical decision support use case
  print('\n5. CLINICAL INSIGHTS');
  print('=' * 50);
  
  // Check cholesterol levels
  final lipidValues = categories['lipid'] as List?;
  if (lipidValues != null) {
    for (var value in lipidValues) {
      final v = value as Map<String, String>;
      if (v['field']!.toLowerCase().contains('ldl')) {
        final ldlValue = double.tryParse(v['value']!) ?? 0;
        if (ldlValue > 100) {
          print('⚠️  LDL Cholesterol elevated: ${v['value']} ${v['unit']}');
          print('   Recommendation: Continue statin therapy');
        }
      }
    }
  }
  
  // Check if on diabetes medication
  final hasDiabetesMed = medications.any(
    (m) => (m as Map)['name'].toString().toLowerCase().contains('metformin')
  );
  if (hasDiabetesMed) {
    print('✓  Patient on diabetes management (Metformin detected)');
  }
  
  // Example 6: Export to structured format
  print('\n6. STRUCTURED DATA EXPORT');
  print('=' * 50);
  
  final structuredExport = {
    'documentType': 'lab_report',
    'extractedAt': DateTime.now().toIso8601String(),
    'labResults': labData['values'],
    'medications': medData['medications'],
    'dates': dateData['dates'],
    'metadata': {
      'totalFields': summary['totalLabValues'] as int + 
                     summary['totalMedications'] as int + 
                     summary['totalDates'] as int,
      'categories': categories.keys.toList(),
      'dosageUnits': medData['dosageUnits'],
      'dateFormats': dateData['formats'],
    }
  };
  
  print('Export ready for storage:');
  print('  • Document Type: ${structuredExport['documentType']}');
  print('  • Total Fields: ${structuredExport['metadata']!['totalFields']}');
  print('  • Categories: ${(structuredExport['metadata']!['categories'] as List).join(', ')}');
  
  print('\n=== End of Integration Example ===');
}
