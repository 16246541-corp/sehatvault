import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';

/// Local Storage Service for health records
/// Uses Hive with encryption for privacy-first data storage
class LocalStorageService {
  static const String _encryptionKeyKey = 'sehatlocker_encryption_key';
  static const String _healthRecordsBox = 'health_records';
  static const String _settingsBox = 'settings';
  static const String _savedPapersBox = 'saved_papers';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  bool _isInitialized = false;

  /// Initialize Hive and open encrypted boxes
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Get application documents directory
    final appDocDir = await getApplicationDocumentsDirectory();
    
    // Initialize Hive
    await Hive.initFlutter(appDocDir.path);

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

    _isInitialized = true;
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

  // MARK: - Saved Papers

  /// Get saved papers box
  Box get _papers => Hive.box(_savedPapersBox);

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
