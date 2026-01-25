import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Service to handle keyboard shortcuts across the application.
class KeyboardShortcutService {
  static final KeyboardShortcutService _instance =
      KeyboardShortcutService._internal();
  factory KeyboardShortcutService() => _instance;
  KeyboardShortcutService._internal();

  /// Defines shortcut mappings for different platforms.
  static final Map<ShortcutActivator, String> globalShortcuts = {
    LogicalKeySet(
      Platform.isMacOS ? LogicalKeyboardKey.meta : LogicalKeyboardKey.control,
      LogicalKeyboardKey.keyR,
    ): 'record_start_stop',
    LogicalKeySet(
      Platform.isMacOS ? LogicalKeyboardKey.meta : LogicalKeyboardKey.control,
      LogicalKeyboardKey.keyS,
    ): 'document_scan',
    LogicalKeySet(
      Platform.isMacOS ? LogicalKeyboardKey.meta : LogicalKeyboardKey.control,
      LogicalKeyboardKey.comma,
    ): 'settings_open',
    LogicalKeySet(
      Platform.isMacOS ? LogicalKeyboardKey.meta : LogicalKeyboardKey.control,
      LogicalKeyboardKey.keyL,
    ): 'lock_session',
    LogicalKeySet(
      Platform.isMacOS ? LogicalKeyboardKey.meta : LogicalKeyboardKey.control,
      LogicalKeyboardKey.slash,
    ): 'toggle_cheat_sheet',
  };

  /// Map of action identifiers to their respective callbacks.
  final Map<String, VoidCallback> _actions = {};

  /// Registers an action callback.
  void registerAction(String actionId, VoidCallback callback) {
    _actions[actionId] = callback;
  }

  /// Unregisters an action callback.
  void unregisterAction(String actionId) {
    _actions.remove(actionId);
  }

  /// Executes the action associated with the given ID.
  void executeAction(String actionId) {
    if (_actions.containsKey(actionId)) {
      triggerFeedback();
      _actions[actionId]!();
    }
  }

  /// Returns true if the given key event matches a system shortcut that might conflict.
  bool isSystemConflict(KeyEvent event) {
    if (Platform.isMacOS) {
      if (HardwareKeyboard.instance.isMetaPressed &&
          event.logicalKey == LogicalKeyboardKey.keyQ) return true; // Quit
      if (HardwareKeyboard.instance.isMetaPressed &&
          event.logicalKey == LogicalKeyboardKey.tab) return true; // Switch app
    } else {
      if (HardwareKeyboard.instance.isAltPressed &&
          event.logicalKey == LogicalKeyboardKey.f4) return true; // Close
      if (HardwareKeyboard.instance.isControlPressed &&
          event.logicalKey == LogicalKeyboardKey.tab) return true; // Switch tab
    }
    return false;
  }

  /// Triggers haptic feedback for shortcut execution.
  Future<void> triggerFeedback() async {
    await HapticFeedback.mediumImpact();
  }
}
