import 'package:flutter/foundation.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  /// Logs a custom event
  Future<void> logEvent(String name, {Map<String, dynamic>? parameters}) async {
    debugPrint('Analytics: Event $name, params: $parameters');
    // In a real implementation, this would send data to an analytics backend
  }

  /// Logs a performance metric (e.g., duration)
  Future<void> logMetric(String name, double value) async {
    debugPrint('Analytics: Metric $name = $value');
  }
}
