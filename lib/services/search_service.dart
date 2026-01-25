import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart' as hive;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../objectbox.g.dart';
import 'package:objectbox/objectbox.dart' as obx;
import '../models/search_entry.dart';
import '../models/document_extraction.dart';
import '../models/follow_up_item.dart';
import '../models/doctor_conversation.dart';
import 'local_storage_service.dart';
import 'medical_dictionary_service.dart';
import '../utils/string_utils.dart';

class SearchService {
  static obx.Store? _store;
  static obx.Box<SearchEntry>? _box;
  final LocalStorageService _storageService;
  // ignore: unused_field
  final MedicalDictionaryService _medicalDictionaryService =
      MedicalDictionaryService();

  SearchService(this._storageService);

  static Future<void> init() async {
    if (_store != null) return;

    final docsDir = await getApplicationDocumentsDirectory();
    final storeDir = Directory(p.join(docsDir.path, 'search_index'));
    if (!storeDir.existsSync()) {
      storeDir.createSync(recursive: true);
    }

    _store = await openStore(directory: storeDir.path);
    _box = _store!.box<SearchEntry>();
  }

  void startListening() {
    debugPrint('SearchService: Starting listeners...');

    // FollowUpItems
    try {
      hive.Hive.box<FollowUpItem>('follow_up_items').watch().listen((event) {
        if (event.deleted) {
          _removeEntry(event.key.toString(), 'followup');
        } else {
          indexFollowUpItem(event.value as FollowUpItem);
        }
      });
    } catch (e) {
      debugPrint('SearchService: Error listening to follow_up_items: $e');
    }

    // DoctorConversations
    try {
      // Ensure box is open (usually opened by LocalStorageService)
      if (hive.Hive.isBoxOpen('doctor_conversations')) {
        hive.Hive.box<DoctorConversation>('doctor_conversations')
            .watch()
            .listen((event) {
          if (event.deleted) {
            _removeEntry(event.key.toString(), 'conversation');
          } else {
            indexConversation(event.value as DoctorConversation);
          }
        });
      } else {
        debugPrint('SearchService: doctor_conversations box not open.');
      }
    } catch (e) {
      debugPrint('SearchService: Error listening to doctor_conversations: $e');
    }

    // DocumentExtractions
    try {
      if (hive.Hive.isBoxOpen('document_extractions')) {
        hive.Hive.box<DocumentExtraction>('document_extractions')
            .watch()
            .listen((event) {
          if (event.deleted) {
            _removeEntry(event.key.toString(), 'document');
          } else {
            indexDocument(event.value as DocumentExtraction);
          }
        });
      }
    } catch (e) {
      debugPrint('SearchService: Error listening to document_extractions: $e');
    }
  }

  Future<void> ensureIndexed() async {
    if (_box == null) {
      debugPrint('SearchService: Store not initialized. Call init() first.');
      return;
    }

    if (_box!.isEmpty()) {
      debugPrint('SearchService: Index empty, rebuilding...');

      // Index Documents
      try {
        final docs = _storageService.getAllDocumentExtractions();
        for (var doc in docs) {
          await indexDocument(doc);
        }
      } catch (e) {
        debugPrint('SearchService: Error indexing documents: $e');
      }

      // Index FollowUps
      try {
        final followUps = _storageService.getAllFollowUpItems();
        for (var item in followUps) {
          await indexFollowUpItem(item);
        }
      } catch (e) {
        debugPrint('SearchService: Error indexing follow-ups: $e');
      }

      // Index Conversations
      try {
        if (hive.Hive.isBoxOpen('doctor_conversations')) {
          final conversations =
              hive.Hive.box<DoctorConversation>('doctor_conversations').values;
          for (var c in conversations) {
            await indexConversation(c);
          }
        }
      } catch (e) {
        debugPrint('SearchService: Error indexing conversations: $e');
      }

      debugPrint('SearchService: Rebuild complete. ${_box!.count()} entries.');
    }
  }

  Future<void> removeDocument(String id) async {
    _removeEntry(id, 'document');
  }

  Future<void> indexDocument(DocumentExtraction doc) async {
    await _putEntry(SearchEntry(
      sourceId: doc.id,
      type: 'document',
      content: _maskSensitiveData(doc.extractedText),
      title: 'Document',
      subtitle: doc.extractedText.length > 50
          ? '${doc.extractedText.substring(0, 50)}...'
          : doc.extractedText,
      timestamp: doc.createdAt,
    ));
  }

  Future<void> indexConversation(DoctorConversation conversation) async {
    await _medicalDictionaryService.load();

    final text = '${conversation.transcript} ${conversation.doctorName}';
    final followUps =
        conversation.followUpItems.join(' '); // Assuming List<String>
    final fullText = '$text $followUps';

    final keywords = _extractKeywords(fullText);

    await _putEntry(SearchEntry(
      sourceId: conversation.id,
      type: 'conversation',
      content: _maskSensitiveData(fullText),
      title: conversation.title,
      subtitle: conversation.doctorName,
      timestamp: conversation.createdAt,
      keywords: keywords,
    ));
  }

  Future<void> indexFollowUpItem(FollowUpItem item) async {
    await _medicalDictionaryService.load();

    final text = '${item.verb} ${item.object ?? ''} ${item.description}';
    await _putEntry(SearchEntry(
      sourceId: item.id,
      type: 'followup',
      content: _maskSensitiveData(text),
      title: '${item.verb} ${item.object ?? ''}',
      subtitle: item.description,
      timestamp: item.dueDate ?? DateTime.now(),
      keywords: _extractKeywords(text),
    ));
  }

  Future<void> _putEntry(SearchEntry entry) async {
    if (_box == null) return;

    // Find existing to preserve ID
    final query = _box!
        .query(SearchEntry_.sourceId.equals(entry.sourceId) &
            SearchEntry_.type.equals(entry.type))
        .build();
    final existing = query.findFirst();
    query.close();

    if (existing != null) {
      entry.id = existing.id;
    }
    _box!.put(entry);
    debugPrint('Indexed ${entry.type}: ${entry.title}');
  }

  void _removeEntry(String sourceId, String type) {
    if (_box == null) return;
    final query = _box!
        .query(SearchEntry_.sourceId.equals(sourceId) &
            SearchEntry_.type.equals(type))
        .build();
    query.remove();
    query.close();
    debugPrint('Removed $type: $sourceId');
  }

  /// Search returns list of SearchEntry
  List<SearchEntry> search(String query) {
    if (_box == null || query.isEmpty) return [];

    final q = query.toLowerCase();

    // 1. Exact/Contains
    final contentQuery = _box!
        .query(SearchEntry_.content.contains(q, caseSensitive: false) |
            SearchEntry_.title.contains(q, caseSensitive: false) |
            SearchEntry_.keywords.contains(q, caseSensitive: false))
        .build();

    final results = contentQuery.find();
    contentQuery.close();

    final existingIds = results.map((e) => e.id).toSet();
    final allEntries = _box!.getAll();
    for (final entry in allEntries) {
      if (existingIds.contains(entry.id)) continue;
      if (_isFuzzyMatch(entry, q)) {
        results.add(entry);
        existingIds.add(entry.id);
      }
    }

    // Ranking
    results.sort((a, b) {
      int scoreA = _calculateScore(a, q);
      int scoreB = _calculateScore(b, q);
      return scoreB.compareTo(scoreA);
    });

    return results;
  }

  int _calculateScore(SearchEntry entry, String query) {
    int score = 0;
    final titleLower = entry.title.toLowerCase();
    final subtitleLower = entry.subtitle.toLowerCase();
    final keywordsLower = entry.keywords.toLowerCase();
    final contentLower = entry.content.toLowerCase();

    if (titleLower.contains(query)) score += 10;
    if (subtitleLower.contains(query)) score += 4;
    if (keywordsLower.contains(query)) score += 5;
    if (contentLower.contains(query)) score += 1;

    final titleSimilarity = StringUtils.calculateSimilarity(titleLower, query);
    if (titleSimilarity >= 0.8) score += (titleSimilarity * 6).round();

    final keywordsSimilarity = _maxTokenSimilarity(keywordsLower, query);
    if (keywordsSimilarity >= 0.8) score += (keywordsSimilarity * 4).round();

    final contentSimilarity = _maxTokenSimilarity(contentLower, query);
    if (contentSimilarity >= 0.8) score += (contentSimilarity * 2).round();

    return score;
  }

  String _maskSensitiveData(String text) {
    // Basic redaction
    text = text.replaceAll(RegExp(r'\b\d{3}-\d{2}-\d{4}\b'), '[REDACTED_SSN]');
    text = text.replaceAll(RegExp(r'\b\d{10,}\b'), '[REDACTED_NUM]');
    return text;
  }

  String _extractKeywords(String text) {
    return _medicalDictionaryService.findAllTerms(text).join(' ');
  }

  bool _isFuzzyMatch(SearchEntry entry, String query) {
    final titleLower = entry.title.toLowerCase();
    if (StringUtils.calculateSimilarity(titleLower, query) >= 0.8) {
      return true;
    }

    final subtitleLower = entry.subtitle.toLowerCase();
    if (subtitleLower.isNotEmpty &&
        StringUtils.calculateSimilarity(subtitleLower, query) >= 0.8) {
      return true;
    }

    final keywordsSimilarity =
        _maxTokenSimilarity(entry.keywords.toLowerCase(), query);
    if (keywordsSimilarity >= 0.8) {
      return true;
    }

    final contentSimilarity =
        _maxTokenSimilarity(entry.content.toLowerCase(), query);
    return contentSimilarity >= 0.8;
  }

  double _maxTokenSimilarity(String text, String query) {
    if (text.isEmpty) return 0;
    final matches = RegExp(r"[A-Za-z0-9]+").allMatches(text);
    double maxScore = 0;
    for (final match in matches) {
      final token = match.group(0);
      if (token == null || token.length < 2) continue;
      final score = StringUtils.calculateSimilarity(token, query);
      if (score > maxScore) {
        maxScore = score;
        if (maxScore >= 0.95) break;
      }
    }
    return maxScore;
  }
}
