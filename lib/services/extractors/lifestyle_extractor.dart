import '../../models/follow_up_item.dart';
import 'base_extractor.dart';

class LifestyleExtractor extends BaseExtractor {
  LifestyleExtractor(super.dictionaryService, super.temporalConfig);

  @override
  List<String> get verbs => [
        "avoid",
        "reduce",
        "limit",
        "exercise",
        "eat",
        "drink",
        "rest",
        "sleep",
        "walk",
        "try",
        "quit",
        "cut back"
      ];

  @override
  FollowUpCategory get category => FollowUpCategory.lifestyle;

  @override
  String? extractObject(String sentence, String verb, int verbIndex) {
    final lowerSentence = sentence.toLowerCase();

    // 1. Check for specific lifestyle keywords
    final keywords = [
      'sodium',
      'salt',
      'sugar',
      'alcohol',
      'smoking',
      'cigarettes',
      'tobacco',
      'caffeine',
      'carbs',
      'carbohydrates',
      'fat',
      'cholesterol',
      'water',
      'fluids',
      'vegetables',
      'fruits',
      'protein',
      'fiber'
    ];

    // Context window
    int start = (verbIndex - 80).clamp(0, sentence.length);
    int end = (verbIndex + verb.length + 80).clamp(0, sentence.length);
    String context = sentence.substring(start, end).toLowerCase();

    for (final kw in keywords) {
      if (context.contains(kw)) {
        return kw;
      }
    }

    // 2. Check for duration (e.g., "walk 30 minutes")
    final durationPattern = RegExp(r'\b\d+\s+(minute|hour)s?\b');
    final durationMatch = durationPattern.firstMatch(context);
    if (durationMatch != null) {
      return durationMatch.group(0);
    }

    // 3. Fallback: Capture a few words after the verb
    // e.g. "quit smoking cold turkey" -> "smoking cold turkey"
    // "walk around the block" -> "around the block"

    // Get text after verb
    String afterVerb = sentence.substring(verbIndex + verb.length).trim();

    // Clean up punctuation
    afterVerb = afterVerb.replaceAll(RegExp(r'^[,\s]+|[,\s.!]+$'), '');

    // Take first 3-4 words
    final words = afterVerb.split(' ');
    if (words.isNotEmpty) {
      return words.take(4).join(' ');
    }

    return null;
  }
}
