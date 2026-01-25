enum AppFlavor {
  dev,
  staging,
  prod,
}

class AppConfig {
  final String appTitle;
  final String apiBaseUrl;
  final AppFlavor flavor;
  final bool enableDetailedLogging;

  AppConfig({
    required this.appTitle,
    required this.apiBaseUrl,
    required this.flavor,
    this.enableDetailedLogging = false,
  });

  static AppConfig? _instance;

  static void setConfig(AppConfig config) {
    _instance = config;
  }

  static AppConfig get instance {
    if (_instance == null) {
      throw Exception('AppConfig not initialized. Call setConfig() before accessing instance.');
    }
    return _instance!;
  }

  bool get isDev => flavor == AppFlavor.dev;
  bool get isStaging => flavor == AppFlavor.staging;
  bool get isProd => flavor == AppFlavor.prod;
}
