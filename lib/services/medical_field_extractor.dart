/// Service dedicated to extracting specific medical fields from text.
/// Provides granular extraction methods that return structured maps.
class MedicalFieldExtractor {
  /// Extracts lab values from text and returns a structured map.
  ///
  /// Returns a map with:
  /// - 'values': List of extracted lab values, each containing:
  ///   - 'field': Name of the lab test (e.g., "Hemoglobin", "Glucose")
  ///   - 'value': Numeric value
  ///   - 'unit': Unit of measurement (e.g., "g/dL", "mg/dL")
  ///   - 'rawText': Original matched text
  /// - 'count': Total number of lab values found
  /// - 'categories': Map grouping values by category (blood, metabolic, etc.)
  static Map<String, dynamic> extractLabValues(String text) {
    if (text.isEmpty) {
      return {
        'values': [],
        'count': 0,
        'categories': {},
      };
    }

    final normalizedText = text.replaceAll(RegExp(r'\s+'), ' ');
    final List<Map<String, String>> results = [];

    // Pattern: Field name, optional separator, numeric value, optional units
    final labRegex = RegExp(
      r'([a-zA-Z\s]{2,30})[:\s]+(\d+(?:\.\d+)?)\s*([a-zA-Z/%µ/]{1,15})?',
      caseSensitive: false,
    );

    // Common lab test categories
    final Map<String, List<String>> labCategories = {
      'blood': [
        'hemoglobin',
        'hb',
        'wbc',
        'rbc',
        'platelets',
        'hematocrit',
        'mcv',
        'mch',
        'mchc'
      ],
      'metabolic': [
        'glucose',
        'hba1c',
        'creatinine',
        'urea',
        'bun',
        'sodium',
        'potassium',
        'chloride',
        'calcium'
      ],
      'lipid': ['cholesterol', 'ldl', 'hdl', 'triglycerides', 'vldl'],
      'liver': [
        'bilirubin',
        'sgot',
        'sgpt',
        'alt',
        'ast',
        'alp',
        'albumin',
        'protein',
        'ggt'
      ],
      'thyroid': ['tsh', 't3', 't4', 'ft3', 'ft4'],
      'vitamin': [
        'vitamin d',
        'vitamin b12',
        'vitamin b',
        'folate',
        'iron',
        'ferritin'
      ],
      'other': [],
    };

    final commonLabTerms = labCategories.values.expand((v) => v).toList();

    final commonUnits = [
      'g/dl',
      'mg/dl',
      'mmol/l',
      '%',
      'u/l',
      'iu/l',
      'mcg',
      'ml',
      'kg',
      'iu',
      'meq/l',
      'µg/dl',
      'ng/ml',
      'pg/ml',
      'cells/µl',
      'x10^3/µl',
      'x10^6/µl',
      'fl',
      'pg',
      'umol/l',
      'µmol/l'
    ];

    for (var match in labRegex.allMatches(normalizedText)) {
      final field = match.group(1)!.trim();
      final value = match.group(2)!;
      final unit = match.group(3)?.trim() ?? '';

      // Validate if it looks like a lab result
      final isMedicalTerm =
          commonLabTerms.any((term) => field.toLowerCase().contains(term));
      final hasUnit = unit.isNotEmpty &&
          commonUnits.any((u) => unit.toLowerCase().contains(u.toLowerCase()));

      if (isMedicalTerm || hasUnit) {
        results.add({
          'field': field,
          'value': value,
          'unit': unit,
          'rawText': match.group(0)!,
        });
      }
    }

    // Categorize the results
    final Map<String, List<Map<String, String>>> categorized = {};
    for (var result in results) {
      final field = result['field']!.toLowerCase();
      String category = 'other';

      for (var entry in labCategories.entries) {
        if (entry.value.any((term) => field.contains(term))) {
          category = entry.key;
          break;
        }
      }

      categorized.putIfAbsent(category, () => []);
      categorized[category]!.add(result);
    }

    return {
      'values': results,
      'count': results.length,
      'categories': categorized,
    };
  }

  /// Extracts medications and dosages from text and returns a structured map.
  ///
  /// Returns a map with:
  /// - 'medications': List of extracted medications, each containing:
  ///   - 'name': Medication name
  ///   - 'dosage': Dosage amount and unit
  ///   - 'frequency': Frequency if detected (e.g., "twice daily")
  ///   - 'rawText': Original matched text
  /// - 'count': Total number of medications found
  /// - 'dosageUnits': Set of unique dosage units found
  static Map<String, dynamic> extractMedications(String text) {
    if (text.isEmpty) {
      return {
        'medications': [],
        'count': 0,
        'dosageUnits': <String>{},
      };
    }

    final normalizedText = text.replaceAll(RegExp(r'\s+'), ' ');
    final List<Map<String, String>> medications = [];
    final Set<String> dosageUnits = {};

    // Pattern: Drug name followed by dosage (number + unit)
    // e.g., "Metformin 500mg", "Amoxicillin 250 mg", "Insulin 10 units"
    final medRegex = RegExp(
      r'\b([a-zA-Z]{4,30})\s+(\d+(?:\.\d+)?)\s*(mg|mcg|µg|g|ml|tab|tabs|tablet|tablets|caps|capsule|capsules|units|iu|drops)\b',
      caseSensitive: false,
    );

    // Frequency patterns
    final frequencyRegex = RegExp(
      r'\b(once daily|twice daily|thrice daily|once|twice|thrice|1x|2x|3x|daily|weekly|monthly|bid|tid|qid|od|bd|td|qd|prn|as needed|every \d+ hours?)\b',
      caseSensitive: false,
    );

    // Words to exclude (common false positives)
    final excludeWords = [
      'time',
      'date',
      'test',
      'result',
      'page',
      'phone',
      'name',
      'report',
      'sample',
      'blood',
      'urine',
      'patient',
      'doctor',
      'hospital',
      'clinic',
      'department',
      'reference',
      'normal',
      'hemoglobin',
      'glucose',
      'creatinine',
      'cholesterol',
      'triglycerides'
    ];

    for (var match in medRegex.allMatches(normalizedText)) {
      final name = match.group(1)!.trim();
      final dosageValue = match.group(2)!.trim();
      final dosageUnit = match.group(3)!.trim();
      final dosage = '$dosageValue $dosageUnit';
      final rawText = match.group(0)!;

      // Filter out common words
      if (excludeWords.contains(name.toLowerCase())) {
        continue;
      }

      // Try to find frequency in surrounding context (±50 chars)
      final matchStart = match.start;
      final contextStart = (matchStart - 50).clamp(0, normalizedText.length);
      final contextEnd = (match.end + 50).clamp(0, normalizedText.length);
      final context = normalizedText.substring(contextStart, contextEnd);

      String frequency = '';

      // Find all matches and pick the closest one, prioritizing those after the medication
      final medStartInContext = matchStart - contextStart;
      final medEndInContext = match.end - contextStart;

      final freqMatches = frequencyRegex.allMatches(context);
      int minDistance = 1000;

      for (var fMatch in freqMatches) {
        int distance;
        bool isAfter = false;

        if (fMatch.start >= medEndInContext) {
          // Frequency is after medication
          distance = fMatch.start - medEndInContext;
          isAfter = true;
        } else if (fMatch.end <= medStartInContext) {
          // Frequency is before medication
          distance = medStartInContext - fMatch.end;
        } else {
          // Overlap
          distance = 0;
        }

        // Add bias against preceding frequencies to favor "Drug Dosage Frequency" format
        if (!isAfter) {
          distance += 10;
        }

        if (distance < minDistance) {
          minDistance = distance;
          frequency = fMatch.group(0)!;
        }
      }

      medications.add({
        'name': name,
        'dosage': dosage,
        'frequency': frequency,
        'rawText': rawText,
      });

      dosageUnits.add(dosageUnit.toLowerCase());
    }

    return {
      'medications': medications,
      'count': medications.length,
      'dosageUnits': dosageUnits.toList(),
    };
  }

  /// Extracts dates from text and returns a structured map.
  ///
  /// Returns a map with:
  /// - 'dates': List of extracted dates, each containing:
  ///   - 'value': The date string
  ///   - 'format': Detected format type
  ///   - 'rawText': Original matched text
  ///   - 'confidence': Confidence level ('high', 'medium', 'low')
  ///   - 'context': Context where date was found ('header', 'footer', 'body')
  /// - 'count': Total number of dates found
  /// - 'formats': Set of date formats detected
  /// - 'documentDate': Most likely document creation date (highest confidence)
  static Map<String, dynamic> extractDates(String text) {
    if (text.isEmpty) {
      return {
        'dates': [],
        'count': 0,
        'formats': <String>{},
      };
    }

    final normalizedText = text.replaceAll(RegExp(r'\s+'), ' ');
    final List<Map<String, String>> dates = [];
    final Set<String> formats = {};

    // Define header/footer sections for priority extraction
    final textLength = normalizedText.length;
    final headerSection =
        normalizedText.substring(0, (textLength * 0.2).round());
    final footerSection = normalizedText.substring((textLength * 0.8).round());
    final bodySection = normalizedText.substring(
        (textLength * 0.2).round(), (textLength * 0.8).round());

    // Date context indicators
    final headerDateIndicators = [
      'report date',
      'date:',
      'created:',
      'issued:',
      'prepared:',
      'dated'
    ];
    final footerDateIndicators = ['dated', 'date'];
    final documentDateIndicators = [
      'document date',
      'file date',
      'report date'
    ];

    // Helper function to determine date confidence and context
    Map<String, String> analyzeDateContext(
        String dateText, String fullText, int matchStart) {
      final lowerDate = dateText.toLowerCase();
      final lowerText = fullText.toLowerCase();

      // Determine context (header, footer, body)
      String context;
      if (matchStart < headerSection.length) {
        context = 'header';
      } else if (matchStart > (textLength * 0.8).round()) {
        context = 'footer';
      } else {
        context = 'body';
      }

      // Determine confidence based on context indicators
      String confidence;
      if (context == 'header') {
        // Check for header date indicators in surrounding context
        final contextStart = (matchStart - 50).clamp(0, fullText.length);
        final contextEnd =
            (matchStart + dateText.length + 50).clamp(0, fullText.length);
        final surroundingContext =
            lowerText.substring(contextStart, contextEnd);

        final hasHeaderIndicator = headerDateIndicators
            .any((indicator) => surroundingContext.contains(indicator));
        confidence = hasHeaderIndicator ? 'high' : 'medium';
      } else if (context == 'footer') {
        final hasFooterIndicator = footerDateIndicators
            .any((indicator) => lowerText.contains(indicator));
        confidence = hasFooterIndicator ? 'medium' : 'low';
      } else {
        // Body context - check for document date indicators
        final hasDocumentIndicator = documentDateIndicators
            .any((indicator) => lowerText.contains(indicator));
        confidence = hasDocumentIndicator ? 'medium' : 'low';
      }

      return {'context': context, 'confidence': confidence};
    }

    // Date patterns with format identifiers
    final datePatterns = [
      {
        'pattern': RegExp(r'\b(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})\b'),
        'format': 'numeric_slash',
      },
      {
        'pattern': RegExp(r'\b(\d{4})-(\d{2})-(\d{2})\b'),
        'format': 'iso_date',
      },
      {
        'pattern': RegExp(
          r'\b(\d{1,2})\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+(\d{2,4})\b',
          caseSensitive: false,
        ),
        'format': 'day_month_year',
      },
      {
        'pattern': RegExp(
          r'\b(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+(\d{1,2}),?\s+(\d{2,4})\b',
          caseSensitive: false,
        ),
        'format': 'month_day_year',
      },
      {
        'pattern': RegExp(
          r'\b(\d{1,2})\s+(January|February|March|April|May|June|July|August|September|October|November|December)\s+(\d{2,4})\b',
          caseSensitive: false,
        ),
        'format': 'day_fullmonth_year',
      },
    ];

    for (var patternInfo in datePatterns) {
      final pattern = patternInfo['pattern'] as RegExp;
      final format = patternInfo['format'] as String;

      for (var match in pattern.allMatches(normalizedText)) {
        final dateValue = match.group(0)!;
        final matchStart = match.start;

        // Analyze context and confidence
        final contextAnalysis =
            analyzeDateContext(dateValue, normalizedText, matchStart);

        dates.add({
          'value': dateValue,
          'format': format,
          'rawText': dateValue,
          'confidence': contextAnalysis['confidence']!,
          'context': contextAnalysis['context']!,
        });

        formats.add(format);
      }
    }

    // Remove duplicates while preserving order and selecting highest confidence
    final uniqueDates = <String, Map<String, String>>{};
    for (var date in dates) {
      final dateValue = date['value']!;
      if (!uniqueDates.containsKey(dateValue)) {
        uniqueDates[dateValue] = date;
      } else {
        // Keep the higher confidence version
        final existingConfidence = uniqueDates[dateValue]!['confidence']!;
        final newConfidence = date['confidence']!;

        // Priority: high > medium > low
        final confidencePriority = {'high': 3, 'medium': 2, 'low': 1};
        if (confidencePriority[newConfidence]! >
            confidencePriority[existingConfidence]!) {
          uniqueDates[dateValue] = date;
        }
      }
    }

    // Find the most likely document date (highest confidence header/footer date)
    Map<String, String>? documentDate;
    final headerFooterDates = uniqueDates.values
        .where((date) =>
            date['context'] == 'header' || date['context'] == 'footer')
        .toList();

    if (headerFooterDates.isNotEmpty) {
      // Sort by confidence (high first) and pick the first one
      headerFooterDates.sort((a, b) {
        final priority = {'high': 3, 'medium': 2, 'low': 1};
        return priority[b['confidence']!]!
            .compareTo(priority[a['confidence']!]!);
      });
      documentDate = headerFooterDates.first;
    }

    return {
      'dates': uniqueDates.values.toList(),
      'count': uniqueDates.length,
      'formats': formats.toList(),
      'documentDate': documentDate,
    };
  }

  /// Extracts all medical fields in one comprehensive call.
  ///
  /// Returns a map containing:
  /// - 'labValues': Result from extractLabValues()
  /// - 'medications': Result from extractMedications()
  /// - 'dates': Result from extractDates()
  /// - 'summary': Overall extraction summary
  static Map<String, dynamic> extractAll(String text) {
    final labValues = extractLabValues(text);
    final medications = extractMedications(text);
    final dates = extractDates(text);

    return {
      'labValues': labValues,
      'medications': medications,
      'dates': dates,
      'summary': {
        'totalLabValues': labValues['count'],
        'totalMedications': medications['count'],
        'totalDates': dates['count'],
        'hasData': (labValues['count'] as int) > 0 ||
            (medications['count'] as int) > 0 ||
            (dates['count'] as int) > 0,
      },
    };
  }
}
