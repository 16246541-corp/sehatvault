import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../managers/shortcut_manager.dart';
import '../../models/health_record.dart';
import '../../screens/ai_screen.dart';
import '../../screens/document_detail_screen.dart';
import '../../screens/document_scanner_screen.dart';
import '../../screens/documents_screen.dart';
import '../../screens/home_screen.dart';
import '../../screens/model_warmup_screen.dart';
import '../../screens/news_screen.dart';
import 'screens/desktop_settings_screen.dart';
import '../../services/biometric_service.dart';
import '../../services/export_service.dart';
import '../../services/keyboard_shortcut_service.dart';
import '../../services/local_storage_service.dart';
import '../../services/model_manager.dart';
import '../../services/model_warmup_service.dart';
import '../../services/onboarding_service.dart';
import '../../services/session_manager.dart';
import '../../utils/theme.dart';
import '../../widgets/auth_gate.dart';
import '../../widgets/dialogs/biometric_enrollment_dialog.dart';
import '../../widgets/education/education_gate.dart';
import '../../screens/onboarding/onboarding_navigator.dart';
import '../../app.dart';

import 'widgets/desktop_floating_overlay_bar.dart';
import 'widgets/desktop_menu_bar.dart';

class SehatLockerDesktopApp extends StatefulWidget {
  const SehatLockerDesktopApp({super.key});

  @override
  State<SehatLockerDesktopApp> createState() => _SehatLockerDesktopAppState();
}

class _SehatLockerDesktopAppState extends State<SehatLockerDesktopApp>
    with WidgetsBindingObserver {
  int _currentIndex = 0;

  late final List<Widget Function()> _screenBuilders;
  late String _settingsCategoryId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _settingsCategoryId = desktopSettingsCategories.first.id;
    _screenBuilders = [
      () => const HomeScreen(),
      () => DocumentsScreen(
            onRecordTap: () => _onItemTapped(2),
          ),
      () => _buildAIScreen(),
      () => const NewsScreen(),
      () => DesktopSettingsScreen(
            selectedCategoryId: _settingsCategoryId,
          ),
    ];

    SessionManager().addListener(_onSessionChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkOverdueItems();
    });
  }

  @override
  void dispose() {
    SessionManager().removeListener(_onSessionChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onSessionChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkBiometricEnrollment(isResume: true);
    }
  }

  Future<void> _checkBiometricEnrollment({bool isResume = false}) async {
    final settings = LocalStorageService().getAppSettings();
    if (settings.hasSeenBiometricEnrollmentPrompt) return;

    final biometricService = BiometricService();
    final status = await biometricService.getBiometricStatus();

    if (status == BiometricStatus.availableButNotEnrolled && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => BiometricEnrollmentDialog(
          onEnroll: () async {
            Navigator.of(ctx).pop();
            await biometricService.openSecuritySettings();
          },
          onUsePin: () {
            Navigator.of(ctx).pop();
            settings.hasSeenBiometricEnrollmentPrompt = true;
            LocalStorageService().saveAppSettings(settings);
          },
          onDismiss: () {
            Navigator.of(ctx).pop();
            settings.hasSeenBiometricEnrollmentPrompt = true;
            LocalStorageService().saveAppSettings(settings);
          },
        ),
      );
    }
  }

  void _checkOverdueItems() {
    final overdueItems = LocalStorageService().getOverdueItems();
    if (overdueItems.isNotEmpty) {
      ScaffoldMessenger.of(context).showMaterialBanner(
        MaterialBanner(
          content:
              Text('You have ${overdueItems.length} overdue follow-up items.'),
          leading: const Icon(Icons.warning_amber, color: Colors.orange),
          backgroundColor:
              Theme.of(context).colorScheme.surfaceContainerHighest,
          actions: [
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
                setState(() {
                  _currentIndex = 0;
                });
              },
              child: const Text('VIEW'),
            ),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
              },
              child: const Text('DISMISS'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _onItemTapped(int index) async {
    if (index == 2) {
      final model = await ModelManager.getRecommendedModel();

      if (!ModelWarmupService().isModelWarmedUp(model.id)) {
        if (mounted) {
          final completed = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => ModelWarmupScreen(
                model: model,
                onComplete: () => Navigator.pop(context, true),
              ),
            ),
          );

          if (completed != true) {
            return;
          }
        }
      }
    }

    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> _handleLogout(BuildContext context) async {
    bool clearData = false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Logout'),
          backgroundColor: const Color(0xFF1E293B),
          titleTextStyle: const TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          contentTextStyle: const TextStyle(color: Colors.white70),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Are you sure you want to log out?'),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Clear all data on this device',
                    style: TextStyle(color: Colors.white)),
                subtitle: const Text('Permanently deletes all records',
                    style: TextStyle(color: Colors.white54)),
                value: clearData,
                onChanged: (value) {
                  setDialogState(() {
                    clearData = value ?? false;
                  });
                },
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: Colors.redAccent,
                checkColor: Colors.white,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Logout',
                  style: TextStyle(
                      color: clearData ? Colors.redAccent : Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      await OnboardingService().logout(clearData: clearData);
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => OnboardingNavigator(
              onComplete: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                      builder: (context) => const SehatLockerApp()),
                  (route) => false,
                );
              },
            ),
          ),
          (route) => false,
        );
      }
    }
  }

  Widget _buildAIScreen() {
    return ValueListenableBuilder<Box>(
      valueListenable: Hive.box('settings').listenable(),
      builder: (context, box, _) {
        final settings = LocalStorageService().getAppSettings();
        return AuthGate(
          enabled: settings
              .enhancedPrivacySettings.requireBiometricsForSensitiveData,
          reason: 'Authenticate to access AI Assistant',
          educationContentId: 'ai_features',
          child: AIScreen(
            onEmergencyExit: () => _onItemTapped(0),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = SessionManager().isLocked;
    final overdueCount = LocalStorageService().getOverdueItems().length;
    final isSettings = _currentIndex == 4;

    void onNewScan() {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const EducationGate(
            contentId: 'document_scanner',
            child: DocumentScannerScreen(),
          ),
        ),
      );
    }

    void onExportPdf() {
      ExportService().exportAuditLogReport(context);
    }

    void onExportJson() {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('JSON Export coming soon')),
      );
    }

    void onOpenRecent(HealthRecord record) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DocumentDetailScreen(healthRecordId: record.id),
        ),
      );
    }

    void onSettings() {
      _onItemTapped(4);
    }

    void onLock() {
      SessionManager().lockImmediately();
    }

    void onAbout() {
      showAboutDialog(
        context: context,
        applicationName: 'Sehat Locker',
        applicationVersion: '1.0.0',
        applicationIcon: const Icon(Icons.lock, size: 48),
        applicationLegalese: '© 2026 Sehat Locker Team',
      );
    }

    void onToggleShortcuts() {
      KeyboardShortcutService().executeAction('toggle_cheat_sheet');
    }

    final overlayActionsEnabled = !isLocked;

    final overlayItems = <DesktopOverlayBarItem>[
      DesktopOverlayBarItem(
        icon: Icons.home_rounded,
        tooltip: 'Home',
        onPressed: overlayActionsEnabled ? () => _onItemTapped(0) : null,
        isSelected: _currentIndex == 0,
      ),
      DesktopOverlayBarItem(
        icon: Icons.psychology_rounded,
        tooltip: 'AI',
        onPressed: overlayActionsEnabled ? () => _onItemTapped(2) : null,
        isSelected: _currentIndex == 2,
      ),
      DesktopOverlayBarItem(
        icon: Icons.article_rounded,
        tooltip: 'News',
        onPressed: overlayActionsEnabled ? () => _onItemTapped(3) : null,
        isSelected: _currentIndex == 3,
      ),
      DesktopOverlayBarItem(
        icon: Icons.folder_rounded,
        tooltip: 'Documents',
        onPressed: overlayActionsEnabled ? () => _onItemTapped(1) : null,
        isSelected: _currentIndex == 1,
      ),
      DesktopOverlayBarItem(
        icon: Icons.settings_rounded,
        tooltip: 'Settings',
        onPressed: overlayActionsEnabled ? () => _onItemTapped(4) : null,
        isSelected: _currentIndex == 4,
      ),
    ];

    return DesktopMenuBar(
      canExport: true,
      isSessionLocked: isLocked,
      onNewScan: onNewScan,
      onExportPdf: onExportPdf,
      onExportJson: onExportJson,
      onOpenRecent: onOpenRecent,
      onSettings: onSettings,
      onLock: onLock,
      onAbout: onAbout,
      onToggleShortcuts: onToggleShortcuts,
      child: AppShortcutManager(
        onRecordToggle: () {
          if (_currentIndex != 2) {
            _onItemTapped(2);
          }
        },
        onScanOpen: () {
          if (_currentIndex == 0) {
            KeyboardShortcutService().executeAction('capture_document');
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const EducationGate(
                  contentId: 'document_scanner',
                  child: DocumentScannerScreen(),
                ),
              ),
            );
          }
        },
        onSettingsOpen: () {
          _onItemTapped(4);
        },
        child: Scaffold(
          body: SafeArea(
            bottom: false,
            child: Row(
              children: [
                _DesktopSidebar(
                  overdueCount: overdueCount,
                  isSessionLocked: isLocked,
                  settingsCategories:
                      isSettings ? desktopSettingsCategories : null,
                  selectedSettingsCategoryId:
                      isSettings ? _settingsCategoryId : null,
                  onSelectSettingsCategory: isSettings
                      ? (id) => setState(() => _settingsCategoryId = id)
                      : null,
                  onLogout: isSettings ? () => _handleLogout(context) : null,
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        child: KeyedSubtree(
                          key: ValueKey<int>(_currentIndex),
                          child: _screenBuilders[_currentIndex](),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 18 + MediaQuery.of(context).viewPadding.bottom,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: DesktopFloatingOverlayBar(items: overlayItems),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: _currentIndex == 1
              ? FloatingActionButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EducationGate(
                          contentId: 'document_scanner',
                          child: DocumentScannerScreen(),
                        ),
                      ),
                    );
                  },
                  backgroundColor: AppTheme.accentTeal,
                  child: const Icon(Icons.document_scanner),
                )
              : null,
        ),
      ),
    );
  }
}

class _DesktopSidebar extends StatelessWidget {
  final int overdueCount;
  final bool isSessionLocked;
  final List<DesktopSettingsCategory>? settingsCategories;
  final String? selectedSettingsCategoryId;
  final ValueChanged<String>? onSelectSettingsCategory;
  final VoidCallback? onLogout;

  const _DesktopSidebar({
    required this.overdueCount,
    required this.isSessionLocked,
    this.settingsCategories,
    this.selectedSettingsCategoryId,
    this.onSelectSettingsCategory,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSettingsSidebar = settingsCategories != null &&
        selectedSettingsCategoryId != null &&
        onSelectSettingsCategory != null;

    return SizedBox(
      width: 280,
      child: Container(
        decoration: BoxDecoration(
          gradient: isSettingsSidebar
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0B1220),
                    Color(0xFF070A14),
                  ],
                )
              : null,
          color: isSettingsSidebar
              ? null
              : isDark
                  ? Colors.black.withValues(alpha: 0.25)
                  : Colors.white.withValues(alpha: 0.65),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: isSettingsSidebar
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Settings',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Privacy-first health locker',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        const Icon(Icons.lock, size: 18),
                        const SizedBox(width: 10),
                        Text(
                          'Sehat Locker',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
            ),
            const Divider(height: 1),
            Expanded(
              child: isSettingsSidebar
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                      child: ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: settingsCategories!.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          final category = settingsCategories![index];
                          final isSelected =
                              category.id == selectedSettingsCategoryId;
                          return _DesktopSettingsSidebarItem(
                            icon: category.icon,
                            iconColor: category.color,
                            title: category.label,
                            subtitle: category.subtitle,
                            isSelected: isSelected,
                            onTap: () => onSelectSettingsCategory!(category.id),
                          );
                        },
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            if (isSettingsSidebar && onLogout != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: _DesktopSettingsSidebarItem(
                  icon: Icons.logout,
                  iconColor: Colors.redAccent,
                  title: 'Logout',
                  subtitle: 'Secure session end',
                  isSelected: false,
                  isDestructive: true,
                  onTap: onLogout!,
                ),
              ),
            _DesktopStatusBar(
              overdueCount: overdueCount,
              isSessionLocked: isSessionLocked,
            ),
          ],
        ),
      ),
    );
  }
}

class _DesktopSettingsSidebarItem extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool isSelected;
  final bool isDestructive;
  final VoidCallback onTap;

  const _DesktopSettingsSidebarItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  State<_DesktopSettingsSidebarItem> createState() =>
      _DesktopSettingsSidebarItemState();
}

class _DesktopSettingsSidebarItemState
    extends State<_DesktopSettingsSidebarItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDestructive
        ? Colors.redAccent.withValues(alpha: widget.isSelected ? 0.18 : 0.10)
        : Colors.white.withValues(alpha: widget.isSelected ? 0.06 : 0.0);
    final border = widget.isDestructive
        ? Colors.redAccent.withValues(alpha: widget.isSelected ? 0.35 : 0.22)
        : widget.isSelected
            ? Colors.white.withValues(alpha: 0.14)
            : Colors.white.withValues(alpha: 0.06);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _isHovered && !widget.isSelected
                ? Colors.white.withValues(alpha: 0.04)
                : bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border, width: 1),
            boxShadow: widget.isSelected || _isHovered
                ? [
                    BoxShadow(
                      color: (widget.isDestructive
                              ? Colors.redAccent
                              : widget.iconColor)
                          .withValues(alpha: widget.isSelected ? 0.10 : 0.06),
                      blurRadius: widget.isSelected ? 18 : 12,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              if (widget.isSelected)
                Container(
                  width: 3,
                  height: 30,
                  decoration: BoxDecoration(
                    color: (widget.isDestructive
                            ? Colors.redAccent
                            : widget.iconColor)
                        .withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                )
              else
                const SizedBox(width: 3),
              const SizedBox(width: 9),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: widget.iconColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  widget.icon,
                  size: 18,
                  color: widget.isDestructive
                      ? Colors.redAccent
                      : widget.iconColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: widget.isDestructive
                            ? Colors.redAccent
                            : Colors.white.withValues(alpha: 0.92),
                        fontSize: 13.5,
                        fontWeight: widget.isSelected
                            ? FontWeight.w700
                            : FontWeight.w600,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 11.5,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.isSelected)
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: Colors.white.withValues(alpha: 0.55),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DesktopStatusBar extends StatelessWidget {
  final int overdueCount;
  final bool isSessionLocked;

  const _DesktopStatusBar({
    required this.overdueCount,
    required this.isSessionLocked,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withValues(alpha: 0.25)
            : Colors.white.withValues(alpha: 0.65),
        border: Border(
          top: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.4),
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, size: 16),
          const SizedBox(width: 8),
          Text(
            isSessionLocked ? 'Session locked' : 'Session active',
            style: theme.textTheme.labelMedium,
          ),
          const Spacer(),
          if (overdueCount > 0)
            Row(
              children: [
                const Icon(Icons.warning_amber, size: 16, color: Colors.orange),
                const SizedBox(width: 6),
                Text(
                  '$overdueCount overdue',
                  style: theme.textTheme.labelMedium,
                ),
              ],
            ),
        ],
      ),
    );
  }
}
