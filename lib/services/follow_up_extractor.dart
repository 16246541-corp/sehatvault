import 'package:uuid/uuid.dart';
import '../models/follow_up_item.dart';
import '../models/doctor_conversation.dart';
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
  
  late final List<BaseExtractor> _extractors;

  FollowUpExtractor({
    VerbMappingConfiguration? verbConfig,
    TemporalPhrasePatternsConfiguration? temporalConfig,
    MedicalDictionaryService? dictionaryService,
  })  : _verbConfig = verbConfig ?? VerbMappingConfiguration(),
        _temporalConfig = temporalConfig ?? TemporalPhrasePatternsConfiguration(),
        _dictionaryService = dictionaryService ?? MedicalDictionaryService() {
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
  List<FollowUpItem> extractFromTranscript(
    String transcript, 
    String conversationId, {
    List<ConversationSegment>? segments,
    DateTime? referenceDate,
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
    
    return items;
  }

  List<String> _splitIntoSentences(String text) {
    // Simple sentence splitter: looks for punctuation followed by whitespace
    return text.trim().split(RegExp(r'(?<=[.!?])\s+'));
  }

  List<String> _splitIntoSentencesFromSegments(List<ConversationSegment> segments) {
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

  FollowUpItem? _processSentence(String sentence, String conversationId, DateTime anchorDate) {
    for (final extractor in _extractors) {
      final item = extractor.extract(sentence, conversationId, anchorDate);
      if (item != null) {
        return item;
      }
    }
    return null;
  }
}
