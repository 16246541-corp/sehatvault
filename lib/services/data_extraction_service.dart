import 'document_classification_service.dart';

/// Service responsible for extracting structured medical data from raw text
/// using regex patterns. This is designed to run after OCR to populate
/// structured fields from medical documents, lab reports, and prescriptions.
class DataExtractionService {
  /// Extracts structured medical data from raw text using regex patterns.
  /// Returns a map compatible with DocumentExtraction's structuredData field.
  static Map<String, dynamic> extractStructuredData(String text) {
    if (text.isEmpty) return {};

    // Normalize text for better matching
    final normalizedText = text.replaceAll(RegExp(r'\s+'), ' ');

    final Map<String, dynamic> structuredData = {
      'documentType': DocumentClassificationService.classifyDocument(text).name,
      'dates': _extractDates(normalizedText),
      'lab_values': _extractLabValues(normalizedText),
      'medications': _extractMedications(normalizedText),
      'vitals': _extractVitals(normalizedText),
      'summary': _generateSummary(normalizedText),
    };

    return structuredData;
  }

  /// Extracts dates in various formats.
  static List<String> _extractDates(String text) {
    final List<String> dates = [];
    final datePatterns = [
      // DD/MM/YYYY or MM/DD/YYYY or DD-MM-YYYY
      RegExp(r'\b\d{1,2}[/-]\d{1,2}[/-]\d{2,4}\b'),
      // YYYY-MM-DD
      RegExp(r'\b\d{4}-\d{2}-\d{2}\b'),
      // 12 Jan 2023 or January 12, 2023
      RegExp(
          r'\b\d{1,2}\s+(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+\d{2,4}\b',
          caseSensitive: false),
      RegExp(
          r'\b(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+\d{1,2},?\s+\d{2,4}\b',
          caseSensitive: false),
    ];

    for (var pattern in datePatterns) {
      dates.addAll(pattern.allMatches(text).map((m) => m.group(0)!));
    }

    // De-duplicate and return
    return dates.toSet().toList();
  }

  /// Extracts lab values like "Hemoglobin: 14.5 g/dL" or "Glucose 95 mg/dL"
  /// Also extracts patient information and reference data from lab reports
  static List<Map<String, String>> _extractLabValues(String text) {
    final List<Map<String, String>> results = [];

    // Pattern: Field name, optional separator, numeric value, optional units
    // We look for name (3-25 chars) followed by number and common medical units
    final labRegex = RegExp(
      r'([a-zA-Z\s]{3,25})[:\s]+(\d+(?:\.\d+)?)\s*([a-zA-Z/%/u]{1,10})?',
      caseSensitive: false,
    );

    // Extract patient information fields
    final patientInfoRegex = RegExp(
      r'(Name|Patient Name|Patient)[:\s]+([a-zA-Z\s]+?)(?=\n|Sex|Age|Ref|$)',
      caseSensitive: false,
    );

    final passportRegex = RegExp(
      r'(Passport No|Passport|ID)[:\s]+([a-zA-Z0-9\s]+?)(?=\n|Patient|Name|Ref|$)',
      caseSensitive: false,
    );

    final refIdRegex = RegExp(
      r'(Ref\.?\s*Id|Ref\.?\s*By|Reference)[:\s]+([a-zA-Z0-9\s-]+?)(?=\n|Patient|Name|Date|$)',
      caseSensitive: false,
    );

    final commonLabTerms = [
      'glucose',
      'hemoglobin',
      'hba1c',
      'cholesterol',
      'ldl',
      'hdl',
      'triglycerides',
      'creatinine',
      'urea',
      'bilirubin',
      'albumin',
      'protein',
      'sodium',
      'potassium',
      'chloride',
      'calcium',
      'wbc',
      'rbc',
      'platelets',
      'tsh',
      't3',
      't4',
      'vitamin',
      'iron'
    ];

    final commonUnits = [
      'g/dl',
      'mg/dl',
      'mmol/l',
      '%',
      'u/l',
      'mcg',
      'ml',
      'kg',
      'iu',
      'mEq/L'
    ];

    // Extract patient information
    for (var match in patientInfoRegex.allMatches(text)) {
      final field = match.group(1)!;
      final value = match.group(2)!.trim();
      if (value.isNotEmpty) {
        results.add({
          'field': field,
          'value': value,
          'unit': '',
        });
      }
    }

    // Extract passport information
    for (var match in passportRegex.allMatches(text)) {
      final field = match.group(1)!;
      final value = match.group(2)!.trim();
      if (value.isNotEmpty) {
        results.add({
          'field': field,
          'value': value,
          'unit': '',
        });
      }
    }

    // Extract reference ID information
    for (var match in refIdRegex.allMatches(text)) {
      final field = match.group(1)!;
      final value = match.group(2)!.trim();
      if (value.isNotEmpty) {
        results.add({
          'field': field,
          'value': value,
          'unit': '',
        });
      }
    }

    // Extract traditional lab values
    for (var match in labRegex.allMatches(text)) {
      final field = match.group(1)!.trim();
      final value = match.group(2)!;
      final unit = match.group(3)?.trim() ?? '';

      // Validate if it looks like a lab result:
      // 1. Contains a known medical term
      // 2. OR has a known medical unit
      final isMedicalTerm =
          commonLabTerms.any((term) => field.toLowerCase().contains(term));
      final hasUnit = unit.isNotEmpty &&
          commonUnits.any((u) => unit.toLowerCase().contains(u.toLowerCase()));

      if (isMedicalTerm || hasUnit) {
        results.add({
          'field': field,
          'value': value,
          'unit': unit,
        });
      }
    }

    return results;
  }

  /// Extracts medications and dosages.
  static List<Map<String, String>> _extractMedications(String text) {
    final List<Map<String, String>> medications = [];

    // Pattern: Drug name followed by dosage (number + unit)
    // e.g., "Metformin 500mg", "Amoxicillin 250 mg", "Insulin 10 units"
    final medRegex = RegExp(
      r'\b([a-zA-Z]{4,25})\s+(\d+\s*(?:mg|mcg|g|ml|tab|caps|units|pills))\b',
      caseSensitive: false,
    );

    for (var match in medRegex.allMatches(text)) {
      final name = match.group(1)!.trim();
      final dosage = match.group(2)!.trim();

      // Basic filtration to avoid catching normal words as meds
      // (This could be improved with a drug database)
      final commonWords = [
        'time',
        'date',
        'test',
        'result',
        'page',
        'phone',
        'name'
      ];
      if (!commonWords.contains(name.toLowerCase())) {
        medications.add({
          'name': name,
          'dosage': dosage,
        });
      }
    }

    return medications;
  }

  /// Extracts vitals like BP, Heart Rate, Temperature.
  static List<Map<String, String>> _extractVitals(String text) {
    final List<Map<String, String>> vitals = [];

    // BP: 120/80
    final bpRegex = RegExp(r'\b(BP|Blood Pressure)[:\s]*(\d{2,3}/\d{2,3})\b',
        caseSensitive: false);
    for (var match in bpRegex.allMatches(text)) {
      vitals.add({'name': 'Blood Pressure', 'value': match.group(2)!});
    }

    // HR/Pulse: 72 bpm
    final hrRegex = RegExp(
        r'\b(HR|Pulse|Heart Rate)[:\s]*(\d{2,3})\s*(?:bpm)?\b',
        caseSensitive: false);
    for (var match in hrRegex.allMatches(text)) {
      vitals
          .add({'name': 'Heart Rate', 'value': match.group(2)!, 'unit': 'bpm'});
    }

    // Temp: 98.6 F or 37 C or 98.6
    final tempRegex = RegExp(
        r'\b(?:Temp|Temperature)[:\s]*(\d{2,3}(?:\.\d+)?)\s*([FC])\b',
        caseSensitive: false);
    for (var match in tempRegex.allMatches(text)) {
      vitals.add({
        'name': 'Temperature',
        'value': match.group(1)!,
        'unit': match.group(2)!
      });
    }

    return vitals;
  }

  /// Generates a comprehensive summary of key medical information
  static String? _generateSummary(String text) {
    if (text.isEmpty) return null;

    // Extract key entities for summary
    final patientName = _extractPatientName(text);
    final labName = _extractLabName(text);
    final date = _extractFirstDate(text);
    final documentType = _identifyDocumentType(text);

    final summaryParts = <String>[];

    if (documentType.isNotEmpty) {
      summaryParts.add(documentType);
    }

    if (labName.isNotEmpty) {
      summaryParts.add(labName);
    }

    if (patientName.isNotEmpty) {
      summaryParts.add('Patient: $patientName');
    }

    if (date.isNotEmpty) {
      summaryParts.add('Date: $date');
    }

    // If we have a good structured summary, use it
    if (summaryParts.length > 1) {
      return summaryParts.join(' | ');
    }

    // Fallback to first 200 chars if no structured data
    if (text.length > 200) {
      return '${text.substring(0, 197)}...';
    }
    return text;
  }

  static String _extractPatientName(String text) {
    final nameRegex = RegExp(
      r'(Name|Patient Name|Patient)[:\s]+([a-zA-Z\s]+?)(?=\n|Sex|Age|Ref|$)',
      caseSensitive: false,
    );
    final match = nameRegex.firstMatch(text);
    return match?.group(2)?.trim() ?? '';
  }

  static String _extractLabName(String text) {
    final labRegex = RegExp(
      r'(ACCURIS|Lab|Laboratory|Pathology)[\s]*([a-zA-Z\s]*)',
      caseSensitive: false,
    );
    final match = labRegex.firstMatch(text);
    if (match != null) {
      final labPart = match.group(0)?.trim() ?? '';
      if (labPart.length > 3 && labPart.length < 50) {
        return labPart;
      }
    }
    return '';
  }

  static String _extractFirstDate(String text) {
    final datePatterns = [
      RegExp(r'\b\d{1,2}[/-]\d{1,2}[/-]\d{2,4}\b'),
      RegExp(r'\b\d{4}-\d{2}-\d{2}\b'),
      RegExp(
          r'\b\d{1,2}\s+(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+\d{2,4}\b',
          caseSensitive: false),
      RegExp(
          r'\b(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+\d{1,2},?\s+\d{2,4}\b',
          caseSensitive: false),
      RegExp(
          r'\b\d{1,2}-(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*-\d{2,4}\b',
          caseSensitive: false),
    ];

    for (var pattern in datePatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(0)!;
      }
    }
    return '';
  }

  static String _identifyDocumentType(String text) {
    final lowerText = text.toLowerCase();

    if (lowerText.contains('pathology') && lowerText.contains('lab')) {
      return 'Pathology Lab Report';
    } else if (lowerText.contains('lab') && lowerText.contains('result')) {
      return 'Lab Results';
    } else if (lowerText.contains('prescription') || lowerText.contains('rx')) {
      return 'Prescription';
    } else if (lowerText.contains('vaccination') ||
        lowerText.contains('immunization')) {
      return 'Vaccination Record';
    } else if (lowerText.contains('discharge') ||
        lowerText.contains('hospital')) {
      return 'Hospital Discharge';
    } else if (lowerText.contains('medical record') ||
        lowerText.contains('patient record')) {
      return 'Medical Record';
    }

    return 'Medical Document';
  }
}
