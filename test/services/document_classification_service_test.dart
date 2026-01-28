import 'package:flutter_test/flutter_test.dart';
import 'package:sehatlocker/models/health_record.dart';
import 'package:sehatlocker/services/document_classification_service.dart';

void main() {
  group('DocumentClassificationService', () {
    test('Empty document returns empty suggestion with 0 confidence', () {
      final suggestion = DocumentClassificationService.suggestCategory('');
      expect(suggestion.category, isNull);
      expect(suggestion.confidence, 0.0);
      expect(suggestion.reasoning, 'Document is empty');
    });

    test('Low confidence text returns null category', () {
      final suggestion = DocumentClassificationService.suggestCategory('This is just some random text with no medical context.');
      expect(suggestion.category, isNull);
      expect(suggestion.confidence, lessThan(0.4));
      expect(suggestion.reasoning, contains('Low confidence'));
    });

    test('Lab Results category detected via keywords', () {
      final text = 'Patient Name: John Doe\nLaboratory Report\nTest: CBC\nHemoglobin: 14.5 g/dL\nWBC: 6.5\nSpecimen: Blood';
      final suggestion = DocumentClassificationService.suggestCategory(text);
      expect(suggestion.category, HealthCategory.labResults);
      expect(suggestion.confidence, greaterThanOrEqualTo(0.4));
      expect(suggestion.reasoning, contains('Matched keywords'));
    });

    test('Lab Results boosted by structured extraction', () {
      // "Hemoglobin 14.5 g/dL" should be extracted by MedicalFieldExtractor
      final text = 'Hemoglobin 14.5 g/dL\nCholesterol 180 mg/dL';
      final suggestion = DocumentClassificationService.suggestCategory(text);
      expect(suggestion.category, HealthCategory.labResults);
      expect(suggestion.reasoning, contains('Detected lab values'));
    });

    test('Prescriptions category detected via keywords', () {
      final text = 'RX: Amoxicillin 500mg\nSig: Take 1 tablet daily\nDispense: 30\nRefills: 0';
      final suggestion = DocumentClassificationService.suggestCategory(text);
      expect(suggestion.category, HealthCategory.prescriptions);
      expect(suggestion.confidence, greaterThanOrEqualTo(0.4));
    });

    test('Prescriptions boosted by structured extraction', () {
      final text = 'Metformin 500mg twice daily';
      final suggestion = DocumentClassificationService.suggestCategory(text);
      expect(suggestion.category, HealthCategory.prescriptions);
      expect(suggestion.reasoning, contains('Detected medications'));
    });

    test('Vaccinations category detected', () {
      final text = 'Immunization Record\nVaccine: COVID-19 Pfizer\nDose: 1\nSite: Left Deltoid';
      final suggestion = DocumentClassificationService.suggestCategory(text);
      expect(suggestion.category, HealthCategory.vaccinations);
      expect(suggestion.confidence, greaterThanOrEqualTo(0.4));
    });

    test('Insurance category detected', () {
      final text = 'Insurance Card\nMember ID: 123456789\nGroup Number: 98765\nPlan: Gold PPO';
      final suggestion = DocumentClassificationService.suggestCategory(text);
      expect(suggestion.category, HealthCategory.insurance);
      expect(suggestion.confidence, greaterThanOrEqualTo(0.4));
    });

    test('Genetic Test Results detected (new keywords)', () {
      final text = 'Genetic Test Report\nGene: BRCA1\nVariant: Pathogenic\nExon 11 deletion';
      final suggestion = DocumentClassificationService.suggestCategory(text);
      expect(suggestion.category, HealthCategory.geneticTestResults);
      expect(suggestion.confidence, greaterThanOrEqualTo(0.4));
    });

    test('Doctor Visit Report detected (new keywords)', () {
      final text = 'Visit Summary\nDiscussion points: Blood pressure control\nNext steps: Increase medication';
      final suggestion = DocumentClassificationService.suggestCategory(text);
      expect(suggestion.category, HealthCategory.doctorVisitReport);
      expect(suggestion.confidence, greaterThanOrEqualTo(0.4));
    });

    test('Imaging Reports detected', () {
      final text = 'Radiology Report\nExam: Chest X-Ray\nFindings: Normal\nImpression: No acute disease';
      final suggestion = DocumentClassificationService.suggestCategory(text);
      expect(suggestion.category, HealthCategory.imagingReports);
    });

    test('Mixed content favors strongest signal', () {
      // Contains "hospital" (medical records) but many "lab" keywords and values
      final text = 'Hospital Name: General Hospital\nLaboratory Report\nGlucose 95 mg/dL\nCreatinine 0.9 mg/dL\nTSH 2.5 uIU/mL';
      final suggestion = DocumentClassificationService.suggestCategory(text);
      expect(suggestion.category, HealthCategory.labResults);
    });

    test('Header analysis boosts score', () {
      final text = 'DISCHARGE SUMMARY\nPatient: Jane Doe\nDate: 2023-01-01...';
      final suggestion = DocumentClassificationService.suggestCategory(text);
      expect(suggestion.category, HealthCategory.medicalRecords);
      expect(suggestion.reasoning, contains('Header match'));
    });

    test('Validation against ReferenceRangeService boosts Lab Results', () {
      // "Hemoglobin" is a known test in ReferenceRangeService
      final text = 'Hemoglobin 13.0 g/dL';
      final suggestion = DocumentClassificationService.suggestCategory(text);
      expect(suggestion.category, HealthCategory.labResults);
      expect(suggestion.reasoning, contains('Validated 1 tests'));
    });

    test('Legacy classifyDocument method returns correct category', () {
      final text = 'Hemoglobin 14.5 g/dL';
      final category = DocumentClassificationService.classifyDocument(text);
      expect(category, HealthCategory.labResults);
    });

    test('Legacy classifyDocument returns other for low confidence', () {
      final text = 'Random non-medical text';
      final category = DocumentClassificationService.classifyDocument(text);
      expect(category, HealthCategory.other);
    });
  });
}
