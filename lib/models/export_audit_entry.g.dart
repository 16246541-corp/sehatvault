// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'export_audit_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExportAuditEntryAdapter extends TypeAdapter<ExportAuditEntry> {
  @override
  final int typeId = 11;

  @override
  ExportAuditEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExportAuditEntry(
      timestamp: fields[0] as DateTime,
      exportType: fields[1] as String,
      format: fields[2] as String,
      recipientType: fields[3] as String,
      entityId: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ExportAuditEntry obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.timestamp)
      ..writeByte(1)
      ..write(obj.exportType)
      ..writeByte(2)
      ..write(obj.format)
      ..writeByte(3)
      ..write(obj.recipientType)
      ..writeByte(4)
      ..write(obj.entityId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExportAuditEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
