import 'package:hive/hive.dart';

part 'doctor_conversation.g.dart';

@HiveType(typeId: 5)
class DoctorConversation extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final int duration;

  @HiveField(3)
  final String encryptedAudioPath;

  @HiveField(4)
  String transcript;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  final List<String> followUpItems;

  @HiveField(7)
  final String doctorName;

  @HiveField(8)
  List<ConversationSegment>? segments;

  DoctorConversation({
    required this.id,
    required this.title,
    required this.duration,
    required this.encryptedAudioPath,
    required this.transcript,
    required this.createdAt,
    required this.followUpItems,
    required this.doctorName,
    this.segments,
  });
}

@HiveType(typeId: 6)
class ConversationSegment extends HiveObject {
  @HiveField(0)
  String text;

  @HiveField(1)
  final int startTimeMs;

  @HiveField(2)
  final int endTimeMs;

  @HiveField(3)
  String speaker; // "User" or "Doctor"

  ConversationSegment({
    required this.text,
    required this.startTimeMs,
    required this.endTimeMs,
    required this.speaker,
  });
}
