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
      'walk': FollowUpCategory.lifestyle,
    });

    temporalConfig = TemporalPhrasePatternsConfiguration.forTesting({
      'deadline': [
        r'in \d+ (?:weeks?|days?|months?)',
        r'within \d+ (?:hours?|days?)',
        r'next (?:week|month)'
      ],
      'frequency': [
        'three times daily',
        'twice a day',
        'once a week',
        'every morning',
        r'\d+ times a day',
        r'\d+ times daily',
        r'every \d+ hours?',
        'daily',
        'weekly',
        'as needed',
        'with meals',
        'at bedtime'
      ],
    });

    dictionaryService = MedicalDictionaryService.forTesting({});

    extractor = FollowUpExtractor(
      verbConfig: verbConfig,
      temporalConfig: temporalConfig,
      dictionaryService: dictionaryService,
    );
  });

  group('FollowUpExtractor Frequency & DueDate', () {
    test('extracts "daily" and sets dueDate to tomorrow', () {
      final anchor = DateTime(2023, 10, 1, 10, 0); // Oct 1st, 10 AM
      const transcript = "Take this pill daily.";
      final items = extractor.extractFromTranscript(transcript, 'conv-1', referenceDate: anchor);

      expect(items.length, 1);
      final item = items.first;
      expect(item.frequency, 'daily');
      // daily -> +1 day
      expect(item.dueDate, anchor.add(const Duration(days: 1)));
    });

    test('extracts "twice a day" and sets dueDate to tomorrow', () {
      final anchor = DateTime(2023, 10, 1, 10, 0);
      const transcript = "Take this twice a day.";
      final items = extractor.extractFromTranscript(transcript, 'conv-1', referenceDate: anchor);

      expect(items.length, 1);
      final item = items.first;
      expect(item.frequency, 'twice a day');
      // twice a day -> +1 day (simplified logic)
      expect(item.dueDate, anchor.add(const Duration(days: 1)));
    });

    test('extracts "every morning" and sets dueDate to next 8 AM', () {
      final anchor = DateTime(2023, 10, 1, 15, 0); // Oct 1st, 3 PM
      const transcript = "Take medication every morning.";
      final items = extractor.extractFromTranscript(transcript, 'conv-1', referenceDate: anchor);

      expect(items.length, 1);
      final item = items.first;
      expect(item.frequency, 'every morning');
      // every morning -> Oct 2nd, 8 AM
      expect(item.dueDate, DateTime(2023, 10, 2, 8, 0));
    });

    test('extracts "once a week" and sets dueDate to +7 days', () {
      final anchor = DateTime(2023, 10, 1, 10, 0);
      const transcript = "Check blood pressure once a week.";
      final items = extractor.extractFromTranscript(transcript, 'conv-1', referenceDate: anchor);

      expect(items.length, 1);
      final item = items.first;
      expect(item.frequency, 'once a week');
      expect(item.dueDate, anchor.add(const Duration(days: 7)));
    });

    test('extracts "every 4 hours" and sets dueDate to +4 hours', () {
      final anchor = DateTime(2023, 10, 1, 10, 0);
      const transcript = "Take pills every 4 hours.";
      final items = extractor.extractFromTranscript(transcript, 'conv-1', referenceDate: anchor);

      expect(items.length, 1);
      final item = items.first;
      expect(item.frequency, 'every 4 hours');
      expect(item.dueDate, anchor.add(const Duration(hours: 4)));
    });

    test('extracts "at bedtime" and sets dueDate correctly', () {
      // Case 1: Before 9 PM (e.g., 10 AM) -> Due today at 9 PM
      final anchor1 = DateTime(2023, 10, 1, 10, 0);
      const transcript = "Take pill at bedtime.";
      final items1 = extractor.extractFromTranscript(transcript, 'conv-1', referenceDate: anchor1);
      expect(items1.first.dueDate, DateTime(2023, 10, 1, 21, 0));

      // Case 2: After 9 PM (e.g., 10 PM) -> Due tomorrow at 9 PM
      final anchor2 = DateTime(2023, 10, 1, 22, 0);
      final items2 = extractor.extractFromTranscript(transcript, 'conv-1', referenceDate: anchor2);
      expect(items2.first.dueDate, DateTime(2023, 10, 2, 21, 0));
    });

    test('prioritizes explicit deadline over frequency calculation', () {
      final anchor = DateTime(2023, 10, 1, 10, 0);
      // "next week" sets deadline to +7 days. "daily" sets freq.
      // We expect dueDate to be +7 days, NOT +1 day.
      const transcript = "Start to take this daily next week.";
      final items = extractor.extractFromTranscript(transcript, 'conv-1', referenceDate: anchor);

      expect(items.length, 1);
      final item = items.first;
      expect(item.frequency, 'daily');
      expect(item.timeframeRaw, 'next week');
      expect(item.dueDate, anchor.add(const Duration(days: 7)));
    });
    
    test('extracts "as needed" with null dueDate', () {
      final anchor = DateTime(2023, 10, 1, 10, 0);
      const transcript = "Take painkillers as needed.";
      final items = extractor.extractFromTranscript(transcript, 'conv-1', referenceDate: anchor);

      expect(items.length, 1);
      final item = items.first;
      expect(item.frequency, 'as needed');
      expect(item.dueDate, null);
    });
  });
}
