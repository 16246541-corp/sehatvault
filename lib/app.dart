import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/follow_up_item.dart';
import 'services/local_storage_service.dart';
import 'screens/documents_screen.dart';
import 'screens/follow_up_list_screen.dart';
import 'screens/ai_screen.dart';
import 'screens/news_screen.dart';
import 'screens/settings_screen.dart';
import 'widgets/navigation/glass_bottom_nav.dart';
import 'widgets/auth_gate.dart';
import 'services/biometric_service.dart';
import 'services/pin_auth_service.dart';
import 'screens/pin_setup_screen.dart';
import 'widgets/dialogs/biometric_enrollment_dialog.dart';
import 'services/education_service.dart';
import 'widgets/education/education_gate.dart';

import 'screens/document_scanner_screen.dart';
import 'utils/theme.dart';

/// Main App Widget with bottom navigation
class SehatLockerApp extends StatefulWidget {
  const SehatLockerApp({super.key});

  @override
  State<SehatLockerApp> createState() => _SehatLockerAppState();
}

class _SehatLockerAppState extends State<SehatLockerApp>
    with WidgetsBindingObserver {
  int _currentIndex = 0;
  bool _pinSetupRequired = false;
  bool _pinSetupChecked = false;
  bool _isCheckingEnrollment = false;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _screens = [
      DocumentsScreen(
        onTasksTap: () => _onItemTapped(1),
        onRecordTap: () => _onItemTapped(2),
      ),
      const FollowUpListScreen(),
      _buildAIScreen(),
      const NewsScreen(),
      const SettingsScreen(),
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkOverdueItems();
      _checkBiometricEnrollment();
    });

    _checkPinSetupRequirement();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkBiometricEnrollment(isResume: true);
    }
  }

  Future<void> _checkBiometricEnrollment({bool isResume = false}) async {
    if (_isCheckingEnrollment) return;
    if (_pinSetupRequired) return;

    _isCheckingEnrollment = true;

    try {
      final settings = LocalStorageService().getAppSettings();

      if (settings.hasSeenBiometricEnrollmentPrompt && !isResume) {
        return;
      }

      final status = await BiometricService().getBiometricStatus();

      if (status == BiometricStatus.availableButNotEnrolled) {
        if (settings.hasSeenBiometricEnrollmentPrompt) return;

        if (!mounted) return;

        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => BiometricEnrollmentDialog(
            onEnroll: () async {
              Navigator.pop(context);
              await BiometricService().openSecuritySettings();
            },
            onUsePin: () async {
              Navigator.pop(context);
              settings.hasSeenBiometricEnrollmentPrompt = true;
              await LocalStorageService().saveAppSettings(settings);
              await _checkPinSetupRequirement();
            },
            onDismiss: () async {
              Navigator.pop(context);
              settings.hasSeenBiometricEnrollmentPrompt = true;
              await LocalStorageService().saveAppSettings(settings);
            },
          ),
        );
      }
    } finally {
      _isCheckingEnrollment = false;
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
                  _currentIndex = 1;
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

  void _onItemTapped(int index) {
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
      0: !(documentComplete && storageComplete),
      2: !aiComplete,
    };
  }

  Future<void> _checkPinSetupRequirement() async {
    final hasBiometrics = await BiometricService().hasEnrolledBiometrics;
    final hasPin = await PinAuthService().hasPin();
    if (mounted) {
      setState(() {
        _pinSetupRequired = !hasBiometrics && !hasPin;
        _pinSetupChecked = true;
      });
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
    if (!_pinSetupChecked) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_pinSetupRequired) {
      return PinSetupScreen(
        mode: PinSetupMode.setup,
        showAppBar: false,
        onComplete: () {
          setState(() {
            _pinSetupRequired = false;
          });
        },
      );
    }

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      floatingActionButton: _currentIndex == 0
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
                badgeCounts: overdueCount > 0 ? {1: overdueCount} : null,
                attentionIndicators: snapshot.data,
              );
            },
          );
        },
      ),
    );
  }
}
