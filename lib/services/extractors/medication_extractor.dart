import '../../models/follow_up_item.dart';
import 'base_extractor.dart';

class MedicationExtractor extends BaseExtractor {
  MedicationExtractor(super.dictionaryService, super.temporalConfig);

  @override
  List<String> get verbs => [
        "take",
        "start",
        "stop",
        "increase",
        "decrease",
        "refill",
        "continue",
        "discontinue",
        "adjust",
        "switch",
        "taper"
      ];

  @override
  FollowUpCategory get category => FollowUpCategory.medication;

  @override
  String? extractObject(String sentence, String verb, int verbIndex) {
    // Context window around the verb
    int start = (verbIndex - 80).clamp(0, sentence.length);
    int end = (verbIndex + verb.length + 80).clamp(0, sentence.length);
    String context = sentence.substring(start, end);

    // Find medication name using the dictionary
    String? medication = dictionaryService.findMedication(context);

    if (medication != null) {
      // Try to extract dosage
      // Look for patterns like "500mg", "10 ml", "1 tablet"
      final dosagePattern = RegExp(
          r'\b\d+(\.\d+)?\s*(mg|g|ml|mcg|oz|tablet|pill|capsule|drop)s?\b',
          caseSensitive: false);

      // Find all dosage matches in the context
      final matches = dosagePattern.allMatches(context);

      // Heuristic: pick the dosage closest to the medication name in the original text?
      // Since we don't know where the medication name was found exactly (dictionaryService doesn't return index),
      // we'll just pick the first dosage found in the context for now.
      // A better approach would be if dictionaryService returned match details.

      if (matches.isNotEmpty) {
        final dosage = matches.first.group(0);
        if (dosage != null) {
          return '$medication $dosage';
        }
      }
      return medication;
    }

    return null;
  }
}
