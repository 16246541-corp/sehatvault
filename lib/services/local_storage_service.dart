import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import '../models/app_settings.dart';
import '../models/health_record.dart';
import '../models/model_metadata.dart';
import '../models/model_option.dart';
import '../models/document_extraction.dart';
import '../models/doctor_conversation.dart';
import '../models/follow_up_item.dart';

/// Local Storage Service for health records
/// Uses Hive with encryption for privacy-first data storage
class LocalStorageService {
  static const String _encryptionKeyKey = 'sehatlocker_encryption_key';
  static const String _healthRecordsBox = 'health_records';
  static const String _settingsBox = 'settings';
  static const String _savedPapersBox = 'saved_papers';
  static const String _searchIndexBox = 'search_index';
  static const String _doctorConversationsBox = 'doctor_conversations';
  static const String _appSettingsKey = 'app_settings_object';
  static const String _autoDeleteOriginalKey = 'auto_delete_original';

  // Singleton instance
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  bool _isInitialized = false;

  /// Initialize Hive and open encrypted boxes
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Get application documents directory
    final appDocDir = await getApplicationDocumentsDirectory();
    
    // Initialize Hive
    await Hive.initFlutter(appDocDir.path);

    // Register Adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(HealthRecordAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(AppSettingsAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(ModelMetadataAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(DocumentExtractionAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(DoctorConversationAdapter());
    }
    if (!Hive.isAdapterRegistered(7)) {
      Hive.registerAdapter(FollowUpItemAdapter());
    }
    if (!Hive.isAdapterRegistered(8)) {
      Hive.registerAdapter(FollowUpCategoryAdapter());
    }
    if (!Hive.isAdapterRegistered(9)) {
      Hive.registerAdapter(FollowUpPriorityAdapter());
    }

    // Get or create encryption key
    final encryptionKey = await _getOrCreateEncryptionKey();

    // Open encrypted boxes
    await Hive.openBox(
      _healthRecordsBox,
      encryptionCipher: HiveAesCipher(encryptionKey),
    );

    await Hive.openBox(
      _settingsBox,
      encryptionCipher: HiveAesCipher(encryptionKey),
    );

    await Hive.openBox(
      _savedPapersBox,
      encryptionCipher: HiveAesCipher(encryptionKey),
    );

    await Hive.openBox(
      _searchIndexBox,
      encryptionCipher: HiveAesCipher(encryptionKey),
    );

    await Hive.openBox(
      _doctorConversationsBox,
      encryptionCipher: HiveAesCipher(encryptionKey),
    );

    _isInitialized = true;
    
    // Initialize model metadata on first load
    await _initializeAppSettingsMetadata();
    
    debugPrint('LocalStorageService initialized with encrypted storage');
  }

  /// Get or create AES-256 encryption key
  Future<List<int>> _getOrCreateEncryptionKey() async {
    String? encodedKey = await _secureStorage.read(key: _encryptionKeyKey);
    
    if (encodedKey == null) {
      // Generate new encryption key
      final key = Hive.generateSecureKey();
      encodedKey = base64Encode(key);
      await _secureStorage.write(key: _encryptionKeyKey, value: encodedKey);
      debugPrint('Generated new encryption key');
    }
    
    return base64Decode(encodedKey);
  }

  // MARK: - Health Records

  /// Get health records box
  Box get _recordsBox => Hive.box(_healthRecordsBox);

  /// Save a health record
  Future<void> saveRecord(String id, Map<String, dynamic> record) async {
    await _recordsBox.put(id, record);
  }

  /// Get a health record by ID
  Map<String, dynamic>? getRecord(String id) {
    return _recordsBox.get(id);
  }

  /// Get all health records
  List<Map<String, dynamic>> getAllRecords() {
    return _recordsBox.values.cast<Map<String, dynamic>>().toList();
  }

  /// Get records by category
  List<Map<String, dynamic>> getRecordsByCategory(String category) {
    return getAllRecords()
        .where((record) => record['category'] == category)
        .toList();
  }

  /// Delete a health record
  Future<void> deleteRecord(String id) async {
    await _recordsBox.delete(id);
  }

  /// Get record count
  int get recordCount => _recordsBox.length;

  // MARK: - Settings

  /// Get settings box
  Box get _settings => Hive.box(_settingsBox);

  /// Save a setting
  Future<void> saveSetting(String key, dynamic value) async {
    await _settings.put(key, value);
  }

  /// Get a setting
  T? getSetting<T>(String key, {T? defaultValue}) {
    return _settings.get(key, defaultValue: defaultValue);
  }

  /// Get App Settings
  AppSettings getAppSettings() {
    return _settings.get(_appSettingsKey) ?? AppSettings.defaultSettings();
  }

  /// Save App Settings
  Future<void> saveAppSettings(AppSettings settings) async {
    await _settings.put(_appSettingsKey, settings);
  }

  /// Get Auto Delete Original setting
  bool get autoDeleteOriginal {
    return _settings.get(_autoDeleteOriginalKey, defaultValue: false);
  }

  /// Set Auto Delete Original setting
  Future<void> setAutoDeleteOriginal(bool value) async {
    await _settings.put(_autoDeleteOriginalKey, value);
  }

  /// Initialize model metadata if it doesn't exist (First load)
  Future<void> _initializeAppSettingsMetadata() async {
    final settings = getAppSettings();
    if (settings.modelMetadataMap.isEmpty) {
      debugPrint('Initializing model metadata on first load');
      final Map<String, ModelMetadata> metadataMap = {};
      for (var model in ModelOption.availableModels) {
        metadataMap[model.id] = model.metadata;
      }
      settings.modelMetadataMap = metadataMap;
      await saveAppSettings(settings);
    }
  }

  // MARK: - Saved Papers

  /// Get saved papers box
  Box get _papers => Hive.box(_savedPapersBox);

  /// Get search index box
  Box get searchIndexBox => Hive.box(_searchIndexBox);

  /// Save a research paper
  Future<void> savePaper(String id, Map<String, dynamic> paper) async {
    await _papers.put(id, paper);
  }

  /// Get all saved papers
  List<Map<String, dynamic>> getSavedPapers() {
    return _papers.values.cast<Map<String, dynamic>>().toList();
  }

  /// Delete a saved paper
  Future<void> deletePaper(String id) async {
    await _papers.delete(id);
  }

  // MARK: - Document Extractions

  /// Get document extractions box (stored in health_records box)
  /// Document extractions are stored separately but can be linked to HealthRecords
  
  /// Save a document extraction
  Future<void> saveDocumentExtraction(DocumentExtraction extraction) async {
    final box = Hive.box('health_records');
    await box.put(extraction.id, extraction);
    debugPrint('Saved DocumentExtraction: ${extraction.id}');
  }

  /// Get a document extraction by ID
  DocumentExtraction? getDocumentExtraction(String id) {
    final box = Hive.box<DocumentExtraction>('health_records');
    return box.values.firstWhere(
      (extraction) => extraction.id == id,
      orElse: () => throw Exception('DocumentExtraction not found: $id'),
    );
  }

  /// Get all document extractions
  List<DocumentExtraction> getAllDocumentExtractions() {
    final box = Hive.box('health_records');
    return box.values
        .whereType<DocumentExtraction>()
        .toList();
  }

  /// Find a document extraction by its content hash
  DocumentExtraction? findDocumentExtractionByHash(String hash) {
    try {
      final box = Hive.box('health_records');
      return box.values
          .whereType<DocumentExtraction>()
          .firstWhere((extraction) => extraction.contentHash == hash);
    } catch (e) {
      return null;
    }
  }

  /// Delete a document extraction
  Future<void> deleteDocumentExtraction(String id) async {
    final extraction = getDocumentExtraction(id);
    if (extraction != null) {
      await extraction.delete();
      debugPrint('Deleted DocumentExtraction: $id');
    }
  }

  // MARK: - Cleanup

  /// Clear all data (for settings screen)
  Future<void> clearAllData() async {
    await _recordsBox.clear();
    await _papers.clear();
    debugPrint('All data cleared');
  }

  /// Close all boxes
  Future<void> close() async {
    await Hive.close();
    _isInitialized = false;
  }
}
