// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document_extraction.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DocumentExtractionAdapter extends TypeAdapter<DocumentExtraction> {
  @override
  final int typeId = 4;

  @override
  DocumentExtraction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DocumentExtraction(
      id: fields[0] as String?,
      originalImagePath: fields[1] as String,
      extractedText: fields[2] as String,
      createdAt: fields[3] as DateTime?,
      confidenceScore: fields[4] as double,
      structuredData: (fields[5] as Map).cast<String, dynamic>(),
      contentHash: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, DocumentExtraction obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.originalImagePath)
      ..writeByte(2)
      ..write(obj.extractedText)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.confidenceScore)
      ..writeByte(5)
      ..write(obj.structuredData)
      ..writeByte(6)
      ..write(obj.contentHash);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocumentExtractionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
