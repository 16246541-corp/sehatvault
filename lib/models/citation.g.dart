// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'citation.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CitationAdapter extends TypeAdapter<Citation> {
  @override
  final int typeId = 14;

  @override
  Citation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Citation(
      id: fields[0] as String?,
      sourceTitle: fields[1] as String,
      sourceUrl: fields[2] as String?,
      sourceDate: fields[3] as DateTime?,
      textSnippet: fields[4] as String?,
      confidenceScore: fields[5] as double,
      type: fields[6] as String,
      relatedField: fields[7] as String?,
      authors: fields[8] as String?,
      publication: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Citation obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.sourceTitle)
      ..writeByte(2)
      ..write(obj.sourceUrl)
      ..writeByte(3)
      ..write(obj.sourceDate)
      ..writeByte(4)
      ..write(obj.textSnippet)
      ..writeByte(5)
      ..write(obj.confidenceScore)
      ..writeByte(6)
      ..write(obj.type)
      ..writeByte(7)
      ..write(obj.relatedField)
      ..writeByte(8)
      ..write(obj.authors)
      ..writeByte(9)
      ..write(obj.publication);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CitationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
