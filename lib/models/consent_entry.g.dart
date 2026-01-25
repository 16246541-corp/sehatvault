// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'consent_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ConsentEntryAdapter extends TypeAdapter<ConsentEntry> {
  @override
  final int typeId = 16;

  @override
  ConsentEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ConsentEntry(
      id: fields[0] as String,
      templateId: fields[1] as String,
      version: fields[2] as String,
      timestamp: fields[3] as DateTime,
      userId: fields[4] as String,
      scope: fields[5] as String,
      granted: fields[6] as bool,
      contentHash: fields[7] as String,
      deviceId: fields[8] as String?,
      ipAddress: fields[9] as String?,
      revocationDate: fields[10] as DateTime?,
      revocationReason: fields[11] as String?,
      syncStatus: fields[12] as String,
      syncedAt: fields[13] as DateTime?,
      lastSyncAttempt: fields[14] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, ConsentEntry obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.templateId)
      ..writeByte(2)
      ..write(obj.version)
      ..writeByte(3)
      ..write(obj.timestamp)
      ..writeByte(4)
      ..write(obj.userId)
      ..writeByte(5)
      ..write(obj.scope)
      ..writeByte(6)
      ..write(obj.granted)
      ..writeByte(7)
      ..write(obj.contentHash)
      ..writeByte(8)
      ..write(obj.deviceId)
      ..writeByte(9)
      ..write(obj.ipAddress)
      ..writeByte(10)
      ..write(obj.revocationDate)
      ..writeByte(11)
      ..write(obj.revocationReason)
      ..writeByte(12)
      ..write(obj.syncStatus)
      ..writeByte(13)
      ..write(obj.syncedAt)
      ..writeByte(14)
      ..write(obj.lastSyncAttempt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConsentEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
