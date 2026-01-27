import 'dart:async';

import '../models/citation.dart';
import '../models/document_extraction.dart';
import '../models/health_pattern_insight.dart';
import '../models/health_record.dart';
import '../services/batch_processing_service.dart';
import '../services/citation_service.dart';
import '../services/local_audit_service.dart';
import '../services/local_storage_service.dart';
import '../services/medical_field_extractor.dart';
import '../services/reference_range_service.dart';
import '../services/safety_filter_service.dart';
import '../services/session_manager.dart';
import '../services/temporal_phrase_patterns_configuration.dart';
import '../services/vault_service.dart';

class HealthIntelligenceEngine {
  static HealthIntelligenceEngine? _instance;

  factory HealthIntelligenceEngine({
    required LocalStorageService storage,
    required MedicalFieldExtractor fieldExtractor,
    required ReferenceRangeService referenceRanges,
    required SafetyFilterService safetyFilter,
    required LocalAuditService auditLogger,
  }) {
    return _instance ??= HealthIntelligenceEngine._internal(
      storage: storage,
      fieldExtractor: fieldExtractor,
      referenceRanges: referenceRanges,
      safetyFilter: safetyFilter,
      auditLogger: auditLogger,
    );
  }

  HealthIntelligenceEngine._internal({
    required LocalStorageService storage,
    required MedicalFieldExtractor fieldExtractor,
    required ReferenceRangeService referenceRanges,
    required SafetyFilterService safetyFilter,
    required LocalAuditService auditLogger,
  })  : _storage = storage,
        _fieldExtractor = fieldExtractor,
        _referenceRanges = referenceRanges,
        _safetyFilter = safetyFilter,
        _auditLogger = auditLogger,
        _vaultService = VaultService(storage),
        _citationService = CitationService(storage);

  final LocalStorageService _storage;
  final MedicalFieldExtractor _fieldExtractor;
  final ReferenceRangeService _referenceRanges;
  final SafetyFilterService _safetyFilter;
  final LocalAuditService _auditLogger;
  final VaultService _vaultService;
  final CitationService _citationService;

  Future<List<HealthPatternInsight>> getCachedInsights() async {
    final insights = _storage.getAllHealthPatternInsights();
    insights.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return insights;
  }

  Future<void> clearInsights() async {
    await _storage.clearHealthPatternInsights();
  }

  Future<List<HealthPatternInsight>> detectAndPersistInsights({
    bool force = false,
  }) async {
    final settings = _storage.getAppSettings();
    final isEnabled = settings.enhancedPrivacySettings.showHealthInsights;

    if (!isEnabled && !force) {
      return getCachedInsights();
    }

    final sessionLocked = SessionManager().isLocked;
    final requireBiometrics =
        settings.enhancedPrivacySettings.requireBiometricsForSensitiveData;
    if (requireBiometrics && sessionLocked) {
      return getCachedInsights();
    }

    final all = await _vaultService.getAllDocuments();
    final records = all.map((e) => e.record).toList();
    final extractions = all
        .where(
            (e) => e.record.recordType != HealthRecord.typeDoctorConversation)
        .toList();

    final userPrivacyThreshold =
        settings.enhancedPrivacySettings.userPrivacyThreshold;

    final filteredExtractions = extractions.where((e) {
      final sensitivity = _readSensitivityLevel(e.record);
      return sensitivity <= userPrivacyThreshold;
    }).toList();

    final insights = <HealthPatternInsight>[];

    final temporalConfig = TemporalPhrasePatternsConfiguration();
    final temporalExtractor = _TemporalHelper(temporalConfig);

    insights.addAll(await _detectConversationPatterns(temporalExtractor));

    final labPoints = <_LabPoint>[];
    if (filteredExtractions.length > 100) {
      await BatchProcessingService().runThrottledJob(
        jobId: 'health_insights_lab_points',
        totalUnits: filteredExtractions.length,
        chunkSize: 50,
        processChunk: (start, end) async {
          labPoints.addAll(
              _collectLabPoints(filteredExtractions.sublist(start, end)));
        },
      );
    } else {
      labPoints.addAll(_collectLabPoints(filteredExtractions));
    }

    insights.addAll(
      await _detectLabTrendsFromPoints(labPoints, temporalExtractor),
    );

    final safeInsights = <HealthPatternInsight>[];
    for (final insight in insights) {
      final sanitizedTitle = _safetyFilter.sanitize(insight.title);
      final sanitizedSummary = _safetyFilter.sanitize(insight.summary);
      final combined = '$sanitizedTitle $sanitizedSummary';
      if (_safetyFilter.hasDiagnosticLanguage(combined)) {
        continue;
      }
      safeInsights.add(
        HealthPatternInsight(
          id: insight.id,
          createdAt: insight.createdAt,
          title: sanitizedTitle,
          summary: sanitizedSummary,
          patternType: insight.patternType,
          timeframeIso8601: insight.timeframeIso8601,
          citations: insight.citations,
          sourceIds: insight.sourceIds,
        ),
      );
    }

    for (final insight in safeInsights) {
      await _storage.saveHealthPatternInsight(insight);
      await _auditLogger.log(
        action: 'health_pattern_generated',
        details: {
          'contentHash': insight.contentHash,
          'patternType': insight.patternType,
          'sourceCount': insight.sourceIds.length.toString(),
        },
        sensitivity: 'info',
      );
    }

    safeInsights.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return safeInsights;
  }

  int _readSensitivityLevel(HealthRecord record) {
    final meta = record.metadata;
    if (meta == null) return 0;
    final v = meta['sensitivityLevel'];
    if (v is int) return v;
    if (v is double) return v.round();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  Future<List<HealthPatternInsight>> _detectConversationPatterns(
    _TemporalHelper temporal,
  ) async {
    final conversations = _storage.getAllDoctorConversations();
    if (conversations.isEmpty) return [];

    final sleepMatches =
        <({String id, String title, DateTime date, String text})>[];

    for (final c in conversations) {
      final rawText = (c.segments != null && c.segments!.isNotEmpty)
          ? c.segments!.map((s) => s.text).join(' ')
          : c.transcript;
      final sanitized = _safetyFilter.sanitize(rawText);
      if (_containsSleepKeyword(sanitized)) {
        sleepMatches.add(
            (id: c.id, title: c.title, date: c.createdAt, text: sanitized));
      }
    }

    if (sleepMatches.length < 3) return [];

    sleepMatches.sort((a, b) => a.date.compareTo(b.date));
    final start = sleepMatches.first.date;
    final end = sleepMatches.last.date;
    final timeframe = temporal.formatIsoDuration(start, end);

    final citations = <Citation>[];
    for (final match in sleepMatches) {
      final citation = Citation(
        sourceTitle: match.title,
        sourceDate: match.date,
        type: 'user_data',
        relatedField: 'sleep',
        textSnippet: 'Sleep-related mention',
        confidenceScore: 0.95,
        publication: 'Local Vault',
      );
      citations.add(citation);
      await _citationService.addCitation(citation);
    }

    return [
      HealthPatternInsight(
        title: 'Sleep-related mentions across conversations',
        summary:
            'Multiple conversations include sleep-related topics over $timeframe.',
        patternType: 'conversation_keyword_temporal',
        timeframeIso8601: timeframe,
        citations: citations,
        sourceIds: sleepMatches.map((e) => e.id).toList(),
      ),
    ];
  }

  bool _containsSleepKeyword(String text) {
    final lower = text.toLowerCase();
    return RegExp(r'\b(sleep|insomnia|fatigue|tired)\b').hasMatch(lower);
  }

  Future<List<HealthPatternInsight>> _detectLabTrends(
    List<({HealthRecord record, DocumentExtraction? extraction})> docs,
    _TemporalHelper temporal,
  ) async {
    final points = _collectLabPoints(docs);
    return _detectLabTrendsFromPoints(points, temporal);
  }

  List<_LabPoint> _collectLabPoints(
    List<({HealthRecord record, DocumentExtraction? extraction})> docs,
  ) {
    final labPoints = <_LabPoint>[];

    for (final d in docs) {
      final extraction = d.extraction;
      if (extraction == null) continue;
      if (!_isValidatedExtraction(extraction)) continue;

      final labValuesRaw = extraction.structuredData['lab_values'];
      if (labValuesRaw is! List) continue;

      final docDate = _resolveDocumentDate(extraction, d.record);

      for (final item in labValuesRaw) {
        if (item is! Map) continue;
        final field = item['field']?.toString();
        final valueStr = item['value']?.toString();
        final unit = item['unit']?.toString();
        if (field == null || valueStr == null) continue;

        final value = double.tryParse(valueStr);
        if (value == null) continue;

        final evaluation = ReferenceRangeService.evaluateLabValue(
          testName: field,
          value: value,
          unit: unit,
        );
        final status = evaluation['status']?.toString() ?? 'unknown';

        labPoints.add(
          _LabPoint(
            recordId: d.record.id,
            title: d.record.title,
            date: docDate,
            field: field,
            value: value,
            unit: unit,
            status: status,
            confidence: extraction.confidenceScore,
          ),
        );
      }
    }

    return labPoints;
  }

  Future<List<HealthPatternInsight>> _detectLabTrendsFromPoints(
      List<_LabPoint> labPoints, _TemporalHelper temporal,
      {bool persistCitations = true}) async {
    if (labPoints.isEmpty) return [];

    final byField = <String, List<_LabPoint>>{};
    for (final p in labPoints) {
      final key = p.field.trim().toLowerCase();
      byField.putIfAbsent(key, () => []).add(p);
    }

    final insights = <HealthPatternInsight>[];

    for (final entry in byField.entries) {
      final points = entry.value..sort((a, b) => a.date.compareTo(b.date));
      if (points.length < 3) continue;

      final increasing =
          _isStrictlyIncreasing(points.map((e) => e.value).toList());
      if (!increasing) continue;

      final start = points.first.date;
      final end = points.last.date;
      final timeframe = temporal.formatIsoDuration(start, end);
      final displayField = points.first.field;

      final citations = <Citation>[];
      for (final p in points) {
        final citation = Citation(
          sourceTitle: p.title,
          sourceDate: p.date,
          type: 'user_data',
          relatedField: '$displayField value',
          textSnippet:
              '$displayField: ${p.value}${p.unit != null ? " ${p.unit}" : ""}',
          confidenceScore: _confidenceFromExtraction(p.confidence),
          publication: 'Local Vault',
        );
        citations.add(citation);
        if (persistCitations) {
          await _citationService.addCitation(citation);
        }
      }

      final summary =
          '$displayField values are trending upward over $timeframe.';

      final combined = '$displayField $summary';
      if (_safetyFilter.hasDiagnosticLanguage(combined)) {
        continue;
      }

      insights.add(
        HealthPatternInsight(
          title: '$displayField trend',
          summary: summary,
          patternType: 'lab_value_progression',
          timeframeIso8601: timeframe,
          citations: citations,
          sourceIds: points.map((e) => e.recordId).toList(),
        ),
      );
    }

    return insights;
  }

  Future<List<HealthPatternInsight>> detectInsightsForEphemeralText({
    required String sourceTitle,
    required DateTime sourceDate,
    required String extractedText,
  }) async {
    final settings = _storage.getAppSettings();
    final sessionLocked = SessionManager().isLocked;
    final requireBiometrics =
        settings.enhancedPrivacySettings.requireBiometricsForSensitiveData;
    if (requireBiometrics && sessionLocked) {
      return [];
    }

    final temporalConfig = TemporalPhrasePatternsConfiguration();
    final temporal = _TemporalHelper(temporalConfig);

    final extracted = MedicalFieldExtractor.extractLabValues(extractedText);
    final values = extracted['values'];
    final labValues = <Map<String, dynamic>>[];
    if (values is List) {
      for (final v in values) {
        if (v is Map) {
          labValues.add({
            'field': v['field']?.toString() ?? '',
            'value': v['value']?.toString() ?? '',
            'unit': v['unit']?.toString() ?? '',
          });
        }
      }
    }

    final extraction = DocumentExtraction(
      originalImagePath: 'ephemeral',
      extractedText: extractedText,
      confidenceScore: 0.85,
      structuredData: {
        'lab_values': labValues,
        'dates': [sourceDate.toIso8601String()],
      },
      createdAt: sourceDate,
    );

    final record = HealthRecord(
      id: 'ephemeral_${sourceDate.millisecondsSinceEpoch}',
      title: sourceTitle,
      category: 'Uncategorized',
      createdAt: sourceDate,
      recordType: HealthRecord.typeDocumentExtraction,
      extractionId: extraction.id,
      metadata: {'subtype': 'ephemeral'},
    );

    final stored = await _vaultService.getAllDocuments();
    final storedDocs = stored
        .where(
            (e) => e.record.recordType != HealthRecord.typeDoctorConversation)
        .toList();

    final userPrivacyThreshold =
        settings.enhancedPrivacySettings.userPrivacyThreshold;

    final filteredStored = storedDocs.where((e) {
      final sensitivity = _readSensitivityLevel(e.record);
      return sensitivity <= userPrivacyThreshold;
    }).toList();

    final combinedDocs =
        <({HealthRecord record, DocumentExtraction? extraction})>[
      ...filteredStored,
      (record: record, extraction: extraction),
    ];

    final points = _collectLabPoints(combinedDocs);
    final trendInsights = await _detectLabTrendsFromPoints(points, temporal,
        persistCitations: false);
    if (trendInsights.isNotEmpty) {
      return trendInsights;
    }

    if (labValues.isNotEmpty) {
      final citations = <Citation>[
        Citation(
          sourceTitle: sourceTitle,
          sourceDate: sourceDate,
          type: 'user_data',
          relatedField: 'lab values',
          textSnippet: 'Detected ${labValues.length} lab value(s)',
          confidenceScore: 0.85,
          publication: 'Ephemeral Analysis',
        ),
      ];

      return [
        HealthPatternInsight(
          title: 'Ephemeral document analysis',
          summary:
              'Detected ${labValues.length} lab value(s) in the dropped file.',
          patternType: 'ephemeral_document',
          timeframeIso8601: 'P0D',
          citations: citations,
          sourceIds: [record.id],
        ),
      ];
    }

    final sanitized = _safetyFilter.sanitize(extractedText);
    if (_containsSleepKeyword(sanitized)) {
      return [
        HealthPatternInsight(
          title: 'Ephemeral document analysis',
          summary: 'Detected sleep-related keywords in the dropped file.',
          patternType: 'ephemeral_document',
          timeframeIso8601: 'P0D',
          citations: [
            Citation(
              sourceTitle: sourceTitle,
              sourceDate: sourceDate,
              type: 'user_data',
              relatedField: 'sleep',
              textSnippet: 'Sleep-related mention',
              confidenceScore: 0.85,
              publication: 'Ephemeral Analysis',
            ),
          ],
          sourceIds: [record.id],
        ),
      ];
    }

    return [];
  }

  bool _isValidatedExtraction(DocumentExtraction extraction) {
    return extraction.confidenceScore >= 0.85;
  }

  DateTime _resolveDocumentDate(
      DocumentExtraction extraction, HealthRecord record) {
    final dates = extraction.structuredData['dates'];
    if (dates is List && dates.isNotEmpty) {
      for (final d in dates) {
        final parsed = DateTime.tryParse(d.toString());
        if (parsed != null) return parsed;
      }
    }
    return record.createdAt;
  }

  bool _isStrictlyIncreasing(List<double> values) {
    for (var i = 1; i < values.length; i++) {
      if (values[i] <= values[i - 1]) return false;
    }
    return true;
  }

  double _confidenceFromExtraction(double confidenceScore) {
    return confidenceScore.clamp(0.0, 1.0);
  }
}

class _LabPoint {
  final String recordId;
  final String title;
  final DateTime date;
  final String field;
  final double value;
  final String? unit;
  final String status;
  final double confidence;

  _LabPoint({
    required this.recordId,
    required this.title,
    required this.date,
    required this.field,
    required this.value,
    required this.unit,
    required this.status,
    required this.confidence,
  });
}

class _TemporalHelper {
  final TemporalPhrasePatternsConfiguration _config;

  _TemporalHelper(this._config);

  String formatIsoDuration(DateTime start, DateTime end) {
    final a = DateTime(start.year, start.month, start.day);
    final b = DateTime(end.year, end.month, end.day);
    if (b.isBefore(a)) return 'P0D';

    if (a.day == b.day) {
      final months = (b.year - a.year) * 12 + (b.month - a.month);
      if (months > 0) return 'P${months}M';
    }

    final days = b.difference(a).inDays;
    return 'P${days}D';
  }
}
