// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model_quantization_service.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class QuantizationFormatAdapter extends TypeAdapter<QuantizationFormat> {
  @override
  final int typeId = 41;

  @override
  QuantizationFormat read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return QuantizationFormat.q2_k;
      case 1:
        return QuantizationFormat.q3_k_m;
      case 2:
        return QuantizationFormat.q4_k_m;
      case 3:
        return QuantizationFormat.q5_k_m;
      case 4:
        return QuantizationFormat.q6_k;
      case 5:
        return QuantizationFormat.q8_0;
      case 6:
        return QuantizationFormat.f16;
      default:
        return QuantizationFormat.q2_k;
    }
  }

  @override
  void write(BinaryWriter writer, QuantizationFormat obj) {
    switch (obj) {
      case QuantizationFormat.q2_k:
        writer.writeByte(0);
        break;
      case QuantizationFormat.q3_k_m:
        writer.writeByte(1);
        break;
      case QuantizationFormat.q4_k_m:
        writer.writeByte(2);
        break;
      case QuantizationFormat.q5_k_m:
        writer.writeByte(3);
        break;
      case QuantizationFormat.q6_k:
        writer.writeByte(4);
        break;
      case QuantizationFormat.q8_0:
        writer.writeByte(5);
        break;
      case QuantizationFormat.f16:
        writer.writeByte(6);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuantizationFormatAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
