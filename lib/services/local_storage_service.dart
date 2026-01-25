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
import '../models/recording_audit_entry.dart';
import '../models/export_audit_entry.dart';
import '../models/enhanced_privacy_settings.dart';
import '../models/auth_audit_entry.dart';
import '../models/citation.dart';
import '../models/issue_report.dart';
import '../models/consent_entry.dart';
import '../models/local_audit_entry.dart';
import '../models/conversation_memory.dart';
import '../models/ai_usage_metric.dart';
import '../models/batch_task.dart';
import '../models/user_profile.dart';
import 'platform_detector.dart';
import 'model_quantization_service.dart';
import '../models/generation_parameters.dart';


/// Local Storage Service for health records
/// Uses Hive with encryption for privacy-first data storage
class LocalStorageService {
  static const String _encryptionKeyKey = 'sehatlocker_encryption_key';
  static const String _healthRecordsBox = 'health_records';
  static const String _settingsBox = 'settings';
  static const String _savedPapersBox = 'saved_papers';
  static const String _searchIndexBox = 'search_index';
  static const String _doctorConversationsBox = 'doctor_conversations';
  static const String _followUpItemsBox = 'follow_up_items';
  static const String _recordingAuditEntriesBox = 'recording_audit_entries';
  static const String _exportAuditEntriesBox = 'export_audit_entries';
  static const String _authAuditEntriesBox = 'auth_audit_entries';
  static const String _issueReportsBox = 'issue_reports';
  static const String _citationsBox = 'citations';
  static const String _consentEntriesBox = 'consent_entries';
  static const String _localAuditEntriesBox = 'local_audit_entries';
  static const String _conversationMemoryBox = 'conversation_memory';
  static const String _batchTasksBox = 'batch_tasks';
  static const String _modelManifestsBox = 'model_manifests';
  static const String _appSettingsKey = 'app_settings_object';
  static const String _userProfileKey = 'user_profile_object';
  static const String _autoDeleteOriginalKey = 'auto_delete_original';
  static const String _userProfileBox = 'user_profile';


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
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(RecordingAuditEntryAdapter());
    }
    if (!Hive.isAdapterRegistered(12)) {
      Hive.registerAdapter(EnhancedPrivacySettingsAdapter());
    }
    if (!Hive.isAdapterRegistered(13)) {
      Hive.registerAdapter(AuthAuditEntryAdapter());
    }
    if (!Hive.isAdapterRegistered(14)) {
      Hive.registerAdapter(CitationAdapter());
    }
    if (!Hive.isAdapterRegistered(15)) {
      Hive.registerAdapter(IssueReportAdapter());
    }
    if (!Hive.isAdapterRegistered(16)) {
      Hive.registerAdapter(ConsentEntryAdapter());
    }
    if (!Hive.isAdapterRegistered(17)) {
      Hive.registerAdapter(LocalAuditEntryAdapter());
    }
    if (!Hive.isAdapterRegistered(25)) {
      Hive.registerAdapter(ConversationMemoryAdapter());
    }
    if (!Hive.isAdapterRegistered(26)) {
      Hive.registerAdapter(MemoryEntryAdapter());
    }
    if (!Hive.isAdapterRegistered(31)) {
      Hive.registerAdapter(GenerationParametersAdapter());
    }
    if (!Hive.isAdapterRegistered(32)) {
      Hive.registerAdapter(AIUsageMetricAdapter());
    }
    if (!Hive.isAdapterRegistered(33)) {
      Hive.registerAdapter(BatchTaskStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(34)) {
      Hive.registerAdapter(BatchTaskPriorityAdapter());
    }
    if (!Hive.isAdapterRegistered(35)) {
      Hive.registerAdapter(BatchTaskAdapter());
    }
    if (!Hive.isAdapterRegistered(40)) {
      Hive.registerAdapter(UserProfileAdapter());
    }
    if (!Hive.isAdapterRegistered(41)) {
      Hive.registerAdapter(QuantizationFormatAdapter());
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

    await Hive.openBox<Citation>(
      _citationsBox,
      encryptionCipher: HiveAesCipher(encryptionKey),
    );

    await Hive.openBox<IssueReport>(
      _issueReportsBox,
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

    await Hive.openBox<FollowUpItem>(
      _followUpItemsBox,
      encryptionCipher: HiveAesCipher(encryptionKey),
    );

    await Hive.openBox<RecordingAuditEntry>(
      _recordingAuditEntriesBox,
      encryptionCipher: HiveAesCipher(encryptionKey),
    );

    await Hive.openBox<ExportAuditEntry>(
      _exportAuditEntriesBox,
      encryptionCipher: HiveAesCipher(encryptionKey),
    );

    await Hive.openBox<AuthAuditEntry>(
      _authAuditEntriesBox,
      encryptionCipher: HiveAesCipher(encryptionKey),
    );

    await Hive.openBox<ConsentEntry>(
      _consentEntriesBox,
      encryptionCipher: HiveAesCipher(encryptionKey),
    );

    await Hive.openBox<LocalAuditEntry>(
      _localAuditEntriesBox,
      encryptionCipher: HiveAesCipher(encryptionKey),
    );

    await Hive.openBox<ConversationMemory>(
      _conversationMemoryBox,
      encryptionCipher: HiveAesCipher(encryptionKey),
    );

    await Hive.openBox<BatchTask>(
      _batchTasksBox,
      encryptionCipher: HiveAesCipher(encryptionKey),
    );

    await Hive.openBox<ModelMetadata>(
      _modelManifestsBox,
      encryptionCipher: HiveAesCipher(encryptionKey),
    );

    await Hive.openBox<UserProfile>(
      _userProfileBox,
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

  // MARK: - Local Audit Entries

  /// Get local audit entries box
  Box<LocalAuditEntry> get _localAuditEntries =>
      Hive.box<LocalAuditEntry>(_localAuditEntriesBox);

  /// Save a local audit entry
  Future<void> saveLocalAuditEntry(LocalAuditEntry entry) async {
    await _localAuditEntries.add(entry);
  }

  /// Get all local audit entries
  List<LocalAuditEntry> getAllLocalAuditEntries() {
    if (!Hive.isBoxOpen(_localAuditEntriesBox)) return [];
    return _localAuditEntries.values.toList();
  }

  /// Delete local audit entries
  Future<void> deleteLocalAuditEntries(List<dynamic> keys) async {
    await _localAuditEntries.deleteAll(keys);
  }

  // MARK: - Health Records

  /// Get health records box
  Box get _recordsBox => Hive.box(_healthRecordsBox);

  /// Get listenable for health records
  ValueListenable<Box> get recordsListenable =>
      Hive.box(_healthRecordsBox).listenable();

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

  // MARK: - Conversation Memory

  /// Get conversation memory for a specific ID
  ConversationMemory? getConversationMemory(String conversationId) {
    final box = Hive.box<ConversationMemory>(_conversationMemoryBox);
    return box.get(conversationId);
  }

  /// Save conversation memory
  Future<void> saveConversationMemory(ConversationMemory memory) async {
    final box = Hive.box<ConversationMemory>(_conversationMemoryBox);
    await box.put(memory.conversationId, memory);
  }

  /// Delete conversation memory
  Future<void> deleteConversationMemory(String conversationId) async {
    final box = Hive.box<ConversationMemory>(_conversationMemoryBox);
    await box.delete(conversationId);
  }

  /// Get all conversation memories
  List<ConversationMemory> getAllConversationMemories() {
    final box = Hive.box<ConversationMemory>(_conversationMemoryBox);
    return box.values.toList();
  }

  // MARK: - Batch Tasks

  /// Get batch tasks box
  Box<BatchTask> get _batchTasks => Hive.box<BatchTask>(_batchTasksBox);

  /// Save a batch task
  Future<void> saveBatchTask(BatchTask task) async {
    await _batchTasks.put(task.id, task);
  }

  /// Get all batch tasks
  List<BatchTask> getAllBatchTasks() {
    if (!Hive.isBoxOpen(_batchTasksBox)) return [];
    return _batchTasks.values.toList();
  }

  /// Delete a batch task
  Future<void> deleteBatchTask(String id) async {
    await _batchTasks.delete(id);
  }

  /// Clear all batch tasks
  Future<void> clearBatchTasks() async {
    await _batchTasks.clear();
  }

  /// Get listenable for batch tasks
  ValueListenable<Box<BatchTask>> get batchTasksListenable =>
      _batchTasks.listenable();

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

    // Update widget data whenever settings are saved
    try {
      // await WidgetDataService().updateWidgetData(settings);
    } catch (e) {
      debugPrint('Failed to update widget data: $e');
    }
  }

  /// Get User Profile
  UserProfile getUserProfile() {
    return Hive.box<UserProfile>(_userProfileBox).get(_userProfileKey) ?? UserProfile();
  }

  /// Save User Profile
  Future<void> saveUserProfile(UserProfile profile) async {
    await Hive.box<UserProfile>(_userProfileBox).put(_userProfileKey, profile);
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
    bool needsSave = false;

    if (settings.modelMetadataMap.isEmpty) {
      debugPrint('Initializing model metadata on first load');
      final Map<String, ModelMetadata> metadataMap = {};
      for (var model in ModelOption.availableModels) {
        metadataMap[model.id] = model.metadata;
      }
      settings.modelMetadataMap = metadataMap;

      // Also apply platform defaults on first load
      await PlatformDetector().getCapabilities();
      PlatformDetector().applyPlatformDefaults(settings);

      needsSave = true;
    }

    if (needsSave) {
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
    return box.values.whereType<DocumentExtraction>().toList();
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

  // MARK: - Doctor Conversations

  /// Get doctor conversations box
  Box get _conversationsBox => Hive.box(_doctorConversationsBox);

  /// Save a doctor conversation
  Future<void> saveDoctorConversation(DoctorConversation conversation) async {
    await _conversationsBox.put(conversation.id, conversation);
  }

  /// Get all doctor conversations
  List<DoctorConversation> getAllDoctorConversations() {
    if (!Hive.isBoxOpen(_doctorConversationsBox)) return [];
    return _conversationsBox.values.cast<DoctorConversation>().toList();
  }

  /// Get a doctor conversation by ID
  DoctorConversation? getDoctorConversation(String id) {
    if (!Hive.isBoxOpen(_doctorConversationsBox)) return null;
    return _conversationsBox.get(id);
  }

  /// Delete a doctor conversation
  Future<void> deleteDoctorConversation(String id) async {
    await _conversationsBox.delete(id);
  }

  // MARK: - Follow Up Items

  /// Get follow-up items box
  Box<FollowUpItem> get _followUpBox =>
      Hive.box<FollowUpItem>(_followUpItemsBox);

  /// Save a follow-up item
  Future<void> saveFollowUpItem(FollowUpItem item) async {
    await _followUpBox.put(item.id, item);
  }

  /// Get a follow-up item by ID
  FollowUpItem? getFollowUpItem(String id) {
    if (!Hive.isBoxOpen(_followUpItemsBox)) return null;
    return _followUpBox.get(id);
  }

  /// Get all follow-up items
  List<FollowUpItem> getAllFollowUpItems() {
    if (!Hive.isBoxOpen(_followUpItemsBox)) return [];
    return _followUpBox.values.cast<FollowUpItem>().toList();
  }

  /// Get overdue follow-up items
  List<FollowUpItem> getOverdueItems() {
    if (!Hive.isBoxOpen(_followUpItemsBox)) return [];
    final now = DateTime.now();
    return _followUpBox.values.cast<FollowUpItem>().where((item) {
      return !item.isCompleted &&
          item.dueDate != null &&
          item.dueDate!.isBefore(now);
    }).toList();
  }

  /// Get listenable for follow-up items box
  ValueListenable<Box<FollowUpItem>> get followUpItemsListenable =>
      _followUpBox.listenable();

  /// Delete a follow-up item
  Future<void> deleteFollowUpItem(String id) async {
    await _followUpBox.delete(id);
  }

  // MARK: - Recording Audit Logs

  /// Get recording audit entries box
  Box<RecordingAuditEntry> get _auditEntriesBox =>
      Hive.box<RecordingAuditEntry>(_recordingAuditEntriesBox);

  /// Get citations box
  Box<Citation> get citationsBox => Hive.box<Citation>(_citationsBox);

  /// Save a recording audit entry
  Future<void> saveRecordingAuditEntry(RecordingAuditEntry entry) async {
    await _auditEntriesBox.add(entry);
  }

  /// Get all recording audit entries
  List<RecordingAuditEntry> getAllRecordingAuditEntries() {
    if (!Hive.isBoxOpen(_recordingAuditEntriesBox)) return [];
    return _auditEntriesBox.values.toList();
  }

  // MARK: - Export Audit Logs

  /// Get export audit entries box
  Box<ExportAuditEntry> get _exportAuditEntries =>
      Hive.box<ExportAuditEntry>(_exportAuditEntriesBox);

  /// Save an export audit entry
  Future<void> saveExportAuditEntry(ExportAuditEntry entry) async {
    await _exportAuditEntries.add(entry);
  }

  /// Get all export audit entries
  List<ExportAuditEntry> getAllExportAuditEntries() {
    if (!Hive.isBoxOpen(_exportAuditEntriesBox)) return [];
    return _exportAuditEntries.values.toList();
  }

  // MARK: - Auth Audit Logs

  /// Get auth audit entries box
  Box<AuthAuditEntry> get _authAuditEntries =>
      Hive.box<AuthAuditEntry>(_authAuditEntriesBox);

  /// Save an auth audit entry
  Future<void> saveAuthAuditEntry(AuthAuditEntry entry) async {
    await _authAuditEntries.add(entry);
  }

  /// Get all auth audit entries
  List<AuthAuditEntry> getAllAuthAuditEntries() {
    if (!Hive.isBoxOpen(_authAuditEntriesBox)) return [];
    return _authAuditEntries.values.toList();
  }

  // MARK: - Issue Reports

  /// Get issue reports box
  Box<IssueReport> get _issueReports => Hive.box<IssueReport>(_issueReportsBox);

  /// Save an issue report
  Future<void> saveIssueReport(IssueReport report) async {
    await _issueReports.put(report.id, report);
  }

  /// Get all issue reports
  List<IssueReport> getAllIssueReports() {
    if (!Hive.isBoxOpen(_issueReportsBox)) return [];
    return _issueReports.values.toList();
  }

  /// Delete an issue report
  Future<void> deleteIssueReport(String id) async {
    await _issueReports.delete(id);
  }

  // MARK: - Consent Entries

  /// Get consent entries box
  Box<ConsentEntry> get _consentEntries =>
      Hive.box<ConsentEntry>(_consentEntriesBox);

  /// Save a consent entry
  Future<void> saveConsentEntry(ConsentEntry entry) async {
    await _consentEntries.put(entry.id, entry);
  }

  /// Get all consent entries
  List<ConsentEntry> getAllConsentEntries() {
    if (!Hive.isBoxOpen(_consentEntriesBox)) return [];
    return _consentEntries.values.toList();
  }

  /// Get a consent entry by ID
  ConsentEntry? getConsentEntry(String id) {
    if (!Hive.isBoxOpen(_consentEntriesBox)) return null;
    return _consentEntries.get(id);
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
