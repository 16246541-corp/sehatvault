import 'package:uuid/uuid.dart';
import '../models/local_audit_entry.dart';
import '../utils/secure_logger.dart';
import 'local_storage_service.dart';
import 'session_manager.dart';

class IntegrityResult {
  final bool isValid;
  final int failingIndex;
  final String? error;

  IntegrityResult({required this.isValid, this.failingIndex = -1, this.error});
}

class LocalAuditService {
  static const String _genesisHash = '00000000000000000000000000000000';

  final LocalStorageService _storageService;
  final SessionManager _sessionManager;

  LocalAuditService(this._storageService, this._sessionManager);

  Future<void> logDocumentCategorization({
    required String category,
    required double confidence,
    required bool isSensitive,
    required String action, // 'save' or 'cancel'
  }) async {
    await log(
      action: 'document_categorization',
      details: {
        'category': category,
        'confidence': confidence.toStringAsFixed(2),
        'is_sensitive': isSensitive.toString(),
        'user_action': action,
      },
      sensitivity: isSensitive ? 'high' : 'info',
    );
  }

  Future<void> log({
    required String action,
    required Map<String, String> details,
    String sensitivity = 'info',
  }) async {
    final now = DateTime.now();
    final id = const Uuid().v4();
    final redactedDetails = _redactSensitiveData(details);
    final sessionId = _sessionManager.currentSessionId;
    final settings = _storageService.getAppSettings();
    final allEntries = _storageService.getAllLocalAuditEntries();
    final anchorHash = _getAnchorHash(settings.localAuditChainAnchorHash);
    final previousHash =
        allEntries.isNotEmpty ? allEntries.last.hash : anchorHash;

    final hash = LocalAuditEntry.generateHash(
      id: id,
      timestamp: now,
      action: action,
      details: redactedDetails,
      previousHash: previousHash,
      sessionId: sessionId,
    );

    final entry = LocalAuditEntry(
      id: id,
      timestamp: now,
      action: action,
      details: redactedDetails,
      previousHash: previousHash,
      hash: hash,
      sessionId: sessionId,
      sensitivity: sensitivity,
    );

    await _storageService.saveLocalAuditEntry(entry);

    if ((allEntries.length + 1) % 100 == 0) {
      await verifyIntegrity();
    }
  }

  Future<IntegrityResult> verifyIntegrity() async {
    final entries = _storageService.getAllLocalAuditEntries();
    if (entries.isEmpty) return IntegrityResult(isValid: true);
    final settings = _storageService.getAppSettings();
    final anchorHash = _getAnchorHash(settings.localAuditChainAnchorHash);
    return _verifyIntegrity(entries, anchorHash);
  }

  static IntegrityResult _verifyIntegrity(
      List<LocalAuditEntry> entries, String anchorHash) {
    if (entries.isEmpty) return IntegrityResult(isValid: true);

    String expectedPreviousHash = anchorHash;

    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];

      if (entry.previousHash != expectedPreviousHash) {
        return IntegrityResult(
            isValid: false, failingIndex: i, error: 'Previous hash mismatch');
      }

      if (!entry.verifyHash()) {
        return IntegrityResult(
            isValid: false,
            failingIndex: i,
            error: 'Self hash verification failed');
      }

      expectedPreviousHash = entry.hash;
    }

    return IntegrityResult(isValid: true);
  }

  List<LocalAuditEntry> getEntries({
    DateTime? startDate,
    DateTime? endDate,
    String? action,
    String? sensitivity,
    String? sessionId,
    String? searchTerm,
  }) {
    var entries = _storageService.getAllLocalAuditEntries();

    entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return entries.where((entry) {
      if (startDate != null && entry.timestamp.isBefore(startDate))
        return false;
      if (endDate != null && entry.timestamp.isAfter(endDate)) return false;
      if (action != null && entry.action != action) return false;
      if (sensitivity != null && entry.sensitivity != sensitivity) return false;
      if (sessionId != null && entry.sessionId != sessionId) return false;

      if (searchTerm != null && searchTerm.isNotEmpty) {
        final term = searchTerm.toLowerCase();
        final inDetails =
            entry.details.values.any((v) => v.toLowerCase().contains(term));
        if (!entry.action.toLowerCase().contains(term) && !inDetails) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  Future<int> runDailyCleanup() async {
    final settings = _storageService.getAppSettings();
    final retentionDays = settings.localAuditRetentionDays;
    if (retentionDays <= 0) return 0;
    return prune(Duration(days: retentionDays));
  }

  Future<int> prune(Duration maxAge) async {
    final cutoff = DateTime.now().subtract(maxAge);
    final allEntries = _storageService.getAllLocalAuditEntries();
    final keysToDelete = <dynamic>[];

    for (var entry in allEntries) {
      if (entry.timestamp.isBefore(cutoff)) {
        keysToDelete.add(entry.key);
      }
    }

    if (keysToDelete.isNotEmpty) {
      await _storageService.deleteLocalAuditEntries(keysToDelete);
      final remaining = _storageService.getAllLocalAuditEntries();
      final settings = _storageService.getAppSettings();
      settings.localAuditChainAnchorHash =
          remaining.isNotEmpty ? remaining.first.previousHash : _genesisHash;
      await _storageService.saveAppSettings(settings);
    }

    return keysToDelete.length;
  }

  Future<void> logVerificationEvent(
      String extractionId, Map<String, dynamic> corrections) async {
    // Store verification history in existing LocalAuditEntry box (TypeId 17)
    // Include: original values, corrected values, timestamp, document ID
    final redactedCorrections = _redactSensitiveData(
        corrections.map((key, value) => MapEntry(key, value.toString())));

    await log(
      action: 'verification',
      details: {
        'extraction_id': extractionId,
        'original_values': redactedCorrections['original_values'] ?? '{}',
        'corrected_values': redactedCorrections['corrected_values'] ?? '{}',
        'verification_timestamp': DateTime.now().toIso8601String(),
      },
      sensitivity: 'info',
    );
  }

  Map<String, String> _redactSensitiveData(Map<String, String> details) {
    final redacted = Map<String, String>.from(details);
    const sensitiveKeys = {
      'password',
      'token',
      'secret',
      'key',
      'auth_code',
      'pin',
      'biometric',
      'private key',
      'auth_result_raw'
    };

    for (final entryKey in redacted.keys) {
      if (sensitiveKeys.contains(entryKey.toLowerCase())) {
        redacted[entryKey] = '[REDACTED]';
        continue;
      }

      final value = redacted[entryKey] ?? '';
      redacted[entryKey] = SecureLogger.redact(value);
    }

    return redacted;
  }

  String _getAnchorHash(String? storedAnchor) {
    if (storedAnchor == null || storedAnchor.isEmpty) {
      return _genesisHash;
    }
    return storedAnchor;
  }
}
