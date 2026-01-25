// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_audit_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LocalAuditEntryAdapter extends TypeAdapter<LocalAuditEntry> {
  @override
  final int typeId = 17;

  @override
  LocalAuditEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocalAuditEntry(
      id: fields[0] as String,
      timestamp: fields[1] as DateTime,
      action: fields[2] as String,
      details: (fields[3] as Map).cast<String, String>(),
      previousHash: fields[4] as String,
      hash: fields[5] as String,
      sessionId: fields[6] as String?,
      sensitivity: fields[7] as String,
    );
  }

  @override
  void write(BinaryWriter writer, LocalAuditEntry obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.timestamp)
      ..writeByte(2)
      ..write(obj.action)
      ..writeByte(3)
      ..write(obj.details)
      ..writeByte(4)
      ..write(obj.previousHash)
      ..writeByte(5)
      ..write(obj.hash)
      ..writeByte(6)
      ..write(obj.sessionId)
      ..writeByte(7)
      ..write(obj.sensitivity);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalAuditEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
