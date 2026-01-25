class MedicalKnowledgeSource {
  final String id;
  final String title;
  final String url;
  final String publication;
  final String authors;
  final DateTime date;
  final String type;
  final bool isReviewed;

  const MedicalKnowledgeSource({
    required this.id,
    required this.title,
    required this.url,
    required this.publication,
    required this.authors,
    required this.date,
    required this.type,
    this.isReviewed = false,
  });
}

class MedicalFact {
  final String id;
  final String claim;
  final List<String> patterns;
  final List<String> sourceIds;
  final double confidence;

  const MedicalFact({
    required this.id,
    required this.claim,
    required this.patterns,
    required this.sourceIds,
    required this.confidence,
  });
}

class MedicalKnowledgeBase {
  static final List<MedicalKnowledgeSource> sources = [
    MedicalKnowledgeSource(
      id: 'who_lab_norms',
      title:
          'WHO Laboratory Manual for the Examination and Processing of Human Semen',
      url: 'https://www.who.int/publications/i/item/9789240030787',
      publication: 'World Health Organization',
      authors: 'WHO Department of Sexual and Reproductive Health and Research',
      date: DateTime(2021, 7, 27),
      type: 'guideline',
      isReviewed: true,
    ),
    MedicalKnowledgeSource(
      id: 'ada_standards_2024',
      title: 'Standards of Care in Diabetes—2024',
      url: 'https://diabetesjournals.org/care/issue/47/Supplement_1',
      publication: 'Diabetes Care',
      authors: 'American Diabetes Association Professional Practice Committee',
      date: DateTime(2024, 1, 1),
      type: 'guideline',
      isReviewed: true,
    ),
    MedicalKnowledgeSource(
      id: 'aha_hypertension_2023',
      title: '2023 ACC/AHA Prevention Guideline',
      url: 'https://www.ahajournals.org/doi/10.1161/CIR.0000000000001140',
      publication: 'Circulation',
      authors: 'American Heart Association',
      date: DateTime(2023, 5, 15),
      type: 'guideline',
      isReviewed: true,
    ),
    MedicalKnowledgeSource(
      id: 'mayo_cholesterol',
      title: 'Cholesterol levels: What is normal?',
      url:
          'https://www.mayoclinic.org/tests-procedures/cholesterol-test/about/pac-20384601',
      publication: 'Mayo Clinic',
      authors: 'Mayo Clinic Staff',
      date: DateTime(2023, 1, 11),
      type: 'reference',
      isReviewed: true,
    ),
  ];

  static final List<MedicalFact> facts = [
    MedicalFact(
      id: 'hba1c_diabetes',
      claim:
          'An HbA1c level of 6.5% or higher is a criterion for diagnosing diabetes.',
      patterns: [
        r'HbA1c.*[\d.]+%?',
        r'diagnosing diabetes.*HbA1c',
      ],
      sourceIds: ['ada_standards_2024'],
      confidence: 0.99,
    ),
    MedicalFact(
      id: 'normal_blood_pressure',
      claim:
          'Normal blood pressure for adults is defined as less than 120/80 mmHg.',
      patterns: [
        r'normal blood pressure (?:.*?) [\d/]+',
        r'[\d/]+ mmHg (?:is|considered) normal',
      ],
      sourceIds: ['aha_hypertension_2023'],
      confidence: 0.98,
    ),
    MedicalFact(
      id: 'fasting_glucose_diabetes',
      claim: 'Fasting plasma glucose ≥126 mg/dL is used to diagnose diabetes.',
      patterns: [
        r'fasting (?:plasma )?glucose (?:>=|of|at least) \d+',
        r'\d+ mg/dL (?:for|diagnose) diabetes',
      ],
      sourceIds: ['ada_standards_2024'],
      confidence: 0.99,
    ),
    MedicalFact(
      id: 'ldl_cholesterol_optimal',
      claim: 'LDL cholesterol levels below 100 mg/dL are considered optimal.',
      patterns: [
        r'LDL (?:cholesterol )?(?:below|less than) \d+',
        r'\d+ mg/dL (?:is|considered) optimal (?:for )?LDL',
      ],
      sourceIds: ['mayo_cholesterol'],
      confidence: 0.95,
    ),
  ];
}
