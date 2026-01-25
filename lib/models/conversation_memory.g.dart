// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_memory.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ConversationMemoryAdapter extends TypeAdapter<ConversationMemory> {
  @override
  final int typeId = 25;

  @override
  ConversationMemory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ConversationMemory(
      conversationId: fields[0] as String,
      entries: (fields[1] as List).cast<MemoryEntry>(),
      lastUpdatedAt: fields[2] as DateTime,
      metrics: (fields[3] as Map).cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, ConversationMemory obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.conversationId)
      ..writeByte(1)
      ..write(obj.entries)
      ..writeByte(2)
      ..write(obj.lastUpdatedAt)
      ..writeByte(3)
      ..write(obj.metrics);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConversationMemoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MemoryEntryAdapter extends TypeAdapter<MemoryEntry> {
  @override
  final int typeId = 26;

  @override
  MemoryEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MemoryEntry(
      role: fields[0] as String,
      content: fields[1] as String,
      timestamp: fields[2] as DateTime,
      isRedacted: fields[3] as bool,
      metadata: (fields[4] as Map).cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, MemoryEntry obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.role)
      ..writeByte(1)
      ..write(obj.content)
      ..writeByte(2)
      ..write(obj.timestamp)
      ..writeByte(3)
      ..write(obj.isRedacted)
      ..writeByte(4)
      ..write(obj.metadata);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MemoryEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
