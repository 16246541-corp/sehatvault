import 'local_storage_service.dart';

/// Service for looking up reference ranges for lab tests and determining
/// if values are within normal limits.
///
/// This service contains embedded reference ranges for common lab tests
/// and provides methods to match lab values against these ranges.
class ReferenceRangeService {

  /// Embedded reference ranges for common lab tests.
  /// Each entry contains:
  /// - testNames: List of common names/aliases for the test
  /// - unit: Standard unit of measurement
  /// - normalRange: Map with 'min' and 'max' values for normal range
  /// - gender: Optional gender-specific ranges ('male', 'female', or 'both')
  /// - ageGroup: Optional age group ('adult', 'child', or 'all')
  /// - category: Category of the test (blood, metabolic, lipid, etc.)
  static final List<Map<String, dynamic>> _referenceRanges = [
    // Blood Count Tests
    {
      'testNames': ['hemoglobin', 'hb', 'hgb'],
      'unit': 'g/dL',
      'normalRange': {'min': 13.5, 'max': 17.5},
      'gender': 'male',
      'ageGroup': 'adult',
      'category': 'blood',
      'description': 'Hemoglobin (Male)',
    },
    {
      'testNames': ['hemoglobin', 'hb', 'hgb'],
      'unit': 'g/dL',
      'normalRange': {'min': 12.0, 'max': 15.5},
      'gender': 'female',
      'ageGroup': 'adult',
      'category': 'blood',
      'description': 'Hemoglobin (Female)',
    },
    {
      'testNames': [
        'wbc',
        'white blood cell',
        'white blood cells',
        'leukocyte'
      ],
      'unit': 'x10^3/µL',
      'normalRange': {'min': 4.5, 'max': 11.0},
      'gender': 'both',
      'ageGroup': 'adult',
      'category': 'blood',
      'description': 'White Blood Cell Count',
    },
    {
      'testNames': ['rbc', 'red blood cell', 'red blood cells', 'erythrocyte'],
      'unit': 'x10^6/µL',
      'normalRange': {'min': 4.5, 'max': 5.9},
      'gender': 'male',
      'ageGroup': 'adult',
      'category': 'blood',
      'description': 'Red Blood Cell Count (Male)',
    },
    {
      'testNames': ['rbc', 'red blood cell', 'red blood cells', 'erythrocyte'],
      'unit': 'x10^6/µL',
      'normalRange': {'min': 4.1, 'max': 5.1},
      'gender': 'female',
      'ageGroup': 'adult',
      'category': 'blood',
      'description': 'Red Blood Cell Count (Female)',
    },
    {
      'testNames': ['platelets', 'platelet count', 'plt'],
      'unit': 'x10^3/µL',
      'normalRange': {'min': 150.0, 'max': 400.0},
      'gender': 'both',
      'ageGroup': 'adult',
      'category': 'blood',
      'description': 'Platelet Count',
    },
    {
      'testNames': ['hematocrit', 'hct', 'packed cell volume', 'pcv'],
      'unit': '%',
      'normalRange': {'min': 38.8, 'max': 50.0},
      'gender': 'male',
      'ageGroup': 'adult',
      'category': 'blood',
      'description': 'Hematocrit (Male)',
    },
    {
      'testNames': ['hematocrit', 'hct', 'packed cell volume', 'pcv'],
      'unit': '%',
      'normalRange': {'min': 34.9, 'max': 44.5},
      'gender': 'female',
      'ageGroup': 'adult',
      'category': 'blood',
      'description': 'Hematocrit (Female)',
    },
    {
      'testNames': ['mcv', 'mean corpuscular volume'],
      'unit': 'fL',
      'normalRange': {'min': 80.0, 'max': 100.0},
      'gender': 'both',
      'ageGroup': 'adult',
      'category': 'blood',
      'description': 'Mean Corpuscular Volume',
    },
    {
      'testNames': ['mch', 'mean corpuscular hemoglobin'],
      'unit': 'pg',
      'normalRange': {'min': 27.0, 'max': 33.0},
      'gender': 'both',
      'ageGroup': 'adult',
      'category': 'blood',
      'description': 'Mean Corpuscular Hemoglobin',
    },
    {
      'testNames': ['mchc', 'mean corpuscular hemoglobin concentration'],
      'unit': 'g/dL',
      'normalRange': {'min': 32.0, 'max': 36.0},
      'gender': 'both',
      'ageGroup': 'adult',
      'category': 'blood',
      'description': 'Mean Corpuscular Hemoglobin Concentration',
    },

    // Metabolic Panel
    {
      'testNames': [
        'glucose',
        'blood glucose',
        'blood sugar',
        'fasting glucose'
      ],
      'unit': 'mg/dL',
      'normalRange': {'min': 70.0, 'max': 100.0},
      'gender': 'both',
      'ageGroup': 'adult',
      'category': 'metabolic',
      'description': 'Fasting Glucose',
    },
    {
      'testNames': ['hba1c', 'a1c', 'glycated hemoglobin', 'glycohemoglobin'],
      'unit': '%',
      'normalRange': {'min': 4.0, 'max': 5.6},
      'gender': 'both',
      'ageGroup': 'adult',
      'category': 'metabolic',
      'description': 'HbA1c',
    },
    {
      'testNames': ['creatinine', 'serum creatinine'],
      'unit': 'mg/dL',
      'normalRange': {'min': 0.7, 'max': 1.3},
      'gender': 'male',
      'ageGroup': 'adult',
      'category': 'metabolic',
      'description': 'Creatinine (Male)',
    },
    {
      'testNames': ['creatinine', 'serum creatinine'],
      'unit': 'mg/dL',
      'normalRange': {'min': 0.6, 'max': 1.1},
      'gender': 'female',
      'ageGroup': 'adult',
      'category': 'metabolic',
      'description': 'Creatinine (Female)',
    },
    {
      'testNames': ['bun', 'blood urea nitrogen', 'urea nitrogen'],
      'unit': 'mg/dL',
      'normalRange': {'min': 7.0, 'max': 20.0},
      'gender': 'both',
      'ageGroup': 'adult',
      'category': 'metabolic',
      'description': 'Blood Urea Nitrogen',
    },
    {
      'testNames': ['urea'],
      'unit': 'mg/dL',
      'normalRange': {'min': 15.0, 'max': 43.0},
      'gender': 'both',
      'ageGroup': 'adult',
      'category': 'metabolic',
      'description': 'Urea',
    },
    {
      'testNames': ['sodium', 'na', 'serum sodium'],
      'unit': 'mEq/L',
      'normalRange': {'min': 136.0, 'max': 145.0},
      'gender': 'both',
      'ageGroup': 'adult',
      'category': 'metabolic',
      'description': 'Sodium',
    },
    {
      'testNames': ['potassium', 'k', 'serum potassium'],
      'unit': 'mEq/L',
      'normalRange': {'min': 3.5, 'max': 5.0},
      'gender': 'both',
      'ageGroup': 'adult',
      'category': 'metabolic',
      'description': 'Potassium',
    },
    {
      'testNames': ['chloride', 'cl', 'serum chloride'],
      'unit': 'mEq/L',
      'normalRange': {'min': 98.0, 'max': 107.0},
      'gender': 'both',
      'ageGroup': 'adult',
      'category': 'metabolic',
      'description': 'Chloride',
    },
    {
      'testNames': ['calcium', 'ca', 'serum calcium'],
      'unit': 'mg/dL',
      'normalRange': {'min': 8.5, 'max': 10.5},
      'gender': 'both',
      'ageGroup': 'adult',
      'category': 'metabolic',
      'description': 'Calcium',
    },

    // Lipid Panel
    {
      'testNames': ['cholesterol', 'total cholesterol', 'serum cholesterol'],
      'unit': 'mg/dL',
      'normalRange': {'min': 0.0, 'max': 200.0},
      'gender': 'both',
      'ageGroup': 'adult',
      'category': 'lipid',
      'description': 'Total Cholesterol',
    },
    {
      'testNames': ['ldl', 'ldl cholesterol', 'low density lipoprotein'],
      'unit': 'mg/dL',
      'normalRange': {'min': 0.0, 'max': 100.0},
      'gender': 'both',
      'ageGroup': 'adult',
      'category': 'lipid',
      'description': 'LDL Cholesterol',
    },
    {
      'testNames': ['hdl', 'hdl cholesterol', 'high density lipoprotein'],
      'unit': 'mg/dL',
      'normalRange': {'min': 40.0, 'max': 999.0},
      'gender': 'male',
      'ageGroup': 'adult',
      'category': 'lipid',
      'description': 'HDL Cholesterol (Male)',
    },
    {
      'testNames': ['hdl', 'hdl cholesterol', 'high density lipoprotein'],
      'unit': 'mg/dL',
      'normalRange': {'min': 50.0, 'max': 999.0},
      'gender': 'female',
      'ageGroup': 'adult',
      'category': 'lipid',
      'description': 'HDL Cholesterol (Female)',
    },
    {
      'testNames': ['triglycerides', 'tg', 'trigs'],
      'unit': 'mg/dL',
      'normalRange': {'min': 0.0, 'max': 150.0},
      'gender': 'both',
      'ageGroup': 'adult',
      'category': 'lipid',
      'description': 'Triglycerides',
    },
    {
      'testNames': ['vldl', 'vldl cholesterol', 'very low density lipoprotein'],
      'unit': 'mg/dL',
      'normalRange': {'min': 2.0, 'max': 30.0},
      'gender': 'both',
      'ageGroup': 'adult',
      'category': 'lipid',
      'description': 'VLDL Cholesterol',
    },

    // Liver Function Tests
    {
      'testNames': ['bilirubin', 'total bilirubin'],
      'unit': 'mg/dL',
      'normalRange': {'min': 0.1, 'max': 1.2},
      'gender': 'both',
      'ageGroup': 'adult',
      'category': 'liver',
      'description': 'Total Bilirubin',
    },
    {
      'testNames': ['direct bilirubin', 'conjugated bilirubin'],
      'unit': 'mg/dL',
      'normalRange': {'min': 0.0, 'max': 0.3},
      'gender': 'both',
      'ageGroup': 'adult',
      'category': 'liver',
      'description': 'Direct Bilirubin',
    },
    {
      'testNames': ['sgot', 'ast', 'aspartate aminotransferase'],
      'unit': 'U/L',
      'normalRange': {'min': 10.0, 'max': 40.0},
      'gender': 'both',
      'ageGroup': 'adult',
      'category': 'liver',
      'description': 'AST (SGOT)',
    },
    {
      'testNames': ['sgpt', 'alt', 'alanine aminotransferase'],
      'unit': 'U/L',
      'normalRange': {'min': 7.0, 'max': 56.0},
      'gender': 'both',
      'ageGroup': 'adult',
      'category': 'liver',
      'description': 'ALT (SGPT)',
    },
    {
      'testNames': ['alp', 'alkaline phosphatase'],
      'unit': 'U/L',
      'normalRange': {'min': 44.0, 'max': 147.0},
      'gender': 'both',
      'ageGroup': 'adult',
      'category': 'liver',
      'description': 'Alkaline Phosphatase',
    },
    {
      'testNames': ['albumin', 'serum albumin'],
      'unit': 'g/dL',
      'normalRange': {'min': 3.5, 'max': 5.5},
      'gender': 'both',
      'ageGroup': 'adult',
      'category': 'liver',
      'description': 'Albumin',
    },
    {
      'testNames': ['protein', 'total protein', 'serum protein'],
      'unit': 'g/dL',
      'normalRange': {'min': 6.0, 'max': 8.3},
      'gender': 'both',
      'ageGroup': 'adult',
      'category': 'liver',
      'description': 'Total Protein',
    },
    {
      'testNames': ['ggt', 'gamma-glutamyl transferase', 'gamma gt'],
      'unit': 'U/L',
      'normalRange': {'min': 0.0, 'max': 51.0},
      'gender': 'both',
      'ageGroup': 'adult',
      'category': 'liver',
      'description': 'GGT',
    },

    // Thyroid Function Tests
    {
      'testNames': ['tsh', 'thyroid stimulating hormone'],
      'unit': 'µIU/mL',
      'normalRange': {'min': 0.4, 'max': 4.0},
      'gender': 'both',
      'ageGroup': 'adult',
      'category': 'thyroid',
      'description': 'TSH',
    },
    {
      'testNames': ['t3', 'triiodothyronine', 'total t3'],
      'unit': 'ng/dL',
      'normalRange': {'min': 80.0, 'max': 200.0},
      'gender': 'both',
      'ageGroup': 'adult',
      'category': 'thyroid',
      'description': 'T3',
    },
    {
      'testNames': ['t4', 'thyroxine', 'total t4'],
      'unit': 'µg/dL',
      'normalRange': {'min': 5.0, 'max': 12.0},
      'gender': 'both',
      'ageGroup': 'adult',
      'category': 'thyroid',
      'description': 'T4',
    },
    {
      'testNames': ['ft3', 'free t3', 'free triiodothyronine'],
      'unit': 'pg/mL',
      'normalRange': {'min': 2.0, 'max': 4.4},
      'gender': 'both',
      'ageGroup': 'adult',
      'category': 'thyroid',
      'description': 'Free T3',
    },
    {
      'testNames': ['ft4', 'free t4', 'free thyroxine'],
      'unit': 'ng/dL',
      'normalRange': {'min': 0.8, 'max': 1.8},
      'gender': 'both',
      'ageGroup': 'adult',
      'category': 'thyroid',
      'description': 'Free T4',
    },

    // Vitamins and Minerals
    {
      'testNames': [
        'vitamin d',
        'vit d',
        '25-oh vitamin d',
        '25-hydroxyvitamin d'
      ],
      'unit': 'ng/mL',
      'normalRange': {'min': 30.0, 'max': 100.0},
      'gender': 'both',
      'ageGroup': 'adult',
      'category': 'vitamin',
      'description': 'Vitamin D',
    },
    {
      'testNames': ['vitamin b12', 'vit b12', 'cobalamin'],
      'unit': 'pg/mL',
      'normalRange': {'min': 200.0, 'max': 900.0},
      'gender': 'both',
      'ageGroup': 'adult',
      'category': 'vitamin',
      'description': 'Vitamin B12',
    },
    {
      'testNames': ['folate', 'folic acid', 'vitamin b9'],
      'unit': 'ng/mL',
      'normalRange': {'min': 2.7, 'max': 17.0},
      'gender': 'both',
      'ageGroup': 'adult',
      'category': 'vitamin',
      'description': 'Folate',
    },
    {
      'testNames': ['iron', 'serum iron'],
      'unit': 'µg/dL',
      'normalRange': {'min': 60.0, 'max': 170.0},
      'gender': 'male',
      'ageGroup': 'adult',
      'category': 'vitamin',
      'description': 'Iron (Male)',
    },
    {
      'testNames': ['iron', 'serum iron'],
      'unit': 'µg/dL',
      'normalRange': {'min': 50.0, 'max': 150.0},
      'gender': 'female',
      'ageGroup': 'adult',
      'category': 'vitamin',
      'description': 'Iron (Female)',
    },
    {
      'testNames': ['ferritin', 'serum ferritin'],
      'unit': 'ng/mL',
      'normalRange': {'min': 24.0, 'max': 336.0},
      'gender': 'male',
      'ageGroup': 'adult',
      'category': 'vitamin',
      'description': 'Ferritin (Male)',
    },
    {
      'testNames': ['ferritin', 'serum ferritin'],
      'unit': 'ng/mL',
      'normalRange': {'min': 11.0, 'max': 307.0},
      'gender': 'female',
      'ageGroup': 'adult',
      'category': 'vitamin',
      'description': 'Ferritin (Female)',
    },
  ];

  /// Looks up the reference range for a given lab test name.
  ///
  /// Returns a list of matching reference ranges (may be multiple if gender-specific).
  /// Each result contains:
  /// - testNames: List of recognized names for this test
  /// - unit: Standard unit of measurement
  /// - normalRange: Map with 'min' and 'max' values
  /// - gender: Gender specification ('male', 'female', or 'both')
  /// - ageGroup: Age group specification
  /// - category: Test category
  /// - description: Human-readable description
  static List<Map<String, dynamic>> lookupReferenceRange(String testName) {
    final normalizedTestName = testName.toLowerCase().trim();
    final exactMatches = <Map<String, dynamic>>[];
    final wordMatches = <Map<String, dynamic>>[];
    final partialMatches = <Map<String, dynamic>>[];

    for (var range in _referenceRanges) {
      final testNames = range['testNames'] as List<dynamic>;

      // Check for exact match first (highest priority)
      final hasExactMatch = testNames
          .any((name) => name.toString().toLowerCase() == normalizedTestName);

      if (hasExactMatch) {
        exactMatches.add(range);
        continue;
      }

      // Check if the search term matches a complete test name (not a substring)
      // For example, "hemoglobin" should match "hemoglobin" but not "mean corpuscular hemoglobin"
      final matchingName = testNames.firstWhere(
        (name) {
          final nameLower = name.toString().toLowerCase();
          // Check if search term is the entire name or vice versa
          return nameLower == normalizedTestName ||
              normalizedTestName == nameLower;
        },
        orElse: () => '',
      );

      if (matchingName.toString().isNotEmpty) {
        wordMatches.add(range);
        continue;
      }

      // Check for partial matches (lowest priority)
      final hasPartialMatch = testNames.any((name) {
        final nameLower = name.toString().toLowerCase();
        return nameLower.contains(normalizedTestName) ||
            normalizedTestName.contains(nameLower);
      });

      if (hasPartialMatch) {
        partialMatches.add(range);
      }
    }

    // Return exact matches first, then word matches, then partial matches
    // If we have exact matches, only return those (most specific)
    if (exactMatches.isNotEmpty) {
      return exactMatches;
    }

    // Otherwise return word matches if we have them
    if (wordMatches.isNotEmpty) {
      return wordMatches;
    }

    // Finally, sort partial matches by length of test name (shorter = more specific)
    partialMatches.sort((a, b) {
      final aNames = a['testNames'] as List<dynamic>;
      final bNames = b['testNames'] as List<dynamic>;
      final aMinLength = aNames
          .map((n) => n.toString().length)
          .reduce((a, b) => a < b ? a : b);
      final bMinLength = bNames
          .map((n) => n.toString().length)
          .reduce((a, b) => a < b ? a : b);
      return aMinLength.compareTo(bMinLength);
    });

    return partialMatches;
  }

  /// Evaluates a lab value against its reference range.
  ///
  /// Parameters:
  /// - testName: Name of the lab test
  /// - value: Numeric value to evaluate
  /// - unit: Optional unit (used for validation)
  /// - gender: Optional gender ('male' or 'female') for gender-specific ranges
  ///
  /// Returns a map with:
  /// - matched: Whether a reference range was found
  /// - status: 'normal', 'low', 'high', or 'unknown'
  /// - referenceRange: The matched reference range (if found)
  /// - message: Human-readable interpretation
  /// - value: The input value
  /// - testName: The input test name
  static Map<String, dynamic> evaluateLabValue({
    required String testName,
    required double value,
    String? unit,
    String? gender,
  }) {
    final matches = lookupReferenceRange(testName);

    if (matches.isEmpty) {
      return {
        'matched': false,
        'status': 'unknown',
        'referenceRange': null,
        'message': 'No reference range found for "$testName"',
        'value': value,
        'testName': testName,
      };
    }

    // Filter by gender if specified
    Map<String, dynamic>? selectedRange;
    final effectiveGender = gender ?? LocalStorageService().getUserProfile().sex;
    
    if (effectiveGender != null && effectiveGender != 'unspecified') {
      final genderLower = effectiveGender.toLowerCase();
      selectedRange = matches.firstWhere(
        (range) => range['gender'] == genderLower || range['gender'] == 'both',
        orElse: () => matches.first,
      );
    } else {

      // Prefer 'both' gender ranges if no gender specified
      selectedRange = matches.firstWhere(
        (range) => range['gender'] == 'both',
        orElse: () => matches.first,
      );
    }

    final normalRange = selectedRange['normalRange'] as Map<String, dynamic>;
    final min = normalRange['min'] as double;
    final max = normalRange['max'] as double;
    final rangeUnit = selectedRange['unit'] as String;

    // Determine status
    String status;
    String message;

    if (value < min) {
      status = 'low';
      message =
          '$testName is LOW ($value ${unit ?? rangeUnit}). Normal range: $min-$max $rangeUnit';
    } else if (value > max) {
      status = 'high';
      message =
          '$testName is HIGH ($value ${unit ?? rangeUnit}). Normal range: $min-$max $rangeUnit';
    } else {
      status = 'normal';
      message =
          '$testName is NORMAL ($value ${unit ?? rangeUnit}). Normal range: $min-$max $rangeUnit';
    }

    return {
      'matched': true,
      'status': status,
      'referenceRange': selectedRange,
      'message': message,
      'value': value,
      'testName': testName,
      'normalRange': {'min': min, 'max': max},
      'unit': rangeUnit,
    };
  }

  /// Evaluates multiple lab values at once.
  ///
  /// Takes a list of lab values (each with 'field', 'value', and optionally 'unit')
  /// and returns evaluation results for each.
  ///
  /// Parameters:
  /// - labValues: List of maps with 'field' (test name), 'value' (numeric), and optional 'unit'
  /// - gender: Optional gender for gender-specific ranges
  ///
  /// Returns a map with:
  /// - results: List of evaluation results for each lab value
  /// - summary: Overall summary with counts of normal/low/high/unknown values
  static Map<String, dynamic> evaluateMultipleLabValues({
    required List<Map<String, dynamic>> labValues,
    String? gender,
  }) {
    final results = <Map<String, dynamic>>[];
    int normalCount = 0;
    int lowCount = 0;
    int highCount = 0;
    int unknownCount = 0;

    for (var labValue in labValues) {
      final testName = labValue['field'] as String;
      final valueStr = labValue['value'] as String;
      final unit = labValue['unit'] as String?;

      // Parse the numeric value
      final value = double.tryParse(valueStr);
      if (value == null) {
        results.add({
          'matched': false,
          'status': 'unknown',
          'message': 'Invalid numeric value: $valueStr',
          'testName': testName,
        });
        unknownCount++;
        continue;
      }

      final evaluation = evaluateLabValue(
        testName: testName,
        value: value,
        unit: unit,
        gender: gender,
      );

      results.add(evaluation);

      // Update counts
      switch (evaluation['status']) {
        case 'normal':
          normalCount++;
          break;
        case 'low':
          lowCount++;
          break;
        case 'high':
          highCount++;
          break;
        default:
          unknownCount++;
      }
    }

    return {
      'results': results,
      'summary': {
        'total': results.length,
        'normal': normalCount,
        'low': lowCount,
        'high': highCount,
        'unknown': unknownCount,
        'hasAbnormal': lowCount > 0 || highCount > 0,
      },
    };
  }

  /// Gets all available reference ranges for a specific category.
  ///
  /// Categories: 'blood', 'metabolic', 'lipid', 'liver', 'thyroid', 'vitamin'
  static List<Map<String, dynamic>> getReferenceRangesByCategory(
      String category) {
    return _referenceRanges
        .where((range) => range['category'] == category.toLowerCase())
        .toList();
  }

  /// Gets a list of all available test names.
  static List<String> getAllTestNames() {
    final allNames = <String>{};
    for (var range in _referenceRanges) {
      final testNames = range['testNames'] as List<dynamic>;
      allNames.addAll(testNames.map((name) => name.toString()));
    }
    return allNames.toList()..sort();
  }

  /// Gets all available categories.
  static List<String> getAllCategories() {
    final categories = <String>{};
    for (var range in _referenceRanges) {
      categories.add(range['category'] as String);
    }
    return categories.toList()..sort();
  }

  /// Citation sources for each category
  static final Map<String, Map<String, String>> _guidelineSources = {
    'blood': {
      'title': 'American Society of Hematology Guidelines',
      'url': 'https://www.hematology.org',
      'date': '2023-01-01',
    },
    'metabolic': {
      'title': 'American Diabetes Association Standards of Care',
      'url': 'https://diabetesjournals.org/care',
      'date': '2024-01-01',
    },
    'lipid': {
      'title': 'ACC/AHA Guideline on the Management of Blood Cholesterol',
      'url': 'https://www.ahajournals.org/doi/10.1161/CIR.0000000000000625',
      'date': '2019-01-01',
    },
    'liver': {
      'title':
          'ACG Clinical Guideline: Evaluation of Abnormal Liver Chemistries',
      'url':
          'https://journals.lww.com/ajg/Fulltext/2017/01000/ACG_Clinical_Guideline__Evaluation_of_Abnormal.14.aspx',
      'date': '2017-01-01',
    },
    'thyroid': {
      'title': 'American Thyroid Association Guidelines',
      'url':
          'https://www.thyroid.org/professionals/ata-professional-guidelines/',
      'date': '2016-01-01',
    },
    'vitamin': {
      'title': 'Dietary Reference Intakes for Calcium and Vitamin D',
      'url': 'https://ods.od.nih.gov/factsheets/VitaminD-HealthProfessional/',
      'date': '2023-08-01',
    },
  };

  /// Gets the citation source for a given test name.
  static Map<String, String>? getCitationSource(String testName) {
    final ranges = lookupReferenceRange(testName);
    if (ranges.isEmpty) return null;

    final category = ranges.first['category'] as String;
    return _guidelineSources[category];
  }
}
