import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';
import 'utils/theme.dart';
import 'services/local_storage_service.dart';
import 'services/encryption_service.dart';
import 'services/search_service.dart';
import 'services/verb_mapping_configuration.dart';
import 'services/temporal_phrase_patterns_configuration.dart';
import 'services/medical_dictionary_service.dart';
import 'services/follow_up_reminder_service.dart';
import 'services/conversation_cleanup_service.dart';
import 'services/citation_service.dart';
import 'services/session_manager.dart';
import 'services/window_manager_service.dart';
import 'services/system_tray_service.dart';
import 'services/prompt_template_service.dart';
import 'services/ai_analytics_service.dart';
import 'services/batch_processing_service.dart';
import 'widgets/session_guard.dart';
import 'screens/onboarding/onboarding_navigator.dart';
import 'services/onboarding_service.dart';
import 'services/platform_detector.dart';
import 'services/ui_target_resolver.dart';
import 'ui/desktop/sehat_locker_desktop_app.dart';
import 'widgets/ai/incompatible_device_screen.dart';


import 'config/app_config.dart';

/// Global storage service instance
final LocalStorageService storageService = LocalStorageService();

Future<void> mainCommon(AppConfig config) async {
  WidgetsFlutterBinding.ensureInitialized();

  AppConfig.setConfig(config);

  // Initialize local storage
  await storageService.initialize();

  // Initialize Window Manager for desktop
  await WindowManagerService().initialize();

  // Initialize System Tray
  await SystemTrayService().init();

  // Initialize ObjectBox Search Index
  await SearchService.init();

  // Initialize encryption service
  await EncryptionService().initialize();

  // Initialize verb mapping configuration
  await VerbMappingConfiguration().load();

  // Initialize temporal phrase patterns configuration
  await TemporalPhrasePatternsConfiguration().load();

  // Initialize medical dictionary service
  await MedicalDictionaryService().load();

  // Initialize prompt templates
  await PromptTemplateService().loadTemplates();

  // Initialize AI analytics
  await AIAnalyticsService().init();

  await CitationService(storageService).migrateExistingDocumentCitations();

  // Initialize follow-up reminder service
  await FollowUpReminderService().initialize();
  // Ideally request permissions here or on first use.
  // For now, let's request on startup to ensure it works.
  await FollowUpReminderService().requestPermissions();

  // Initialize batch processing service
  BatchProcessingService().initialize();

  // Run daily conversation cleanup
  await ConversationCleanupService(storageService).runDailyCleanup();

  // Initialize search index (ensure existing docs are indexed)
  final searchService = SearchService(storageService);
  await searchService.ensureIndexed();

  // Start listening to changes for automatic indexing
  searchService.startListening();
  // We need to keep searchService alive, but since it attaches listeners to Hive boxes
  // which are singletons/globally accessible, the closures should keep working.
  // However, startListening uses _storageService.followUpItemsListenable.addListener.
  // The listener is a closure inside SearchService. If SearchService is GC'd, the closure might still exist
  // referenced by the ValueNotifier? Yes.
  // But to be safe and clean, we might want to store it in a global or service locator.
  // For now, let's assume it works as the listener is held by the Box.

  runApp(const MyApp());
}



class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isOnboardingComplete = false;
  bool _initialized = false;
  bool _isIncompatible = false;
  double _detectedRam = 0;
  UiTarget? _uiTarget;

  @override
  void initState() {
    super.initState();
    // Start session monitoring
    SessionManager().startSession();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final uiTarget = await UiTargetResolver.resolve();
    await _applyPreferredOrientations(uiTarget);

    final caps = await PlatformDetector().getCapabilities();

    if (uiTarget == UiTarget.mobile && caps.ramGB < 7.5) {
      if (mounted) {
        setState(() {
          _isIncompatible = true;
          _detectedRam = caps.ramGB;
          _uiTarget = uiTarget;
          _initialized = true;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _uiTarget = uiTarget;
      });
    }

    await _checkOnboardingStatus();
  }

  Future<void> _applyPreferredOrientations(UiTarget uiTarget) async {
    if (uiTarget == UiTarget.mobile) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      return;
    }

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<void> _checkOnboardingStatus() async {
    final isComplete = await OnboardingService().isOnboardingComplete();
    if (mounted) {
      setState(() {
        _isOnboardingComplete = isComplete;
        _initialized = true;
      });
    }
  }


  Widget _getScreenForStep() {
    if (!_isOnboardingComplete) {
      return OnboardingNavigator(onComplete: () {
        setState(() {
          _isOnboardingComplete = true;
        });
      });
    }
    if (_uiTarget == UiTarget.desktop) {
      return const SehatLockerDesktopApp();
    }
    return const SehatLockerApp();
  }



  @override
  void dispose() {
    SessionManager().stopSession();
    WindowManagerService().dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized || _uiTarget == null) {
      // Show a minimal loading state while checking onboarding status
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_isIncompatible) {
      return IncompatibleDeviceScreen(
        detectedRam: _detectedRam,
        requiredRam: 8.0,
      );
    }

    return SessionGuard(
      child: ValueListenableBuilder<Box>(
        valueListenable: storageService.settingsListenable,
        builder: (context, box, _) {
          final settings = storageService.getAppSettings();
          
          ThemeMode themeMode;
          // Robustly handle potentially null or invalid theme modes
          try {
            switch (settings.themeMode) {
              case 'light':
                themeMode = ThemeMode.light;
                break;
              case 'dark':
                themeMode = ThemeMode.dark;
                break;
              case 'system':
              default:
                themeMode = ThemeMode.system;
            }
          } catch (e) {
            // Fallback for safety
            themeMode = ThemeMode.system;
          }

          double fontScale = 1.0;
          try {
            // Clamp font scale to reasonable limits to prevent layout crashes
            fontScale = settings.fontScale.clamp(0.8, 1.4);
          } catch (e) {
            fontScale = 1.0;
          }

          return MaterialApp(
            navigatorKey: SessionManager().navigatorKey,
            title: 'Sehat Locker',
            debugShowCheckedModeBanner: false,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'),
            ],
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            builder: (context, child) {
              final mediaQuery = MediaQuery.of(context);
              return MediaQuery(
                data: mediaQuery.copyWith(
                  textScaleFactor: fontScale,
                ),
                child: child!,
              );
            },
            home: _getScreenForStep(),
          );
        },
      ),
    );
  }
}
