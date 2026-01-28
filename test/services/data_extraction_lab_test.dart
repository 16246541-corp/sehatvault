import 'package:flutter_test/flutter_test.dart';
import 'package:sehatlocker/services/data_extraction_service.dart';

void main() {
  group('DataExtractionService Lab Report Tests', () {
    test('extracts pathology lab report data correctly', () {
      final labText = '''
sterling ACCURIS MC-2202 Pathology lab that cares 
Passport No : 
Patient Information 
Name : Lyubochka Svetka 
SexAge : Male 41 Y 
Ref. Id Ref. By 01-Feb-1982 
Sca
''';

      final result = DataExtractionService.extractStructuredData(labText);

      expect(result['documentType'], equals('labResults'));
      expect(result['summary'], contains('Pathology Lab Report'));
      expect(result['summary'], contains('Patient: Lyubochka Svetka'));
      expect(result['summary'], contains('Patient: Lyubochka Svetka'));

      final labValues = result['lab_values'] as List<Map<String, String>>;
      expect(labValues.length, greaterThan(0));

      // Check for patient name
      final nameEntry = labValues.firstWhere(
        (entry) => entry['field']?.toLowerCase().contains('name') ?? false,
        orElse: () => {'field': '', 'value': '', 'unit': ''},
      );
      expect(nameEntry['value'], equals('Lyubochka Svetka'));

      // Check for passport info
      final passportEntry = labValues.firstWhere(
        (entry) => entry['field']?.toLowerCase().contains('passport') ?? false,
        orElse: () => {'field': '', 'value': '', 'unit': ''},
      );
      expect(passportEntry['field'], contains('Passport'));
    });

    test('extracts traditional lab values', () {
      final labText = '''
Lab Report
Hemoglobin: 13.8 g/dL
Glucose: 95 mg/dL
WBC: 7.2 K/uL
''';

      final result = DataExtractionService.extractStructuredData(labText);
      final labValues = result['lab_values'] as List<Map<String, String>>;

      expect(labValues.length, equals(3));

      final hemoglobin = labValues.firstWhere(
        (entry) =>
            entry['field']?.toLowerCase().contains('hemoglobin') ?? false,
      );
      expect(hemoglobin['value'], equals('13.8'));
      expect(hemoglobin['unit'], equals('g/dL'));

      final glucose = labValues.firstWhere(
        (entry) => entry['field']?.toLowerCase().contains('glucose') ?? false,
      );
      expect(glucose['value'], equals('95'));
      expect(glucose['unit'], equals('mg/dL'));
    });
  });
}
