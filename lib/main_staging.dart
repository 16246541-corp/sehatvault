import 'main_common.dart';
import 'config/app_config.dart';

void main() async {
  final config = AppConfig(
    appTitle: 'SehatLocker (Staging)',
    apiBaseUrl: 'https://staging-api.sehatlocker.com',
    flavor: AppFlavor.staging,
    enableDetailedLogging: true,
  );

  await mainCommon(config);
}
