import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'follow_up_item.g.dart';

@HiveType(typeId: 8)
enum FollowUpCategory {
  @HiveField(0)
  medication,
  @HiveField(1)
  appointment,
  @HiveField(2)
  test,
  @HiveField(3)
  lifestyle,
  @HiveField(4)
  monitoring,
  @HiveField(5)
  warning,
  @HiveField(6)
  decision;

  String toDisplayString() {
    switch (this) {
      case FollowUpCategory.medication:
        return 'Medication';
      case FollowUpCategory.appointment:
        return 'Appointment';
      case FollowUpCategory.test:
        return 'Test';
      case FollowUpCategory.lifestyle:
        return 'Lifestyle';
      case FollowUpCategory.monitoring:
        return 'Monitoring';
      case FollowUpCategory.warning:
        return 'Warning';
      case FollowUpCategory.decision:
        return 'Decision';
    }
  }

  IconData get icon {
    switch (this) {
      case FollowUpCategory.medication:
        return Icons.medication;
      case FollowUpCategory.appointment:
        return Icons.calendar_today;
      case FollowUpCategory.test:
        return Icons.science;
      case FollowUpCategory.lifestyle:
        return Icons.self_improvement;
      case FollowUpCategory.monitoring:
        return Icons.monitor_heart;
      case FollowUpCategory.warning:
        return Icons.warning_amber;
      case FollowUpCategory.decision:
        return Icons.psychology;
    }
  }
}

@HiveType(typeId: 9)
enum FollowUpPriority {
  @HiveField(0)
  high,
  @HiveField(1)
  normal,
}

@HiveType(typeId: 7)
class FollowUpItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final FollowUpCategory category;

  @HiveField(2)
  final String verb;

  @HiveField(3)
  final String? object;

  @HiveField(4)
  final String description;

  @HiveField(5)
  final FollowUpPriority priority;

  @HiveField(6)
  final DateTime? dueDate;

  @HiveField(7)
  final String? timeframeRaw;

  @HiveField(8)
  final String? frequency;

  @HiveField(9)
  final String sourceConversationId;

  @HiveField(10)
  final DateTime createdAt;

  @HiveField(11)
  bool isCompleted;

  @HiveField(12)
  String? calendarEventId;

  @HiveField(13)
  bool isPotentialDuplicate;

  @HiveField(14)
  String? linkedRecordId;

  @HiveField(15)
  String? linkedEntityName;

  @HiveField(16)
  String? linkedContext;

  FollowUpItem({
    required this.id,
    required this.category,
    required this.verb,
    this.object,
    required this.description,
    required this.priority,
    this.dueDate,
    this.timeframeRaw,
    this.frequency,
    required this.sourceConversationId,
    required this.createdAt,
    this.isCompleted = false,
    this.calendarEventId,
    this.isPotentialDuplicate = false,
    this.linkedRecordId,
    this.linkedEntityName,
    this.linkedContext,
  });

  String get structuredTitle {
    final parts = [
      verb.isNotEmpty ? '${verb[0].toUpperCase()}${verb.substring(1)}' : verb,
      object,
      timeframeRaw,
    ];
    return parts.where((part) => part != null && part.isNotEmpty).join(' ');
  }
}
