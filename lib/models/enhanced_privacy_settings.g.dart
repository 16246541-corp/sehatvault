// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'enhanced_privacy_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EnhancedPrivacySettingsAdapter
    extends TypeAdapter<EnhancedPrivacySettings> {
  @override
  final int typeId = 12;

  @override
  EnhancedPrivacySettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EnhancedPrivacySettings(
      requireBiometricsForSensitiveData: fields[0] as bool,
      requireBiometricsForExport: fields[1] as bool,
      requireBiometricsForModelChange: fields[2] as bool,
      requireBiometricsForSettings: fields[3] as bool,
      tempFileRetentionMinutes: fields[4] as int,
    );
  }

  @override
  void write(BinaryWriter writer, EnhancedPrivacySettings obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.requireBiometricsForSensitiveData)
      ..writeByte(1)
      ..write(obj.requireBiometricsForExport)
      ..writeByte(2)
      ..write(obj.requireBiometricsForModelChange)
      ..writeByte(3)
      ..write(obj.requireBiometricsForSettings)
      ..writeByte(4)
      ..write(obj.tempFileRetentionMinutes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EnhancedPrivacySettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
