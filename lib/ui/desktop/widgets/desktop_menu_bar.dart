import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../models/health_record.dart';
import '../../../services/local_storage_service.dart';

class DesktopMenuBar extends StatelessWidget {
  final Widget child;
  final VoidCallback onNewScan;
  final VoidCallback onExportPdf;
  final VoidCallback onExportJson;
  final Function(HealthRecord) onOpenRecent;
  final VoidCallback onSettings;
  final VoidCallback onLock;
  final VoidCallback onAbout;
  final VoidCallback onToggleShortcuts;
  final bool canExport;
  final bool isSessionLocked;

  const DesktopMenuBar({
    super.key,
    required this.child,
    required this.onNewScan,
    required this.onExportPdf,
    required this.onExportJson,
    required this.onOpenRecent,
    required this.onSettings,
    required this.onLock,
    required this.onAbout,
    required this.onToggleShortcuts,
    this.canExport = true,
    this.isSessionLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    if (kIsWeb ||
        (!Platform.isMacOS && !Platform.isWindows && !Platform.isLinux)) {
      return child;
    }

    return Directionality(
      textDirection: Directionality.of(context),
      child: PlatformMenuBar(
        menus: _buildMenus(context),
        child: child,
      ),
    );
  }

  List<PlatformMenu> _buildMenus(BuildContext context) {
    final List<PlatformMenu> menus = [];

    if (Platform.isMacOS) {
      menus.add(
        PlatformMenu(
          label: 'Sehat Locker',
          menus: [
            PlatformMenuItemGroup(
              members: [
                PlatformMenuItem(
                  label: 'About Sehat Locker',
                  onSelected: onAbout,
                ),
              ],
            ),
            PlatformMenuItemGroup(
              members: [
                PlatformMenuItem(
                  label: 'Settings...',
                  shortcut:
                      const SingleActivator(LogicalKeyboardKey.comma, meta: true),
                  onSelected: onSettings,
                ),
              ],
            ),
            const PlatformProvidedMenuItem(
                type: PlatformProvidedMenuItemType.servicesSubmenu),
            const PlatformProvidedMenuItem(type: PlatformProvidedMenuItemType.hide),
            const PlatformProvidedMenuItem(type: PlatformProvidedMenuItemType.quit),
          ],
        ),
      );
    }

    menus.add(
      PlatformMenu(
        label: 'File',
        menus: [
          PlatformMenuItem(
            label: 'New Scan',
            shortcut: SingleActivator(
              LogicalKeyboardKey.keyS,
              meta: Platform.isMacOS,
              control: !Platform.isMacOS,
            ),
            onSelected: isSessionLocked ? null : onNewScan,
          ),
          PlatformMenu(
            label: 'Export',
            menus: [
              PlatformMenuItem(
                label: 'Export as PDF',
                onSelected: (isSessionLocked || !canExport) ? null : onExportPdf,
              ),
              PlatformMenuItem(
                label: 'Export as Encrypted JSON',
                onSelected: (isSessionLocked || !canExport) ? null : onExportJson,
              ),
            ],
          ),
          PlatformMenu(
            label: 'Recent Documents',
            menus: isSessionLocked ? [] : _buildRecentDocumentsMenu(),
          ),
          if (!Platform.isMacOS)
            PlatformMenuItem(
              label: 'Settings',
              shortcut: const SingleActivator(LogicalKeyboardKey.comma, control: true),
              onSelected: isSessionLocked ? null : onSettings,
            ),
          if (!Platform.isMacOS)
            PlatformMenuItemGroup(
              members: [
                PlatformMenuItem(
                  label: 'Exit',
                  onSelected: () => SystemNavigator.pop(),
                ),
              ],
            ),
        ],
      ),
    );

    menus.add(
      const PlatformMenu(
        label: 'Edit',
        menus: [
          PlatformMenuItemGroup(
            members: [
              PlatformMenuItem(
                label: 'Undo',
                shortcut: SingleActivator(LogicalKeyboardKey.keyZ, meta: true),
              ),
              PlatformMenuItem(
                label: 'Redo',
                shortcut: SingleActivator(LogicalKeyboardKey.keyZ,
                    meta: true, shift: true),
              ),
            ],
          ),
          PlatformMenuItemGroup(
            members: [
              PlatformMenuItem(
                label: 'Cut',
                shortcut: SingleActivator(LogicalKeyboardKey.keyX, meta: true),
              ),
              PlatformMenuItem(
                label: 'Copy',
                shortcut: SingleActivator(LogicalKeyboardKey.keyC, meta: true),
              ),
              PlatformMenuItem(
                label: 'Paste',
                shortcut: SingleActivator(LogicalKeyboardKey.keyV, meta: true),
              ),
              PlatformMenuItem(
                label: 'Select All',
                shortcut: SingleActivator(LogicalKeyboardKey.keyA, meta: true),
              ),
            ],
          ),
        ],
      ),
    );

    menus.add(
      PlatformMenu(
        label: 'View',
        menus: [
          PlatformMenuItem(
            label: 'Shortcut Cheat Sheet',
            shortcut: SingleActivator(
              LogicalKeyboardKey.slash,
              meta: Platform.isMacOS,
              control: !Platform.isMacOS,
            ),
            onSelected: isSessionLocked ? null : onToggleShortcuts,
          ),
        ],
      ),
    );

    menus.add(
      PlatformMenu(
        label: 'Window',
        menus: [
          PlatformMenuItem(
            label: 'Lock Session',
            shortcut: SingleActivator(
              LogicalKeyboardKey.keyL,
              meta: Platform.isMacOS,
              control: !Platform.isMacOS,
            ),
            onSelected: isSessionLocked ? null : onLock,
          ),
          if (Platform.isMacOS) ...[
            const PlatformProvidedMenuItem(
                type: PlatformProvidedMenuItemType.minimizeWindow),
            const PlatformProvidedMenuItem(
                type: PlatformProvidedMenuItemType.zoomWindow),
          ],
        ],
      ),
    );

    if (!Platform.isMacOS) {
      menus.add(
        PlatformMenu(
          label: 'Help',
          menus: [
            PlatformMenuItem(
              label: 'About Sehat Locker',
              onSelected: onAbout,
            ),
          ],
        ),
      );
    }

    return menus;
  }

  List<PlatformMenuItem> _buildRecentDocumentsMenu() {
    final storageService = LocalStorageService();
    final records = storageService.getAllRecords();

    final List<HealthRecord> sortedRecords = records.map((map) {
      return HealthRecord(
        id: map['id'] as String? ?? '',
        title: map['title'] as String? ?? 'Untitled',
        category: map['category'] as String? ?? 'Other',
        createdAt: _parseDateTime(map['createdAt']),
        updatedAt: _parseDateTime(map['updatedAt']),
        filePath: map['filePath'] as String?,
        notes: map['notes'] as String?,
        metadata: (map['metadata'] as Map?)?.cast<String, dynamic>(),
        recordType: map['recordType'] as String?,
        extractionId: map['extractionId'] as String?,
      );
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final mruRecords = sortedRecords.take(5).toList();

    if (mruRecords.isEmpty) {
      return [
        const PlatformMenuItem(
          label: 'No recent documents',
        ),
      ];
    }

    return mruRecords.map((record) {
      return PlatformMenuItem(
        label: record.title,
        onSelected: () => onOpenRecent(record),
      );
    }).toList();
  }

  DateTime _parseDateTime(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
