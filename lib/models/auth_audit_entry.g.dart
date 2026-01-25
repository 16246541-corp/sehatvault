// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_audit_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AuthAuditEntryAdapter extends TypeAdapter<AuthAuditEntry> {
  @override
  final int typeId = 13;

  @override
  AuthAuditEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AuthAuditEntry(
      timestamp: fields[0] as DateTime,
      action: fields[1] as String,
      success: fields[2] as bool,
      failureReason: fields[3] as String?,
      deviceId: fields[4] as String,
      batteryLevel: fields[5] as int,
    );
  }

  @override
  void write(BinaryWriter writer, AuthAuditEntry obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.timestamp)
      ..writeByte(1)
      ..write(obj.action)
      ..writeByte(2)
      ..write(obj.success)
      ..writeByte(3)
      ..write(obj.failureReason)
      ..writeByte(4)
      ..write(obj.deviceId)
      ..writeByte(5)
      ..write(obj.batteryLevel);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthAuditEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
