import 'package:flutter_test/flutter_test.dart';
import 'package:sehatlocker/models/follow_up_item.dart';
import 'package:sehatlocker/services/follow_up_extractor.dart';
import 'package:sehatlocker/services/temporal_phrase_patterns_configuration.dart';
import 'package:sehatlocker/services/verb_mapping_configuration.dart';
import 'package:sehatlocker/services/medical_dictionary_service.dart';
import 'package:uuid/uuid.dart';

void main() {
  late FollowUpExtractor extractor;
  late VerbMappingConfiguration verbConfig;
  late TemporalPhrasePatternsConfiguration temporalConfig;
  late MedicalDictionaryService dictionaryService;

  setUp(() {
    verbConfig = VerbMappingConfiguration.forTesting({
      'take': FollowUpCategory.medication,
      'schedule': FollowUpCategory.appointment,
    });

    temporalConfig = TemporalPhrasePatternsConfiguration.forTesting({
      'deadline': [],
      'frequency': [],
    });

    dictionaryService = MedicalDictionaryService.forTesting({});

    extractor = FollowUpExtractor(
      verbConfig: verbConfig,
      temporalConfig: temporalConfig,
      dictionaryService: dictionaryService,
    );
  });

  FollowUpItem createItem(String description) {
    return FollowUpItem(
      id: const Uuid().v4(),
      category: FollowUpCategory.medication,
      verb: 'take',
      description: description,
      priority: FollowUpPriority.normal,
      sourceConversationId: 'existing-conv',
      createdAt: DateTime.now(),
    );
  }

  group('FollowUpExtractor Deduplication', () {
    test('flags exact duplicate', () {
      final existingItems = [createItem("Take 10mg Lisinopril daily.")];
      const transcript = "Take 10mg Lisinopril daily.";
      
      final items = extractor.extractFromTranscript(
        transcript, 
        'new-conv',
        existingItems: existingItems
      );

      expect(items.length, 1);
      expect(items.first.isPotentialDuplicate, isTrue);
    });

    test('flags similar duplicate (>80%)', () {
      final existingItems = [createItem("Take 10mg Lisinopril daily.")];
      // "Take 10mg Lisinopril daily" vs "Take 10mg Lisinopril day" -> high similarity
      // "daily" (5 chars) -> "day" (3 chars). Distance 2. Length 27. 
      // Distance is small.
      const transcript = "Take 10mg Lisinopril every day."; 
      // "daily" vs "every day".
      // "Take 10mg Lisinopril daily." (27)
      // "Take 10mg Lisinopril every day." (31)
      // Distance roughly 6-7? 24/31 = 0.77? Let's try something closer.
      
      // "Take 10mg Lisinopril daily."
      // "Take 10mg Lisinopril daily" (missing dot) -> distance 1. 26/27 > 0.9.
      
      final items = extractor.extractFromTranscript(
        "Take 10mg Lisinopril daily", 
        'new-conv',
        existingItems: existingItems
      );

      expect(items.length, 1);
      expect(items.first.isPotentialDuplicate, isTrue);
    });
    
    test('flags typo duplicate', () {
      final existingItems = [createItem("Schedule appointment with Cardiologist.")];
      // Typo: "Cardiolgist"
      const transcript = "Schedule appointment with Cardiolgist.";
      
      final items = extractor.extractFromTranscript(
        transcript, 
        'new-conv',
        existingItems: existingItems
      );

      expect(items.length, 1);
      expect(items.first.isPotentialDuplicate, isTrue);
    });

    test('does not flag dissimilar items', () {
      final existingItems = [createItem("Take Metformin.")];
      const transcript = "Take Lisinopril.";
      
      final items = extractor.extractFromTranscript(
        transcript, 
        'new-conv',
        existingItems: existingItems
      );

      expect(items.length, 1);
      expect(items.first.isPotentialDuplicate, isFalse);
    });

    test('does not flag if existing list is empty', () {
      const transcript = "Take Metformin.";
      final items = extractor.extractFromTranscript(
        transcript, 
        'new-conv',
        existingItems: []
      );

      expect(items.length, 1);
      expect(items.first.isPotentialDuplicate, isFalse);
    });
  });
}
