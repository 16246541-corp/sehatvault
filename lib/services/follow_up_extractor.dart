import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import '../models/follow_up_item.dart';
import '../models/doctor_conversation.dart';
import '../models/health_record.dart';
import '../models/document_extraction.dart';
import '../utils/string_utils.dart';
import 'vault_service.dart';
import 'verb_mapping_configuration.dart';
import 'temporal_phrase_patterns_configuration.dart';
import 'medical_dictionary_service.dart';
import 'extractors/base_extractor.dart';
import 'extractors/medication_extractor.dart';
import 'extractors/appointment_extractor.dart';
import 'extractors/test_extractor.dart';
import 'extractors/lifestyle_extractor.dart';
import 'extractors/monitoring_extractor.dart';
import 'extractors/warning_extractor.dart';
import 'extractors/decision_extractor.dart';

class FollowUpExtractor {
  final VerbMappingConfiguration _verbConfig;
  final TemporalPhrasePatternsConfiguration _temporalConfig;
  final MedicalDictionaryService _dictionaryService;
  final VaultService? _vaultService;

  late final List<BaseExtractor> _extractors;

  FollowUpExtractor({
    VerbMappingConfiguration? verbConfig,
    TemporalPhrasePatternsConfiguration? temporalConfig,
    MedicalDictionaryService? dictionaryService,
    VaultService? vaultService,
  })  : _verbConfig = verbConfig ?? VerbMappingConfiguration(),
        _temporalConfig =
            temporalConfig ?? TemporalPhrasePatternsConfiguration(),
        _dictionaryService = dictionaryService ?? MedicalDictionaryService(),
        _vaultService = vaultService {
    _extractors = [
      MedicationExtractor(_dictionaryService, _temporalConfig),
      AppointmentExtractor(_dictionaryService, _temporalConfig),
      TestExtractor(_dictionaryService, _temporalConfig),
      LifestyleExtractor(_dictionaryService, _temporalConfig),
      MonitoringExtractor(_dictionaryService, _temporalConfig),
      WarningExtractor(_dictionaryService, _temporalConfig),
      DecisionExtractor(_dictionaryService, _temporalConfig),
    ];
  }

  /// Extracts follow-up items from a transcript.
  ///
  /// Returns a list of [FollowUpItem]s found in the transcript.
  /// [referenceDate] is used as the anchor for relative dates (defaults to DateTime.now()).
  /// [existingItems] if provided, will be used to flag potential duplicates (similarity > 80%).
  List<FollowUpItem> extractFromTranscript(
    String transcript,
    String conversationId, {
    List<ConversationSegment>? segments,
    DateTime? referenceDate,
    List<FollowUpItem>? existingItems,
  }) {
    if (transcript.isEmpty && (segments == null || segments.isEmpty)) return [];

    // Ensure dependencies are loaded
    if (!_temporalConfig.isLoaded || !_dictionaryService.isLoaded) {
      print('Warning: Configurations not loaded. Returning empty list.');
      return [];
    }

    final anchorDate = referenceDate ?? DateTime.now();
    final List<FollowUpItem> items = [];

    // Split into sentences (handling . ? ! followed by space or using segments/silence)
    final sentences = segments != null && segments.isNotEmpty
        ? _splitIntoSentencesFromSegments(segments)
        : _splitIntoSentences(transcript);

    for (final sentence in sentences) {
      final item = _processSentence(sentence, conversationId, anchorDate);
      if (item != null) {
        items.add(item);
      }
    }

    if (existingItems != null && existingItems.isNotEmpty) {
      _markDuplicates(items, existingItems);
    }

    return items;
  }

  /// Enriches follow-up items by linking them to existing vault records.
  ///
  /// - Medications are linked to Prescriptions in the vault.
  /// - Tests are linked to Lab Results in the vault.
  Future<void> enrichItems(List<FollowUpItem> items) async {
    if (_vaultService == null) return;
    if (items.isEmpty) return;

    try {
      final allDocs = await _vaultService!.getAllDocuments();

      for (final item in items) {
        if (item.object == null) continue;

        if (item.category == FollowUpCategory.medication) {
          _linkMedication(item, allDocs);
        } else if (item.category == FollowUpCategory.test ||
            item.category == FollowUpCategory.monitoring) {
          _linkTest(item, allDocs);
        }
      }
    } catch (e) {
      debugPrint('Error enriching items: $e');
    }
  }

  void _linkMedication(FollowUpItem item,
      List<({HealthRecord record, DocumentExtraction? extraction})> docs) {
    // Look for Prescriptions or Medical Records
    final candidates = docs.where((d) =>
        d.record.category == 'Prescriptions' ||
        d.record.category == 'Medical Records');

    for (final doc in candidates) {
      final extraction = doc.extraction;
      if (extraction == null) continue;

      // Check structured data medications
      final medications = extraction.structuredData['medications'] as List?;
      if (medications != null) {
        for (final med in medications) {
          final name = med['name']?.toString().toLowerCase();
          // Check if item object contains medication name or vice versa
          // item.object might be "Metformin 500mg", med name might be "Metformin"
          if (name != null &&
              (item.object!.toLowerCase().contains(name) ||
                  name.contains(item.object!.toLowerCase()))) {
            item.linkedRecordId = doc.record.id;
            item.linkedEntityName = med['name'];
            item.linkedContext = 'From ${doc.record.title}';
            return; // Found a match
          }
        }
      }
    }
  }

  void _linkTest(FollowUpItem item,
      List<({HealthRecord record, DocumentExtraction? extraction})> docs) {
    // Look for Lab Results
    final candidates = docs.where((d) => d.record.category == 'Lab Results');

    for (final doc in candidates) {
      final extraction = doc.extraction;
      if (extraction == null) continue;

      final labs = extraction.structuredData['lab_values'] as List?;
      if (labs != null) {
        for (final lab in labs) {
          final field = lab['field']?.toString().toLowerCase();
          if (field != null &&
              (item.object!.toLowerCase().contains(field) ||
                  field.contains(item.object!.toLowerCase()))) {
            item.linkedRecordId = doc.record.id;
            item.linkedEntityName = lab['field'];
            item.linkedContext = 'Result: ${lab['value']} ${lab['unit']}';
            return;
          }
        }
      }
    }
  }

  /// Flags potential duplicates in [newItems] by comparing against [existingItems].
  /// Uses Levenshtein distance on description with > 80% similarity threshold.
  void _markDuplicates(
      List<FollowUpItem> newItems, List<FollowUpItem> existingItems) {
    for (final newItem in newItems) {
      for (final existingItem in existingItems) {
        // Skip comparing with itself if IDs match (unlikely for new items but good practice)
        if (newItem.id == existingItem.id) continue;

        final similarity = StringUtils.calculateSimilarity(
            newItem.description, existingItem.description);
        if (similarity > 0.8) {
          newItem.isPotentialDuplicate = true;
          break;
        }
      }
    }
  }

  List<String> _splitIntoSentences(String text) {
    // Simple sentence splitter: looks for punctuation followed by whitespace
    return text.trim().split(RegExp(r'(?<=[.!?])\s+'));
  }

  List<String> _splitIntoSentencesFromSegments(
      List<ConversationSegment> segments) {
    final sentences = <String>[];
    StringBuffer currentSentence = StringBuffer();

    for (int i = 0; i < segments.length; i++) {
      final segment = segments[i];
      final text = segment.text.trim();

      if (text.isEmpty) continue;

      if (currentSentence.isNotEmpty) {
        currentSentence.write(' ');
      }
      currentSentence.write(text);

      // Check for split conditions
      bool shouldSplit = false;

      // 1. Punctuation (ends with . ? !)
      if (RegExp(r'[.!?]$').hasMatch(text)) {
        shouldSplit = true;
      }

      // 2. Silence Gap (look ahead)
      if (!shouldSplit && i < segments.length - 1) {
        final nextSegment = segments[i + 1];
        final gap = nextSegment.startTimeMs - segment.endTimeMs;
        // Threshold for silence indicating a sentence break (e.g., 1000ms)
        if (gap > 1000) {
          shouldSplit = true;
        }

        // 3. Speaker Change
        if (segment.speaker != nextSegment.speaker) {
          shouldSplit = true;
        }
      } else if (i == segments.length - 1) {
        // Always split at the end
        shouldSplit = true;
      }

      if (shouldSplit) {
        sentences.add(currentSentence.toString().trim());
        currentSentence.clear();
      }
    }

    // Add any remaining text
    if (currentSentence.isNotEmpty) {
      sentences.add(currentSentence.toString().trim());
    }

    return sentences;
  }

  FollowUpItem? _processSentence(
      String sentence, String conversationId, DateTime anchorDate) {
    for (final extractor in _extractors) {
      final item = extractor.extract(sentence, conversationId, anchorDate);
      if (item != null) {
        return item;
      }
    }
    return null;
  }
}
