import 'package:hive/hive.dart';

part 'model_metadata.g.dart';

@HiveType(typeId: 3)
class ModelMetadata extends HiveObject {
  @HiveField(0)
  final String version;

  @HiveField(1)
  final String checksum;

  @HiveField(2)
  final DateTime releaseDate;

  ModelMetadata({
    required this.version,
    required this.checksum,
    required this.releaseDate,
  });
}
