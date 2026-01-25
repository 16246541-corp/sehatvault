import 'package:uuid/uuid.dart';
import '../../models/follow_up_item.dart';
import '../medical_dictionary_service.dart';
import '../temporal_phrase_patterns_configuration.dart';

abstract class BaseExtractor {
  final MedicalDictionaryService dictionaryService;
  final TemporalPhrasePatternsConfiguration temporalConfig;
  final Uuid _uuid = const Uuid();

  BaseExtractor(this.dictionaryService, this.temporalConfig);

  /// Returns the list of verbs this extractor handles.
  List<String> get verbs;

  /// Tries to extract a FollowUpItem from the sentence.
  FollowUpItem? extract(
      String sentence, String conversationId, DateTime anchorDate) {
    final lowerSentence = sentence.toLowerCase().trim();
    if (lowerSentence.isEmpty) return null;

    String? foundVerb;
    int verbIndex = -1;

    // Sort verbs by length (descending)
    final sortedVerbs = List<String>.from(verbs)
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final verb in sortedVerbs) {
      final pattern =
          RegExp(r'\b' + RegExp.escape(verb) + r'\b', caseSensitive: false);
      final match = pattern.firstMatch(lowerSentence);

      if (match != null) {
        foundVerb = verb;
        verbIndex = match.start;
        break;
      }
    }

    if (foundVerb == null) return null;

    return process(sentence, foundVerb, verbIndex, conversationId, anchorDate);
  }

  /// Process the sentence once a verb is found.
  /// Subclasses can override this if they need custom processing flow,
  /// but usually they should override `extractObject` and `extractCategory`.
  FollowUpItem? process(String sentence, String verb, int verbIndex,
      String conversationId, DateTime anchorDate) {
    // 1. Extract Temporal Information
    final temporalInfo = extractTemporalInfo(sentence, anchorDate);

    // 2. Extract Object
    // Remove timeframe and frequency from the sentence to help object extraction
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

    // Re-calculate verb index in clean sentence
    int cleanVerbIndex =
        cleanSentence.toLowerCase().indexOf(verb.toLowerCase());

    if (cleanVerbIndex == -1) {
      // Verb was removed or lost in cleaning
      return null;
    }

    final object = extractObject(cleanSentence, verb, cleanVerbIndex) ??
        extractObjectFallback(cleanSentence, verb, cleanVerbIndex);
    if (object == null) {
      return null;
    }

    // If subclass fails to extract specific object, maybe return null or generic?
    // User requirements imply specific extractions.

    return FollowUpItem(
      id: _uuid.v4(),
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

  FollowUpCategory get category;

  String? extractObject(String sentence, String verb, int verbIndex);

  String? extractObjectFallback(String sentence, String verb, int verbIndex) {
    String afterVerb = sentence.substring(verbIndex + verb.length).trim();
    afterVerb = afterVerb.replaceAll(RegExp(r'^[,\s]+|[,\s.!]+$'), '');
    if (afterVerb.isNotEmpty) {
      return afterVerb;
    }
    return null;
  }

  FollowUpPriority determinePriority(String sentence) {
    final lower = sentence.toLowerCase();
    if (lower.contains('immediately') ||
        lower.contains('urgently') ||
        lower.contains('right away') ||
        lower.contains('asap')) {
      return FollowUpPriority.high;
    }
    return FollowUpPriority.normal;
  }

  TemporalInfo extractTemporalInfo(String sentence, DateTime anchorDate) {
    String? timeframeRaw;
    String? frequency;
    DateTime? dueDate;

    // Check for deadline patterns
    for (final patternStr in temporalConfig.deadlinePatterns) {
      final pattern = RegExp(patternStr, caseSensitive: false);
      final match = pattern.firstMatch(sentence);
      if (match != null) {
        timeframeRaw = match.group(0);
        if (timeframeRaw != null) {
          dueDate = parseRelativeDate(timeframeRaw, anchorDate);
        }
        break;
      }
    }

    // Check for frequency patterns
    for (final patternStr in temporalConfig.frequencyPatterns) {
      final pattern = RegExp(patternStr, caseSensitive: false);
      final match = pattern.firstMatch(sentence);
      if (match != null) {
        frequency = match.group(0);
        break;
      }
    }

    // Calculate dueDate from frequency if not already set by deadline
    if (dueDate == null && frequency != null) {
      dueDate = calculateNextOccurrenceFromFrequency(frequency, anchorDate);
    }

    return TemporalInfo(timeframeRaw, frequency, dueDate);
  }

  // Copied from FollowUpExtractor and adapted
  static final Map<String, int> _numberWords = {
    'one': 1,
    'two': 2,
    'three': 3,
    'four': 4,
    'five': 5,
    'six': 6,
    'seven': 7,
    'eight': 8,
    'nine': 9,
    'ten': 10,
    'eleven': 11,
    'twelve': 12,
    'thirteen': 13,
    'fourteen': 14,
    'fifteen': 15,
    'sixteen': 16,
    'seventeen': 17,
    'eighteen': 18,
    'nineteen': 19,
    'twenty': 20,
    'thirty': 30,
    'forty': 40,
    'fifty': 50,
    'sixty': 60,
  };

  DateTime? parseRelativeDate(String phrase, DateTime anchorDate) {
    final lowerPhrase = phrase.toLowerCase().trim();

    // "in X [days/weeks/months]" or "within X [days/weeks/months]"
    final durationPattern =
        RegExp(r'(?:in|within)\s+(\w+|\d+)\s+(hour|day|week|month|year)s?');
    final durationMatch = durationPattern.firstMatch(lowerPhrase);
    if (durationMatch != null) {
      final numberStr = durationMatch.group(1)!;
      final unit = durationMatch.group(2)!;

      int? amount = int.tryParse(numberStr);
      amount ??= _numberWords[numberStr];

      if (amount != null) {
        switch (unit) {
          case 'hour':
            return anchorDate.add(Duration(hours: amount));
          case 'day':
            return anchorDate.add(Duration(days: amount));
          case 'week':
            return anchorDate.add(Duration(days: amount * 7));
          case 'month':
            // Simple month addition (approximate)
            return DateTime(anchorDate.year, anchorDate.month + amount,
                anchorDate.day, anchorDate.hour, anchorDate.minute);
          case 'year':
            return DateTime(anchorDate.year + amount, anchorDate.month,
                anchorDate.day, anchorDate.hour, anchorDate.minute);
        }
      }
    }

    // "next [week/month/year]"
    if (lowerPhrase.contains('next week')) {
      return anchorDate.add(const Duration(days: 7));
    }
    if (lowerPhrase.contains('next month')) {
      return DateTime(anchorDate.year, anchorDate.month + 1, anchorDate.day,
          anchorDate.hour, anchorDate.minute);
    }
    if (lowerPhrase.contains('next year')) {
      return DateTime(anchorDate.year + 1, anchorDate.month, anchorDate.day,
          anchorDate.hour, anchorDate.minute);
    }

    // "by [weekday]" e.g., "by Friday"
    final weekdayPattern = RegExp(
        r'by\s+(monday|tuesday|wednesday|thursday|friday|saturday|sunday)');
    final weekdayMatch = weekdayPattern.firstMatch(lowerPhrase);
    if (weekdayMatch != null) {
      final weekdayStr = weekdayMatch.group(1)!;
      int targetWeekday;
      switch (weekdayStr) {
        case 'monday':
          targetWeekday = DateTime.monday;
          break;
        case 'tuesday':
          targetWeekday = DateTime.tuesday;
          break;
        case 'wednesday':
          targetWeekday = DateTime.wednesday;
          break;
        case 'thursday':
          targetWeekday = DateTime.thursday;
          break;
        case 'friday':
          targetWeekday = DateTime.friday;
          break;
        case 'saturday':
          targetWeekday = DateTime.saturday;
          break;
        case 'sunday':
          targetWeekday = DateTime.sunday;
          break;
        default:
          targetWeekday = DateTime.monday;
      }

      // Calculate days until next occurrence of this weekday
      int daysUntil = targetWeekday - anchorDate.weekday;
      if (daysUntil <= 0) {
        daysUntil += 7;
      }
      return anchorDate.add(Duration(days: daysUntil));
    }

    return null;
  }

  DateTime? calculateNextOccurrenceFromFrequency(
      String frequency, DateTime anchorDate) {
    final lowerFreq = frequency.toLowerCase();

    // "every morning" -> Next 8:00 AM
    if (lowerFreq.contains('every morning')) {
      final tomorrow = anchorDate.add(const Duration(days: 1));
      return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 8, 0);
    }

    // "at bedtime" -> Next 9:00 PM
    if (lowerFreq.contains('at bedtime')) {
      final todayBedtime =
          DateTime(anchorDate.year, anchorDate.month, anchorDate.day, 21, 0);
      if (anchorDate.isBefore(todayBedtime)) {
        return todayBedtime;
      } else {
        return todayBedtime.add(const Duration(days: 1));
      }
    }

    // "weekly" or "once a week" -> +7 days
    if (lowerFreq.contains('weekly') || lowerFreq.contains('once a week')) {
      return anchorDate.add(const Duration(days: 7));
    }

    // "daily", "times a day", "times daily" -> +1 day
    if (lowerFreq.contains('daily') ||
        lowerFreq.contains('times a day') ||
        lowerFreq.contains('times daily') ||
        lowerFreq.contains('twice a day')) {
      return anchorDate.add(const Duration(days: 1));
    }

    // "every X hours"
    final hoursPattern = RegExp(r'every\s+(\d+)\s+hours?');
    final match = hoursPattern.firstMatch(lowerFreq);
    if (match != null) {
      final hours = int.parse(match.group(1)!);
      return anchorDate.add(Duration(hours: hours));
    }

    return null;
  }
}

class TemporalInfo {
  final String? timeframeRaw;
  final String? frequency;
  final DateTime? dueDate;

  TemporalInfo(this.timeframeRaw, this.frequency, this.dueDate);
}
