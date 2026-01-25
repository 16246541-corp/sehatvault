import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:system_info2/system_info2.dart';
import 'platform_detector.dart';

/// Represents the current memory pressure state.
enum MemoryPressureLevel {
  normal,
  warning,
  critical,
}

/// Information about current memory usage.
class MemoryStatus {
  final double totalRAMGB;
  final double usedRAMGB;
  final double availableRAMGB;
  final MemoryPressureLevel level;
  final DateTime timestamp;

  MemoryStatus({
    required this.totalRAMGB,
    required this.usedRAMGB,
    required this.availableRAMGB,
    required this.level,
    required this.timestamp,
  });

  double get usagePercentage => (usedRAMGB / totalRAMGB) * 100;

  @override
  String toString() =>
      'MemoryStatus(Level: $level, Usage: ${usagePercentage.toStringAsFixed(1)}%, Available: ${availableRAMGB.toStringAsFixed(2)}GB)';
}

/// Service for monitoring device memory pressure and usage.
class MemoryMonitorService with WidgetsBindingObserver {
  static final MemoryMonitorService _instance = MemoryMonitorService._internal();
  factory MemoryMonitorService() => _instance;

  MemoryMonitorService._internal() {
    WidgetsBinding.instance.addObserver(this);
    _startMonitoring();
  }

  final _statusController = StreamController<MemoryStatus>.broadcast();
  Stream<MemoryStatus> get onStatusChanged => _statusController.stream;

  MemoryStatus? _lastStatus;
  MemoryStatus? get lastStatus => _lastStatus;

  Timer? _monitorTimer;
  final Duration _interval = const Duration(seconds: 5);

  void _startMonitoring() {
    _monitorTimer = Timer.periodic(_interval, (_) => _checkMemory());
    _checkMemory(); // Initial check
  }

  Future<void> _checkMemory() async {
    try {
      final totalMemory = SysInfo.getTotalPhysicalMemory();
      final freeMemory = SysInfo.getFreePhysicalMemory();
      
      final totalGB = totalMemory / (1024 * 1024 * 1024);
      final freeGB = freeMemory / (1024 * 1024 * 1024);
      final usedGB = totalGB - freeGB;
      
      final usageRatio = usedGB / totalGB;
      
      MemoryPressureLevel level = MemoryPressureLevel.normal;
      if (usageRatio > 0.9 || freeGB < 0.5) {
        level = MemoryPressureLevel.critical;
      } else if (usageRatio > 0.75 || freeGB < 1.0) {
        level = MemoryPressureLevel.warning;
      }

      final status = MemoryStatus(
        totalRAMGB: totalGB,
        usedRAMGB: usedGB,
        availableRAMGB: freeGB,
        level: level,
        timestamp: DateTime.now(),
      );

      _lastStatus = status;
      _statusController.add(status);
      
      if (level != MemoryPressureLevel.normal) {
        debugPrint('Memory Monitor: Low memory detected! $status');
      }
    } catch (e) {
      debugPrint('Memory Monitor: Error checking memory: $e');
    }
  }

  @override
  void didHaveMemoryPressure() {
    debugPrint('Memory Monitor: OS reported memory pressure!');
    // Immediate check when OS reports pressure
    _checkMemory();
  }

  /// Forces a memory check and returns the result.
  Future<MemoryStatus> refresh() async {
    await _checkMemory();
    return _lastStatus!;
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _monitorTimer?.cancel();
    _statusController.close();
  }
}
