import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../models/citation.dart';
import '../models/document_extraction.dart';
import '../models/doctor_conversation.dart';
import '../models/export_audit_entry.dart';
import '../models/follow_up_item.dart';
import '../models/model_option.dart';
import '../models/health_record.dart';
import '../models/recording_audit_entry.dart';
import '../models/consent_entry.dart';
import '../services/biometric_service.dart';
import '../services/citation_service.dart';
import '../services/encryption_service.dart';
import '../services/local_storage_service.dart';
import '../services/pdf_export_service.dart';
import '../services/safety_filter_service.dart';
import '../services/ai_service.dart';
import '../widgets/dialogs/auth_prompt_dialog.dart';

import '../services/compliance_service.dart';
import '../services/local_audit_service.dart';
import '../services/session_manager.dart';

enum ExportFormat { pdf, plainText, encryptedJson }

class ExportOptions {
  final ExportFormat format;
  final bool includeSpeakerLabels;
  final bool includeFollowUps;
  final bool includeConfidenceScores;
  final bool isExternalRecipient;

  const ExportOptions({
    required this.format,
    this.includeSpeakerLabels = true,
    this.includeFollowUps = true,
    this.includeConfidenceScores = false,
    this.isExternalRecipient = false,
  });
}

class ExportService {
  final LocalStorageService _storageService = LocalStorageService();
  final BiometricService _biometricService = BiometricService();
  final EncryptionService _encryptionService = EncryptionService();
  final CitationService _citationService =
      CitationService(LocalStorageService());

  Future<bool> _authenticateExport(
    BuildContext context,
    String reason,
  ) async {
    final settings = _storageService.getAppSettings();
    if (!settings.enhancedPrivacySettings.requireBiometricsForExport) {
      return true;
    }

    // Show Custom Auth Prompt Dialog
    bool userConsented = false;
    await AuthPromptDialog.show(
      context: context,
      reason: reason,
      onAuthenticate: () {
        userConsented = true;
        Navigator.of(context).pop();
      },
      onCancel: () {
        userConsented = false;
        Navigator.of(context).pop();
      },
    );

    if (!userConsented) {
      return false;
    }

    try {
      final authenticated = await _biometricService.authenticate(
        reason: reason,
        sessionId: _biometricService.sessionId,
      );
      if (!authenticated && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Authentication failed. Export cancelled.')),
        );
      }
      return authenticated;
    } on BiometricAuthException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
      return false;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Authentication failed: $e')),
        );
      }
      return false;
    }
  }

  Future<void> exportFollowUpsReport(BuildContext context) async {
    final authenticated = await _authenticateExport(
      context,
      'Authenticate to export follow-up report',
    );
    if (!authenticated) return;

    // 1. Get Pending Items
    final box = Hive.box<FollowUpItem>('follow_up_items');
    final pendingItems = box.values.where((item) => !item.isCompleted).toList();

    if (pendingItems.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('No pending follow-up items to export.')),
        );
      }
      return;
    }

    // 2. Group by Category
    final Map<FollowUpCategory, List<FollowUpItem>> groupedItems = {};
    for (final item in pendingItems) {
      if (!groupedItems.containsKey(item.category)) {
        groupedItems[item.category] = [];
      }
      groupedItems[item.category]!.add(item);
    }

    // Sort categories
    final sortedCategories = groupedItems.keys.toList()
      ..sort((a, b) => a.index.compareTo(b.index));

    // 3. Generate PDF
    final pdf = pw.Document();

    final now = DateTime.now();
    final dateFormat = DateFormat('MMMM d, yyyy');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildHeader(now, dateFormat),
            pw.SizedBox(height: 20),
            ...sortedCategories.expand((category) {
              return [
                _buildCategoryHeader(category),
                ...groupedItems[category]!.map((item) => _buildItemRow(item)),
                pw.SizedBox(height: 10),
              ];
            }),
            _buildFooter(),
          ];
        },
      ),
    );

    // 4. Save and Share
    await _saveAndSharePdf(context, pdf, 'follow_up_report.pdf',
        'Sehat Locker Follow-Up Report', now, dateFormat);

    // Audit log
    await _logExport('follow_up_report', ExportFormat.pdf, false, 'summary');
  }

  Future<void> exportRecordingComplianceReport(BuildContext context) async {
    final authenticated = await _authenticateExport(
      context,
      'Authenticate to export recording compliance report',
    );
    if (!authenticated) return;

    final entries = _storageService.getAllRecordingAuditEntries();
    if (entries.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No recording history to export.')),
        );
      }
      return;
    }

    entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final pdf = pw.Document();
    final now = DateTime.now();
    final dateFormat = DateFormat('MMMM d, yyyy');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildComplianceHeader(now, dateFormat),
            pw.SizedBox(height: 12),
            ...entries.map((entry) => _buildAuditRow(entry)),
            _buildFooter(),
          ];
        },
      ),
    );

    await _saveAndSharePdf(context, pdf, 'recording_compliance_report.pdf',
        'Sehat Locker Recording Compliance Report', now, dateFormat);

    // Audit log
    await _logExport(
        'recording_compliance_report', ExportFormat.pdf, false, 'summary');
  }

  Future<void> exportConsentHistory(BuildContext context) async {
    final authenticated = await _authenticateExport(
      context,
      'Authenticate to export consent history',
    );
    if (!authenticated) return;

    final entries = _storageService.getAllConsentEntries();
    if (entries.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No consent history to export.')),
        );
      }
      return;
    }

    entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final pdf = pw.Document();
    final now = DateTime.now();
    final dateFormat = DateFormat('MMMM d, yyyy');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildConsentHeader(now, dateFormat),
            pw.SizedBox(height: 12),
            ...entries.map((entry) => _buildConsentRow(entry)),
            _buildFooter(),
          ];
        },
      ),
    );

    await _saveAndSharePdf(context, pdf, 'consent_history.pdf',
        'Sehat Locker Consent History', now, dateFormat);

    final jsonFile = await _getExportFile('consent_history.json.enc');
    final jsonEntries = entries
        .map((entry) => {
              'id': entry.id,
              'templateId': entry.templateId,
              'version': entry.version,
              'timestamp': entry.timestamp.toIso8601String(),
              'userId': entry.userId,
              'scope': entry.scope,
              'granted': entry.granted,
              'contentHash': entry.contentHash,
              'deviceId': entry.deviceId,
              'ipAddress': entry.ipAddress,
              'revocationDate': entry.revocationDate?.toIso8601String(),
              'revocationReason': entry.revocationReason,
              'syncStatus': entry.syncStatus,
              'syncedAt': entry.syncedAt?.toIso8601String(),
              'lastSyncAttempt': entry.lastSyncAttempt?.toIso8601String(),
            })
        .toList();

    final jsonStr = jsonEncode({
      'exportedAt': now.toIso8601String(),
      'entries': jsonEntries,
    });
    final encrypted = _encryptionService.encryptData(utf8.encode(jsonStr));
    await jsonFile.writeAsBytes(encrypted);

    if (context.mounted) {
      await Share.shareXFiles(
        [XFile(jsonFile.path)],
        subject: 'Encrypted Consent History',
        text: 'Encrypted consent history attached.',
      );
    }

    await _logExport('consent_history', ExportFormat.pdf, false, 'summary');
    await _logExport(
        'consent_history', ExportFormat.encryptedJson, false, 'summary');
  }

  /// Deprecated: Use exportTranscriptEnhanced instead
  Future<void> exportTranscript(
      BuildContext context, DoctorConversation conversation) async {
    await exportTranscriptEnhanced(
        context, conversation, const ExportOptions(format: ExportFormat.pdf));
  }

  Future<void> exportTranscriptEnhanced(
    BuildContext context,
    DoctorConversation conversation,
    ExportOptions options,
  ) async {
    // 1. Biometric Auth
    bool authenticated = false;
    final settings = _storageService.getAppSettings();

    if (!settings.enhancedPrivacySettings.requireBiometricsForExport) {
      authenticated = true;
    } else {
      try {
        authenticated = await _biometricService.authenticate(
          reason: 'Authenticate to export transcript',
          sessionId: _biometricService.sessionId,
        );
      } on BiometricAuthException catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message)),
          );
        }
        return;
      }
    }

    if (!authenticated) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Authentication failed. Export cancelled.')),
        );
      }
      return;
    }

    try {
      final now = DateTime.now();
      final dateFormat = DateFormat('MMMM d, yyyy');

      // Process conversation content through AI pipeline before export
      final processedConversation =
          await _processConversationForExport(conversation);

      final file = await _getExportFile(
          'transcript_${processedConversation.id}${options.format == ExportFormat.encryptedJson ? ".json.enc" : options.format == ExportFormat.pdf ? ".pdf" : ".txt"}');
      String filePath = file.path;
      String subject;
      String text;

      if (options.format == ExportFormat.pdf) {
        final pdf = pw.Document();
        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(32),
            pageTheme: pw.PageTheme(
              pageFormat: PdfPageFormat.a4,
              buildBackground: (context) => _buildWatermark(context),
            ),
            build: (pw.Context context) {
              return [
                _buildTranscriptHeader(processedConversation, now, dateFormat),
                pw.SizedBox(height: 20),
                _buildTranscriptContent(processedConversation, options),
                if (options.includeFollowUps &&
                    processedConversation.followUpItems.isNotEmpty) ...[
                  pw.SizedBox(height: 20),
                  pw.Divider(),
                  pw.Text('Follow-Up Items',
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 14)),
                  pw.SizedBox(height: 10),
                  ...processedConversation.followUpItems.map(
                      (item) => pw.Bullet(text: _redactSensitiveData(item))),
                ],
                pw.SizedBox(height: 20),
                _buildFooter(),
              ];
            },
          ),
        );

        await file.writeAsBytes(await pdf.save());
        subject = 'Sehat Locker Transcript - ${processedConversation.title}';
        text = 'Transcript export attached.';
      } else if (options.format == ExportFormat.plainText) {
        final sb = StringBuffer();
        sb.writeln('TRANSCRIPT: ${processedConversation.title}');
        sb.writeln('Doctor: ${processedConversation.doctorName}');
        sb.writeln(
            'Date: ${dateFormat.format(processedConversation.createdAt)}');
        sb.writeln();

        if (processedConversation.segments != null &&
            processedConversation.segments!.isNotEmpty) {
          for (final segment in processedConversation.segments!) {
            final redactedText = _redactSensitiveData(segment.text);
            if (options.includeSpeakerLabels) {
              sb.writeln('${segment.speaker}: $redactedText');
            } else {
              sb.writeln(redactedText);
            }
          }
        } else {
          sb.writeln(_redactSensitiveData(processedConversation.transcript));
        }

        if (options.includeFollowUps &&
            processedConversation.followUpItems.isNotEmpty) {
          sb.writeln();
          sb.writeln('FOLLOW-UP ITEMS:');
          for (final item in processedConversation.followUpItems) {
            sb.writeln('- ${_redactSensitiveData(item)}');
          }
        }

        await file.writeAsString(sb.toString());
        subject = 'Transcript Export';
        text = 'Transcript text attached.';
      } else {
        // Encrypted JSON
        final segmentsData = processedConversation.segments
                ?.map((s) => {
                      'speaker': s.speaker,
                      'text': _redactSensitiveData(s.text),
                      'startTimeMs': s.startTimeMs,
                      'endTimeMs': s.endTimeMs,
                    })
                .toList() ??
            [];

        final data = {
          'id': processedConversation.id,
          'title': processedConversation.title,
          'doctorName': processedConversation.doctorName,
          'createdAt': processedConversation.createdAt.toIso8601String(),
          'transcript': _redactSensitiveData(processedConversation.transcript),
          'segments': segmentsData,
          'followUpItems': processedConversation.followUpItems
              .map((i) => _redactSensitiveData(i))
              .toList(),
        };

        final jsonStr = jsonEncode(data);
        final encrypted = _encryptionService.encryptData(utf8.encode(jsonStr));

        await file.writeAsBytes(encrypted);
        subject = 'Encrypted Transcript Data';
        text = 'Encrypted transcript data attached.';
      }

      // Share
      if (context.mounted) {
        final result = await Share.shareXFiles(
          [XFile(filePath)],
          subject: subject,
          text: text,
        );

        if (result.status == ShareResultStatus.dismissed) {
          // Fallback to clipboard if needed, or just notify.
          // Usually dismissed means user cancelled.
          // Requirement says "copy-to-clipboard fallback".
          // We can check if sharing is unavailable?
          // Actually, share_plus returns result.
          // If format is text, we can offer to copy.
          // But let's assume if they dismiss, they might want to copy?
          // Or maybe we add a "Copy" option in the UI instead of fallback here.
          // "Integrate share_plus with copy-to-clipboard fallback" usually means if sharing fails or isn't supported.
          // I'll stick to Share. If it fails (exception), I'll try to copy text.
        }
      }

      // Audit Log
      await _logExport('transcript', options.format,
          options.isExternalRecipient, conversation.id);
    } catch (e) {
      debugPrint('Export failed: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
      // Fallback for Plain Text: Copy to Clipboard
      if (options.format == ExportFormat.plainText && context.mounted) {
        try {
          // Re-generate text to copy (simplified)
          final text = _redactSensitiveData(conversation.transcript);
          await Clipboard.setData(ClipboardData(text: text));
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content:
                      Text('Sharing failed. Copied to clipboard instead.')),
            );
          }
        } catch (_) {}
      }
    }
  }

  Future<void> exportDocumentExtraction(
    BuildContext context,
    DocumentExtraction extraction, {
    HealthRecord? record,
    ExportFormat format = ExportFormat.pdf,
    bool isExternalRecipient = false,
  }) async {
    final authenticated = await _authenticateExport(
      context,
      'Authenticate to export document',
    );
    if (!authenticated) return;

    try {
      final file = await _getExportFile(
          'document_${extraction.id}${format == ExportFormat.encryptedJson ? ".json.enc" : format == ExportFormat.pdf ? ".pdf" : ".txt"}');
      String filePath = file.path;
      String subject;
      String text;

      if (format == ExportFormat.pdf) {
        final pdfPath = await PdfExportService().generatePdf(
          extraction: extraction,
          record: record,
          outputPath: filePath,
        );
        filePath = pdfPath;
        subject = 'Sehat Locker Document Export';
        text = 'Document export attached.';
      } else if (format == ExportFormat.plainText) {
        final sb = StringBuffer();
        sb.writeln('DOCUMENT EXTRACTION');
        sb.writeln('Date: ${extraction.createdAt.toIso8601String()}');
        if (record != null) {
          sb.writeln('Title: ${record.title}');
          sb.writeln('Category: ${record.category}');
          if (record.notes != null && record.notes!.isNotEmpty) {
            sb.writeln('Notes: ${record.notes}');
          }
        }
        sb.writeln();
        sb.writeln('EXTRACTED DATA:');
        if (extraction.structuredData.isNotEmpty) {
          extraction.structuredData.forEach((key, value) {
            sb.writeln('- $key: $value');
          });
        } else {
          sb.writeln('- None');
        }
        sb.writeln();
        sb.writeln('ORIGINAL TEXT:');
        sb.writeln(extraction.extractedText);

        if (extraction.citations != null && extraction.citations!.isNotEmpty) {
          final references = _citationService.formatCitations(
            extraction.citations!,
            style: 'reference',
          );
          if (references.isNotEmpty) {
            sb.writeln();
            sb.writeln('REFERENCES:');
            sb.writeln(references);
          }
        }

        await File(filePath).writeAsString(sb.toString());
        subject = 'Document Extraction Export';
        text = 'Document extraction text attached.';
      } else {
        final citations = extraction.citations
                ?.where((c) => c.confidenceScore >= 0.85)
                .map((c) => {
                      'id': c.id,
                      'sourceTitle': c.sourceTitle,
                      'sourceUrl': c.sourceUrl,
                      'sourceDate': c.sourceDate?.toIso8601String(),
                      'textSnippet': c.textSnippet,
                      'confidenceScore': c.confidenceScore,
                      'type': c.type,
                      'relatedField': c.relatedField,
                      'authors': c.authors,
                      'publication': c.publication,
                    })
                .toList() ??
            [];

        final data = {
          'id': extraction.id,
          'createdAt': extraction.createdAt.toIso8601String(),
          'originalImagePath': extraction.originalImagePath,
          'extractedText': extraction.extractedText,
          'confidenceScore': extraction.confidenceScore,
          'structuredData': extraction.structuredData,
          'citations': citations,
          'record': record != null
              ? {
                  'id': record.id,
                  'title': record.title,
                  'category': record.category,
                  'createdAt': record.createdAt.toIso8601String(),
                  'notes': record.notes,
                }
              : null,
        };

        final jsonStr = jsonEncode(data);
        final encrypted = _encryptionService.encryptData(utf8.encode(jsonStr));

        await File(filePath).writeAsBytes(encrypted);
        subject = 'Encrypted Document Extraction Data';
        text = 'Encrypted document extraction data attached.';
      }

      if (context.mounted) {
        await Share.shareXFiles(
          [XFile(filePath)],
          subject: subject,
          text: text,
        );
      }

      await _logExport(
        'document_extraction',
        format,
        isExternalRecipient,
        extraction.id,
      );
    } catch (e) {
      debugPrint('Export failed: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<DoctorConversation> _processConversationForExport(
      DoctorConversation conversation) async {
    final aiService = AIService();

    // We create a "processed" copy of the conversation for export
    // Note: We don't save this to DB, it's just for the export file

    String processedTranscript =
        await aiService.processContent(conversation.transcript);

    List<ConversationSegment>? processedSegments;
    if (conversation.segments != null) {
      processedSegments = [];
      for (final segment in conversation.segments!) {
        final processedText = await aiService.processContent(segment.text);
        processedSegments.add(ConversationSegment(
          text: processedText,
          startTimeMs: segment.startTimeMs,
          endTimeMs: segment.endTimeMs,
          speaker: segment.speaker,
          speakerConfidence: segment.speakerConfidence,
        ));
      }
    }

    return DoctorConversation(
      id: conversation.id,
      title: conversation.title,
      duration: conversation.duration,
      encryptedAudioPath: conversation.encryptedAudioPath,
      transcript: processedTranscript,
      createdAt: conversation.createdAt,
      followUpItems: conversation.followUpItems,
      doctorName: conversation.doctorName,
      segments: processedSegments,
      originalTranscript: conversation.originalTranscript,
      editedAt: conversation.editedAt,
      complianceVersion: conversation.complianceVersion,
      complianceReviewDate: conversation.complianceReviewDate,
    );
  }

  pw.Widget _buildTranscriptContent(
      DoctorConversation conversation, ExportOptions options) {
    final List<Citation> citations =
        _citationService.generateCitationsFromText(conversation.transcript);

    pw.Widget content;
    if (conversation.segments != null && conversation.segments!.isNotEmpty) {
      content = pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: conversation.segments!.map((segment) {
          final text = _redactSensitiveData(segment.text);
          final sanitizedText = SafetyFilterService().sanitize(text);
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.RichText(
              text: pw.TextSpan(
                children: [
                  if (options.includeSpeakerLabels)
                    pw.TextSpan(
                      text: '${segment.speaker}: ',
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                          color: PdfColors.grey700),
                    ),
                  pw.TextSpan(
                    text: sanitizedText,
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      );
    } else {
      final text = _redactSensitiveData(conversation.transcript);
      final sanitizedText = SafetyFilterService().sanitize(text);
      content = pw.Text(
        sanitizedText,
        style: const pw.TextStyle(fontSize: 12),
      );
    }

    if (citations.isEmpty) return content;

    final references = _citationService.formatCitations(
      citations,
      style: 'reference',
    );

    if (references.isEmpty) return content;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        content,
        pw.SizedBox(height: 20),
        pw.Divider(),
        pw.SizedBox(height: 10),
        pw.Text(
          'Medical References',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          references,
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
      ],
    );
  }

  String _redactSensitiveData(String text) {
    // Redact Phone Numbers
    final phoneRegex = RegExp(r'\b\d{3}[-.]?\d{3}[-.]?\d{4}\b');
    var redacted =
        text.replaceAllMapped(phoneRegex, (match) => '[REDACTED PHONE]');

    // Redact Email
    final emailRegex = RegExp(r'\b[\w\.-]+@[\w\.-]+\.\w{2,4}\b');
    redacted =
        redacted.replaceAllMapped(emailRegex, (match) => '[REDACTED EMAIL]');

    // Address Redaction (Very basic - looking for common street types followed by numbers or vice versa)
    // Real address redaction requires NLP. This is a best-effort regex.
    final addressRegex = RegExp(
        r'\d+\s+[A-Za-z]+\s+(St|Street|Ave|Avenue|Rd|Road|Blvd|Boulevard|Ln|Lane|Dr|Drive)\b',
        caseSensitive: false);
    redacted = redacted.replaceAllMapped(
        addressRegex, (match) => '[REDACTED ADDRESS]');

    return redacted;
  }

  Future<void> exportAuditLogReport(BuildContext context) async {
    final authenticated = await _authenticateExport(
      context,
      'Authenticate to export local audit log report',
    );
    if (!authenticated) return;

    final localAuditService =
        LocalAuditService(_storageService, SessionManager());
    final entries = localAuditService.getEntries();

    if (entries.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No audit entries to export.')),
        );
      }
      return;
    }

    // Verify integrity before export
    final integrityResult = await localAuditService.verifyIntegrity();
    if (!integrityResult.isValid) {
      if (context.mounted) {
        final proceed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Integrity Warning'),
                content: Text(
                    'Audit log integrity check failed at index ${integrityResult.failingIndex}. '
                    'The log may have been tampered with. Export anyway?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Export Anyway'),
                  ),
                ],
              ),
            ) ??
            false;
        if (!proceed) return;
      }
    }

    final pdf = pw.Document();
    final now = DateTime.now();
    final dateFormat = DateFormat('MMMM d, yyyy HH:mm:ss');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildAuditLogHeader(now, dateFormat, integrityResult.isValid),
            pw.SizedBox(height: 12),
            ...entries.map((entry) => _buildLocalAuditRow(entry, dateFormat)),
            _buildFooter(),
          ];
        },
      ),
    );

    await _saveAndSharePdf(context, pdf, 'local_audit_log_report.pdf',
        'Sehat Locker Local Audit Log Report', now, dateFormat);

    // Also export as encrypted JSON for machine verification
    final jsonFile = await _getExportFile('local_audit_log.json.enc');
    final jsonEntries = entries
        .map((entry) => {
              'id': entry.id,
              'timestamp': entry.timestamp.toIso8601String(),
              'action': entry.action,
              'details': entry.details,
              'sensitivity': entry.sensitivity,
              'sessionId': entry.sessionId,
              'previousHash': entry.previousHash,
              'hash': entry.hash,
            })
        .toList();

    final jsonStr = jsonEncode({
      'exportedAt': now.toIso8601String(),
      'integrityValid': integrityResult.isValid,
      'failingIndex': integrityResult.failingIndex,
      'entries': jsonEntries,
    });

    final encrypted = _encryptionService.encryptData(utf8.encode(jsonStr));
    await jsonFile.writeAsBytes(encrypted);

    if (context.mounted) {
      await Share.shareXFiles(
        [XFile(jsonFile.path)],
        subject: 'Encrypted Local Audit Log',
        text: 'Encrypted local audit log attached for verification.',
      );
    }

    // Audit log the export itself
    await _logExport(
        'local_audit_log_report', ExportFormat.pdf, false, 'summary');
    await _logExport(
        'local_audit_log_report', ExportFormat.encryptedJson, false, 'summary');
  }

  pw.Widget _buildAuditLogHeader(
      DateTime date, DateFormat fmt, bool integrityValid) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildEmergencyWarning(),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Sehat Locker',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey800,
              ),
            ),
            pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: pw.BoxDecoration(
                color: integrityValid ? PdfColors.green100 : PdfColors.red100,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Text(
                integrityValid ? 'INTEGRITY VERIFIED' : 'INTEGRITY FAILED',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: integrityValid ? PdfColors.green900 : PdfColors.red900,
                ),
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'Local Audit Log Report',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.Text(
          'Generated on: ${fmt.format(date)}',
          style: const pw.TextStyle(
            fontSize: 12,
            color: PdfColors.grey700,
          ),
        ),
        pw.Divider(thickness: 1, color: PdfColors.grey400),
      ],
    );
  }

  pw.Widget _buildLocalAuditRow(dynamic entry, DateFormat fmt) {
    // Note: using dynamic because LocalAuditEntry is not imported directly as a type but via LocalAuditService
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.all(8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                fmt.format(entry.timestamp),
                style:
                    const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
              ),
              pw.Text(
                entry.sensitivity.toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: entry.sensitivity == 'critical'
                      ? PdfColors.red700
                      : (entry.sensitivity == 'warning'
                          ? PdfColors.orange700
                          : PdfColors.blue700),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            entry.action.replaceAll('_', ' ').toUpperCase(),
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            'Details: ${jsonEncode(entry.details)}',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            'Hash: ${entry.hash.substring(0, 16)}...',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
          ),
        ],
      ),
    );
  }

  Future<void> _logExport(
      String type, ExportFormat format, bool external, String entityId) async {
    try {
      final entry = ExportAuditEntry(
        timestamp: DateTime.now(),
        exportType: type,
        format: format.name,
        recipientType: external ? 'external' : 'self',
        entityId: entityId,
      );
      await _storageService.saveExportAuditEntry(entry);

      final localAuditService =
          LocalAuditService(_storageService, SessionManager());
      await localAuditService.log(
        action: 'export_data',
        details: {
          'exportType': type,
          'format': format.name,
          'recipientType': external ? 'external' : 'self',
          'entityId': entityId,
        },
        sensitivity: 'warning',
      );
    } catch (e) {
      debugPrint('Failed to log export audit: $e');
    }
  }

  pw.Widget _buildWatermark(pw.Context context) {
    return pw.Center(
      child: pw.Transform.rotate(
        angle: -0.5,
        child: pw.Opacity(
          opacity: 0.1,
          child: pw.Text(
            'PRIVATE - DO NOT DISTRIBUTE',
            style: pw.TextStyle(
              fontSize: 40,
              color: PdfColors.grey900,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Future<File> _getExportFile(String fileName) async {
    final settings = _storageService.getAppSettings();
    if (settings.lastExportDirectory != null &&
        Directory(settings.lastExportDirectory!).existsSync()) {
      return File(
          '${settings.lastExportDirectory}${Platform.pathSeparator}$fileName');
    }
    final tempDir = await getTemporaryDirectory();
    return File('${tempDir.path}${Platform.pathSeparator}$fileName');
  }

  Future<void> _saveAndSharePdf(BuildContext context, pw.Document pdf,
      String filename, String subject, DateTime now, DateFormat fmt) async {
    try {
      final file = await _getExportFile(filename);
      await file.writeAsBytes(await pdf.save());

      if (context.mounted) {
        final settings = _storageService.getAppSettings();
        bool isSavedToCustomDir = settings.lastExportDirectory != null &&
            Directory(settings.lastExportDirectory!).existsSync() &&
            file.path.startsWith(settings.lastExportDirectory!);

        if (isSavedToCustomDir) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Saved to: ${file.path}')),
          );
        }

        await Share.shareXFiles(
          [XFile(file.path)],
          subject: subject,
          text: 'Here is your report generated on ${fmt.format(now)}.',
        );
      }
    } catch (e) {
      debugPrint('Error generating/sharing PDF: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting report: $e')),
        );
      }
    }
  }

  pw.Widget _buildEmergencyWarning() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      margin: const pw.EdgeInsets.only(bottom: 8),
      decoration: const pw.BoxDecoration(
        color: PdfColors.amber100,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Text(
        _emergencyWarningText(),
        style: pw.TextStyle(
          color: PdfColors.amber900,
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  String _emergencyWarningText() => Intl.message(
        'NOT FOR MEDICAL EMERGENCIES - DO NOT RELY FOR CRITICAL HEALTH DECISIONS',
        name: 'exportEmergencyWarningText',
      );

  pw.Widget _buildHeader(DateTime date, DateFormat fmt) {
    final settings = _storageService.getAppSettings();
    ModelOption? model;
    try {
      model = ModelOption.availableModels.firstWhere(
        (m) => m.id == settings.selectedModelId,
      );
    } catch (_) {}

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildEmergencyWarning(),
        pw.Text(
          'Sehat Locker',
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blueGrey800,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'Pending Follow-Up Items Report',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.Text(
          'Generated on: ${fmt.format(date)}',
          style: const pw.TextStyle(
            fontSize: 12,
            color: PdfColors.grey700,
          ),
        ),
        if (model != null && model.knowledgeCutoffDate != null) ...[
          pw.SizedBox(height: 4),
          pw.Text(
            'Current AI Analysis Model: ${model.name} (Knowledge Cutoff: ${fmt.format(model.knowledgeCutoffDate!)})',
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.orange800,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
        pw.Divider(thickness: 1, color: PdfColors.grey400),
      ],
    );
  }

  pw.Widget _buildTranscriptHeader(
      DoctorConversation conversation, DateTime date, DateFormat fmt) {
    ModelOption? model;
    if (conversation.modelId != null) {
      try {
        model = ModelOption.availableModels.firstWhere(
          (m) => m.id == conversation.modelId,
        );
      } catch (_) {}
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildEmergencyWarning(),
        pw.Text(
          'Sehat Locker',
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blueGrey800,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          conversation.title,
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.Text(
          'Doctor: ${conversation.doctorName}',
          style: const pw.TextStyle(fontSize: 14),
        ),
        pw.Text(
          'Date: ${fmt.format(conversation.createdAt)}',
          style: const pw.TextStyle(fontSize: 14),
        ),
        if (model != null && model.knowledgeCutoffDate != null) ...[
          pw.SizedBox(height: 4),
          pw.Text(
            'AI Model: ${model.name} (Knowledge Cutoff: ${fmt.format(model.knowledgeCutoffDate!)})',
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.orange800,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
        pw.SizedBox(height: 4),
        pw.Text(
          'Generated on: ${fmt.format(date)}',
          style: const pw.TextStyle(
            fontSize: 12,
            color: PdfColors.grey700,
          ),
        ),
        pw.Divider(thickness: 1, color: PdfColors.grey400),
      ],
    );
  }

  pw.Widget _buildCategoryHeader(FollowUpCategory category) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 10, bottom: 5),
      child: pw.Row(
        children: [
          pw.Text(
            category.toDisplayString(),
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue700,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildItemRow(FollowUpItem item) {
    final conversation =
        _storageService.getDoctorConversation(item.sourceConversationId);
    final conversationTitle = conversation?.title ?? 'Unknown Conversation';

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Text(
                  item.structuredTitle,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              if (item.dueDate != null)
                pw.Text(
                  'Due: ${DateFormat('MMM d').format(item.dueDate!)}',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.red700,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            item.description,
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Source: $conversationTitle',
            style: pw.TextStyle(
              fontSize: 9,
              color: PdfColors.grey600,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.Divider(thickness: 1, color: PdfColors.grey400),
        pw.SizedBox(height: 8),
        pw.Text(
          'FDA DISCLAIMER: This content is for informational purposes only and does not constitute medical advice. Please consult a qualified healthcare provider for diagnosis and treatment.',
          style: pw.TextStyle(
            fontSize: 8,
            color: PdfColors.grey600,
            fontStyle: pw.FontStyle.italic,
          ),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Text(
              'Generated by Sehat Locker',
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> exportComplianceChecklist(
      BuildContext context, ComplianceReport report) async {
    if (!await _authenticateExport(context, 'Export Compliance Report')) {
      return;
    }

    final pdf = pw.Document();
    final font = await PdfGoogleFonts.robotoRegular();
    final bold = await PdfGoogleFonts.robotoBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          _buildComplianceHeader(report.timestamp, DateFormat.yMMMMEEEEd()),
          pw.SizedBox(height: 20),
          pw.Text('Compliance Score: ${report.score}/100',
              style: pw.TextStyle(font: bold, fontSize: 18)),
          pw.SizedBox(height: 10),
          pw.Text('Report Signature: ${report.signature}',
              style: pw.TextStyle(
                  font: font, fontSize: 10, color: PdfColors.grey700)),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            headers: ['Check', 'Status', 'Details'],
            data: report.results
                .map((r) => [r.name, r.passed ? 'PASS' : 'FAIL', r.details])
                .toList(),
            headerStyle: pw.TextStyle(font: bold),
            cellStyle: pw.TextStyle(font: font),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(1),
              2: const pw.FlexColumnWidth(4),
            },
          ),
          pw.SizedBox(height: 20),
          _buildFooter(),
        ],
      ),
    );

    await _saveAndSharePdf(
        context,
        pdf,
        'compliance_report_${report.timestamp.millisecondsSinceEpoch}.pdf',
        'Sehat Locker Compliance Report',
        report.timestamp,
        DateFormat.yMMMMEEEEd());
  }

  pw.Widget _buildComplianceHeader(DateTime date, DateFormat fmt) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Sehat Locker',
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blueGrey800,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'Recording Compliance Report',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.Text(
          'Generated on: ${fmt.format(date)}',
          style: const pw.TextStyle(
            fontSize: 12,
            color: PdfColors.grey700,
          ),
        ),
        pw.Divider(thickness: 1, color: PdfColors.grey400),
      ],
    );
  }

  pw.Widget _buildConsentHeader(DateTime date, DateFormat fmt) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Sehat Locker',
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blueGrey800,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'Consent History Report',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.Text(
          'Generated on: ${fmt.format(date)}',
          style: const pw.TextStyle(
            fontSize: 12,
            color: PdfColors.grey700,
          ),
        ),
        pw.Divider(thickness: 1, color: PdfColors.grey400),
      ],
    );
  }

  pw.Widget _buildAuditRow(RecordingAuditEntry entry) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Date: ${DateFormat('yyyy-MM-dd HH:mm').format(entry.timestamp)}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Text('Device ID: ${entry.deviceId}'),
                pw.Text('Duration: ${entry.duration.inMinutes} mins'),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                entry.consentConfirmed ? 'CONSENTED' : 'NO CONSENT',
                style: pw.TextStyle(
                  color: entry.consentConfirmed
                      ? PdfColors.green700
                      : PdfColors.red700,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if (entry.doctorName == 'EMERGENCY DELETION')
                pw.Text(
                  'EMERGENCY DELETION',
                  style: pw.TextStyle(
                    color: PdfColors.red,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildConsentRow(ConsentEntry entry) {
    final status = entry.revocationDate != null
        ? 'REVOKED'
        : (entry.granted ? 'GRANTED' : 'DENIED');
    final statusColor = entry.granted && entry.revocationDate == null
        ? PdfColors.green700
        : PdfColors.red700;

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Date: ${DateFormat('yyyy-MM-dd HH:mm').format(entry.timestamp)}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Text('Scope: ${entry.scope}'),
                pw.Text('Template: ${entry.templateId} v${entry.version}'),
                if (entry.revocationDate != null)
                  pw.Text(
                    'Revoked: ${DateFormat('yyyy-MM-dd HH:mm').format(entry.revocationDate!)}',
                  ),
                if (entry.revocationReason != null)
                  pw.Text('Reason: ${entry.revocationReason}'),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                status,
                style: pw.TextStyle(
                  color: statusColor,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                entry.syncStatus.toUpperCase(),
                style: pw.TextStyle(
                  color: PdfColors.grey700,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
