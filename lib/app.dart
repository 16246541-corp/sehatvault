import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/follow_up_item.dart';
import 'services/local_storage_service.dart';
import 'screens/home_screen.dart';
import 'screens/documents_screen.dart';
import 'screens/follow_up_list_screen.dart';
import 'screens/ai_screen.dart';
import 'screens/news_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/model_warmup_screen.dart';
import 'services/model_warmup_service.dart';
import 'services/model_manager.dart';
import 'widgets/navigation/glass_bottom_nav.dart';
import 'widgets/auth_gate.dart';
import 'services/biometric_service.dart';
import 'widgets/dialogs/biometric_enrollment_dialog.dart';
import 'services/education_service.dart';
import 'widgets/education/education_gate.dart';

import 'screens/document_scanner_screen.dart';
import 'screens/document_detail_screen.dart';
import 'utils/theme.dart';
import 'services/keyboard_shortcut_service.dart';
import 'services/session_manager.dart';
import 'services/export_service.dart';
import 'managers/shortcut_manager.dart';
import 'widgets/desktop/desktop_menu_bar.dart';
import 'models/health_record.dart';

/// Main App Widget with bottom navigation
class SehatLockerApp extends StatefulWidget {
  const SehatLockerApp({super.key});

  @override
  State<SehatLockerApp> createState() => _SehatLockerAppState();
}

class _SehatLockerAppState extends State<SehatLockerApp>
    with WidgetsBindingObserver {
  int _currentIndex = 0;

  late final List<Widget Function()> _screenBuilders;
  final Map<int, Widget> _screenCache = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _screenBuilders = [
      () => const HomeScreen(),
      () => DocumentsScreen(
            onRecordTap: () => _onItemTapped(2),
          ),
      _buildAIScreen,
      () => const NewsScreen(),
      () => const SettingsScreen(),
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

    // Skip if user has already seen the prompt
    if (settings.hasSeenBiometricEnrollmentPrompt) return;

    // Check if biometrics are available but not enrolled
    final biometricService = BiometricService();
    final status = await biometricService.getBiometricStatus();

    if (status == BiometricStatus.availableButNotEnrolled && mounted) {
      // Show the enrollment dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => BiometricEnrollmentDialog(
          onEnroll: () async {
            Navigator.of(ctx).pop();
            // Navigate to system settings for biometric enrollment
            await biometricService.openSecuritySettings();
          },
          onUsePin: () {
            Navigator.of(ctx).pop();
            // Mark as seen so we don't prompt again
            settings.hasSeenBiometricEnrollmentPrompt = true;
            LocalStorageService().saveAppSettings(settings);
          },
          onDismiss: () {
            Navigator.of(ctx).pop();
            // Mark as seen so we don't prompt again
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
                  _currentIndex = 0; // Go to Home for tasks
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
      // AI Tab

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
            // User cancelled or it failed, don't switch to AI tab
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

  Widget _getScreen(int index) {
    return _screenCache.putIfAbsent(index, () => _screenBuilders[index]());
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = SessionManager().isLocked;

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
        // Placeholder for JSON export
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
        _onItemTapped(4); // Index 4 is settings
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
            // Trigger scan action if on documents screen
            KeyboardShortcutService().executeAction('capture_document');
          } else {
            // Open scanner if not on documents screen
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
          _onItemTapped(4); // Index 4 is settings
        },
        child: Scaffold(
          extendBody: true,
          body: KeyedSubtree(
            key: ValueKey<int>(_currentIndex),
            child: _getScreen(_currentIndex),
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
          bottomNavigationBar: ValueListenableBuilder<Box<FollowUpItem>>(
            valueListenable: LocalStorageService().followUpItemsListenable,
            builder: (context, box, _) {
              final now = DateTime.now();
              final overdueCount = box.values
                  .where((item) =>
                      !item.isCompleted &&
                      item.dueDate != null &&
                      item.dueDate!.isBefore(now))
                  .length;

              return FutureBuilder<Map<int, bool>>(
                future: _getEducationIndicators(),
                builder: (context, snapshot) {
                  return GlassBottomNav(
                    currentIndex: _currentIndex,
                    onItemTapped: _onItemTapped,
                    badgeCounts: overdueCount > 0 ? {0: overdueCount} : null,
                    attentionIndicators: snapshot.data,
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
