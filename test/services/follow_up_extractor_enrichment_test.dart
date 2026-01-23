import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sehatlocker/models/document_extraction.dart';
import 'package:sehatlocker/models/follow_up_item.dart';
import 'package:sehatlocker/models/health_record.dart';
import 'package:sehatlocker/services/follow_up_extractor.dart';
import 'package:sehatlocker/services/vault_service.dart';

// Manual Mock for VaultService
class MockVaultService implements VaultService {
  List<({HealthRecord record, DocumentExtraction? extraction})> _mockDocuments = [];

  void setMockDocuments(List<({HealthRecord record, DocumentExtraction? extraction})> docs) {
    _mockDocuments = docs;
  }

  @override
  Future<List<({HealthRecord record, DocumentExtraction? extraction})>> getAllDocuments() async {
    return _mockDocuments;
  }

  @override
  Future<HealthRecord> saveDocumentToVault({required File imageFile, required String title, required String category, String? notes, Map<String, dynamic>? additionalMetadata, void Function(String status)? onProgress}) {
    throw UnimplementedError();
  }

  @override
  Future<HealthRecord> saveDocumentWithAutoCategory({required File imageFile, required String title, String? notes, Map<String, dynamic>? additionalMetadata, void Function(String status)? onProgress}) {
    throw UnimplementedError();
  }

  @override
  Future<({DocumentExtraction? extraction, HealthRecord record})> getCompleteDocument(String healthRecordId) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteDocument(String healthRecordId) {
    throw UnimplementedError();
  }
}

void main() {
  group('FollowUpExtractor Enrichment', () {
    late FollowUpExtractor extractor;
    late MockVaultService mockVaultService;

    setUp(() {
      mockVaultService = MockVaultService();
      extractor = FollowUpExtractor(
        vaultService: mockVaultService,
      );
    });

    test('enriches medication item with linked prescription', () async {
      // Setup mock vault data
      final prescriptionRecord = HealthRecord(
        id: 'rec-1',
        title: 'Prescription Oct 2023',
        category: 'Prescriptions',
        createdAt: DateTime(2023, 10, 1),
        recordType: HealthRecord.typeDocumentExtraction,
        extractionId: 'ext-1',
      );
      
      final prescriptionExtraction = DocumentExtraction(
        id: 'ext-1',
        originalImagePath: 'path/to/img',
        extractedText: 'Metformin 500mg',
        structuredData: {
          'medications': [
            {'name': 'Metformin', 'dosage': '500mg'}
          ]
        },
        confidenceScore: 0.9,
      );

      mockVaultService.setMockDocuments([
        (record: prescriptionRecord, extraction: prescriptionExtraction)
      ]);

      // Create a follow-up item
      final item = FollowUpItem(
        id: 'item-1',
        category: FollowUpCategory.medication,
        verb: 'take',
        object: 'Metformin',
        description: 'Take Metformin daily.',
        priority: FollowUpPriority.high,
        sourceConversationId: 'conv-1',
        createdAt: DateTime.now(),
      );

      // Run enrichment
      await extractor.enrichItems([item]);

      // Verify linking
      expect(item.linkedRecordId, 'rec-1');
      expect(item.linkedEntityName, 'Metformin');
      expect(item.linkedContext, contains('From Prescription Oct 2023'));
    });

    test('enriches test item with linked lab result', () async {
      // Setup mock vault data
      final labRecord = HealthRecord(
        id: 'rec-2',
        title: 'Lab Report',
        category: 'Lab Results',
        createdAt: DateTime(2023, 10, 5),
        recordType: HealthRecord.typeDocumentExtraction,
        extractionId: 'ext-2',
      );
      
      final labExtraction = DocumentExtraction(
        id: 'ext-2',
        originalImagePath: 'path/to/img',
        extractedText: 'HbA1c: 5.7%',
        structuredData: {
          'lab_values': [
            {'field': 'HbA1c', 'value': '5.7', 'unit': '%'}
          ]
        },
        confidenceScore: 0.9,
      );

      mockVaultService.setMockDocuments([
        (record: labRecord, extraction: labExtraction)
      ]);

      // Create a follow-up item
      final item = FollowUpItem(
        id: 'item-2',
        category: FollowUpCategory.test,
        verb: 'check',
        object: 'HbA1c',
        description: 'Check HbA1c levels.',
        priority: FollowUpPriority.normal,
        sourceConversationId: 'conv-1',
        createdAt: DateTime.now(),
      );

      // Run enrichment
      await extractor.enrichItems([item]);

      // Verify linking
      expect(item.linkedRecordId, 'rec-2');
      expect(item.linkedEntityName, 'HbA1c');
      expect(item.linkedContext, 'Result: 5.7 %');
    });
  });
}
