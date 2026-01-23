import 'package:flutter_test/flutter_test.dart';
import 'package:sehatlocker/services/medical_field_extractor.dart';

void main() {
  group('MedicalFieldExtractor', () {
    group('extractLabValues', () {
      test('should extract simple lab values with units', () {
        const text = 'Hemoglobin: 13.5 g/dL\nGlucose 95 mg/dL';
        final result = MedicalFieldExtractor.extractLabValues(text);

        expect(result['count'], 2);
        final values = result['values'] as List;
        
        expect(values[0]['field'], 'Hemoglobin');
        expect(values[0]['value'], '13.5');
        expect(values[0]['unit'], 'g/dL');
        
        expect(values[1]['field'], 'Glucose');
        expect(values[1]['value'], '95');
        expect(values[1]['unit'], 'mg/dL');
      });

      test('should categorize lab values correctly', () {
        const text = 'Hemoglobin 14.0 g/dL\nGlucose 100 mg/dL\nTSH 2.5 mIU/L';
        final result = MedicalFieldExtractor.extractLabValues(text);
        final categories = result['categories'] as Map<String, dynamic>;

        expect(categories['blood']!.length, 1); // Hemoglobin
        expect(categories['metabolic']!.length, 1); // Glucose
        expect(categories['thyroid']!.length, 1); // TSH
      });

      test('should handle variations in separators', () {
        const text = 'Hb:12.5 g/dL\nWBC  6.5 x10^3/uL';
        final result = MedicalFieldExtractor.extractLabValues(text);
        
        expect(result['count'], 2);
        final values = result['values'] as List;
        expect(values[0]['field'], 'Hb');
        expect(values[0]['value'], '12.5');
        
        expect(values[1]['field'], 'WBC');
        expect(values[1]['value'], '6.5');
      });

      test('should return empty result for empty input', () {
        final result = MedicalFieldExtractor.extractLabValues('');
        expect(result['count'], 0);
        expect(result['values'], isEmpty);
      });
    });

    group('extractMedications', () {
      test('should extract medications with dosages and frequencies', () {
        const text = 'Metformin 500mg twice daily\nLisinopril 10 mg once daily';
        final result = MedicalFieldExtractor.extractMedications(text);

        expect(result['count'], 2);
        final meds = result['medications'] as List;

        expect(meds[0]['name'], 'Metformin');
        expect(meds[0]['dosage'], '500 mg');
        expect(meds[0]['frequency'], 'twice daily');

        expect(meds[1]['name'], 'Lisinopril');
        expect(meds[1]['dosage'], '10 mg');
        expect(meds[1]['frequency'], 'once daily');
      });

      test('should filter out common excluded words', () {
        const text = 'Patient 12345\nReport Date\nAmoxicillin 250 mg';
        final result = MedicalFieldExtractor.extractMedications(text);

        expect(result['count'], 1);
        final meds = result['medications'] as List;
        expect(meds[0]['name'], 'Amoxicillin');
      });

      test('should collect unique dosage units', () {
        const text = 'DrugA 10mg\nDrugB 5 ml\nDrugC 20mg';
        final result = MedicalFieldExtractor.extractMedications(text);
        final units = result['dosageUnits'] as List;

        expect(units, containsAll(['mg', 'ml']));
        expect(units.length, 2);
      });
    });

    group('extractDates', () {
      test('should extract dates in various formats', () {
        const text = 'Report Date: 12/05/2023\nDOB: 15 Jan 1980\nVisit: 2023-06-20';
        final result = MedicalFieldExtractor.extractDates(text);

        expect(result['count'], 3);
        final dates = result['dates'] as List;
        final formats = result['formats'] as List;

        expect(dates.any((d) => d['value'] == '12/05/2023'), isTrue);
        expect(dates.any((d) => d['value'] == '15 Jan 1980'), isTrue);
        expect(dates.any((d) => d['value'] == '2023-06-20'), isTrue);
        
        expect(formats, containsAll(['numeric_slash', 'day_month_year', 'iso_date']));
      });

      test('should deduplicate identical dates', () {
        const text = 'Date: 2023-01-01\nAnother mention of 2023-01-01';
        final result = MedicalFieldExtractor.extractDates(text);

        expect(result['count'], 1);
        final dates = result['dates'] as List;
        expect(dates[0]['value'], '2023-01-01');
      });
    });

    group('extractAll', () {
      test('should aggregate all extractions', () {
        const text = '''
          Patient Report
          Date: 2023-10-15
          
          LAB RESULTS:
          Hemoglobin 13.2 g/dL
          
          MEDICATIONS:
          Aspirin 81 mg daily
        ''';
        
        final result = MedicalFieldExtractor.extractAll(text);
        
        expect(result['labValues']['count'], 1);
        expect(result['medications']['count'], 1);
        expect(result['dates']['count'], 1);
        
        final summary = result['summary'] as Map<String, dynamic>;
        expect(summary['hasData'], isTrue);
        expect(summary['totalLabValues'], 1);
        expect(summary['totalMedications'], 1);
        expect(summary['totalDates'], 1);
      });
    });
  });
}
