import '../../models/follow_up_item.dart';
import 'base_extractor.dart';

class DecisionExtractor extends BaseExtractor {
  DecisionExtractor(super.dictionaryService, super.temporalConfig);

  @override
  List<String> get verbs =>
      ["consider", "discuss", "decide", "think about", "weigh", "evaluate"];

  @override
  FollowUpCategory get category => FollowUpCategory.decision;

  @override
  String? extractObject(String sentence, String verb, int verbIndex) {
    // Topics are hard to dictionary-match. Use heuristics.

    // 1. Text after verb
    String afterVerb = sentence.substring(verbIndex + verb.length).trim();

    // Clean start/end
    afterVerb = afterVerb.replaceAll(RegExp(r'^[,\s]+|[,\s.!]+$'), '');

    // Stop at common connectors or end of sentence
    // e.g. "discuss knee replacement options with your family"
    // we want "knee replacement options"

    final stopWords = [' with ', ' at ', ' in ', ' when ', ' if '];
    int endIndex = afterVerb.length;

    for (final word in stopWords) {
      final idx = afterVerb.indexOf(word);
      if (idx != -1 && idx < endIndex) {
        endIndex = idx;
      }
    }

    String object = afterVerb.substring(0, endIndex).trim();

    if (object.isEmpty) {
      // Fallback: take next 4 words
      final words = afterVerb.split(' ');
      if (words.isNotEmpty) {
        object = words.take(4).join(' ');
      }
    }

    return object.isNotEmpty ? object : null;
  }

  @override
  FollowUpItem? process(String sentence, String verb, int verbIndex,
      String conversationId, DateTime anchorDate) {
    // Override process to enforce "at next visit" if no timeframe?
    // User says: "Tag as discussion topic for next visit."
    // Example output: timeframe: "at next visit"

    final item =
        super.process(sentence, verb, verbIndex, conversationId, anchorDate);

    if (item != null && item.timeframeRaw == null) {
      // Create a new item with updated timeframe
      return FollowUpItem(
        id: item.id,
        category: item.category,
        verb: item.verb,
        object: item.object,
        description: item.description,
        priority: item.priority,
        dueDate: item.dueDate, // Maybe set generic future date?
        timeframeRaw: "at next visit",
        frequency: item.frequency,
        sourceConversationId: item.sourceConversationId,
        createdAt: item.createdAt,
      );
    }

    return item;
  }
}
