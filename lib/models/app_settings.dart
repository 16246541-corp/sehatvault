import 'package:hive/hive.dart';
import 'model_metadata.dart';

part 'app_settings.g.dart';

@HiveType(typeId: 2)
class AppSettings extends HiveObject {
  @HiveField(0)
  String selectedModelId;

  @HiveField(1)
  bool autoSelectModel;

  @HiveField(2)
  Map<String, ModelMetadata> modelMetadataMap;

  AppSettings({
    required this.selectedModelId,
    this.autoSelectModel = true,
    Map<String, ModelMetadata>? modelMetadataMap,
  }) : modelMetadataMap = modelMetadataMap ?? {};

  factory AppSettings.defaultSettings() {
    return AppSettings(
      selectedModelId: 'med_gemma_4b',
      autoSelectModel: true,
    );
  }
}
