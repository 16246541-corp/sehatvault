// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'batch_task.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BatchTaskAdapter extends TypeAdapter<BatchTask> {
  @override
  final int typeId = 35;

  @override
  BatchTask read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BatchTask(
      id: fields[0] as String,
      title: fields[1] as String,
      filePath: fields[2] as String,
      status: fields[3] as BatchTaskStatus,
      priority: fields[4] as BatchTaskPriority,
      progress: fields[5] as double,
      error: fields[6] as String?,
      createdAt: fields[7] as DateTime,
      startedAt: fields[8] as DateTime?,
      completedAt: fields[9] as DateTime?,
      metadata: (fields[10] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, BatchTask obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.filePath)
      ..writeByte(3)
      ..write(obj.status)
      ..writeByte(4)
      ..write(obj.priority)
      ..writeByte(5)
      ..write(obj.progress)
      ..writeByte(6)
      ..write(obj.error)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.startedAt)
      ..writeByte(9)
      ..write(obj.completedAt)
      ..writeByte(10)
      ..write(obj.metadata);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BatchTaskAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BatchTaskStatusAdapter extends TypeAdapter<BatchTaskStatus> {
  @override
  final int typeId = 33;

  @override
  BatchTaskStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return BatchTaskStatus.pending;
      case 1:
        return BatchTaskStatus.processing;
      case 2:
        return BatchTaskStatus.completed;
      case 3:
        return BatchTaskStatus.failed;
      case 4:
        return BatchTaskStatus.cancelled;
      default:
        return BatchTaskStatus.pending;
    }
  }

  @override
  void write(BinaryWriter writer, BatchTaskStatus obj) {
    switch (obj) {
      case BatchTaskStatus.pending:
        writer.writeByte(0);
        break;
      case BatchTaskStatus.processing:
        writer.writeByte(1);
        break;
      case BatchTaskStatus.completed:
        writer.writeByte(2);
        break;
      case BatchTaskStatus.failed:
        writer.writeByte(3);
        break;
      case BatchTaskStatus.cancelled:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BatchTaskStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BatchTaskPriorityAdapter extends TypeAdapter<BatchTaskPriority> {
  @override
  final int typeId = 34;

  @override
  BatchTaskPriority read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return BatchTaskPriority.low;
      case 1:
        return BatchTaskPriority.normal;
      case 2:
        return BatchTaskPriority.high;
      default:
        return BatchTaskPriority.low;
    }
  }

  @override
  void write(BinaryWriter writer, BatchTaskPriority obj) {
    switch (obj) {
      case BatchTaskPriority.low:
        writer.writeByte(0);
        break;
      case BatchTaskPriority.normal:
        writer.writeByte(1);
        break;
      case BatchTaskPriority.high:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BatchTaskPriorityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
