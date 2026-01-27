import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/document_extraction.dart';
import '../models/health_record.dart';
import '../models/doctor_conversation.dart';
import 'ocr_service.dart';
import 'local_storage_service.dart';
import 'search_service.dart';
import 'citation_service.dart';
import 'health_intelligence_engine.dart';
import 'local_audit_service.dart';
import 'medical_field_extractor.dart';
import 'reference_range_service.dart';
import 'safety_filter_service.dart';
import 'session_manager.dart';

/// Service for saving documents to the encrypted vault
/// Handles the complete pipeline: OCR → DocumentExtraction → HealthRecord → Encrypted Storage
class VaultService {
  final LocalStorageService _storageService;
  late final SearchService _searchService;
  late final CitationService _citationService;

  VaultService(this._storageService) {
    _searchService = SearchService(_storageService);
    _citationService = CitationService(_storageService);
  }

  /// Save a document to the vault with full OCR processing
  ///
  /// This method:
  /// 1. Runs OCR on the image to extract text and structured data
  /// 2. Creates a DocumentExtraction object with the results
  /// 3. Creates a HealthRecord linked to the extraction
  /// 4. Saves both to encrypted Hive boxes
  ///
  /// Returns the created HealthRecord
  Future<HealthRecord> saveDocumentToVault({
    required File imageFile,
    required String title,
    required String category,
    String? notes,
    Map<String, dynamic>? additionalMetadata,
    void Function(String status)? onProgress,
  }) async {
    try {
      // Step 1: Run OCR processing
      onProgress?.call('Extracting text from document...');
      var extraction = await OCRService.processDocument(imageFile);

      // Calculate content hash and check for duplicates
      final contentHash = _generateContentHash(extraction.extractedText);
      final existingExtraction =
          _storageService.findDocumentExtractionByHash(contentHash);

      if (existingExtraction != null) {
        throw DuplicateDocumentException(existingExtraction.id);
      }

      // Update extraction with hash
      extraction = extraction.copyWith(contentHash: contentHash);

      debugPrint('OCR completed. Confidence: ${extraction.confidenceScore}');
      debugPrint('Extracted ${extraction.extractedText.length} characters');
      debugPrint(
          'Structured data fields: ${extraction.structuredData.keys.join(", ")}');

      // Step 1.5: Inject Citations
      if (extraction.structuredData.containsKey('lab_values')) {
        onProgress?.call('Generating citations...');
        final labValues = extraction.structuredData['lab_values'] as List;
        final citations =
            _citationService.generateCitationsForLabValues(labValues);

        if (citations.isNotEmpty) {
          // Save citations to Hive (Citation Database)
          for (final citation in citations) {
            await _citationService.addCitation(citation);
          }
          // Link to extraction
          extraction = extraction.copyWith(citations: citations);
          debugPrint('Generated ${citations.length} citations');
        }
      }

      // Step 2: Save DocumentExtraction to Hive
      onProgress?.call('Saving extraction data...');
      await _storageService.saveDocumentExtraction(extraction);
      debugPrint('DocumentExtraction saved with ID: ${extraction.id}');

      // Step 3: Create HealthRecord linked to the extraction
      onProgress?.call('Creating health record...');

      final bool autoDelete = _storageService.autoDeleteOriginal;
      final ext = p.extension(extraction.originalImagePath).toLowerCase();
      final isPreviewableImage = ['.jpg', '.jpeg', '.png'].contains(ext);

      final healthRecord = HealthRecord(
        id: const Uuid().v4(),
        title: title,
        category: category,
        createdAt: DateTime.now(),
        filePath: autoDelete
            ? null
            : (isPreviewableImage ? extraction.originalImagePath : null),
        notes: notes,
        recordType: HealthRecord.typeDocumentExtraction,
        extractionId: extraction.id,
        metadata: {
          'confidenceScore': extraction.confidenceScore,
          'textLength': extraction.extractedText.length,
          'structuredFieldCount': extraction.structuredData.length,
          ...?additionalMetadata,
        },
      );

      // Step 4: Save HealthRecord to Hive
      onProgress?.call('Saving to encrypted vault...');
      await _storageService.saveRecord(
        healthRecord.id,
        _healthRecordToMap(healthRecord),
      );

      // Step 5: Auto-delete original image if enabled
      if (autoDelete) {
        try {
          final file = File(extraction.originalImagePath);
          if (await file.exists()) {
            await file.delete();
            debugPrint(
                'Auto-deleted original image: ${extraction.originalImagePath}');
          }
        } catch (e) {
          debugPrint('Failed to auto-delete image: $e');
        }
      }

      debugPrint('HealthRecord saved with ID: ${healthRecord.id}');
      onProgress?.call('Document saved successfully!');

      unawaited(
        HealthIntelligenceEngine(
          storage: _storageService,
          fieldExtractor: MedicalFieldExtractor(),
          referenceRanges: ReferenceRangeService(),
          safetyFilter: SafetyFilterService(),
          auditLogger: LocalAuditService(_storageService, SessionManager()),
        ).detectAndPersistInsights().catchError((_) {}),
      );

      return healthRecord;
    } catch (e, stackTrace) {
      debugPrint('Error saving document to vault: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Save a document with automatic category detection based on extracted content
  ///
  /// Uses structured data to intelligently categorize the document:
  /// - Lab values → Lab Results
  /// - Medications → Prescriptions
  /// - Dates with medical context → Medical Records
  Future<HealthRecord> saveDocumentWithAutoCategory({
    required File imageFile,
    required String title,
    String? notes,
    Map<String, dynamic>? additionalMetadata,
    void Function(String status)? onProgress,
  }) async {
    // First, run OCR to get structured data
    onProgress?.call('Analyzing document...');
    var extraction = await OCRService.processDocument(imageFile);

    // Calculate content hash and check for duplicates
    final contentHash = _generateContentHash(extraction.extractedText);
    final existingExtraction =
        _storageService.findDocumentExtractionByHash(contentHash);

    if (existingExtraction != null) {
      throw DuplicateDocumentException(existingExtraction.id);
    }

    // Update extraction with hash
    extraction = extraction.copyWith(contentHash: contentHash);

    if (extraction.structuredData.containsKey('lab_values')) {
      onProgress?.call('Generating citations...');
      final labValues = extraction.structuredData['lab_values'] as List;
      final citations =
          _citationService.generateCitationsForLabValues(labValues);

      if (citations.isNotEmpty) {
        for (final citation in citations) {
          await _citationService.addCitation(citation);
        }
        extraction = extraction.copyWith(citations: citations);
        debugPrint('Generated ${citations.length} citations');
      }
    }

    // Detect category from structured data
    final String category = _detectCategory(extraction.structuredData);
    debugPrint('Auto-detected category: $category');

    // Now save with the detected category
    // We need to save the extraction first, then create the health record
    onProgress?.call('Saving extraction data...');
    await _storageService.saveDocumentExtraction(extraction);
    await _searchService.indexDocument(extraction);

    onProgress?.call('Creating health record...');
    final healthRecord = HealthRecord(
      id: const Uuid().v4(),
      title: title,
      category: category,
      createdAt: DateTime.now(),
      filePath: ['.jpg', '.jpeg', '.png']
              .contains(p.extension(extraction.originalImagePath).toLowerCase())
          ? extraction.originalImagePath
          : null,
      notes: notes,
      recordType: HealthRecord.typeDocumentExtraction,
      extractionId: extraction.id,
      metadata: {
        'confidenceScore': extraction.confidenceScore,
        'textLength': extraction.extractedText.length,
        'structuredFieldCount': extraction.structuredData.length,
        'autoDetectedCategory': true,
        ...?additionalMetadata,
      },
    );

    onProgress?.call('Saving to encrypted vault...');
    await _storageService.saveRecord(
      healthRecord.id,
      _healthRecordToMap(healthRecord),
    );

    debugPrint('HealthRecord saved with auto-detected category: $category');
    onProgress?.call('Document saved successfully!');

    unawaited(
      HealthIntelligenceEngine(
        storage: _storageService,
        fieldExtractor: MedicalFieldExtractor(),
        referenceRanges: ReferenceRangeService(),
        safetyFilter: SafetyFilterService(),
        auditLogger: LocalAuditService(_storageService, SessionManager()),
      ).detectAndPersistInsights().catchError((_) {}),
    );

    return healthRecord;
  }

  /// Save a doctor conversation to the vault as a health record
  Future<HealthRecord> saveConversationToVault(
    DoctorConversation conversation, {
    void Function(String status)? onProgress,
  }) async {
    onProgress?.call('Linking conversation to vault...');

    // Create metadata
    final metadata = {
      'duration': conversation.duration,
      'doctorName': conversation.doctorName,
      'transcriptLength': conversation.transcript.length,
      'hasFollowUps': conversation.followUpItems.isNotEmpty,
      'subtype': 'conversation',
    };

    final healthRecord = HealthRecord(
      id: const Uuid().v4(),
      title: conversation.title,
      category: 'Medical Records',
      createdAt: conversation.createdAt,
      filePath: null,
      notes: 'Doctor conversation with ${conversation.doctorName}',
      recordType: HealthRecord.typeDoctorConversation,
      extractionId: conversation.id,
      metadata: metadata,
    );

    onProgress?.call('Saving to encrypted vault...');
    await _storageService.saveRecord(
      healthRecord.id,
      _healthRecordToMap(healthRecord),
    );

    debugPrint('HealthRecord linked to conversation: ${conversation.id}');
    onProgress?.call('Conversation saved successfully!');

    return healthRecord;
  }

  /// Retrieve a complete document with its extraction data
  ///
  /// Returns both the HealthRecord and its linked DocumentExtraction
  Future<({HealthRecord record, DocumentExtraction? extraction})>
      getCompleteDocument(String healthRecordId) async {
    final recordMap = _storageService.getRecord(healthRecordId);
    if (recordMap == null) {
      throw Exception('Health record not found: $healthRecordId');
    }

    final record = _mapToHealthRecord(recordMap);
    DocumentExtraction? extraction;

    if (record.extractionId != null &&
        record.recordType != HealthRecord.typeDoctorConversation) {
      try {
        extraction =
            _storageService.getDocumentExtraction(record.extractionId!);
      } catch (e) {
        debugPrint(
            'Warning: Could not load extraction ${record.extractionId}: $e');
      }
    }

    return (record: record, extraction: extraction);
  }

  /// Get all health records with their extraction data
  Future<List<({HealthRecord record, DocumentExtraction? extraction})>>
      getAllDocuments() async {
    final recordMaps = _storageService.getAllRecords();
    final List<({HealthRecord record, DocumentExtraction? extraction})>
        documents = [];

    for (final recordMap in recordMaps) {
      final record = _mapToHealthRecord(recordMap);
      DocumentExtraction? extraction;

      if (record.extractionId != null &&
          record.recordType != HealthRecord.typeDoctorConversation) {
        try {
          extraction =
              _storageService.getDocumentExtraction(record.extractionId!);
        } catch (e) {
          debugPrint(
              'Warning: Could not load extraction ${record.extractionId}: $e');
        }
      }

      documents.add((record: record, extraction: extraction));
    }

    return documents;
  }

  /// Delete a document and its associated extraction
  Future<void> deleteDocument(String healthRecordId) async {
    final recordMap = _storageService.getRecord(healthRecordId);
    if (recordMap == null) {
      throw Exception('Health record not found: $healthRecordId');
    }

    final record = _mapToHealthRecord(recordMap);

    // Delete the associated data (Extraction or Conversation)
    if (record.extractionId != null) {
      if (record.recordType == HealthRecord.typeDoctorConversation) {
        try {
          await _storageService.deleteDoctorConversation(record.extractionId!);
          debugPrint('Deleted DoctorConversation: ${record.extractionId}');
        } catch (e) {
          debugPrint(
              'Warning: Could not delete conversation ${record.extractionId}: $e');
        }
      } else {
        try {
          await _storageService.deleteDocumentExtraction(record.extractionId!);
          await _searchService.removeDocument(record.extractionId!);
          debugPrint('Deleted DocumentExtraction: ${record.extractionId}');
        } catch (e) {
          debugPrint(
              'Warning: Could not delete extraction ${record.extractionId}: $e');
        }
      }
    }

    // Delete the image file if it exists
    if (record.filePath != null) {
      try {
        final file = File(record.filePath!);
        if (await file.exists()) {
          await file.delete();
          debugPrint('Deleted image file: ${record.filePath}');
        }
      } catch (e) {
        debugPrint(
            'Warning: Could not delete image file ${record.filePath}: $e');
      }
    }

    // Delete the health record
    await _storageService.deleteRecord(healthRecordId);
    debugPrint('Deleted HealthRecord: $healthRecordId');
  }

  // MARK: - Private Helper Methods

  /// Detect category from structured data
  String _detectCategory(Map<String, dynamic> structuredData) {
    // 1. Try keyword-based classification (from DocumentClassificationService)
    if (structuredData.containsKey('documentType')) {
      try {
        final typeName = structuredData['documentType'] as String;
        // The service returns the enum name (e.g. 'labResults')
        // We find the matching enum and get its display name
        final category = HealthCategory.values.byName(typeName);

        // If the classifier returned 'other' (default), we might still want to check
        // for specific fields below, so we don't return immediately if it's 'other'.
        if (category != HealthCategory.other) {
          return category.displayName;
        }
      } catch (e) {
        debugPrint('Error parsing documentType: $e');
      }
    }

    // 2. Fallback: Check for specific extracted fields
    // Check for lab values
    final labValues = structuredData['lab_values'] as List?;
    if (labValues != null && labValues.isNotEmpty) {
      return 'Lab Results';
    }

    // Check for medications
    final medications = structuredData['medications'] as List?;
    if (medications != null && medications.isNotEmpty) {
      return 'Prescriptions';
    }

    // Check for vaccination keywords in vitals or other fields
    final vitals = structuredData['vitals'] as List?;
    if (vitals != null && vitals.isNotEmpty) {
      final vitalText = vitals.toString().toLowerCase();
      if (vitalText.contains('vaccine') || vitalText.contains('immunization')) {
        return 'Vaccinations';
      }
    }

    // Default to Medical Records
    return 'Medical Records';
  }

  /// Convert HealthRecord to Map for Hive storage
  Map<String, dynamic> _healthRecordToMap(HealthRecord record) {
    return {
      'id': record.id,
      'title': record.title,
      'category': record.category,
      'createdAt': record.createdAt.toIso8601String(),
      'updatedAt': record.updatedAt?.toIso8601String(),
      'filePath': record.filePath,
      'notes': record.notes,
      'metadata': record.metadata,
      'recordType': record.recordType,
      'extractionId': record.extractionId,
    };
  }

  /// Convert Map to HealthRecord
  HealthRecord _mapToHealthRecord(Map<String, dynamic> map) {
    return HealthRecord(
      id: map['id'] as String,
      title: map['title'] as String,
      category: map['category'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
      filePath: map['filePath'] as String?,
      notes: map['notes'] as String?,
      metadata: map['metadata'] as Map<String, dynamic>?,
      recordType: map['recordType'] as String?,
      extractionId: map['extractionId'] as String?,
    );
  }

  /// Generate SHA-256 hash for content
  String _generateContentHash(String text) {
    if (text.isEmpty) {
      // Return a unique hash for empty text to avoid blocking uploads of empty docs (though unlikely)
      // Or just hash the empty string. Let's hash the empty string.
      // But practically, OCR might return empty text for different images.
      // Maybe include file size or something if text is empty?
      // For now, strict text hashing.
    }
    final bytes = utf8.encode(text);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}

/// Exception thrown when a duplicate document is found
class DuplicateDocumentException implements Exception {
  final String existingRecordId;
  final String message;

  DuplicateDocumentException(this.existingRecordId,
      [this.message = 'Duplicate document found']);

  @override
  String toString() =>
      'DuplicateDocumentException: $message (Existing ID: $existingRecordId)';
}
