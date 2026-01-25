import 'package:flutter_test/flutter_test.dart';
import 'package:sehatlocker/services/citation_service.dart';
import 'package:sehatlocker/services/local_storage_service.dart';
import 'package:sehatlocker/services/safety_filter_service.dart';
import 'package:sehatlocker/services/analytics_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sehatlocker/models/citation.dart';
import 'package:mockito/mockito.dart';

class FakeLocalStorageService extends Fake implements LocalStorageService {
  @override
  Box<Citation> get citationsBox => FakeBox<Citation>();
}

class FakeBox<T> extends Fake implements Box<T> {
  @override
  Future<void> put(dynamic key, T value) async {}

  @override
  Iterable<T> get values => [];
}

class FakeSafetyFilterService extends Fake implements SafetyFilterService {
  @override
  String sanitize(String content) => content;
}

class FakeAnalyticsService extends Fake implements AnalyticsService {
  @override
  Future<void> logMetric(String name, double value) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CitationService Tests', () {
    late CitationService citationService;
    late FakeLocalStorageService fakeStorage;
    late FakeSafetyFilterService fakeSafety;
    late FakeAnalyticsService fakeAnalytics;

    setUp(() {
      fakeStorage = FakeLocalStorageService();
      fakeSafety = FakeSafetyFilterService();
      fakeAnalytics = FakeAnalyticsService();
      citationService = CitationService(
        fakeStorage,
        safetyFilter: fakeSafety,
        analyticsService: fakeAnalytics,
      );
    });

    test('detects HbA1c factual claim and matches source', () {
      const text = "Your HbA1c level of 6.5% indicates a potential diagnosis.";
      final citations = citationService.generateCitationsFromText(text);

      expect(citations, isNotEmpty);
      final hba1cCitation =
          citations.firstWhere((c) => c.sourceTitle.contains('Diabetes'));
      expect(hba1cCitation.confidenceScore, greaterThanOrEqualTo(0.95));
      expect(hba1cCitation.publication, equals('Diabetes Care'));
    });

    test('detects blood pressure claim', () {
      const text = "A normal blood pressure is usually below 120/80 mmHg.";
      final citations = citationService.generateCitationsFromText(text);

      expect(citations, isNotEmpty);
      expect(citations.any((c) => c.sourceTitle.contains('AHA')), isTrue);
    });

    test('handles empty text gracefully', () {
      final citations = citationService.generateCitationsFromText("");
      expect(citations, isEmpty);
    });

    test('confidence score is higher for reviewed sources', () {
      const text = "HbA1c of 6.5";
      final citations = citationService.generateCitationsFromText(text);

      for (final citation in citations) {
        // ADA source is reviewed in our mock KB
        expect(citation.confidenceScore, greaterThan(0.90));
      }
    });

    test('deduplicates citations from the same source', () {
      const text = "HbA1c 6.5 and fasting glucose 126";
      final citations = citationService.generateCitationsFromText(text);

      // Both claims point to ADA guidelines
      final adaCitations =
          citations.where((c) => c.sourceTitle.contains('Diabetes')).toList();
      expect(adaCitations.length, equals(1));
    });
  });
}
