import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:hive/hive.dart';
import 'package:sehatlocker/models/document_extraction.dart';
import 'package:sehatlocker/models/metric_snapshot.dart';
import 'package:sehatlocker/models/user_profile.dart';
import 'package:sehatlocker/services/local_storage_service.dart';
import 'package:sehatlocker/services/health_metrics_aggregator.dart';
import 'package:sehatlocker/exceptions/unverified_data_exception.dart';

import 'health_metrics_aggregator_test.mocks.dart';

@GenerateMocks([LocalStorageService])
void main() {
  group('HealthMetricsAggregator', () {
    late HealthMetricsAggregator aggregator;
    late MockLocalStorageService mockStorageService;

    final testUserProfile = UserProfile(
      displayName: 'Test User',
      sex: 'male',
      dateOfBirth: DateTime(1990, 1, 1),
    );

    setUp(() {
      mockStorageService = MockLocalStorageService();
      aggregator = HealthMetricsAggregator(mockStorageService);

      // Setup default mock behavior
      when(mockStorageService.getUserProfile()).thenReturn(testUserProfile);

      // Mock that Phase 1 is complete (has verified documents)
      when(mockStorageService.getDocumentsWithVerifiedExtractions())
          .thenReturn([
        DocumentExtraction(
          originalImagePath: '/test/path',
          extractedText: 'Test document',
          confidenceScore: 0.95,
          structuredData: {},
          userVerifiedAt: DateTime.now(),
        )
      ]);

      // Call checkPhase1Completion to set the internal flag
      aggregator.checkPhase1Completion();
    });

    group('getLatestVerifiedMetric', () {
      test('returns null when no verified documents exist', () async {
        // Arrange - Reset to no verified documents
        when(mockStorageService.getDocumentsWithVerifiedExtractions())
            .thenReturn([]);
        aggregator.checkPhase1Completion(); // Update internal state

        // Act
        final result =
            await aggregator.getLatestVerifiedMetric('ldl_cholesterol');

        // Assert
        expect(result, isNull);
        verify(mockStorageService.getDocumentsWithVerifiedExtractions())
            .called(3); // Setup, checkPhase1Completion, and method call
      });

      test('returns null when metric not found in verified documents',
          () async {
        // Arrange
        final verifiedExtraction = DocumentExtraction(
          originalImagePath: '/test/path',
          extractedText: 'Some text without lab values',
          confidenceScore: 0.95,
          structuredData: {'other_data': 'value'},
          userVerifiedAt: DateTime.now(),
        );

        when(mockStorageService.getDocumentsWithVerifiedExtractions())
            .thenReturn([verifiedExtraction]);

        // Act
        final result =
            await aggregator.getLatestVerifiedMetric('ldl_cholesterol');

        // Assert
        expect(result, isNull);
      });

      test('returns latest verified metric with correct values', () async {
        // Arrange
        final now = DateTime.now();
        final olderExtraction = DocumentExtraction(
          originalImagePath: '/test/path1',
          extractedText: 'LDL 120 mg/dL',
          confidenceScore: 0.95,
          structuredData: {
            'lab_values': [
              {'field': 'ldl_cholesterol', 'value': '120', 'unit': 'mg/dL'}
            ]
          },
          userVerifiedAt: now.subtract(const Duration(days: 1)),
          userCorrectedDocumentDate: now.subtract(const Duration(days: 1)),
        );

        final newerExtraction = DocumentExtraction(
          originalImagePath: '/test/path2',
          extractedText: 'LDL 95 mg/dL',
          confidenceScore: 0.95,
          structuredData: {
            'lab_values': [
              {'field': 'ldl_cholesterol', 'value': '95', 'unit': 'mg/dL'}
            ]
          },
          userVerifiedAt: now,
          userCorrectedDocumentDate: now,
        );

        when(mockStorageService.getDocumentsWithVerifiedExtractions())
            .thenReturn([olderExtraction, newerExtraction]);

        // Mock the health record lookup
        when(mockStorageService.getAllRecords()).thenReturn([
          {
            'id': 'record123',
            'extractionId': newerExtraction.id,
            'title': 'Test Record',
            'category': 'Lab Results',
            'createdAt': now,
          }
        ]);

        // Act
        final result =
            await aggregator.getLatestVerifiedMetric('ldl_cholesterol');

        // Assert
        expect(result, isNotNull);
        expect(result!.metricName, 'ldl_cholesterol');
        expect(result.value, 95.0);
        expect(result.unit, 'mg/dL');
        expect(result.isOutsideReference, isFalse); // 95 is within normal range
        expect(result.sourceRecordId, isNotEmpty);
      });

      test('handles user-corrected document dates correctly', () async {
        // Arrange
        final now = DateTime.now();
        final extraction = DocumentExtraction(
          originalImagePath: '/test/path',
          extractedText: 'LDL 150 mg/dL',
          confidenceScore: 0.95,
          structuredData: {
            'lab_values': [
              {'field': 'ldl_cholesterol', 'value': '150', 'unit': 'mg/dL'}
            ]
          },
          userVerifiedAt: now,
          extractedDocumentDate: now.subtract(const Duration(days: 5)),
          userCorrectedDocumentDate: now.subtract(const Duration(days: 1)),
        );

        when(mockStorageService.getDocumentsWithVerifiedExtractions())
            .thenReturn([extraction]);

        when(mockStorageService.getAllRecords()).thenReturn([
          {
            'id': 'record456',
            'extractionId': extraction.id,
            'title': 'Test Record',
            'category': 'Lab Results',
            'createdAt': now,
          }
        ]);

        // Act
        final result =
            await aggregator.getLatestVerifiedMetric('ldl_cholesterol');

        // Assert
        expect(result, isNotNull);
        expect(
            result!.measuredAt, equals(now.subtract(const Duration(days: 1))));
      });

      test('correctly identifies values outside reference range', () async {
        // Arrange
        final now = DateTime.now();
        final extraction = DocumentExtraction(
          originalImagePath: '/test/path',
          extractedText: 'LDL 160 mg/dL',
          confidenceScore: 0.95,
          structuredData: {
            'lab_values': [
              {'field': 'ldl_cholesterol', 'value': '160', 'unit': 'mg/dL'}
            ]
          },
          userVerifiedAt: now,
        );

        when(mockStorageService.getDocumentsWithVerifiedExtractions())
            .thenReturn([extraction]);

        when(mockStorageService.getAllRecords()).thenReturn([
          {
            'id': 'record789',
            'extractionId': extraction.id,
            'title': 'Test Record',
            'category': 'Lab Results',
            'createdAt': now,
          }
        ]);

        // Act
        final result =
            await aggregator.getLatestVerifiedMetric('ldl_cholesterol');

        // Assert
        expect(result, isNotNull);
        expect(result!.value, 160.0);
        expect(result.isOutsideReference, isTrue); // 160 is above normal range
      });

      test('caches metric snapshots for performance', () async {
        // Arrange
        final now = DateTime.now();
        final extraction = DocumentExtraction(
          originalImagePath: '/test/path',
          extractedText: 'LDL 100 mg/dL',
          confidenceScore: 0.95,
          structuredData: {
            'lab_values': [
              {'field': 'ldl_cholesterol', 'value': '100', 'unit': 'mg/dL'}
            ]
          },
          userVerifiedAt: now,
        );

        when(mockStorageService.getDocumentsWithVerifiedExtractions())
            .thenReturn([extraction]);

        when(mockStorageService.getAllRecords()).thenReturn([
          {
            'id': 'record999',
            'extractionId': extraction.id,
            'title': 'Test Record',
            'category': 'Lab Results',
            'createdAt': now,
          }
        ]);

        // Act
        await aggregator.getLatestVerifiedMetric('ldl_cholesterol');

        // Assert
        verify(mockStorageService.saveMetricSnapshot(any)).called(1);
      });
    });

    group('getAllLatestVerifiedMetrics', () {
      test('returns empty list when no verified documents exist', () async {
        // Arrange - Reset to no verified documents
        when(mockStorageService.getDocumentsWithVerifiedExtractions())
            .thenReturn([]);
        aggregator.checkPhase1Completion(); // Update internal state

        // Act
        final results = await aggregator.getAllLatestVerifiedMetrics();

        // Assert
        expect(results, isEmpty);
      });

      test('returns all unique metrics from verified documents', () async {
        // Arrange
        final now = DateTime.now();
        final extraction = DocumentExtraction(
          originalImagePath: '/test/path',
          extractedText: 'Multiple lab values',
          confidenceScore: 0.95,
          structuredData: {
            'lab_values': [
              {'field': 'ldl_cholesterol', 'value': '100', 'unit': 'mg/dL'},
              {'field': 'hdl_cholesterol', 'value': '45', 'unit': 'mg/dL'},
              {'field': 'total_cholesterol', 'value': '180', 'unit': 'mg/dL'},
            ]
          },
          userVerifiedAt: now,
        );

        when(mockStorageService.getDocumentsWithVerifiedExtractions())
            .thenReturn([extraction]);

        when(mockStorageService.getAllRecords()).thenReturn([
          {
            'id': 'record111',
            'extractionId': extraction.id,
            'title': 'Test Record',
            'category': 'Lab Results',
            'createdAt': now,
          }
        ]);

        // Act
        final results = await aggregator.getAllLatestVerifiedMetrics();

        // Assert
        expect(results.length, 3);
        expect(results.map((s) => s.metricName).toSet(),
            {'ldl_cholesterol', 'hdl_cholesterol', 'total_cholesterol'});
      });

      test('sorts results by measured date (most recent first)', () async {
        // Arrange
        final now = DateTime.now();
        final olderExtraction = DocumentExtraction(
          originalImagePath: '/test/path1',
          extractedText: 'LDL 100 mg/dL',
          confidenceScore: 0.95,
          structuredData: {
            'lab_values': [
              {'field': 'ldl_cholesterol', 'value': '100', 'unit': 'mg/dL'}
            ]
          },
          userVerifiedAt: now.subtract(const Duration(days: 2)),
          userCorrectedDocumentDate: now.subtract(const Duration(days: 2)),
        );

        final newerExtraction = DocumentExtraction(
          originalImagePath: '/test/path2',
          extractedText: 'HDL 50 mg/dL',
          confidenceScore: 0.95,
          structuredData: {
            'lab_values': [
              {'field': 'hdl_cholesterol', 'value': '50', 'unit': 'mg/dL'}
            ]
          },
          userVerifiedAt: now,
          userCorrectedDocumentDate: now,
        );

        when(mockStorageService.getDocumentsWithVerifiedExtractions())
            .thenReturn([olderExtraction, newerExtraction]);

        when(mockStorageService.getAllRecords()).thenReturn([
          {
            'id': 'record222',
            'extractionId': olderExtraction.id,
            'title': 'Test Record 1',
            'category': 'Lab Results',
            'createdAt': now.subtract(const Duration(days: 2)),
          },
          {
            'id': 'record333',
            'extractionId': newerExtraction.id,
            'title': 'Test Record 2',
            'category': 'Lab Results',
            'createdAt': now,
          }
        ]);

        // Act
        final results = await aggregator.getAllLatestVerifiedMetrics();

        // Assert
        expect(results.length, 2);
        expect(results[0].metricName, 'hdl_cholesterol'); // More recent
        expect(results[1].metricName, 'ldl_cholesterol'); // Older
      });
    });

    group('checkPhase1Completion', () {
      test('returns false when no verified documents exist', () {
        // Arrange
        when(mockStorageService.getDocumentsWithVerifiedExtractions())
            .thenReturn([]);

        // Act
        final result = aggregator.checkPhase1Completion();

        // Assert
        expect(result, isFalse);
      });

      test('returns true when verified documents exist', () {
        // Arrange
        final extraction = DocumentExtraction(
          originalImagePath: '/test/path',
          extractedText: 'Test document',
          confidenceScore: 0.95,
          structuredData: {},
          userVerifiedAt: DateTime.now(),
        );

        when(mockStorageService.getDocumentsWithVerifiedExtractions())
            .thenReturn([extraction]);

        // Act
        final result = aggregator.checkPhase1Completion();

        // Assert
        expect(result, isTrue);
      });
    });

    group('Performance requirements', () {
      test('meets performance requirement for 200 verified documents',
          () async {
        // Arrange: Create 200 verified documents with lab values
        final now = DateTime.now();
        final verifiedDocs = <DocumentExtraction>[];
        final healthRecords = <Map<String, dynamic>>[];

        for (int i = 0; i < 200; i++) {
          final extraction = DocumentExtraction(
            originalImagePath: '/test/path$i',
            extractedText: 'LDL ${100 + i} mg/dL',
            confidenceScore: 0.95,
            structuredData: {
              'lab_values': [
                {
                  'field': 'ldl_cholesterol',
                  'value': '${100 + i}',
                  'unit': 'mg/dL'
                }
              ]
            },
            userVerifiedAt: now.subtract(Duration(days: i)),
          );
          verifiedDocs.add(extraction);

          healthRecords.add({
            'id': 'record_perf_$i',
            'extractionId': extraction.id,
            'title': 'Performance Test Record $i',
            'category': 'Lab Results',
            'createdAt': now.subtract(Duration(days: i)),
          });
        }

        when(mockStorageService.getDocumentsWithVerifiedExtractions())
            .thenReturn(verifiedDocs);

        when(mockStorageService.getAllRecords()).thenReturn(healthRecords);

        // Act & Measure performance
        final stopwatch = Stopwatch()..start();
        final result =
            await aggregator.getLatestVerifiedMetric('ldl_cholesterol');
        stopwatch.stop();

        // Assert
        expect(result, isNotNull);
        expect(stopwatch.elapsedMilliseconds,
            lessThan(300)); // Performance requirement
      });
    });

    group('Edge cases and error handling', () {
      test('handles malformed lab values gracefully', () async {
        // Arrange
        final now = DateTime.now();
        final extraction = DocumentExtraction(
          originalImagePath: '/test/path',
          extractedText: 'LDL invalid mg/dL',
          confidenceScore: 0.95,
          structuredData: {
            'lab_values': [
              {'field': 'ldl_cholesterol', 'value': 'invalid', 'unit': 'mg/dL'}
            ]
          },
          userVerifiedAt: now,
        );

        when(mockStorageService.getDocumentsWithVerifiedExtractions())
            .thenReturn([extraction]);

        // Act
        final result =
            await aggregator.getLatestVerifiedMetric('ldl_cholesterol');

        // Assert
        expect(result, isNull); // Should return null for invalid values
      });

      test('handles missing unit information', () async {
        // Arrange
        final now = DateTime.now();
        final extraction = DocumentExtraction(
          originalImagePath: '/test/path',
          extractedText: 'LDL 100',
          confidenceScore: 0.95,
          structuredData: {
            'lab_values': [
              {'field': 'ldl_cholesterol', 'value': '100'} // No unit
            ]
          },
          userVerifiedAt: now,
        );

        when(mockStorageService.getDocumentsWithVerifiedExtractions())
            .thenReturn([extraction]);

        when(mockStorageService.getAllRecords()).thenReturn([
          {
            'id': 'record444',
            'extractionId': extraction.id,
            'title': 'Test Record',
            'category': 'Lab Results',
            'createdAt': now,
          }
        ]);

        // Act
        final result =
            await aggregator.getLatestVerifiedMetric('ldl_cholesterol');

        // Assert
        expect(result, isNotNull);
        expect(result!.unit, isEmpty); // Empty unit when not provided
      });

      test('normalizes metric names correctly', () async {
        // Arrange
        final now = DateTime.now();
        final extraction = DocumentExtraction(
          originalImagePath: '/test/path',
          extractedText: 'LDL-Cholesterol: 100 mg/dL',
          confidenceScore: 0.95,
          structuredData: {
            'lab_values': [
              {'field': 'LDL-Cholesterol', 'value': '100', 'unit': 'mg/dL'}
            ]
          },
          userVerifiedAt: now,
        );

        when(mockStorageService.getDocumentsWithVerifiedExtractions())
            .thenReturn([extraction]);

        when(mockStorageService.getAllRecords()).thenReturn([
          {
            'id': 'record555',
            'extractionId': extraction.id,
            'title': 'Test Record',
            'category': 'Lab Results',
            'createdAt': now,
          }
        ]);

        // Act
        final result =
            await aggregator.getLatestVerifiedMetric('ldl_cholesterol');

        // Assert
        expect(result, isNotNull);
        expect(result!.metricName, 'ldl_cholesterol');
        expect(result.value, 100.0);
      });
    });
  });
}
