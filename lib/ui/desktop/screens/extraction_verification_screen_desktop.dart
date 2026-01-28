import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/document_extraction.dart';
import '../../../models/health_record.dart';
import '../../../services/vault_service.dart';
import '../../../services/ocr_service.dart';
import '../../../services/image_service.dart';
import '../../../services/local_audit_service.dart';
import '../../../services/local_storage_service.dart';
import '../../../services/session_manager.dart';
import '../../../services/date_validation_service.dart';
import '../../../shared/widgets/verification/verified_extraction_card.dart';

class ExtractionVerificationScreenDesktop extends StatefulWidget {
  final DocumentExtraction extraction;
  final HealthCategory category;

  const ExtractionVerificationScreenDesktop({
    super.key,
    required this.extraction,
    required this.category,
  });

  @override
  State<ExtractionVerificationScreenDesktop> createState() =>
      _ExtractionVerificationScreenDesktopState();
}

class _ExtractionVerificationScreenDesktopState
    extends State<ExtractionVerificationScreenDesktop> {
  late DocumentExtraction _currentExtraction;
  bool _isSaving = false;
  bool _isRescanning = false;
  Map<String, dynamic>? _userCorrections;
  DateTime? _documentDate;
  final DateValidationService _dateValidationService = DateValidationService();
  bool _showDateWarning = false;
  String? _dateWarningMessage;

  @override
  void initState() {
    super.initState();
    _currentExtraction = widget.extraction;
    _documentDate = _resolveDocumentDate();
    _validateDocumentDate();
  }

  DateTime? _resolveDocumentDate() {
    // Priority: user corrected > extracted document date > from structured data
    if (_currentExtraction.userCorrectedDocumentDate != null) {
      return _currentExtraction.userCorrectedDocumentDate;
    }

    if (_currentExtraction.extractedDocumentDate != null) {
      return _currentExtraction.extractedDocumentDate;
    }

    // Fallback to legacy structured data extraction
    return _tryResolveExistingDate(_currentExtraction.structuredData);
  }

  void _validateDocumentDate() {
    if (_documentDate == null) return;

    final captureTime = _currentExtraction.createdAt;

    // Check chronological plausibility
    if (!_dateValidationService.isChronologicallyPlausible(
        _documentDate!, captureTime)) {
      setState(() {
        _showDateWarning = true;
        _dateWarningMessage =
            'This date seems unusual compared to when the document was captured';
      });
      return;
    }

    // Check valid date range
    if (!_dateValidationService.isValidDocumentDate(_documentDate!)) {
      setState(() {
        _showDateWarning = true;
        _dateWarningMessage =
            'Date must be after 1900 and not more than 1 year in the future';
      });
      return;
    }

    setState(() {
      _showDateWarning = false;
      _dateWarningMessage = null;
    });
  }

  DateTime? _tryResolveExistingDate(Map<String, dynamic> data) {
    final dates = data['dates'];
    if (dates is List && dates.isNotEmpty) {
      for (final d in dates) {
        final parsed = DateTime.tryParse(d.toString());
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  String _safePatientGender() {
    try {
      return LocalStorageService().getUserProfile().sex ?? 'unspecified';
    } catch (_) {
      return 'unspecified';
    }
  }

  bool get _canSave {
    if (_documentDate == null) return false;
    if (_showDateWarning) return false; // Block save if date validation fails

    final data = _userCorrections ?? _currentExtraction.structuredData;
    final labValues = data['lab_values'];
    final meds = data['medications'];
    final vitals = data['vitals'];

    bool hasAnyValue = false;

    if (labValues is List) {
      hasAnyValue = labValues.any((e) {
        if (e is! Map) return false;
        final v = e['value']?.toString().trim() ?? '';
        return v.isNotEmpty;
      });
    }
    if (!hasAnyValue && meds is List) {
      hasAnyValue = meds.any((e) {
        if (e is! Map) return false;
        final name = e['name']?.toString().trim() ?? '';
        final dosage = e['dosage']?.toString().trim() ?? '';
        return name.isNotEmpty || dosage.isNotEmpty;
      });
    }
    if (!hasAnyValue && vitals is List) {
      hasAnyValue = vitals.any((e) {
        if (e is! Map) return false;
        final v = e['value']?.toString().trim() ?? '';
        return v.isNotEmpty;
      });
    }

    return hasAnyValue;
  }

  Map<String, dynamic> _buildCorrectionsDelta({
    required Map<String, dynamic> original,
    required Map<String, dynamic> corrected,
  }) {
    final delta = <String, dynamic>{};
    for (final key in ['lab_values', 'medications', 'vitals', 'dates']) {
      final a = jsonEncode(original[key]);
      final b = jsonEncode(corrected[key]);
      if (a != b) delta[key] = corrected[key];
    }
    return delta;
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    try {
      final correctedData = Map<String, dynamic>.from(
        _userCorrections ?? _currentExtraction.structuredData,
      );
      correctedData['dates'] = [_documentDate!.toIso8601String()];

      final delta = _buildCorrectionsDelta(
        original: _currentExtraction.structuredData,
        corrected: correctedData,
      );

      // Check if document date was corrected
      final DateTime? originalDate = _currentExtraction.extractedDocumentDate ??
          _tryResolveExistingDate(_currentExtraction.structuredData);
      final bool dateWasCorrected = originalDate == null ||
          !_documentDate!.isAtSameMomentAs(originalDate);

      final verifiedExtraction = _currentExtraction.copyWith(
        userVerifiedAt: DateTime.now(),
        userCorrections: delta,
        structuredData: correctedData,
        userCorrectedDocumentDate: dateWasCorrected ? _documentDate : null,
      );

      final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final title = '${widget.category.displayName} - $dateStr';

      final vaultService = VaultService(LocalStorageService());
      await vaultService.saveProcessedDocument(
        extraction: verifiedExtraction,
        title: title,
        category: widget.category.displayName,
        onProgress: (status) {
          // Optional
        },
      );

      final auditService =
          LocalAuditService(LocalStorageService(), SessionManager());

      // Log document verification
      await auditService.log(
          action: 'document_verified',
          details: {
            'extractionId': verifiedExtraction.id,
            'category': widget.category.displayName,
            'correctionCount': delta.length.toString(),
          },
          sensitivity: 'info');

      // Log date correction if applicable
      if (dateWasCorrected && originalDate != null) {
        await auditService.log(
            action: 'document_date_corrected',
            details: {
              'extractionId': verifiedExtraction.id,
              'original': originalDate.toIso8601String(),
              'corrected': _documentDate!.toIso8601String(),
            },
            sensitivity: 'info');
      }

      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error saving: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleRescan() async {
    setState(() => _isRescanning = true);
    try {
      final file = File(_currentExtraction.originalImagePath);
      if (await file.exists()) {
        final compressedPath = await ImageService.compressImage(file);
        final newExtraction =
            await OCRService.processDocument(File(compressedPath));
        setState(() {
          _currentExtraction = newExtraction;
          _userCorrections = null;
          _documentDate = _resolveDocumentDate();
          _validateDocumentDate();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rescan failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isRescanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Extraction'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isRescanning ? null : _handleRescan,
            tooltip: 'Re-scan',
          ),
        ],
      ),
      body: _isSaving || _isRescanning
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                // Left Pane: Image Preview
                Expanded(
                  flex: 1,
                  child: Container(
                    color: Colors.black12,
                    child: Center(
                      child: Image.file(
                        File(_currentExtraction.originalImagePath),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                // Right Pane: Verification Form
                Expanded(
                  flex: 1,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Review Extracted Data',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Verify the data against the original document.',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Colors.grey),
                        ),
                        const SizedBox(height: 24),

                        // Document Date Section
                        Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 24),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 24),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Document Date',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Spacer(),
                                    if (_currentExtraction
                                            .extractedDocumentDate !=
                                        null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade100,
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        child: Text(
                                          'Auto-extracted',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.blue.shade800,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Date display and controls
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _documentDate == null
                                                ? 'No date selected'
                                                : _dateValidationService
                                                    .formatDateForDisplay(
                                                        _documentDate),
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              color: _documentDate == null
                                                  ? Colors.grey
                                                  : Colors.black,
                                            ),
                                          ),
                                          if (_documentDate != null)
                                            Text(
                                              DateFormat('EEEE, MMMM d, y')
                                                  .format(_documentDate!),
                                              style: TextStyle(
                                                  color: Colors.grey.shade600),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        setState(() {
                                          _documentDate = DateTime.now();
                                          _validateDocumentDate();
                                        });
                                      },
                                      icon: const Icon(Icons.today, size: 16),
                                      label: const Text('Use Today'),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.calendar_today),
                                      onPressed: () async {
                                        final now = DateTime.now();
                                        final picked = await showDatePicker(
                                          context: context,
                                          initialDate: _documentDate ?? now,
                                          firstDate: DateTime(1900),
                                          lastDate: now
                                              .add(const Duration(days: 365)),
                                        );
                                        if (picked == null) return;
                                        setState(() {
                                          _documentDate = picked;
                                          _validateDocumentDate();
                                        });
                                      },
                                    ),
                                  ],
                                ),

                                // Warning banner
                                if (_showDateWarning &&
                                    _dateWarningMessage != null)
                                  Container(
                                    margin: const EdgeInsets.only(top: 16),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: Colors.orange.shade200),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.warning_amber,
                                            color: Colors.orange.shade700,
                                            size: 20),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            _dateWarningMessage!,
                                            style: TextStyle(
                                                color: Colors.orange.shade800,
                                                fontSize: 14),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),

                        // Verification card
                        VerifiedExtractionCard(
                          extraction: _currentExtraction,
                          onDataChanged: (data) {
                            setState(() => _userCorrections = data);
                          },
                          isDesktop: true,
                          patientGender: _safePatientGender(),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 16),
                            FilledButton.icon(
                              onPressed: _canSave ? _handleSave : null,
                              icon: const Icon(Icons.check),
                              label: const Text('Confirm & Save'),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 16),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
