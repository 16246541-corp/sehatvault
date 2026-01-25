import 'package:hive_flutter/hive_flutter.dart';
import '../models/citation.dart';
import 'analytics_service.dart';
import 'local_storage_service.dart';
import 'medical_field_extractor.dart';
import 'reference_range_service.dart';

class CitationService {
  static const String _citationsMigrationKey = 'citations_migration_completed';
  final LocalStorageService _storageService;
  final AnalyticsService _analyticsService = AnalyticsService();

  CitationService(this._storageService);

  Box<Citation> get _box => _storageService.citationsBox;

  Future<void> addCitation(Citation citation) async {
    final stopwatch = Stopwatch()..start();
    await _box.put(citation.id, citation);
    stopwatch.stop();
    await _analyticsService.logMetric(
        'citation_add_time', stopwatch.elapsedMilliseconds.toDouble());
  }

  List<Citation> getCitations() {
    return _box.values.toList();
  }

  Citation? getCitationById(String id) {
    return _box.get(id);
  }

  /// Formats citations based on the requested style
  String formatCitations(List<Citation> citations, {String style = 'inline'}) {
    if (citations.isEmpty) return '';

    // Filter by confidence threshold
    final validCitations =
        citations.where((c) => c.confidenceScore >= 0.85).toList();
    if (validCitations.isEmpty) return '';

    switch (style) {
      case 'footnote':
        return validCitations.map((c) => c.footnoteCitation).join(' ');
      case 'reference':
        return validCitations.map((c) => c.fullReference).join('\n');
      case 'inline':
      default:
        return validCitations.map((c) => c.inlineCitation).join(' ');
    }
  }

  Citation createCitationFromTemplate({
    required String title,
    required String url,
    required String date,
    required String type,
    String? textSnippet,
    String? relatedField,
  }) {
    return Citation(
      sourceTitle: title,
      sourceUrl: url,
      sourceDate: DateTime.tryParse(date),
      type: type,
      textSnippet: textSnippet,
      relatedField: relatedField,
      confidenceScore: 0.95, // High confidence for templates
    );
  }

  List<Citation> generateCitationsForLabValues(List<dynamic> labValues) {
    final stopwatch = Stopwatch()..start();
    final citations = <Citation>[];
    for (final item in labValues) {
      if (item is Map) {
        final field = item['field'] as String?;
        if (field != null) {
          final source = ReferenceRangeService.getCitationSource(field);
          if (source != null) {
            // Check if we already have a citation for this source to avoid duplicates
            final alreadyExists =
                citations.any((c) => c.sourceTitle == source['title']);
            if (!alreadyExists) {
              citations.add(createCitationFromTemplate(
                title: source['title']!,
                url: source['url']!,
                date: source['date']!,
                type: 'guideline',
                relatedField: field,
              ));
            }
          }
        }
      }
    }
    stopwatch.stop();
    _analyticsService.logMetric(
        'citation_generation_time', stopwatch.elapsedMilliseconds.toDouble());
    return citations;
  }

  List<Citation> generateCitationsFromText(String text) {
    if (text.isEmpty) return [];
    final extracted = MedicalFieldExtractor.extractLabValues(text);
    final values = extracted['values'];
    if (values is List && values.isNotEmpty) {
      return generateCitationsForLabValues(values);
    }
    return [];
  }

  Future<int> migrateExistingDocumentCitations() async {
    final migrated = _storageService.getSetting<bool>(
          _citationsMigrationKey,
          defaultValue: false,
        ) ??
        false;
    if (migrated) return 0;

    final stopwatch = Stopwatch()..start();
    final documents = _storageService.getAllDocumentExtractions();
    int updated = 0;

    for (final extraction in documents) {
      final existing = extraction.citations;
      if (existing != null && existing.isNotEmpty) {
        continue;
      }

      List<dynamic> labValues = [];
      final structured = extraction.structuredData['lab_values'];
      if (structured is List && structured.isNotEmpty) {
        labValues = structured;
      } else if (extraction.extractedText.isNotEmpty) {
        final extracted = MedicalFieldExtractor.extractLabValues(
          extraction.extractedText,
        );
        final values = extracted['values'];
        if (values is List && values.isNotEmpty) {
          labValues = values;
        }
      }

      if (labValues.isEmpty) {
        continue;
      }

      final citations = generateCitationsForLabValues(labValues);
      if (citations.isEmpty) {
        continue;
      }

      for (final citation in citations) {
        await addCitation(citation);
      }

      final updatedExtraction = extraction.copyWith(citations: citations);
      await _storageService.saveDocumentExtraction(updatedExtraction);
      updated++;
    }

    stopwatch.stop();
    await _analyticsService.logMetric(
      'citation_migration_time',
      stopwatch.elapsedMilliseconds.toDouble(),
    );
    await _analyticsService.logEvent(
      'citation_migration',
      parameters: {
        'updated': updated,
        'total': documents.length,
      },
    );
    await _storageService.saveSetting(_citationsMigrationKey, true);

    return updated;
  }
}
