import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import '../models/consent_entry.dart';
import 'local_storage_service.dart';

class ConsentService {
  final LocalStorageService _storageService = LocalStorageService();
  final Connectivity _connectivity = Connectivity();

  // Singleton
  static final ConsentService _instance = ConsentService._internal();
  factory ConsentService() => _instance;
  ConsentService._internal();

  /// Record a new consent
  Future<ConsentEntry> recordConsent({
    required String templateId,
    required String version,
    required String userId,
    required String scope,
    required bool granted,
    required String content, // The actual text agreed to
    String? deviceId,
    String? ipAddress,
  }) async {
    // Calculate hash
    final bytes = utf8.encode(content);
    final digest = sha256.convert(bytes);
    final contentHash = digest.toString();

    final connectivityResult = await _connectivity.checkConnectivity();
    final isOffline = connectivityResult.contains(ConnectivityResult.none);
    final now = DateTime.now();

    final entry = ConsentEntry.create(
      templateId: templateId,
      version: version,
      userId: userId,
      scope: scope,
      granted: granted,
      contentHash: contentHash,
      deviceId: deviceId,
      ipAddress: ipAddress,
      syncStatus: isOffline ? 'pending' : 'synced',
      syncedAt: isOffline ? null : now,
      lastSyncAttempt: now,
    );

    await _storageService.saveConsentEntry(entry);
    return entry;
  }

  /// Get the latest consent entry for a scope
  ConsentEntry? getLatestConsent(String scope) {
    final entries = _storageService.getAllConsentEntries();
    final scopeEntries = entries.where((e) => e.scope == scope).toList();

    if (scopeEntries.isEmpty) return null;

    // Sort by timestamp descending
    scopeEntries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return scopeEntries.first;
  }

  /// Check if there is a valid consent for a scope
  bool hasValidConsent(String scope) {
    final latest = getLatestConsent(scope);
    return isValidConsentEntry(latest);
  }

  /// Revoke consent for a scope
  Future<void> revokeConsent(String scope, String reason) async {
    final latest = getLatestConsent(scope);
    if (latest != null && latest.granted && latest.revocationDate == null) {
      final revokedEntry = latest.revoke(reason);
      await _storageService.saveConsentEntry(revokedEntry);
    }
  }

  /// Load template content
  Future<String> loadTemplate(String templateId, String version) async {
    try {
      return await rootBundle.loadString(
          'assets/data/consent_templates/${templateId}_$version.md');
    } catch (e) {
      // Fallback or error
      return "Consent template not found.";
    }
  }

  /// Get history for a scope
  List<ConsentEntry> getConsentHistory(String scope) {
    final entries = _storageService.getAllConsentEntries();
    final scopeEntries = entries.where((e) => e.scope == scope).toList();
    scopeEntries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return scopeEntries;
  }

  /// Get all history
  List<ConsentEntry> getAllHistory() {
    final entries = _storageService.getAllConsentEntries();
    entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return entries;
  }

  bool isValidConsentEntry(ConsentEntry? entry) {
    if (entry == null) return false;
    return entry.granted && entry.revocationDate == null;
  }

  List<ConsentEntry> getPendingSyncEntries() {
    final entries = _storageService.getAllConsentEntries();
    return entries.where((entry) => entry.syncStatus != 'synced').toList();
  }

  Future<void> markEntrySynced(ConsentEntry entry) async {
    final updated = entry.markSynced(DateTime.now());
    await _storageService.saveConsentEntry(updated);
  }
}
