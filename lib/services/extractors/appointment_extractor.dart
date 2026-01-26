import '../../models/follow_up_item.dart';
import 'base_extractor.dart';

class AppointmentExtractor extends BaseExtractor {
  AppointmentExtractor(super.dictionaryService, super.temporalConfig);

  @override
  List<String> get verbs => [
        "schedule",
        "book",
        "see",
        "visit",
        "refer",
        "consult",
        "return",
        "come back",
        "call",
        "contact",
        "set"
      ];

  @override
  FollowUpCategory get category => FollowUpCategory.appointment;

  @override
  String? extractObject(String sentence, String verb, int verbIndex) {
    int start = (verbIndex - 80).clamp(0, sentence.length);
    int end = (verbIndex + verb.length + 80).clamp(0, sentence.length);
    String context = sentence.substring(start, end);

    // 1. Try finding a specialist
    String? specialist = dictionaryService.findSpecialist(context);
    if (specialist != null) return specialist;

    // 2. Try finding "Dr. [Name]"
    // Matches "Dr. Smith", "Dr. Jane Doe"
    final doctorPattern = RegExp(r'\bDr\.\s+[A-Z][a-z]+(?:\s+[A-Z][a-z]+)?\b');
    final doctorMatch =
        doctorPattern.firstMatch(sentence); // Check full sentence for name
    if (doctorMatch != null) {
      return doctorMatch.group(0);
    }

    // 3. specific keywords
    if (context.toLowerCase().contains('follow-up')) return 'follow-up';
    if (context.toLowerCase().contains('clinic')) return 'clinic';
    if (context.toLowerCase().contains('hospital')) return 'hospital';
    if (context.toLowerCase().contains('lab')) return 'lab';

    return 'follow-up';
  }
}
