import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/foundation.dart';

class BatteryMonitorService {
  final Battery _battery = Battery();
  Timer? _monitorTimer;

  static const int warningThreshold = 20;
  static const int optimizationThreshold = 15;
  static const int criticalThreshold = 10;

  Future<int> get batteryLevel => _battery.batteryLevel;
  Future<BatteryState> get batteryState => _battery.batteryState;

  /// Checks battery status before recording.
  /// Returns a warning message if battery is low and not charging.
  /// Returns null if safe to proceed.
  Future<String?> checkPreRecordingBattery() async {
    try {
      final level = await _battery.batteryLevel;
      final state = await _battery.batteryState;

      // If charging or full, we are safe
      if (state == BatteryState.charging || state == BatteryState.full) {
        return null;
      }

      if (level < warningThreshold) {
        return 'Battery is low ($level%). Recording may stop unexpectedly. Continue?';
      }
    } catch (e) {
      debugPrint('Error checking battery status: $e');
      // Fail safe: allow recording if we can't check battery
    }
    return null;
  }

  /// Checks if optimization (lower sample rate) should be applied.
  Future<bool> shouldOptimizeRecording() async {
    try {
      final level = await _battery.batteryLevel;
      final state = await _battery.batteryState;

      if (state == BatteryState.charging || state == BatteryState.full) {
        return false;
      }
      return level < optimizationThreshold;
    } catch (e) {
      return false;
    }
  }

  /// Starts monitoring battery level with a callback.
  /// Calls [onUpdate] with current level and state.
  /// Calls [onCritical] if battery drops below critical threshold.
  void startMonitoring({
    required Function(int level, BatteryState state) onUpdate,
    required VoidCallback onCritical,
  }) {
    stopMonitoring();

    // Initial check
    _check(onUpdate, onCritical);

    // Poll every minute
    _monitorTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _check(onUpdate, onCritical);
    });
  }

  Future<void> _check(
    Function(int level, BatteryState state) onUpdate,
    VoidCallback onCritical,
  ) async {
    try {
      final level = await _battery.batteryLevel;
      final state = await _battery.batteryState;

      onUpdate(level, state);

      if (state != BatteryState.charging &&
          state != BatteryState.full &&
          level < criticalThreshold) {
        onCritical();
      }
    } catch (e) {
      debugPrint('Error monitoring battery: $e');
    }
  }

  void stopMonitoring() {
    _monitorTimer?.cancel();
    _monitorTimer = null;
  }
}
