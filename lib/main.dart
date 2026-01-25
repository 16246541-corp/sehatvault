import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
import 'widgets/session_guard.dart';

/// Global storage service instance
final LocalStorageService storageService = LocalStorageService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations (portrait only for mobile)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize local storage
  await storageService.initialize();

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

  await CitationService(storageService).migrateExistingDocumentCitations();

  // Initialize follow-up reminder service
  await FollowUpReminderService().initialize();
  // Ideally request permissions here or on first use.
  // For now, let's request on startup to ensure it works.
  await FollowUpReminderService().requestPermissions();

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
  @override
  void initState() {
    super.initState();
    // Start session monitoring
    SessionManager().startSession();
  }

  @override
  void dispose() {
    SessionManager().stopSession();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SessionGuard(
      child: MaterialApp(
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
        themeMode: ThemeMode.system,
        home: const SehatLockerApp(),
      ),
    );
  }
}
