// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recording_audit_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RecordingAuditEntryAdapter extends TypeAdapter<RecordingAuditEntry> {
  @override
  final int typeId = 10;

  @override
  RecordingAuditEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RecordingAuditEntry(
      timestamp: fields[0] as DateTime,
      duration: fields[1] as Duration,
      consentConfirmed: fields[2] as bool,
      doctorName: fields[3] as String,
      fileSizeBytes: fields[4] as int,
      deviceId: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, RecordingAuditEntry obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.timestamp)
      ..writeByte(1)
      ..write(obj.duration)
      ..writeByte(2)
      ..write(obj.consentConfirmed)
      ..writeByte(3)
      ..write(obj.doctorName)
      ..writeByte(4)
      ..write(obj.fileSizeBytes)
      ..writeByte(5)
      ..write(obj.deviceId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecordingAuditEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
