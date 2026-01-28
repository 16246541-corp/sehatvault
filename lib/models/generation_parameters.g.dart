// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'generation_parameters.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GenerationParametersAdapter extends TypeAdapter<GenerationParameters> {
  @override
  final int typeId = 31;

  @override
  GenerationParameters read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GenerationParameters(
      temperature: fields[0] == null ? 0.7 : fields[0] as double,
      topP: fields[1] == null ? 0.9 : fields[1] as double,
      topK: fields[2] == null ? 40 : fields[2] as int,
      maxTokens: fields[3] == null ? 1024 : fields[3] as int,
      presencePenalty: fields[4] == null ? 0.0 : fields[4] as double,
      frequencyPenalty: fields[5] == null ? 0.0 : fields[5] as double,
      seed: fields[6] == null ? -1 : fields[6] as int,
      enablePatternContext: fields[7] == null ? false : fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, GenerationParameters obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.temperature)
      ..writeByte(1)
      ..write(obj.topP)
      ..writeByte(2)
      ..write(obj.topK)
      ..writeByte(3)
      ..write(obj.maxTokens)
      ..writeByte(4)
      ..write(obj.presencePenalty)
      ..writeByte(5)
      ..write(obj.frequencyPenalty)
      ..writeByte(6)
      ..write(obj.seed)
      ..writeByte(7)
      ..write(obj.enablePatternContext);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GenerationParametersAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
