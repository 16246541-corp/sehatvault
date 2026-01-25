// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_usage_metric.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AIUsageMetricAdapter extends TypeAdapter<AIUsageMetric> {
  @override
  final int typeId = 32;

  @override
  AIUsageMetric read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AIUsageMetric(
      timestamp: fields[0] as DateTime,
      modelId: fields[1] as String,
      tokensPerSecond: fields[2] as double,
      totalTokens: fields[3] as int,
      loadTimeMs: fields[4] as double,
      peakMemoryMb: fields[5] as double,
      operationType: fields[6] as String?,
      isSuccessful: fields[7] as bool,
      metadata: (fields[8] as Map?)?.cast<String, String>(),
    );
  }

  @override
  void write(BinaryWriter writer, AIUsageMetric obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.timestamp)
      ..writeByte(1)
      ..write(obj.modelId)
      ..writeByte(2)
      ..write(obj.tokensPerSecond)
      ..writeByte(3)
      ..write(obj.totalTokens)
      ..writeByte(4)
      ..write(obj.loadTimeMs)
      ..writeByte(5)
      ..write(obj.peakMemoryMb)
      ..writeByte(6)
      ..write(obj.operationType)
      ..writeByte(7)
      ..write(obj.isSuccessful)
      ..writeByte(8)
      ..write(obj.metadata);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AIUsageMetricAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
