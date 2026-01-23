import 'package:flutter_test/flutter_test.dart';
import 'package:sehatlocker/models/follow_up_item.dart';
import 'package:sehatlocker/services/follow_up_extractor.dart';
import 'package:sehatlocker/services/temporal_phrase_patterns_configuration.dart';
import 'package:sehatlocker/services/verb_mapping_configuration.dart';

void main() {
  late FollowUpExtractor extractor;
  late VerbMappingConfiguration verbConfig;
  late TemporalPhrasePatternsConfiguration temporalConfig;
  final DateTime referenceDate = DateTime(2023, 10, 10, 10, 0); // Tuesday

  setUp(() {
    verbConfig = VerbMappingConfiguration.forTesting({
      'come': FollowUpCategory.appointment,
      'take': FollowUpCategory.medication,
      'submit': FollowUpCategory.decision,
    });

    temporalConfig = TemporalPhrasePatternsConfiguration.forTesting({
      'deadline': [
        r'\bin\s+(?:one|two|three|four|five|six|seven|eight|nine|ten|\d+)\s+(?:day|week|month|year)s?\b',
        r'\bwithin\s+(?:one|two|three|four|five|six|seven|eight|nine|ten|\d+)\s+(?:hour|day|week|month|year)s?\b',
        r'\bnext\s+(?:week|month|year)\b',
        r'\bby\s+(?:monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b',
      ],
      'frequency': [],
    });

    extractor = FollowUpExtractor(
      verbConfig: verbConfig,
      temporalConfig: temporalConfig,
    );
  });

  group('FollowUpExtractor Temporal Extraction', () {
    test('extracts "in two weeks"', () {
      const transcript = "Come back in two weeks.";
      final items = extractor.extractFromTranscript(
        transcript, 
        'conv-1', 
        referenceDate: referenceDate
      );

      expect(items.length, 1);
      final item = items.first;
      expect(item.timeframeRaw, 'in two weeks');
      // 2 weeks from Oct 10 is Oct 24
      expect(item.dueDate, DateTime(2023, 10, 24, 10, 0));
    });

    test('extracts "in 3 days"', () {
      const transcript = "Come back in 3 days.";
      final items = extractor.extractFromTranscript(
        transcript, 
        'conv-1', 
        referenceDate: referenceDate
      );

      expect(items.length, 1);
      final item = items.first;
      expect(item.timeframeRaw, 'in 3 days');
      // 3 days from Oct 10 is Oct 13
      expect(item.dueDate, DateTime(2023, 10, 13, 10, 0));
    });

    test('extracts "next month"', () {
      const transcript = "Come back next month.";
      final items = extractor.extractFromTranscript(
        transcript, 
        'conv-1', 
        referenceDate: referenceDate
      );

      expect(items.length, 1);
      final item = items.first;
      expect(item.timeframeRaw, 'next month');
      // Next month from Oct 10 is Nov 10
      expect(item.dueDate, DateTime(2023, 11, 10, 10, 0));
    });

    test('extracts "by Friday"', () {
      // Oct 10 2023 is a Tuesday. Friday is Oct 13.
      const transcript = "Submit the report by Friday.";
      final items = extractor.extractFromTranscript(
        transcript, 
        'conv-1', 
        referenceDate: referenceDate
      );

      expect(items.length, 1);
      final item = items.first;
      expect(item.timeframeRaw, 'by Friday');
      expect(item.dueDate, DateTime(2023, 10, 13, 10, 0));
    });
    
    test('extracts "within 48 hours"', () {
      const transcript = "Take this within 48 hours.";
      
      final items = extractor.extractFromTranscript(
        transcript, 
        'conv-1', 
        referenceDate: referenceDate
      );

      expect(items.length, 1);
      expect(items.first.timeframeRaw, 'within 48 hours');
      // 48 hours from Oct 10 10:00 is Oct 12 10:00
      expect(items.first.dueDate, DateTime(2023, 10, 12, 10, 0)); 
    });
  });
}
