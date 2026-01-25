import 'main_common.dart';
import 'config/app_config.dart';

void main() async {
  final config = AppConfig(
    appTitle: 'SehatLocker (Dev)',
    apiBaseUrl: 'https://dev-api.sehatlocker.com',
    flavor: AppFlavor.dev,
    enableDetailedLogging: true,
  );

  await mainCommon(config);
}
