// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'follow_up_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FollowUpItemAdapter extends TypeAdapter<FollowUpItem> {
  @override
  final int typeId = 7;

  @override
  FollowUpItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FollowUpItem(
      id: fields[0] as String,
      category: fields[1] as FollowUpCategory,
      verb: fields[2] as String,
      object: fields[3] as String?,
      description: fields[4] as String,
      priority: fields[5] as FollowUpPriority,
      dueDate: fields[6] as DateTime?,
      timeframeRaw: fields[7] as String?,
      frequency: fields[8] as String?,
      sourceConversationId: fields[9] as String,
      createdAt: fields[10] as DateTime,
      isCompleted: fields[11] as bool,
      calendarEventId: fields[12] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, FollowUpItem obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.category)
      ..writeByte(2)
      ..write(obj.verb)
      ..writeByte(3)
      ..write(obj.object)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.priority)
      ..writeByte(6)
      ..write(obj.dueDate)
      ..writeByte(7)
      ..write(obj.timeframeRaw)
      ..writeByte(8)
      ..write(obj.frequency)
      ..writeByte(9)
      ..write(obj.sourceConversationId)
      ..writeByte(10)
      ..write(obj.createdAt)
      ..writeByte(11)
      ..write(obj.isCompleted)
      ..writeByte(12)
      ..write(obj.calendarEventId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FollowUpItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class FollowUpCategoryAdapter extends TypeAdapter<FollowUpCategory> {
  @override
  final int typeId = 8;

  @override
  FollowUpCategory read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return FollowUpCategory.medication;
      case 1:
        return FollowUpCategory.appointment;
      case 2:
        return FollowUpCategory.test;
      case 3:
        return FollowUpCategory.lifestyle;
      case 4:
        return FollowUpCategory.monitoring;
      case 5:
        return FollowUpCategory.warning;
      case 6:
        return FollowUpCategory.decision;
      default:
        return FollowUpCategory.medication;
    }
  }

  @override
  void write(BinaryWriter writer, FollowUpCategory obj) {
    switch (obj) {
      case FollowUpCategory.medication:
        writer.writeByte(0);
        break;
      case FollowUpCategory.appointment:
        writer.writeByte(1);
        break;
      case FollowUpCategory.test:
        writer.writeByte(2);
        break;
      case FollowUpCategory.lifestyle:
        writer.writeByte(3);
        break;
      case FollowUpCategory.monitoring:
        writer.writeByte(4);
        break;
      case FollowUpCategory.warning:
        writer.writeByte(5);
        break;
      case FollowUpCategory.decision:
        writer.writeByte(6);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FollowUpCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class FollowUpPriorityAdapter extends TypeAdapter<FollowUpPriority> {
  @override
  final int typeId = 9;

  @override
  FollowUpPriority read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return FollowUpPriority.high;
      case 1:
        return FollowUpPriority.normal;
      default:
        return FollowUpPriority.high;
    }
  }

  @override
  void write(BinaryWriter writer, FollowUpPriority obj) {
    switch (obj) {
      case FollowUpPriority.high:
        writer.writeByte(0);
        break;
      case FollowUpPriority.normal:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FollowUpPriorityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
