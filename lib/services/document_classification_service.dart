import '../models/health_record.dart';

/// Service responsible for classifying medical documents into categories
/// based on keyword matching.
class DocumentClassificationService {
  /// Classifies the document text into a HealthCategory.
  static HealthCategory classifyDocument(String text) {
    if (text.isEmpty) return HealthCategory.other;

    final lowerText = text.toLowerCase();

    // Calculate scores for each category
    final scores = <HealthCategory, int>{
      HealthCategory.labResults: _calculateScore(lowerText, _labKeywords),
      HealthCategory.prescriptions:
          _calculateScore(lowerText, _prescriptionKeywords),
      HealthCategory.vaccinations:
          _calculateScore(lowerText, _vaccinationKeywords),
      HealthCategory.insurance: _calculateScore(lowerText, _insuranceKeywords),
      HealthCategory.medicalRecords:
          _calculateScore(lowerText, _medicalRecordKeywords),
    };

    // Find the category with the highest score
    var bestCategory = HealthCategory.other;
    var maxScore = 0;

    scores.forEach((category, score) {
      if (score > maxScore) {
        maxScore = score;
        bestCategory = category;
      }
    });

    // If scores are too low, default to 'other' (implicitly done)
    // or maybe 'medicalRecords' if it has some generic medical terms?
    // For now, simple max score wins.

    // Heuristic: specific beats generic.
    // If Lab and Medical Record are close, Lab is usually what we want if it has lab keywords.
    // The scoring should naturally handle this if keywords are chosen well.

    return bestCategory;
  }

  static int _calculateScore(String text, List<String> keywords) {
    int score = 0;
    for (var keyword in keywords) {
      // Simple containment check. Could be improved with regex for word boundaries
      // to avoid partial matches (e.g. "table" matching "tablet"), but
      // medical terms are usually distinct enough.
      // Using RegExp with word boundaries for better accuracy:
      final regex = RegExp(r'\b' + RegExp.escape(keyword) + r'\b');
      if (text.contains(keyword)) {
        // Fast check
        score += regex.allMatches(text).length;
      }
    }
    return score;
  }

  // Keywords definitions
  static const _labKeywords = [
    'laboratory',
    'lab report',
    'test result',
    'reference range',
    'analyte',
    'specimen',
    'collection date',
    'pathology',
    'pathology lab',
    'hematology',
    'chemistry',
    'urinalysis',
    'microbiology',
    'assay',
    'units',
    'flag',
    'abnormal',
    'hemoglobin',
    'glucose',
    'cholesterol',
    'tsh',
    'creatinine',
    'cbc',
    'lipid panel',
    'metabolic panel',
    'liver function',
    'culture',
    'sensitivity',
    'patient information',
    'ref. id',
    'ref by',
    'passport no',
    'sexage',
    'accutis',
    'sterling',
    'mc-2202'
  ];

  static const _prescriptionKeywords = [
    'rx',
    'prescription',
    'prescribed',
    'sig',
    'dispense',
    'refill',
    'tablet',
    'capsule',
    'take daily',
    'take by mouth',
    'substitute',
    'pharmacy',
    'pharmacist',
    'drug',
    'medication',
    'dosage',
    'frequency',
    'route',
    'mg',
    'ml',
    'pills',
    'provider',
    'dea'
  ];

  static const _vaccinationKeywords = [
    'immunization',
    'vaccine',
    'vaccination',
    'dose',
    'lot number',
    'manufacturer',
    'site',
    'route',
    'covid-19',
    'influenza',
    'flu',
    'hepatitis',
    'tetanus',
    'tdap',
    'mmr',
    'varicella',
    'pneumococcal',
    'booster',
    'clinic',
    'administered'
  ];

  static const _insuranceKeywords = [
    'insurance',
    'policy',
    'member id',
    'group number',
    'plan',
    'coverage',
    'claim',
    'benefits',
    'eligibility',
    'deductible',
    'copay',
    'coinsurance',
    'payer',
    'provider network',
    'enrollment',
    'beneficiary',
    'subscriber'
  ];

  static const _medicalRecordKeywords = [
    'hospital',
    'discharge',
    'summary',
    'diagnosis',
    'history',
    'examination',
    'chief complaint',
    'assessment',
    'plan',
    'progress note',
    'clinical',
    'physician',
    'doctor',
    'patient',
    'medical center',
    'clinic',
    'visit',
    'symptoms',
    'treatment',
    'consultation',
    'referral',
    'radiology',
    'imaging'
  ];
}
