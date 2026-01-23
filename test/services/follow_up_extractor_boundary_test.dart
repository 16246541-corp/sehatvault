import 'package:flutter_test/flutter_test.dart';
import 'package:sehatlocker/models/doctor_conversation.dart';
import 'package:sehatlocker/models/follow_up_item.dart';
import 'package:sehatlocker/services/follow_up_extractor.dart';
import 'package:sehatlocker/services/verb_mapping_configuration.dart';
import 'package:sehatlocker/services/temporal_phrase_patterns_configuration.dart';

// Reuse mocks from the existing test
class MockVerbMappingConfiguration extends VerbMappingConfiguration {
  MockVerbMappingConfiguration() : super.forTesting();

  @override
  bool get isLoaded => true;

  @override
  List<String> get allVerbs => ['take', 'schedule'];

  @override
  FollowUpCategory? getCategoryForVerb(String verb) {
    if (verb == 'take') return FollowUpCategory.medication;
    if (verb == 'schedule') return FollowUpCategory.appointment;
    return null;
  }
}

class MockTemporalPhrasePatternsConfiguration extends TemporalPhrasePatternsConfiguration {
  MockTemporalPhrasePatternsConfiguration() : super.forTesting();
  @override
  bool get isLoaded => true;
  @override
  List<String> get deadlinePatterns => [];
  @override
  List<String> get frequencyPatterns => [];
}

void main() {
  group('FollowUpExtractor Boundary Detection', () {
    late FollowUpExtractor extractor;
    late MockVerbMappingConfiguration mockVerbConfig;
    late MockTemporalPhrasePatternsConfiguration mockTemporalConfig;

    setUp(() {
      mockVerbConfig = MockVerbMappingConfiguration();
      mockTemporalConfig = MockTemporalPhrasePatternsConfiguration();
      extractor = FollowUpExtractor(
        verbConfig: mockVerbConfig,
        temporalConfig: mockTemporalConfig,
      );
    });

    test('splits sentences using punctuation within segments', () {
      final segments = [
        ConversationSegment(
          text: "Take medicine.",
          startTimeMs: 0,
          endTimeMs: 1000,
          speaker: "Doctor",
        ),
        ConversationSegment(
          text: "Schedule appointment.",
          startTimeMs: 1100, // Small gap
          endTimeMs: 2000,
          speaker: "Doctor",
        ),
      ];

      final items = extractor.extractFromTranscript("", "id", segments: segments);
      expect(items.length, 2);
      expect(items[0].verb, "take");
      expect(items[1].verb, "schedule");
    });

    test('splits sentences using silence gap > 1000ms', () {
      final segments = [
        ConversationSegment(
          text: "Take medicine", // No punctuation
          startTimeMs: 0,
          endTimeMs: 1000,
          speaker: "Doctor",
        ),
        ConversationSegment(
          text: "Schedule appointment",
          startTimeMs: 2500, // 1500ms gap
          endTimeMs: 3500,
          speaker: "Doctor",
        ),
      ];

      final items = extractor.extractFromTranscript("", "id", segments: segments);
      expect(items.length, 2);
      expect(items[0].verb, "take");
      expect(items[1].verb, "schedule");
    });

    test('does not split if silence gap is small', () {
       final segments = [
        ConversationSegment(
          text: "Take", 
          startTimeMs: 0,
          endTimeMs: 500,
          speaker: "Doctor",
        ),
        ConversationSegment(
          text: "medicine",
          startTimeMs: 600, // 100ms gap
          endTimeMs: 1000,
          speaker: "Doctor",
        ),
      ];

      final items = extractor.extractFromTranscript("", "id", segments: segments);
      expect(items.length, 1);
      expect(items[0].verb, "take");
      expect(items[0].object, "medicine");
    });

    test('splits sentences on speaker change', () {
      final segments = [
        ConversationSegment(
          text: "Take medicine", 
          startTimeMs: 0,
          endTimeMs: 1000,
          speaker: "Doctor",
        ),
        ConversationSegment(
          text: "Schedule appointment", 
          startTimeMs: 1100, 
          endTimeMs: 2000,
          speaker: "User",
        ),
      ];

      final items = extractor.extractFromTranscript("", "id", segments: segments);
      expect(items.length, 2);
    });
  });
}
