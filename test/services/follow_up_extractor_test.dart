import 'package:flutter_test/flutter_test.dart';
import 'package:sehatlocker/models/follow_up_item.dart';
import 'package:sehatlocker/services/follow_up_extractor.dart';
import 'package:sehatlocker/services/temporal_phrase_patterns_configuration.dart';
import 'package:sehatlocker/services/verb_mapping_configuration.dart';
import 'package:sehatlocker/services/medical_dictionary_service.dart';

void main() {
  late FollowUpExtractor extractor;
  late VerbMappingConfiguration verbConfig;
  late TemporalPhrasePatternsConfiguration temporalConfig;
  late MedicalDictionaryService dictionaryService;

  setUp(() {
    verbConfig = VerbMappingConfiguration.forTesting({
      'take': FollowUpCategory.medication,
      'schedule': FollowUpCategory.appointment,
      'check': FollowUpCategory.monitoring,
    });

    temporalConfig = TemporalPhrasePatternsConfiguration.forTesting({
      'deadline': [r'\bin\s+\d+\s+days?\b', r'\bnext\s+week\b'],
      'frequency': [r'\bdaily\b', r'\btwice\s+a\s+day\b'],
    });

    dictionaryService = MedicalDictionaryService.forTesting({});

    extractor = FollowUpExtractor(
      verbConfig: verbConfig,
      temporalConfig: temporalConfig,
      dictionaryService: dictionaryService,
    );
  });

  group('FollowUpExtractor', () {
    test('extracts item with simple verb', () {
      const transcript = "You need to take your medication.";
      final items = extractor.extractFromTranscript(transcript, 'conv-1');

      expect(items.length, 1);
      final item = items.first;
      expect(item.verb, 'take');
      expect(item.category, FollowUpCategory.medication);
      expect(item.description, 'You need to take your medication.');
    });

    test('extracts item with frequency', () {
      const transcript = "Take this pill twice a day.";
      final items = extractor.extractFromTranscript(transcript, 'conv-1');

      expect(items.length, 1);
      final item = items.first;
      expect(item.verb, 'take');
      expect(item.category, FollowUpCategory.medication);
      expect(item.frequency, 'twice a day');
    });

    test('extracts multiple items from multiple sentences', () {
      const transcript = "Please schedule a follow-up. Also check your blood pressure.";
      final items = extractor.extractFromTranscript(transcript, 'conv-1');

      expect(items.length, 2);
      
      expect(items[0].verb, 'schedule');
      expect(items[0].category, FollowUpCategory.appointment);
      
      expect(items[1].verb, 'check');
      expect(items[1].category, FollowUpCategory.monitoring);
    });

    test('ignores sentences without mapped verbs', () {
      const transcript = "Hello, how are you? I am fine.";
      final items = extractor.extractFromTranscript(transcript, 'conv-1');

      expect(items, isEmpty);
    });
    
    test('extracts full sentence as description', () {
       const transcript = "You must schedule an appointment with the cardiologist.";
       final items = extractor.extractFromTranscript(transcript, 'conv-1');
       
       expect(items.first.description, "You must schedule an appointment with the cardiologist.");
    });
  });
}
