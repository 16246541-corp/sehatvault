import '../../models/follow_up_item.dart';
import 'base_extractor.dart';

class MonitoringExtractor extends BaseExtractor {
  MonitoringExtractor(super.dictionaryService, super.temporalConfig);

  @override
  List<String> get verbs => [
        "monitor",
        "track",
        "log",
        "record",
        "watch",
        "observe",
        "note",
        "report",
        "notify",
        "alert",
        "check"
      ];

  @override
  FollowUpCategory get category => FollowUpCategory.monitoring;

  @override
  String? extractObject(String sentence, String verb, int verbIndex) {
    int start = (verbIndex - 80).clamp(0, sentence.length);
    int end = (verbIndex + verb.length + 80).clamp(0, sentence.length);
    String context = sentence.substring(start, end);
    final lowerContext = context.toLowerCase();

    // 1. Check for tests (often what is monitored)
    String? test = dictionaryService.findTest(context);
    if (test != null) return test;

    // 2. Common monitoring keywords
    final keywords = [
      'blood pressure',
      'bp',
      'blood sugar',
      'glucose',
      'weight',
      'temperature',
      'fever',
      'pulse',
      'heart rate',
      'symptoms',
      'pain',
      'swelling',
      'redness',
      'intake',
      'output'
    ];

    for (final kw in keywords) {
      if (lowerContext.contains(kw)) return kw;
    }

    // 3. Body parts
    String? bodyPart = dictionaryService.findBodyPart(context);
    if (bodyPart != null) return bodyPart;

    return null;
  }
}
