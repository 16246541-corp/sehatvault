// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'issue_report.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class IssueReportAdapter extends TypeAdapter<IssueReport> {
  @override
  final int typeId = 15;

  @override
  IssueReport read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return IssueReport(
      id: fields[0] as String,
      timestamp: fields[1] as DateTime,
      description: fields[2] as String,
      deviceMetrics: (fields[3] as Map).cast<String, dynamic>(),
      logLines: (fields[4] as List).cast<String>(),
      isRedacted: fields[5] as bool,
      status: fields[6] as String,
      originalHash: fields[7] as String,
      redactedHash: fields[8] as String,
    );
  }

  @override
  void write(BinaryWriter writer, IssueReport obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.timestamp)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.deviceMetrics)
      ..writeByte(4)
      ..write(obj.logLines)
      ..writeByte(5)
      ..write(obj.isRedacted)
      ..writeByte(6)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.originalHash)
      ..writeByte(8)
      ..write(obj.redactedHash);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IssueReportAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
