import '../../models/follow_up_item.dart';
import 'base_extractor.dart';

class WarningExtractor extends BaseExtractor {
  WarningExtractor(super.dictionaryService, super.temporalConfig);

  @override
  List<String> get verbs => [
        "prevent",
        "protect",
        "avoid",
        "watch for",
        "look out for",
        "be aware of"
      ];

  @override
  FollowUpCategory get category => FollowUpCategory.warning;

  @override
  String? extractObject(String sentence, String verb, int verbIndex) {
    int start = (verbIndex - 80).clamp(0, sentence.length);
    int end = (verbIndex + verb.length + 80).clamp(0, sentence.length);
    String context = sentence.substring(start, end).toLowerCase();

    // 1. Look for symptoms
    final symptoms = [
      'dizziness',
      'fever',
      'swelling',
      'chest pain',
      'pain',
      'shortness of breath',
      'nausea',
      'vomiting',
      'bleeding',
      'rash',
      'hives',
      'infection',
      'redness',
      'drainage',
      'pus',
      'warmth',
      'chills'
    ];

    String? foundSymptom;
    for (final sym in symptoms) {
      if (context.contains(sym)) {
        foundSymptom = sym;
        break; // Pick first found?
      }
    }

    // 2. Check for "signs of X"
    final signsPattern = RegExp(r'signs of\s+\w+');
    final signsMatch = signsPattern.firstMatch(context);

    String? objectCandidate;

    if (signsMatch != null) {
      objectCandidate = signsMatch.group(0);
      if (foundSymptom != null && !objectCandidate!.contains(foundSymptom)) {
        objectCandidate = '$objectCandidate: $foundSymptom';
      }
    } else if (foundSymptom != null) {
      objectCandidate = foundSymptom;
    }

    // 3. Conditional trigger extraction
    // "if you experience...", "call immediately if..."
    final ifPattern =
        RegExp(r'if\s+(you\s+)?(experience|feel|notice|have)\s+([^,.!]+)');
    final ifMatch = ifPattern.firstMatch(sentence);

    if (ifMatch != null) {
      final condition = ifMatch.group(0);
      if (objectCandidate == null) {
        objectCandidate = condition;
      } else {
        // If the condition is long, it might be better to just keep the object simple,
        // but the user example shows a rich object.
        // Let's just return the object candidate found so far.
      }
    }

    // Fallback: text after verb
    if (objectCandidate == null) {
      String afterVerb = sentence.substring(verbIndex + verb.length).trim();
      afterVerb = afterVerb.replaceAll(RegExp(r'^[,\s]+|[,\s.!]+$'), '');
      final words = afterVerb.split(' ');
      if (words.isNotEmpty) {
        objectCandidate = words.take(5).join(' ');
      }
    }

    return objectCandidate;
  }
}
