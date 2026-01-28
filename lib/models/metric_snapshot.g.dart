// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'metric_snapshot.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MetricSnapshotAdapter extends TypeAdapter<MetricSnapshot> {
  @override
  final int typeId = 68;

  @override
  MetricSnapshot read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MetricSnapshot(
      metricName: fields[0] as String,
      value: fields[1] as double,
      unit: fields[2] as String,
      measuredAt: fields[3] as DateTime,
      sourceRecordId: fields[4] as String,
      isOutsideReference: fields[5] as bool,
      createdAt: fields[6] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, MetricSnapshot obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.metricName)
      ..writeByte(1)
      ..write(obj.value)
      ..writeByte(2)
      ..write(obj.unit)
      ..writeByte(3)
      ..write(obj.measuredAt)
      ..writeByte(4)
      ..write(obj.sourceRecordId)
      ..writeByte(5)
      ..write(obj.isOutsideReference)
      ..writeByte(6)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MetricSnapshotAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
