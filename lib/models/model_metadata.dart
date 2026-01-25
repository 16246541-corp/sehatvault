import 'package:hive/hive.dart';
import '../services/model_quantization_service.dart';

part 'model_metadata.g.dart';

@HiveType(typeId: 3)
class ModelMetadata extends HiveObject {
  @HiveField(0)
  final String version;

  @HiveField(1)
  final String checksum;

  @HiveField(2)
  final DateTime releaseDate;

  @HiveField(3)
  final QuantizationFormat quantization;

  @HiveField(4)
  final String? signature;

  @HiveField(5)
  final String? publicKey;

  ModelMetadata({
    required this.version,
    required this.checksum,
    required this.releaseDate,
    this.quantization = QuantizationFormat.q4_k_m,
    this.signature,
    this.publicKey,
  });
}
