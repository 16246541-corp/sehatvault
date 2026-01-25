import 'main_common.dart';
import 'config/app_config.dart';

void main() async {
  final config = AppConfig(
    appTitle: 'SehatLocker',
    apiBaseUrl: 'https://api.sehatlocker.com',
    flavor: AppFlavor.prod,
    enableDetailedLogging: false,
  );

  await mainCommon(config);
}
