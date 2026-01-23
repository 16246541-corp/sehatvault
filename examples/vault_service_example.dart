import 'dart:io';
import 'package:sehatlocker/services/vault_service.dart';
import 'package:sehatlocker/services/local_storage_service.dart';

/// Example demonstrating the VaultService for saving documents to encrypted storage
void main() async {
  print('=== VaultService Example ===\n');

  // Initialize storage service
  final storageService = LocalStorageService();
  await storageService.initialize();
  print('✓ LocalStorageService initialized\n');

  // Create VaultService instance
  final vaultService = VaultService(storageService);
  print('✓ VaultService created\n');

  // Example 1: Save a lab report with manual category
  print('--- Example 1: Save Lab Report (Manual Category) ---');
  try {
    final labReportImage = File('/path/to/lab_report.jpg');
    
    final healthRecord = await vaultService.saveDocumentToVault(
      imageFile: labReportImage,
      title: 'Blood Test Results - Jan 2026',
      category: 'Lab Results',
      notes: 'Annual health checkup',
      additionalMetadata: {
        'doctor': 'Dr. Smith',
        'hospital': 'City Medical Center',
      },
      onProgress: (status) {
        print('  Progress: $status');
      },
    );

    print('✓ Document saved successfully!');
    print('  Health Record ID: ${healthRecord.id}');
    print('  Extraction ID: ${healthRecord.extractionId}');
    print('  Category: ${healthRecord.category}');
    print('  Confidence Score: ${healthRecord.metadata?['confidenceScore']}\n');
  } catch (e) {
    print('✗ Error: $e\n');
  }

  // Example 2: Save a prescription with auto-category detection
  print('--- Example 2: Save Prescription (Auto Category) ---');
  try {
    final prescriptionImage = File('/path/to/prescription.jpg');
    
    final healthRecord = await vaultService.saveDocumentWithAutoCategory(
      imageFile: prescriptionImage,
      title: 'Prescription - Dr. Johnson',
      notes: 'Antibiotics for infection',
      onProgress: (status) {
        print('  Progress: $status');
      },
    );

    print('✓ Document saved with auto-detected category!');
    print('  Health Record ID: ${healthRecord.id}');
    print('  Auto-detected Category: ${healthRecord.category}');
    print('  Text Length: ${healthRecord.metadata?['textLength']} characters\n');
  } catch (e) {
    print('✗ Error: $e\n');
  }

  // Example 3: Retrieve a complete document
  print('--- Example 3: Retrieve Complete Document ---');
  try {
    final allDocs = await vaultService.getAllDocuments();
    
    if (allDocs.isNotEmpty) {
      final firstDoc = allDocs.first;
      print('✓ Retrieved document:');
      print('  Title: ${firstDoc.record.title}');
      print('  Category: ${firstDoc.record.category}');
      print('  Created: ${firstDoc.record.createdAt}');
      
      if (firstDoc.extraction != null) {
        print('  Extraction Data:');
        print('    - Confidence: ${firstDoc.extraction!.confidenceScore}');
        print('    - Text Length: ${firstDoc.extraction!.extractedText.length}');
        print('    - Structured Fields: ${firstDoc.extraction!.structuredData.keys.join(", ")}');
        
        // Show some extracted data
        final structuredData = firstDoc.extraction!.structuredData;
        if (structuredData.containsKey('labValues')) {
          final labValues = structuredData['labValues'] as List;
          print('    - Lab Values Found: ${labValues.length}');
          if (labValues.isNotEmpty) {
            print('      Example: ${labValues.first}');
          }
        }
        if (structuredData.containsKey('medications')) {
          final medications = structuredData['medications'] as List;
          print('    - Medications Found: ${medications.length}');
          if (medications.isNotEmpty) {
            print('      Example: ${medications.first}');
          }
        }
      }
      print('');
    } else {
      print('  No documents found in vault\n');
    }
  } catch (e) {
    print('✗ Error: $e\n');
  }

  // Example 4: Get specific document by ID
  print('--- Example 4: Get Specific Document ---');
  try {
    final allDocs = await vaultService.getAllDocuments();
    
    if (allDocs.isNotEmpty) {
      final recordId = allDocs.first.record.id;
      final completeDoc = await vaultService.getCompleteDocument(recordId);
      
      print('✓ Retrieved specific document:');
      print('  ID: ${completeDoc.record.id}');
      print('  Title: ${completeDoc.record.title}');
      print('  Has Extraction: ${completeDoc.extraction != null}');
      print('');
    }
  } catch (e) {
    print('✗ Error: $e\n');
  }

  // Example 5: Delete a document
  print('--- Example 5: Delete Document ---');
  try {
    final allDocs = await vaultService.getAllDocuments();
    
    if (allDocs.isNotEmpty) {
      final recordId = allDocs.last.record.id;
      print('  Deleting document: $recordId');
      
      await vaultService.deleteDocument(recordId);
      
      print('✓ Document deleted successfully!');
      print('  - Health record removed');
      print('  - Extraction data removed');
      print('  - Image file removed\n');
    }
  } catch (e) {
    print('✗ Error: $e\n');
  }

  // Example 6: Show vault statistics
  print('--- Example 6: Vault Statistics ---');
  try {
    final allDocs = await vaultService.getAllDocuments();
    
    print('✓ Vault Statistics:');
    print('  Total Documents: ${allDocs.length}');
    
    // Count by category
    final categoryCount = <String, int>{};
    for (final doc in allDocs) {
      categoryCount[doc.record.category] = 
          (categoryCount[doc.record.category] ?? 0) + 1;
    }
    
    print('  By Category:');
    categoryCount.forEach((category, count) {
      print('    - $category: $count');
    });
    
    // Count documents with extractions
    final docsWithExtractions = allDocs.where((d) => d.extraction != null).length;
    print('  Documents with Extractions: $docsWithExtractions');
    
    // Average confidence score
    if (docsWithExtractions > 0) {
      final avgConfidence = allDocs
          .where((d) => d.extraction != null)
          .map((d) => d.extraction!.confidenceScore)
          .reduce((a, b) => a + b) / docsWithExtractions;
      print('  Average Confidence Score: ${(avgConfidence * 100).toStringAsFixed(1)}%');
    }
    print('');
  } catch (e) {
    print('✗ Error: $e\n');
  }

  print('=== Example Complete ===');
}
