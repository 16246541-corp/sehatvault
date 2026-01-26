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
import '../../screens/settings_screen.dart';
import '../../services/biometric_service.dart';
import '../../services/education_service.dart';
import '../../services/export_service.dart';
import '../../services/keyboard_shortcut_service.dart';
import '../../services/local_storage_service.dart';
import '../../services/model_manager.dart';
import '../../services/model_warmup_service.dart';
import '../../services/session_manager.dart';
import '../../utils/design_constants.dart';
import '../../utils/theme.dart';
import '../../widgets/auth_gate.dart';
import '../../widgets/dialogs/biometric_enrollment_dialog.dart';
import '../../widgets/education/education_gate.dart';
import '../../widgets/navigation/glass_bottom_nav.dart';

import 'widgets/desktop_menu_bar.dart';

class SehatLockerDesktopApp extends StatefulWidget {
  const SehatLockerDesktopApp({super.key});

  @override
  State<SehatLockerDesktopApp> createState() => _SehatLockerDesktopAppState();
}

class _SehatLockerDesktopAppState extends State<SehatLockerDesktopApp>
    with WidgetsBindingObserver {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _screens = [
      const HomeScreen(),
      DocumentsScreen(
        onRecordTap: () => _onItemTapped(2),
      ),
      _buildAIScreen(),
      const NewsScreen(),
      const SettingsScreen(),
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

  Future<Map<int, bool>> _getEducationIndicators() async {
    final educationService = EducationService();
    final aiComplete =
        await educationService.isEducationCompleted('ai_features');
    final documentComplete =
        await educationService.isEducationCompleted('document_scanner');
    final storageComplete =
        await educationService.isEducationCompleted('secure_storage');

    return {
      1: !(documentComplete && storageComplete),
      2: !aiComplete,
    };
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

    return DesktopMenuBar(
      canExport: true,
      isSessionLocked: isLocked,
      onNewScan: () {
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
      onExportPdf: () {
        ExportService().exportAuditLogReport(context);
      },
      onExportJson: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('JSON Export coming soon')),
        );
      },
      onOpenRecent: (HealthRecord record) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                DocumentDetailScreen(healthRecordId: record.id),
          ),
        );
      },
      onSettings: () {
        _onItemTapped(4);
      },
      onLock: () {
        SessionManager().lockImmediately();
      },
      onAbout: () {
        showAboutDialog(
          context: context,
          applicationName: 'Sehat Locker',
          applicationVersion: '1.0.0',
          applicationIcon: const Icon(Icons.lock, size: 48),
          applicationLegalese: '© 2026 Sehat Locker Team',
        );
      },
      onToggleShortcuts: () {
        KeyboardShortcutService().executeAction('toggle_cheat_sheet');
      },
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
        child: FutureBuilder<Map<int, bool>>(
          future: _getEducationIndicators(),
          builder: (context, snapshot) {
            final attentionIndicators = snapshot.data;

            final navTotalHeight = DesignConstants.bottomNavHeight +
                DesignConstants.bottomNavPadding.vertical;
            const sidebarWidth = 280.0;
            const dividerWidth = 1.0;
            const horizontalMargin = 16.0;

            return Scaffold(
              extendBody: true,
              body: Stack(
                clipBehavior: Clip.none,
                children: [
                  SafeArea(
                    bottom: false,
                    child: Row(
                      children: [
                        _DesktopSidebar(
                          currentIndex: _currentIndex,
                          attentionIndicators: attentionIndicators,
                          overdueCount: overdueCount,
                          isSessionLocked: isLocked,
                          onSelect: (index) => _onItemTapped(index),
                        ),
                        const VerticalDivider(width: 1),
                        Expanded(
                          child: Padding(
                            padding:
                                EdgeInsets.only(bottom: navTotalHeight + 16),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 180),
                              switchInCurve: Curves.easeOut,
                              switchOutCurve: Curves.easeIn,
                              child: KeyedSubtree(
                                key: ValueKey<int>(_currentIndex),
                                child: _screens[_currentIndex],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: sidebarWidth + dividerWidth + horizontalMargin,
                    right: horizontalMargin,
                    bottom: 8,
                    child: GlassBottomNav(
                      currentIndex: _currentIndex,
                      onItemTapped: (index) => _onItemTapped(index),
                      badgeCounts: overdueCount > 0 ? {0: overdueCount} : null,
                      attentionIndicators: attentionIndicators,
                    ),
                  ),
                ],
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
            );
          },
        ),
      ),
    );
  }
}

class _DesktopSidebar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onSelect;
  final Map<int, bool>? attentionIndicators;
  final int overdueCount;
  final bool isSessionLocked;

  const _DesktopSidebar({
    required this.currentIndex,
    required this.onSelect,
    required this.attentionIndicators,
    required this.overdueCount,
    required this.isSessionLocked,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      width: 280,
      child: Container(
        color: isDark
            ? Colors.black.withValues(alpha: 0.25)
            : Colors.white.withValues(alpha: 0.65),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
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
              child: ListView(
                padding: const EdgeInsets.all(8),
                children: [
                  _NavItem(
                    selected: currentIndex == 0,
                    icon: Icons.home_outlined,
                    selectedIcon: Icons.home,
                    label: 'Home',
                    onTap: () => onSelect(0),
                  ),
                  _NavItem(
                    selected: currentIndex == 1,
                    icon: Icons.folder_outlined,
                    selectedIcon: Icons.folder,
                    label: 'Documents',
                    showAttention: attentionIndicators?[1] == true,
                    onTap: () => onSelect(1),
                  ),
                  _NavItem(
                    selected: currentIndex == 2,
                    icon: Icons.psychology_outlined,
                    selectedIcon: Icons.psychology,
                    label: 'AI',
                    showAttention: attentionIndicators?[2] == true,
                    onTap: () => onSelect(2),
                  ),
                  _NavItem(
                    selected: currentIndex == 3,
                    icon: Icons.article_outlined,
                    selectedIcon: Icons.article,
                    label: 'News',
                    onTap: () => onSelect(3),
                  ),
                  _NavItem(
                    selected: currentIndex == 4,
                    icon: Icons.settings_outlined,
                    selectedIcon: Icons.settings,
                    label: 'Settings',
                    onTap: () => onSelect(4),
                  ),
                ],
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

class _NavItem extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final VoidCallback onTap;
  final bool showAttention;

  const _NavItem({
    required this.selected,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.onTap,
    this.showAttention = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeColor = theme.colorScheme.primary;
    final inactiveColor =
        isDark ? Colors.white.withValues(alpha: 0.8) : Colors.black87;

    return ListTile(
      selected: selected,
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            selected ? selectedIcon : icon,
            color: selected ? activeColor : inactiveColor,
          ),
          if (showAttention)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppTheme.accentTeal,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
      title: Text(
        label,
        style: TextStyle(
          color: selected ? activeColor : inactiveColor,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
