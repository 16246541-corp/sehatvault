import 'dart:io';
import 'package:sehatlocker/services/ocr_service.dart';
import 'package:sehatlocker/services/data_extraction_service.dart';
import 'package:sehatlocker/models/document_extraction.dart';

/// Example usage of the document extraction pipeline.
/// 
/// This demonstrates how to:
/// 1. Process a medical document image
/// 2. Extract structured data from OCR text
/// 3. Store the results in a DocumentExtraction object
void main() async {
  // Example 1: Full pipeline with processDocument
  print('=== Example 1: Full Pipeline ===');
  final imageFile = File('/path/to/medical/document.jpg');
  
  try {
    // This single call does everything:
    // - OCR with preprocessing
    // - Text extraction
    // - Structured data extraction
    final DocumentExtraction result = await OCRService.processDocument(imageFile);
    
    print('Extracted Text: ${result.extractedText}');
    print('Confidence Score: ${result.confidenceScore}');
    print('Structured Data:');
    print('  Dates: ${result.structuredData['dates']}');
    print('  Lab Values: ${result.structuredData['lab_values']}');
    print('  Medications: ${result.structuredData['medications']}');
    print('  Vitals: ${result.structuredData['vitals']}');
    
    // Save to Hive (assuming LocalStorageService is initialized)
    // await result.save();
    
  } catch (e) {
    print('Error processing document: $e');
  }
  
  // Example 2: Step-by-step extraction (for custom workflows)
  print('\n=== Example 2: Step-by-Step ===');
  
  try {
    // Step 1: Extract text only
    final String extractedText = await OCRService.extractTextFromImage(imageFile);
    print('Raw OCR Text: $extractedText');
    
    // Step 2: Extract structured data from the text
    final Map<String, dynamic> structuredData = 
        DataExtractionService.extractStructuredData(extractedText);
    
    print('Structured Data: $structuredData');
    
  } catch (e) {
    print('Error in step-by-step extraction: $e');
  }
  
  // Example 3: Testing with sample medical text
  print('\n=== Example 3: Sample Medical Text ===');
  
  const sampleText = '''
    LABORATORY REPORT
    Patient: John Doe
    Date: 23/01/2026
    
    Complete Blood Count:
    Hemoglobin: 14.5 g/dL
    WBC: 7200 cells/mcL
    Platelets: 250000 /mcL
    
    Metabolic Panel:
    Glucose: 95 mg/dL
    Creatinine: 1.1 mg/dL
    Sodium: 140 mEq/L
    Potassium: 4.2 mEq/L
    
    Vitals:
    BP: 120/80
    Heart Rate: 72 bpm
    Temperature: 98.6 F
    
    Medications:
    Metformin 500mg - twice daily
    Lisinopril 10mg - once daily
  ''';
  
  final extractedData = DataExtractionService.extractStructuredData(sampleText);
  
  print('Dates found: ${extractedData['dates']}');
  print('\nLab Values:');
  for (var lab in extractedData['lab_values']) {
    print('  ${lab['field']}: ${lab['value']} ${lab['unit']}');
  }
  
  print('\nMedications:');
  for (var med in extractedData['medications']) {
    print('  ${med['name']}: ${med['dosage']}');
  }
  
  print('\nVitals:');
  for (var vital in extractedData['vitals']) {
    print('  ${vital['name']}: ${vital['value']} ${vital['unit'] ?? ''}');
  }
}
