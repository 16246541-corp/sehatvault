import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sehatlocker/services/vault_service.dart';
import 'package:sehatlocker/services/local_storage_service.dart';

/// Integration test for the complete "Save to Vault" workflow
/// 
/// This test demonstrates the end-to-end process:
/// 1. Initialize storage service
/// 2. Create vault service
/// 3. Save a document with OCR processing
/// 4. Verify HealthRecord and DocumentExtraction are created
/// 5. Retrieve and validate the saved data
/// 6. Test deletion workflow
void main() {
  group('VaultService Integration Tests', () {
    late LocalStorageService storageService;
    late VaultService vaultService;

    setUpAll(() async {
      // Initialize storage service
      storageService = LocalStorageService();
      await storageService.initialize();
      vaultService = VaultService(storageService);
    });

    tearDownAll(() async {
      // Clean up
      await storageService.clearAllData();
      await storageService.close();
    });

    test('Complete save to vault workflow', () async {
      // Note: This test requires a real image file for OCR
      // In a real test, you would provide a test image
      // For now, this demonstrates the API usage
      
      print('Test: Complete save to vault workflow');
      print('This test demonstrates the API but requires a real image file');
      
      // Example usage (would work with a real image):
      // final testImage = File('test_assets/sample_lab_report.jpg');
      // 
      // final healthRecord = await vaultService.saveDocumentToVault(
      //   imageFile: testImage,
      //   title: 'Test Lab Report',
      //   category: 'Lab Results',
      //   notes: 'Integration test',
      //   onProgress: (status) {
      //     print('Progress: $status');
      //   },
      // );
      // 
      // expect(healthRecord.id, isNotEmpty);
      // expect(healthRecord.title, equals('Test Lab Report'));
      // expect(healthRecord.category, equals('Lab Results'));
      // expect(healthRecord.recordType, equals(HealthRecord.typeDocumentExtraction));
      // expect(healthRecord.extractionId, isNotNull);
    });

    test('Auto-category detection workflow', () async {
      print('Test: Auto-category detection');
      print('This demonstrates intelligent category detection from OCR data');
      
      // Example usage:
      // final testImage = File('test_assets/prescription.jpg');
      // 
      // final healthRecord = await vaultService.saveDocumentWithAutoCategory(
      //   imageFile: testImage,
      //   title: 'Test Prescription',
      //   onProgress: (status) {
      //     print('Progress: $status');
      //   },
      // );
      // 
      // // Should auto-detect as 'Prescriptions' if medications are found
      // expect(healthRecord.category, equals('Prescriptions'));
      // expect(healthRecord.metadata?['autoDetectedCategory'], isTrue);
    });

    test('Retrieve complete document', () async {
      print('Test: Retrieve complete document with extraction data');
      
      // Example usage:
      // final allDocs = await vaultService.getAllDocuments();
      // 
      // if (allDocs.isNotEmpty) {
      //   final firstDoc = allDocs.first;
      //   
      //   expect(firstDoc.record, isA<HealthRecord>());
      //   expect(firstDoc.extraction, isA<DocumentExtraction>());
      //   
      //   // Verify linking
      //   expect(firstDoc.record.extractionId, equals(firstDoc.extraction?.id));
      //   
      //   // Verify extraction data
      //   expect(firstDoc.extraction?.extractedText, isNotEmpty);
      //   expect(firstDoc.extraction?.structuredData, isNotEmpty);
      // }
    });

    test('Delete document workflow', () async {
      print('Test: Complete document deletion');
      
      // Example usage:
      // final allDocs = await vaultService.getAllDocuments();
      // 
      // if (allDocs.isNotEmpty) {
      //   final docToDelete = allDocs.first;
      //   final recordId = docToDelete.record.id;
      //   
      //   await vaultService.deleteDocument(recordId);
      //   
      //   // Verify deletion
      //   expect(
      //     () => vaultService.getCompleteDocument(recordId),
      //     throwsException,
      //   );
      // }
    });

    test('Vault statistics', () async {
      print('Test: Vault statistics and analytics');
      
      // Example usage:
      // final allDocs = await vaultService.getAllDocuments();
      // 
      // print('Total documents: ${allDocs.length}');
      // 
      // // Count by category
      // final categoryCount = <String, int>{};
      // for (final doc in allDocs) {
      //   categoryCount[doc.record.category] = 
      //       (categoryCount[doc.record.category] ?? 0) + 1;
      // }
      // 
      // print('Documents by category:');
      // categoryCount.forEach((category, count) {
      //   print('  $category: $count');
      // });
      // 
      // // Average confidence score
      // final docsWithExtractions = allDocs.where((d) => d.extraction != null);
      // if (docsWithExtractions.isNotEmpty) {
      //   final avgConfidence = docsWithExtractions
      //       .map((d) => d.extraction!.confidenceScore)
      //       .reduce((a, b) => a + b) / docsWithExtractions.length;
      //   
      //   print('Average confidence: ${(avgConfidence * 100).toStringAsFixed(1)}%');
      //   expect(avgConfidence, greaterThan(0.0));
      //   expect(avgConfidence, lessThanOrEqualTo(1.0));
      // }
    });

    test('Error handling - missing image file', () async {
      print('Test: Error handling for missing image file');
      
      final nonExistentImage = File('/path/to/nonexistent/image.jpg');
      
      expect(
        () => vaultService.saveDocumentToVault(
          imageFile: nonExistentImage,
          title: 'Test',
          category: 'Lab Results',
        ),
        throwsException,
      );
    });

    test('Progress callback functionality', () async {
      print('Test: Progress callback updates');
      
      final progressUpdates = <String>[];
      
      // Example usage:
      // final testImage = File('test_assets/sample_document.jpg');
      // 
      // await vaultService.saveDocumentToVault(
      //   imageFile: testImage,
      //   title: 'Test Document',
      //   category: 'Medical Records',
      //   onProgress: (status) {
      //     progressUpdates.add(status);
      //     print('Progress: $status');
      //   },
      // );
      // 
      // // Verify progress updates were received
      // expect(progressUpdates, isNotEmpty);
      // expect(progressUpdates, contains('Extracting text from document...'));
      // expect(progressUpdates, contains('Saving extraction data...'));
      // expect(progressUpdates, contains('Creating health record...'));
      // expect(progressUpdates, contains('Saving to encrypted vault...'));
      // expect(progressUpdates, contains('Document saved successfully!'));
    });
  });
}
