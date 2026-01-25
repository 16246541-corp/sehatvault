import 'package:uuid/uuid.dart';
import '../../models/follow_up_item.dart';
import 'base_extractor.dart';

class TestExtractor extends BaseExtractor {
  TestExtractor(super.dictionaryService, super.temporalConfig);

  @override
  List<String> get verbs => [
        "tests",
        "get",
        "order",
        "run",
        "check",
        "measure",
        "repeat",
        "retest",
        "confirm",
        "review",
        "perform",
        "schedule"
      ];

  @override
  FollowUpCategory get category => FollowUpCategory.test;

  @override
  String? extractObject(String sentence, String verb, int verbIndex) {
    int start = (verbIndex - 80).clamp(0, sentence.length);
    int end = (verbIndex + verb.length + 80).clamp(0, sentence.length);
    String context = sentence.substring(start, end);

    // Try finding test first
    String? test = dictionaryService.findTest(context);

    // Fallback to procedure
    test ??= dictionaryService.findProcedure(context);

    if (test != null) {
      // Check if there's a body part mentioned nearby to refine the object
      // e.g. "MRI of knee"
      String? bodyPart = dictionaryService.findBodyPart(context);

      if (bodyPart != null) {
        // Avoid duplication if the test name already includes the body part
        if (!test.toLowerCase().contains(bodyPart.toLowerCase())) {
          return '$test of $bodyPart';
        }
      }
      return test;
    }

    return null;
  }

  @override
  FollowUpItem? process(String sentence, String verb, int verbIndex,
      String conversationId, DateTime anchorDate) {
    final temporalInfo = extractTemporalInfo(sentence, anchorDate);

    String cleanSentence = sentence;
    if (temporalInfo.timeframeRaw != null) {
      cleanSentence = cleanSentence.replaceAll(
          RegExp(RegExp.escape(temporalInfo.timeframeRaw!),
              caseSensitive: false),
          ' ');
    }
    if (temporalInfo.frequency != null) {
      cleanSentence = cleanSentence.replaceAll(
          RegExp(RegExp.escape(temporalInfo.frequency!), caseSensitive: false),
          ' ');
    }

    final object = extractObject(cleanSentence, verb, verbIndex);
    if (object == null) {
      return null;
    }

    return FollowUpItem(
      id: const Uuid().v4(),
      category: category,
      verb: verb,
      object: object,
      description: sentence.trim(),
      priority: determinePriority(sentence),
      dueDate: temporalInfo.dueDate,
      timeframeRaw: temporalInfo.timeframeRaw,
      frequency: temporalInfo.frequency,
      sourceConversationId: conversationId,
      createdAt: DateTime.now(),
    );
  }
}
