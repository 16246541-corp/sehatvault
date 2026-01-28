import 'package:flutter_test/flutter_test.dart';
import 'package:sehatlocker/services/vault_service.dart';

void main() {
  group('healthRecordFromStorageMap', () {
    test('normalizes metadata to a string-keyed map', () {
      final record = healthRecordFromStorageMap({
        'id': '1',
        'title': 'T',
        'category': 'C',
        'createdAt': DateTime(2026, 1, 1).toIso8601String(),
        'updatedAt': null,
        'filePath': null,
        'notes': null,
        'metadata': <dynamic, dynamic>{'confidenceScore': 0.9, 1: 'one'},
        'recordType': null,
        'extractionId': null,
      });

      expect(record.metadata, isNotNull);
      expect(record.metadata!['confidenceScore'], equals(0.9));
      expect(record.metadata!['1'], equals('one'));
    });

    test('returns null metadata when metadata is not a map', () {
      final record = healthRecordFromStorageMap({
        'id': '1',
        'title': 'T',
        'category': 'C',
        'createdAt': DateTime(2026, 1, 1).toIso8601String(),
        'updatedAt': null,
        'filePath': null,
        'notes': null,
        'metadata': 'oops',
        'recordType': null,
        'extractionId': null,
      });

      expect(record.metadata, isNull);
    });
  });
}

