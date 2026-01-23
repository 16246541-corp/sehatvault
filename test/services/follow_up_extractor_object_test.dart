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
      'consult': FollowUpCategory.appointment,
      'perform': FollowUpCategory.test,
      'check': FollowUpCategory.monitoring,
    });

    temporalConfig = TemporalPhrasePatternsConfiguration.forTesting({
      'deadline': [],
      'frequency': [],
    });

    dictionaryService = MedicalDictionaryService(initialData: {
      'medications': [
        {'canonical_name': 'Metformin', 'aliases': [], 'category': 'Antidiabetic'},
        {'canonical_name': 'Lisinopril', 'aliases': [], 'category': 'Antihypertensive'},
      ],
      'specialists': ['Cardiologist', 'Dermatologist'],
      'tests': [
        {'canonical_name': 'Blood Pressure', 'aliases': ['BP'], 'category': 'Vitals'},
        {'canonical_name': 'HbA1c', 'aliases': [], 'category': 'Biochemistry'},
      ],
      'procedures': ['ECG'],
      'body_parts': ['Heart'],
    });

    extractor = FollowUpExtractor(
      verbConfig: verbConfig,
      temporalConfig: temporalConfig,
      dictionaryService: dictionaryService,
    );
  });

  group('FollowUpExtractor Object Extraction', () {
    test('extracts medication object', () {
      const transcript = "Please take Metformin daily.";
      final items = extractor.extractFromTranscript(transcript, 'conv-1');

      expect(items.length, 1);
      final item = items.first;
      expect(item.verb, 'take');
      expect(item.object, 'Metformin');
      expect(item.category, FollowUpCategory.medication);
    });

    test('extracts specialist object', () {
      const transcript = "You should consult a Cardiologist soon.";
      final items = extractor.extractFromTranscript(transcript, 'conv-1');

      expect(items.length, 1);
      final item = items.first;
      expect(item.verb, 'consult');
      expect(item.object, 'Cardiologist');
      expect(item.category, FollowUpCategory.appointment);
    });

    test('extracts test object', () {
      const transcript = "We need to perform an HbA1c test.";
      final items = extractor.extractFromTranscript(transcript, 'conv-1');

      expect(items.length, 1);
      final item = items.first;
      expect(item.verb, 'perform');
      expect(item.object, 'HbA1c');
      expect(item.category, FollowUpCategory.test);
    });
    
    test('extracts body part for monitoring', () {
       const transcript = "Check your heart rate."; 
       final items = extractor.extractFromTranscript(transcript, 'conv-1');
       
       expect(items.length, 1);
       final item = items.first;
       expect(item.verb, 'check');
       expect(item.object, 'heart rate'); 
    });
    
    test('falls back to heuristic if no dictionary match', () {
       const transcript = "Take the blue pill.";
       final items = extractor.extractFromTranscript(transcript, 'conv-1');
       
       expect(items.length, 1);
       final item = items.first;
       expect(item.verb, 'take');
       expect(item.object, 'the blue pill'); // Fallback
    });
    
    test('handles object before verb (scanning context)', () {
       const transcript = "Metformin, you should take.";
       final items = extractor.extractFromTranscript(transcript, 'conv-1');
       
       expect(items.length, 1);
       final item = items.first;
       expect(item.verb, 'take');
       expect(item.object, 'Metformin');
    });
  });
}
