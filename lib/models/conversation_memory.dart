import 'package:hive/hive.dart';

part 'conversation_memory.g.dart';

@HiveType(typeId: 25)
class ConversationMemory extends HiveObject {
  @HiveField(0)
  String conversationId;

  @HiveField(1)
  List<MemoryEntry> entries;

  @HiveField(2)
  DateTime lastUpdatedAt;

  @HiveField(3)
  Map<String, dynamic> metrics;

  ConversationMemory({
    required this.conversationId,
    required this.entries,
    required this.lastUpdatedAt,
    this.metrics = const {},
  });
}

@HiveType(typeId: 26)
class MemoryEntry extends HiveObject {
  @HiveField(0)
  final String role; // 'user', 'assistant', 'system'

  @HiveField(1)
  final String content;

  @HiveField(2)
  final DateTime timestamp;

  @HiveField(3)
  final bool isRedacted;

  @HiveField(4)
  final Map<String, dynamic> metadata;

  MemoryEntry({
    required this.role,
    required this.content,
    required this.timestamp,
    this.isRedacted = false,
    this.metadata = const {},
  });
}
