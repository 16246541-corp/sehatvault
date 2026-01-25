import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../models/auth_audit_entry.dart';
import '../models/enhanced_privacy_settings.dart';
import '../services/auth_audit_service.dart';
import '../services/local_storage_service.dart';
import '../services/storage_usage_service.dart';

class PrivacyManifestData {
  final StorageUsage storageUsage;
  final List<AuthAuditEntry> recentAccessLogs;
  final EnhancedPrivacySettings privacySettings;
  final int privacyScore;
  final Map<String, dynamic> privacyMetrics;

  PrivacyManifestData({
    required this.storageUsage,
    required this.recentAccessLogs,
    required this.privacySettings,
    required this.privacyScore,
    required this.privacyMetrics,
  });
}

class PrivacyManifestService {
  final LocalStorageService _storageService;
  late final AuthAuditService _authAuditService;
  late final StorageUsageService _storageUsageService;

  PrivacyManifestService(this._storageService) {
    _authAuditService = AuthAuditService(_storageService);
    _storageUsageService = StorageUsageService(_storageService);
  }

  Future<PrivacyManifestData> generateManifest() async {
    final storageUsage = await _storageUsageService.calculateStorageUsage();
    final recentAccessLogs = _authAuditService.getRecentEvents();
    final settings = _storageService.getAppSettings();
    final privacySettings = settings.enhancedPrivacySettings;

    final privacyScore =
        _calculatePrivacyScore(privacySettings, recentAccessLogs);
    final metrics = _calculateMetrics(storageUsage, recentAccessLogs);

    return PrivacyManifestData(
      storageUsage: storageUsage,
      recentAccessLogs: recentAccessLogs,
      privacySettings: privacySettings,
      privacyScore: privacyScore,
      privacyMetrics: metrics,
    );
  }

  int _calculatePrivacyScore(
    EnhancedPrivacySettings settings,
    List<AuthAuditEntry> logs,
  ) {
    int score = 100;

    if (!settings.requireBiometricsForSensitiveData) score -= 20;
    if (!settings.requireBiometricsForExport) score -= 20;
    if (settings.tempFileRetentionMinutes > 0)
      score += 5; // Bonus for auto-cleanup

    // Deduct for recent failures (potential breach attempts)
    final recentFailures = logs.where((l) => !l.success).length;
    score -= (recentFailures * 5);

    return score.clamp(0, 100);
  }

  Map<String, dynamic> _calculateMetrics(
    StorageUsage usage,
    List<AuthAuditEntry> logs,
  ) {
    final totalAccesses = logs.length;
    final successfulAccesses = logs.where((l) => l.success).length;
    final failedAccesses = totalAccesses - successfulAccesses;

    return {
      'storage_encrypted_percentage':
          100, // All storage is encrypted in SehatLocker
      'total_access_events': totalAccesses,
      'successful_accesses': successfulAccesses,
      'failed_accesses': failedAccesses,
      'last_audit_date': logs.isNotEmpty ? logs.first.timestamp : null,
    };
  }

  Future<void> exportManifest(PrivacyManifestData data) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('SehatLocker Privacy Manifest',
                      style: pw.TextStyle(
                          fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Text(
                      DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text('Privacy Score: ${data.privacyScore}/100',
                style:
                    pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 20),
            pw.Header(level: 1, child: pw.Text('Storage Breakdown')),
            _buildStorageTable(data.storageUsage),
            pw.SizedBox(height: 20),
            pw.Header(level: 1, child: pw.Text('Privacy Configuration')),
            _buildSettingsTable(data.privacySettings),
            pw.SizedBox(height: 20),
            pw.Header(level: 1, child: pw.Text('Recent Access History')),
            _buildAccessLogTable(data.recentAccessLogs),
            pw.Footer(
              leading: pw.Text('SehatLocker - Private & Secure'),
              trailing: pw.Text('Page ${context.pageNumber}'),
            ),
          ];
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/privacy_manifest.pdf');
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles([XFile(file.path)],
        text: 'SehatLocker Privacy Manifest');
  }

  pw.Widget _buildStorageTable(StorageUsage usage) {
    return pw.TableHelper.fromTextArray(
      headers: ['Category', 'Size', 'Count'],
      data: [
        [
          'Conversations',
          _formatBytes(usage.conversationsBytes),
          usage.conversationCount.toString()
        ],
        [
          'Documents',
          _formatBytes(usage.documentsBytes),
          usage.documentCount.toString()
        ],
        ['Models', _formatBytes(usage.modelsBytes), '-'],
        ['Total App Usage', _formatBytes(usage.totalBytes), '-'],
      ],
    );
  }

  pw.Widget _buildSettingsTable(EnhancedPrivacySettings settings) {
    return pw.TableHelper.fromTextArray(
      headers: ['Setting', 'Enabled'],
      data: [
        [
          'Bio Auth for Sensitive Data',
          settings.requireBiometricsForSensitiveData ? 'Yes' : 'No'
        ],
        [
          'Bio Auth for Export',
          settings.requireBiometricsForExport ? 'Yes' : 'No'
        ],
        [
          'Bio Auth for Settings',
          settings.requireBiometricsForSettings ? 'Yes' : 'No'
        ],
        ['Temp File Retention', '${settings.tempFileRetentionMinutes} min'],
      ],
    );
  }

  pw.Widget _buildAccessLogTable(List<AuthAuditEntry> logs) {
    // Limit to last 20 for PDF
    final displayLogs = logs.take(20).toList();
    return pw.TableHelper.fromTextArray(
      headers: ['Time', 'Action', 'Status'],
      data: displayLogs.map((log) {
        return [
          DateFormat('MM-dd HH:mm').format(log.timestamp),
          log.action,
          log.success ? 'Success' : 'Failed',
        ];
      }).toList(),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
