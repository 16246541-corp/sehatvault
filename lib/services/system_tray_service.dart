import 'dart:async';
import 'dart:io' show Platform, File, Process, Directory;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import 'conversation_recorder_service.dart';
import 'battery_monitor_service.dart';
import 'session_manager.dart';
import 'platform_detector.dart';
import 'window_manager_service.dart';
import 'keyboard_shortcut_service.dart';

/// States for the system tray icon indicators.
enum TrayRecordingState { idle, recording, paused }

/// Service for managing the system tray integration on desktop platforms.
class SystemTrayService {
  static final SystemTrayService _instance = SystemTrayService._internal();
  factory SystemTrayService() => _instance;
  SystemTrayService._internal();

  static const MethodChannel _channel =
      MethodChannel('com.sehatlocker/system_tray');

  bool _isInitialized = false;
  TrayRecordingState _currentRecordingState = TrayRecordingState.idle;
  int _batteryLevel = 100;
  bool _isLocked = false;
  bool _isEnterprise = false;

  /// Initializes the system tray service.
  Future<void> init() async {
    if (_isInitialized) return;

    final capabilities = await PlatformDetector().getCapabilities();
    if (!capabilities.isDesktop) return;

    _isEnterprise = await _detectEnterprise();
    _isLocked = SessionManager().isLocked;

    await _setupTray();
    _isInitialized = true;
    _startListeners();
  }

  /// Sets up the initial tray configuration via platform channel.
  Future<void> _setupTray() async {
    try {
      await _channel.invokeMethod('initTray', {
        'tooltip': 'Sehat Locker - Privacy Protected',
        'isEnterprise': _isEnterprise,
      });
      await updateTray();
    } catch (e) {
      debugPrint('Error setting up system tray: $e');
    }
  }

  /// Updates the tray icon and menu based on current application state.
  Future<void> updateTray() async {
    if (!_isInitialized) return;

    try {
      await _channel.invokeMethod('updateTray', {
        'recordingState': _currentRecordingState.name,
        'batteryLevel': _batteryLevel,
        'isLocked': _isLocked,
        'tooltip': _getTooltipContent(),
        'menuItems': _buildMenuItems(),
      });
    } catch (e) {
      debugPrint('Error updating system tray: $e');
    }
  }

  /// Generates privacy-focused tooltip content.
  String _getTooltipContent() {
    String stateText;
    switch (_currentRecordingState) {
      case TrayRecordingState.recording:
        stateText = 'Recording Active';
        break;
      case TrayRecordingState.paused:
        stateText = 'Recording Paused';
        break;
      case TrayRecordingState.idle:
        stateText = 'Protected';
        break;
    }

    final lockText = _isLocked ? 'Session Locked' : 'Session Active';
    return 'Sehat Locker: $stateText | $lockText | Battery: $_batteryLevel%';
  }

  /// Builds the context menu items for the tray.
  List<Map<String, dynamic>> _buildMenuItems() {
    final List<Map<String, dynamic>> items = [
      {
        'id': 'open_app',
        'label': 'Open Sehat Locker',
        'enabled': true,
        'shortcut': Platform.isMacOS ? 'cmd+o' : 'ctrl+o',
      },
      {'type': 'separator'},
      {
        'id': 'toggle_recording',
        'label': _currentRecordingState == TrayRecordingState.recording
            ? 'Stop Recording'
            : 'Start Recording',
        'enabled': !_isLocked,
        'shortcut': Platform.isMacOS ? 'cmd+r' : 'ctrl+r',
      },
      {
        'id': 'lock_session',
        'label': _isLocked ? 'Unlock Session' : 'Lock Session',
        'enabled': true,
        'shortcut': Platform.isMacOS ? 'cmd+l' : 'ctrl+l',
      },
      {'type': 'separator'},
      {
        'id': 'battery_status',
        'label': 'Battery: $_batteryLevel% ${_batteryLevel < 20 ? "(!)" : ""}',
        'enabled': false,
        'accessibilityLabel': 'Current battery level is $_batteryLevel percent',
      },
      {'type': 'separator'},
      {
        'id': 'quit',
        'label': 'Quit',
        'enabled': true,
      },
    ];

    if (_isEnterprise) {
      items.insert(2, {
        'id': 'enterprise_policy',
        'label': 'Enterprise Policy Active',
        'enabled': false,
      });
    }

    return items;
  }

  /// Starts listening to relevant services for state updates.
  void _startListeners() {
    // Handle menu clicks from native side
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onTrayMenuItemClick':
          await _handleMenuItemClick(call.arguments as String);
          break;
      }
    });

    // Monitor Battery
    BatteryMonitorService().startMonitoring(
      onUpdate: (level, state) {
        if (_batteryLevel != level) {
          _batteryLevel = level;
          updateTray();
        }
      },
      onCritical: () {
        // Critical battery handled by RecorderService
      },
    );

    // Monitor Session State
    SessionManager().addListener(() {
      if (_isLocked != SessionManager().isLocked) {
        _isLocked = SessionManager().isLocked;
        updateTray();
      }
    });

    // Monitor Recording State (Integration point)
    ConversationRecorderService().addListener(() {
      final recorder = ConversationRecorderService();
      TrayRecordingState newState = TrayRecordingState.idle;
      if (recorder.isRecording) {
        newState = TrayRecordingState.recording;
      } else if (recorder.isPaused) {
        newState = TrayRecordingState.paused;
      }

      if (_currentRecordingState != newState) {
        _currentRecordingState = newState;
        updateTray();
      }
    });
  }

  /// Handles menu item clicks by delegating to appropriate services.
  Future<void> _handleMenuItemClick(String actionId) async {
    switch (actionId) {
      case 'open_app':
        await WindowManagerService().initialize(); // Ensure initialized
        final isVisible = await windowManager.isVisible();
        if (!isVisible) {
          await windowManager.show();
        }
        await windowManager.focus();
        break;
      case 'toggle_recording':
        final recorder = ConversationRecorderService();
        if (recorder.isRecording) {
          // In a real app, we might need to handle stop logic from AIScreen
          // but here we can at least pause/stop.
          // Since AIScreen handles the UI, we might just trigger a global shortcut or event.
          KeyboardShortcutService().executeAction('record_start_stop');
        } else if (!_isLocked) {
          KeyboardShortcutService().executeAction('record_start_stop');
        }
        break;
      case 'lock_session':
        if (_isLocked) {
          // Bring app to front to show lock screen
          await _handleMenuItemClick('open_app');
        } else {
          await SessionManager().lockImmediately();
        }
        break;
      case 'quit':
        SystemNavigator.pop();
        break;
    }
  }

  /// Detects if the app is running in an enterprise environment.
  Future<bool> _detectEnterprise() async {
    try {
      if (Platform.isMacOS) {
        // Check for Managed Preferences or MDM profiles
        final result =
            await Process.run('profiles', ['status', '-type', 'enrollment']);
        return result.stdout.toString().contains('Enrolled via DEP: Yes') ||
            Directory('/Library/Managed Preferences').existsSync();
      } else if (Platform.isWindows) {
        // Check if domain joined
        final result = await Process.run('powershell.exe', [
          '-Command',
          '(Get-WmiObject -Class Win32_ComputerSystem).PartofDomain'
        ]);
        return result.stdout.toString().trim().toLowerCase() == 'true';
      }
    } catch (e) {
      debugPrint('Error detecting enterprise environment: $e');
    }
    return false;
  }
}
