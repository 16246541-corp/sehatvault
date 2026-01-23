import 'dart:io';
import 'package:sehatlocker/models/document_extraction.dart';
import 'package:sehatlocker/models/health_record.dart';
import 'package:sehatlocker/services/pdf_export_service.dart';

/// Example usage of PdfExportService
///
/// Note: This example requires Flutter environment to run because of path_provider.
/// Use inside a Flutter app or integration test.
void main() async {
  // Mock data
  final extraction = DocumentExtraction(
    originalImagePath: '/path/to/image.jpg',
    extractedText: 'Patient: John Doe\nDate: 2026-01-23\n...',
    confidenceScore: 0.95,
    structuredData: {
      'patient_name': 'John Doe',
      'date': '2026-01-23',
      'test_results': 'Normal',
    },
  );

  final record = HealthRecord(
    id: '123',
    title: 'Lab Report',
    category: 'Lab Results',
    createdAt: DateTime.now(),
    notes: 'Annual checkup',
  );

  final service = PdfExportService();

  try {
    // Generate PDF
    final pdfPath = await service.generatePdf(
      extraction: extraction,
      record: record,
    );
    
    print('PDF generated at: $pdfPath');
    
    // In a real app, you might want to share this file or open it
    // Share.shareFiles([pdfPath], text: 'My Medical Record');
    // OpenFile.open(pdfPath);
    
  } catch (e) {
    print('Error generating PDF: $e');
  }
}
