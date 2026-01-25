import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'local_storage_service.dart';
import 'platform_detector.dart';

/// Service for managing desktop window state, persistence, and multi-monitor support.
class WindowManagerService with WindowListener {
  static final WindowManagerService _instance =
      WindowManagerService._internal();
  factory WindowManagerService() => _instance;
  WindowManagerService._internal();

  bool _isInitialized = false;
  final LocalStorageService _storageService = LocalStorageService();

  /// Initialize the window manager and restore state.
  Future<void> initialize() async {
    if (_isInitialized) return;

    final capabilities = await PlatformDetector().getCapabilities();
    if (!capabilities.isDesktop) return;

    await windowManager.ensureInitialized();
    windowManager.addListener(this);

    _isInitialized = true;
    await _restoreWindowState();
  }

  /// Restore window state from local storage with failsafe logic for multi-monitor setups.
  Future<void> _restoreWindowState() async {
    final settings = _storageService.getAppSettings();

    // Only restore if enabled
    if (!settings.persistWindowState) {
      await windowManager.setSize(const Size(1200, 800));
      await windowManager.center();
      await windowManager.show();
      return;
    }

    // Only restore if we have saved values
    if (settings.desktopWindowWidth == null ||
        settings.desktopWindowHeight == null) {
      // Default size if nothing is saved
      await windowManager.setSize(const Size(1200, 800));
      await windowManager.center();
      await windowManager.show();
      return;
    }

    double width = settings.desktopWindowWidth!;
    double height = settings.desktopWindowHeight!;
    double? x = settings.desktopWindowX;
    double? y = settings.desktopWindowY;
    bool isMaximized = settings.isMaximized;

    if (isMaximized) {
      await windowManager.maximize();
    } else {
      await windowManager.setSize(Size(width, height));

      if (settings.restoreWindowPosition && x != null && y != null) {
        // Validate position is within a visible monitor
        final isValid = await _isPositionVisible(x, y, width, height);
        if (isValid) {
          await windowManager.setPosition(Offset(x, y));
        } else {
          // Failsafe: Reset to center if monitor is disconnected or position is invalid
          await windowManager.center();
          debugPrint(
              'Window position failsafe triggered: Resetting to center.');
        }
      } else {
        await windowManager.center();
      }
    }

    await windowManager.show();
    await windowManager.focus();
  }

  /// Check if the saved position is visible on any current monitor.
  Future<bool> _isPositionVisible(
      double x, double y, double width, double height) async {
    try {
      final displays = await screenRetriever.getAllDisplays();
      final windowRect = Rect.fromLTWH(x, y, width, height);

      for (final display in displays) {
        final displayRect = Rect.fromLTWH(
          display.visiblePosition?.dx ?? 0,
          display.visiblePosition?.dy ?? 0,
          display.visibleSize?.width ?? 0,
          display.visibleSize?.height ?? 0,
        );

        // Check if there is significant overlap with any monitor
        final intersection = windowRect.intersect(displayRect);
        if (intersection.width > 50 && intersection.height > 50) {
          return true;
        }
      }
    } catch (e) {
      debugPrint('Error validating window position: $e');
    }
    return false;
  }

  /// Save current window state to local storage.
  Future<void> saveWindowState() async {
    if (!_isInitialized) return;

    try {
      final settings = _storageService.getAppSettings();
      if (!settings.persistWindowState) return;

      final isMaximized = await windowManager.isMaximized();

      if (isMaximized) {
        settings.isMaximized = true;
      } else {
        final size = await windowManager.getSize();
        final position = await windowManager.getPosition();

        settings.isMaximized = false;
        settings.desktopWindowWidth = size.width;
        settings.desktopWindowHeight = size.height;
        settings.desktopWindowX = position.dx;
        settings.desktopWindowY = position.dy;
      }

      await _storageService.saveAppSettings(settings);
    } catch (e) {
      debugPrint('Error saving window state: $e');
    }
  }

  /// Get current DPI scaling factor for the window.
  Future<double> getDevicePixelRatio() async {
    if (!_isInitialized) return 1.0;
    try {
      final primaryDisplay = await screenRetriever.getPrimaryDisplay();
      return primaryDisplay.scaleFactor?.toDouble() ?? 1.0;
    } catch (e) {
      return 1.0;
    }
  }

  // WindowListener implementation

  @override
  void onWindowResized() {
    saveWindowState();
  }

  @override
  void onWindowMoved() {
    saveWindowState();
  }

  @override
  void onWindowMaximize() {
    saveWindowState();
  }

  @override
  void onWindowUnmaximize() {
    saveWindowState();
  }

  @override
  void onWindowClose() {
    saveWindowState();
  }

  /// Dispose and remove listeners.
  void dispose() {
    windowManager.removeListener(this);
  }
}
