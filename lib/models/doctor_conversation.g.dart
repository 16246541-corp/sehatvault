// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'doctor_conversation.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DoctorConversationAdapter extends TypeAdapter<DoctorConversation> {
  @override
  final int typeId = 5;

  @override
  DoctorConversation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DoctorConversation(
      id: fields[0] as String,
      title: fields[1] as String,
      duration: fields[2] as int,
      encryptedAudioPath: fields[3] as String,
      transcript: fields[4] as String,
      createdAt: fields[5] as DateTime,
      followUpItems: (fields[6] as List).cast<String>(),
      doctorName: fields[7] as String,
      segments: (fields[8] as List?)?.cast<ConversationSegment>(),
      originalTranscript: fields[9] as String?,
      editedAt: fields[10] as DateTime?,
      complianceVersion: fields[11] as String?,
      complianceReviewDate: fields[12] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, DoctorConversation obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.duration)
      ..writeByte(3)
      ..write(obj.encryptedAudioPath)
      ..writeByte(4)
      ..write(obj.transcript)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.followUpItems)
      ..writeByte(7)
      ..write(obj.doctorName)
      ..writeByte(8)
      ..write(obj.segments)
      ..writeByte(9)
      ..write(obj.originalTranscript)
      ..writeByte(10)
      ..write(obj.editedAt)
      ..writeByte(11)
      ..write(obj.complianceVersion)
      ..writeByte(12)
      ..write(obj.complianceReviewDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DoctorConversationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ConversationSegmentAdapter extends TypeAdapter<ConversationSegment> {
  @override
  final int typeId = 6;

  @override
  ConversationSegment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ConversationSegment(
      text: fields[0] as String,
      startTimeMs: fields[1] as int,
      endTimeMs: fields[2] as int,
      speaker: fields[3] as String,
      speakerConfidence: fields[4] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, ConversationSegment obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.text)
      ..writeByte(1)
      ..write(obj.startTimeMs)
      ..writeByte(2)
      ..write(obj.endTimeMs)
      ..writeByte(3)
      ..write(obj.speaker)
      ..writeByte(4)
      ..write(obj.speakerConfidence);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConversationSegmentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
