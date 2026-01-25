import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/keyboard_shortcut_service.dart';
import '../services/local_storage_service.dart';
import '../services/session_manager.dart';
import '../widgets/design/glass_card.dart';

/// Intent for recording start/stop.
class RecordIntent extends Intent {
  const RecordIntent();
}

/// Intent for document scanning.
class ScanIntent extends Intent {
  const ScanIntent();
}

/// Intent for settings.
class SettingsIntent extends Intent {
  const SettingsIntent();
}

/// Intent for locking.
class LockIntent extends Intent {
  const LockIntent();
}

/// Intent for cheat sheet.
class CheatSheetIntent extends Intent {
  const CheatSheetIntent();
}

/// Manager to handle shortcut actions and UI overlay.
class AppShortcutManager extends StatefulWidget {
  final Widget child;
  final VoidCallback? onRecordToggle;
  final VoidCallback? onScanOpen;
  final VoidCallback? onSettingsOpen;

  const AppShortcutManager({
    super.key,
    required this.child,
    this.onRecordToggle,
    this.onScanOpen,
    this.onSettingsOpen,
  });

  @override
  State<AppShortcutManager> createState() => _AppShortcutManagerState();
}

class _AppShortcutManagerState extends State<AppShortcutManager> {
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    KeyboardShortcutService().registerAction('lock_session', () {
      SessionManager().lockImmediately();
    });
    KeyboardShortcutService().registerAction('settings_open', () {
      widget.onSettingsOpen?.call();
    });
    KeyboardShortcutService()
        .registerAction('toggle_cheat_sheet', _toggleCheatSheet);
  }

  @override
  void dispose() {
    KeyboardShortcutService().unregisterAction('lock_session');
    KeyboardShortcutService().unregisterAction('settings_open');
    KeyboardShortcutService().unregisterAction('toggle_cheat_sheet');
    super.dispose();
  }

  void _toggleCheatSheet() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    } else {
      _overlayEntry = OverlayEntry(
        builder: (context) => _CheatSheetOverlay(
          onClose: _toggleCheatSheet,
        ),
      );
      Overlay.of(context).insert(_overlayEntry!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled =
        LocalStorageService().getAppSettings().enableKeyboardShortcuts;
    if (!enabled) return widget.child;

    return Shortcuts(
      shortcuts: {
        LogicalKeySet(
          Platform.isMacOS
              ? LogicalKeyboardKey.meta
              : LogicalKeyboardKey.control,
          LogicalKeyboardKey.keyR,
        ): const RecordIntent(),
        LogicalKeySet(
          Platform.isMacOS
              ? LogicalKeyboardKey.meta
              : LogicalKeyboardKey.control,
          LogicalKeyboardKey.keyS,
        ): const ScanIntent(),
        LogicalKeySet(
          Platform.isMacOS
              ? LogicalKeyboardKey.meta
              : LogicalKeyboardKey.control,
          LogicalKeyboardKey.comma,
        ): const SettingsIntent(),
        LogicalKeySet(
          Platform.isMacOS
              ? LogicalKeyboardKey.meta
              : LogicalKeyboardKey.control,
          LogicalKeyboardKey.keyL,
        ): const LockIntent(),
        LogicalKeySet(
          Platform.isMacOS
              ? LogicalKeyboardKey.meta
              : LogicalKeyboardKey.control,
          LogicalKeyboardKey.slash,
        ): const CheatSheetIntent(),
      },
      child: Actions(
        actions: {
          RecordIntent: CallbackAction<RecordIntent>(
            onInvoke: (intent) {
              if (!LocalStorageService()
                  .getAppSettings()
                  .enableKeyboardShortcuts) {
                return null;
              }
              KeyboardShortcutService().executeAction('record_start_stop');
              widget.onRecordToggle?.call();
              return null;
            },
          ),
          ScanIntent: CallbackAction<ScanIntent>(
            onInvoke: (intent) {
              if (!LocalStorageService()
                  .getAppSettings()
                  .enableKeyboardShortcuts) {
                return null;
              }
              KeyboardShortcutService().executeAction('capture_document');
              widget.onScanOpen?.call();
              return null;
            },
          ),
          SettingsIntent: CallbackAction<SettingsIntent>(
            onInvoke: (intent) {
              if (!LocalStorageService()
                  .getAppSettings()
                  .enableKeyboardShortcuts) {
                return null;
              }
              KeyboardShortcutService().executeAction('settings_open');
              widget.onSettingsOpen?.call();
              return null;
            },
          ),
          LockIntent: CallbackAction<LockIntent>(
            onInvoke: (intent) {
              if (!LocalStorageService()
                  .getAppSettings()
                  .enableKeyboardShortcuts) {
                return null;
              }
              KeyboardShortcutService().executeAction('lock_session');
              return null;
            },
          ),
          CheatSheetIntent: CallbackAction<CheatSheetIntent>(
            onInvoke: (intent) {
              if (!LocalStorageService()
                  .getAppSettings()
                  .enableKeyboardShortcuts) {
                return null;
              }
              KeyboardShortcutService().executeAction('toggle_cheat_sheet');
              _toggleCheatSheet();
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          onKeyEvent: (node, event) {
            if (KeyboardShortcutService().isSystemConflict(event)) {
              return KeyEventResult.ignored;
            }
            return KeyEventResult.ignored;
          },
          child: widget.child,
        ),
      ),
    );
  }
}

class _CheatSheetOverlay extends StatelessWidget {
  final VoidCallback onClose;

  const _CheatSheetOverlay({required this.onClose});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final modifier = Platform.isMacOS ? '⌘' : 'Ctrl';

    return Material(
      color: Colors.black54,
      child: InkWell(
        onTap: onClose,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Keyboard Shortcuts',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: onClose,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _ShortcutRow(
                      label: 'Toggle Recording',
                      shortcut: '$modifier + R',
                    ),
                    _ShortcutRow(
                      label: 'Capture / Open Scanner',
                      shortcut: '$modifier + S',
                    ),
                    _ShortcutRow(
                      label: 'Settings',
                      shortcut: '$modifier + ,',
                    ),
                    _ShortcutRow(
                      label: 'Lock Session',
                      shortcut: '$modifier + L',
                    ),
                    _ShortcutRow(
                      label: 'This Cheat Sheet',
                      shortcut: '$modifier + /',
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Press Esc or tap anywhere to close',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShortcutRow extends StatelessWidget {
  final String label;
  final String shortcut;

  const _ShortcutRow({required this.label, required this.shortcut});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              shortcut,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
