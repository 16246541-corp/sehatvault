import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'utils/theme.dart';
import 'services/local_storage_service.dart';
import 'services/search_service.dart';
import 'services/verb_mapping_configuration.dart';
import 'services/temporal_phrase_patterns_configuration.dart';
import 'services/medical_dictionary_service.dart';
import 'services/follow_up_reminder_service.dart';

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

  // Initialize verb mapping configuration
  await VerbMappingConfiguration().load();

  // Initialize temporal phrase patterns configuration
  await TemporalPhrasePatternsConfiguration().load();

  // Initialize medical dictionary service
  await MedicalDictionaryService().load();

  // Initialize follow-up reminder service
  await FollowUpReminderService().initialize();
  // Ideally request permissions here or on first use.
  // For now, let's request on startup to ensure it works.
  await FollowUpReminderService().requestPermissions();

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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sehat Locker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const SehatLockerApp(),
    );
  }
}
