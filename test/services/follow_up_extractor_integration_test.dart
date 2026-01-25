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

  final DateTime referenceDate = DateTime(2026, 1, 24, 10, 0);

  setUp(() {
    verbConfig = VerbMappingConfiguration.forTesting({
      'take': FollowUpCategory.medication,
      'schedule': FollowUpCategory.appointment,
      'track': FollowUpCategory.monitoring,
      'watch': FollowUpCategory.warning,
      'consider': FollowUpCategory.decision,
      'exercise': FollowUpCategory.lifestyle,
      'set': FollowUpCategory.appointment,
    });

    temporalConfig = TemporalPhrasePatternsConfiguration.forTesting({
      'deadline': [
        r'\bwithin\s+(?:one|two|three|four|five|six|seven|eight|nine|ten|\d+)\s+(?:hour|day|week|month|year)s?\b',
        r'\bnext\s+(?:visit|week|month|year)\b',
      ],
      'frequency': [
        r'\bdaily\b',
        r'\bevery\s+morning\b',
        r'\bthree\s+times\s+weekly\b',
      ],
    });

    dictionaryService = MedicalDictionaryService.forTesting({
      'medications': [
        {'canonical_name': 'Metformin', 'aliases': []},
        {'canonical_name': 'Aspirin', 'aliases': []},
      ],
      'tests': [
        {'canonical_name': 'lipid panel', 'aliases': []},
        {
          'canonical_name': 'blood pressure',
          'aliases': ['bp']
        },
        {'canonical_name': 'MRI', 'aliases': []},
      ],
      'body_parts': ['chest', 'heart'],
      'specialists': ['Cardiologist', 'Dr. Smith'],
      'procedures': ['surgical options'],
    });

    extractor = FollowUpExtractor(
      verbConfig: verbConfig,
      temporalConfig: temporalConfig,
      dictionaryService: dictionaryService,
    );
  });

  group('FollowUpExtractor Integration Tests', () {
    const testTranscript =
        "Doctor: You should start taking Metformin 500mg daily. "
        "Also schedule a lipid panel test within two weeks. "
        "Track your blood pressure every morning. "
        "Be aware of any chest pain symptoms. "
        "Consider discussing surgical options next visit. "
        "Exercise at least 30 minutes three times weekly. "
        "Set a follow-up appointment with Dr. Smith.";

    test('Comprehensive extraction of all categories', () {
      final items = extractor.extractFromTranscript(
          testTranscript, 'test-conv-id',
          referenceDate: referenceDate);

      expect(items.length, 7, reason: 'Should extract 7 items');

      final medication =
          items.firstWhere((i) => i.category == FollowUpCategory.medication);
      expect(medication.object, contains('Metformin'));
      expect(
          ['start', 'take', 'taking'], contains(medication.verb.toLowerCase()));
      expect(medication.frequency, 'daily');

      final testItem =
          items.firstWhere((i) => i.category == FollowUpCategory.test);
      expect(testItem.verb.toLowerCase(), 'schedule');
      expect(testItem.object, contains('lipid panel'));
      expect(testItem.timeframeRaw, 'within two weeks');

      final monitoring =
          items.firstWhere((i) => i.category == FollowUpCategory.monitoring);
      expect(monitoring.verb.toLowerCase(), 'track');
      expect(monitoring.object, contains('blood pressure'));
      expect(monitoring.frequency, 'every morning');

      final warning =
          items.firstWhere((i) => i.category == FollowUpCategory.warning);
      expect([
        'prevent',
        'protect',
        'avoid',
        'watch for',
        'look out for',
        'be aware of'
      ], contains(warning.verb.toLowerCase()));
      expect(warning.object, contains('chest pain'));

      final decision =
          items.firstWhere((i) => i.category == FollowUpCategory.decision);
      expect(decision.verb.toLowerCase(), contains('consider'));
      expect(decision.description, contains('surgical options'));
      expect(decision.timeframeRaw, contains('next visit'));

      final lifestyle =
          items.firstWhere((i) => i.category == FollowUpCategory.lifestyle);
      expect(lifestyle.verb.toLowerCase(), contains('exercise'));
      expect(lifestyle.description, contains('30 minutes'));
      expect(lifestyle.frequency, 'three times weekly');

      final appointment =
          items.firstWhere((i) => i.category == FollowUpCategory.appointment);
      expect(appointment.verb.toLowerCase(), contains('set'));
      expect(['dr. smith', 'follow-up'],
          contains(appointment.object?.toLowerCase()));
    });

    test('Handles poor audio quality markers and interruptions', () {
      const poorAudioTranscript =
          "Doctor: You need to [unintelligible] take Aspirin daily. "
          "Also um schedule [cough] an MRI scan.";

      final items = extractor.extractFromTranscript(
          poorAudioTranscript, 'conv-noisy',
          referenceDate: referenceDate);

      expect(items.length, greaterThanOrEqualTo(2));

      final med =
          items.firstWhere((i) => i.category == FollowUpCategory.medication);
      expect(med.object, contains('Aspirin'));

      final test = items.firstWhere((i) => i.category == FollowUpCategory.test);
      expect(test.object, contains('MRI'));
    });
  });
}
