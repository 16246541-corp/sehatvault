import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:intl/intl.dart';

import '../models/issue_report.dart';
import '../models/auth_audit_entry.dart';
import 'export_service.dart';
import 'encryption_service.dart';
import 'local_storage_service.dart';
import 'auth_audit_service.dart';
import '../utils/secure_logger.dart';

class IssueReportingService extends ExportService {
  final LocalStorageService _storageService = LocalStorageService();
  final AuthAuditService _authAuditService =
      AuthAuditService(LocalStorageService());
  final Connectivity _connectivity = Connectivity();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final Battery _battery = Battery();

  Future<IssueReport> previewReport({
    required String description,
    List<String>? logs,
    bool includeLogs = true,
    bool includeDeviceMetrics = true,
  }) async {
    return _buildReport(
      description: description,
      logs: logs,
      includeLogs: includeLogs,
      includeDeviceMetrics: includeDeviceMetrics,
      persist: false,
    );
  }

  Future<IssueReport> createReport({
    required String description,
    List<String>? logs,
    bool includeLogs = true,
    bool includeDeviceMetrics = true,
  }) async {
    final report = await _buildReport(
      description: description,
      logs: logs,
      includeLogs: includeLogs,
      includeDeviceMetrics: includeDeviceMetrics,
      persist: true,
    );

    await _authAuditService.logEvent(
      action: 'create_issue_report',
      success: true,
      failureReason: null,
    );

    return report;
  }

  Future<void> submitReport(IssueReport report) async {
    final connectivityResult = await _connectivity.checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      await _authAuditService.logEvent(
        action: 'queue_issue_report',
        success: true,
        failureReason: null,
      );
      return;
    }

    try {
      await Future.delayed(const Duration(seconds: 2));

      final submittedReport = IssueReport(
        id: report.id,
        timestamp: report.timestamp,
        description: report.description,
        deviceMetrics: report.deviceMetrics,
        logLines: report.logLines,
        originalHash: report.originalHash,
        redactedHash: report.redactedHash,
        status: 'submitted',
      );
      await _storageService.saveIssueReport(submittedReport);

      await _authAuditService.logEvent(
        action: 'submit_issue_report',
        success: true,
        failureReason: null,
      );
    } catch (e) {
      await _authAuditService.logEvent(
        action: 'submit_issue_report',
        success: false,
        failureReason: e.toString(),
      );
    }
  }

  Future<void> exportReport(
    BuildContext context,
    IssueReport report, {
    ExportFormat format = ExportFormat.pdf,
  }) async {
    final outputDir = await getTemporaryDirectory();
    String filePath;
    String subject;
    String text;

    if (format == ExportFormat.pdf) {
      final pdf = pw.Document();
      final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Text('Issue Report (Anonymized)',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 18)),
              ),
              pw.SizedBox(height: 10),
              pw.Text('Report ID: ${report.id}'),
              pw.Text('Timestamp: ${dateFormat.format(report.timestamp)}'),
              pw.Text('Status: ${report.status}'),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Text('Description:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(report.description),
              pw.SizedBox(height: 20),
              pw.Text('Device Metrics:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ...report.deviceMetrics.entries
                  .map((e) => pw.Text('${e.key}: ${e.value}')),
              pw.SizedBox(height: 20),
              if (report.logLines.isNotEmpty) ...[
                pw.Text('Logs:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ...report.logLines.map(
                    (l) => pw.Text(l, style: const pw.TextStyle(fontSize: 10))),
              ],
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.Text('Verification:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text('Original Hash: ${report.originalHash}',
                  style: const pw.TextStyle(fontSize: 8)),
              pw.Text('Redacted Hash: ${report.redactedHash}',
                  style: const pw.TextStyle(fontSize: 8)),
            ];
          },
        ),
      );

      filePath = '${outputDir.path}/issue_report_${report.id}.pdf';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());
      subject = 'Issue Report ${report.id}';
      text = 'Anonymized issue report attached.';
    } else {
      final data = {
        'id': report.id,
        'timestamp': report.timestamp.toIso8601String(),
        'status': report.status,
        'description': report.description,
        'deviceMetrics': report.deviceMetrics,
        'logLines': report.logLines,
        'originalHash': report.originalHash,
        'redactedHash': report.redactedHash,
      };

      final jsonStr = jsonEncode(data);
      final encrypted = EncryptionService().encryptData(utf8.encode(jsonStr));

      filePath = '${outputDir.path}/issue_report_${report.id}.json.enc';
      final file = File(filePath);
      await file.writeAsBytes(encrypted);
      subject = 'Encrypted Issue Report ${report.id}';
      text = 'Encrypted issue report attached.';
    }

    if (context.mounted) {
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: subject,
        text: text,
      );
    }

    await _authAuditService.logEvent(
      action: 'export_issue_report',
      success: true,
      failureReason: null,
    );
  }

  Future<IssueReport> _buildReport({
    required String description,
    List<String>? logs,
    required bool includeLogs,
    required bool includeDeviceMetrics,
    required bool persist,
  }) async {
    final String id = const Uuid().v4();
    final DateTime now = DateTime.now();

    final deviceMetrics = includeDeviceMetrics
        ? await _collectDeviceMetrics()
        : <String, dynamic>{};

    final String redactedDescription = SecureLogger.redact(description);
    final List<String> redactedLogs = includeLogs
        ? (logs ?? []).map((line) => SecureLogger.redact(line)).toList()
        : <String>[];

    final String originalHash =
        sha256.convert(utf8.encode(description)).toString();
    final String redactedHash =
        sha256.convert(utf8.encode(redactedDescription)).toString();

    final report = IssueReport(
      id: id,
      timestamp: now,
      description: redactedDescription,
      deviceMetrics: deviceMetrics,
      logLines: redactedLogs,
      originalHash: originalHash,
      redactedHash: redactedHash,
      status: 'pending',
    );

    if (persist) {
      await _storageService.saveIssueReport(report);
    }

    return report;
  }

  Future<Map<String, dynamic>> _collectDeviceMetrics() async {
    final Map<String, dynamic> metrics = {};

    // Battery
    try {
      final level = await _battery.batteryLevel;
      metrics['batteryLevel'] = level;
      final state = await _battery.batteryState;
      metrics['batteryState'] = state.toString();
    } catch (e) {
      metrics['battery'] = 'Unknown';
    }

    // Device Info (Redacted)
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        metrics['os'] = 'Android ${androidInfo.version.release}';
        metrics['model'] =
            androidInfo.model; // Generally safe, but could be specific
        metrics['manufacturer'] = androidInfo.manufacturer;
        // Do NOT include androidId or specific identifiers
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        metrics['os'] = '${iosInfo.systemName} ${iosInfo.systemVersion}';
        metrics['model'] = iosInfo.model;
        metrics['utsname'] = iosInfo.utsname.machine;
        // Do NOT include identifierForVendor
      }
    } catch (e) {
      metrics['deviceInfo'] = 'Unavailable';
    }

    // Network
    try {
      final connectivity = await _connectivity.checkConnectivity();
      metrics['network'] = connectivity.toString();
    } catch (e) {
      metrics['network'] = 'Unknown';
    }

    return metrics;
  }
}
