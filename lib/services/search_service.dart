import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/document_extraction.dart';
import '../models/follow_up_item.dart';
import 'local_storage_service.dart';
import 'dart:math';

/// Service for indexing and searching extracted text
class SearchService {
  final LocalStorageService _storageService;

  SearchService(this._storageService);

  Box get _indexBox => _storageService.searchIndexBox;

  /// Start listening to changes in data sources to keep index up-to-date
  void startListening() {
    Hive.box<FollowUpItem>('follow_up_items').watch().listen((event) {
      if (event.deleted) {
        removeDocument(event.key.toString());
      } else {
        final item = event.value as FollowUpItem;
        indexFollowUpItem(item);
      }
    });
    debugPrint('SearchService listening to data changes');
  }

  /// Index a document's extracted text
  Future<void> indexDocument(DocumentExtraction doc) async {
    await _indexText(doc.id, doc.extractedText);
    debugPrint('Indexed document ${doc.id}');
  }

  /// Index a follow-up item
  Future<void> indexFollowUpItem(FollowUpItem item) async {
    final text =
        '${item.verb} ${item.object ?? ''} ${item.description} ${item.category.toString().split('.').last}';
    await _indexText(item.id, text);
    debugPrint('Indexed follow-up item ${item.id}');
  }

  /// Core indexing logic
  Future<void> _indexText(String id, String text) async {
    final tokens = _tokenize(text);

    for (var token in tokens) {
      // Get existing list of IDs for this token
      List<String> currentIds = List<String>.from(
          _indexBox.get(token, defaultValue: <String>[]) as List);

      if (!currentIds.contains(id)) {
        currentIds.add(id);
        await _indexBox.put(token, currentIds);
      }
    }
  }

  /// Rebuild the entire index from existing documents and follow-ups
  Future<void> rebuildIndex() async {
    debugPrint('Rebuilding search index...');
    await _indexBox.clear();

    // Index documents
    final docs = _storageService.getAllDocumentExtractions();
    for (var doc in docs) {
      await indexDocument(doc);
    }

    // Index follow-ups
    final followUps = _storageService.getAllFollowUpItems();
    for (var item in followUps) {
      await indexFollowUpItem(item);
    }

    debugPrint(
        'Search index rebuild complete. Indexed ${docs.length} documents and ${followUps.length} follow-ups.');
  }

  /// Ensure all documents and follow-ups are indexed (run on app start)
  /// Only runs if index is empty but items exist
  Future<void> ensureIndexed() async {
    if (_indexBox.isEmpty) {
      final docs = _storageService.getAllDocumentExtractions();
      final followUps = _storageService.getAllFollowUpItems();

      if (docs.isNotEmpty || followUps.isNotEmpty) {
        debugPrint('Search index empty but items exist. indexing...');
        for (var doc in docs) {
          await indexDocument(doc);
        }
        for (var item in followUps) {
          await indexFollowUpItem(item);
        }
      }
    }
  }

  /// Remove a document from the index
  Future<void> removeDocument(String docId) async {
    final keys = _indexBox.keys;
    for (var key in keys) {
      List<String> ids = List<String>.from(
          _indexBox.get(key, defaultValue: <String>[]) as List);

      if (ids.contains(docId)) {
        ids.remove(docId);
        if (ids.isEmpty) {
          await _indexBox.delete(key);
        } else {
          await _indexBox.put(key, ids);
        }
      }
    }
    debugPrint('Removed document $docId from search index');
  }

  /// Search for documents matching the query
  /// Supports fuzzy matching
  List<String> search(String query) {
    final queryTokens = _tokenize(query);
    if (queryTokens.isEmpty) return [];

    Set<String> resultIds = {};
    bool firstToken = true;

    // Get all keys once to avoid repeated access
    final indexKeys = _indexBox.keys.cast<String>().toList();

    for (var token in queryTokens) {
      Set<String> tokenMatches = {};

      // 1. Exact match
      if (_indexBox.containsKey(token)) {
        final ids = List<String>.from(_indexBox.get(token) as List);
        tokenMatches.addAll(ids);
      }

      // 2. Fuzzy match (Levenshtein distance <= 2 OR contains)
      for (var key in indexKeys) {
        if (key == token) continue; // Already handled

        // Check if key contains token or token contains key (substring match)
        bool isSubstring = key.contains(token) || token.contains(key);

        // Check edit distance for short words, be stricter
        // For longer words, allow more edits
        int maxDist = token.length < 4 ? 1 : 2;

        if (isSubstring || _levenshtein(key, token) <= maxDist) {
          final ids = List<String>.from(_indexBox.get(key) as List);
          tokenMatches.addAll(ids);
        }
      }

      if (firstToken) {
        resultIds.addAll(tokenMatches);
        firstToken = false;
      } else {
        // Intersection: Document must contain something matching ALL query tokens
        resultIds = resultIds.intersection(tokenMatches);
      }
    }

    return resultIds.toList();
  }

  /// Tokenize text into unique words
  Set<String> _tokenize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ') // Replace punctuation with space
        .split(RegExp(r'\s+'))
        .where((s) => s.length > 2) // Filter out very short words
        .toSet();
  }

  /// Calculate Levenshtein distance between two strings
  int _levenshtein(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    List<int> v0 = List<int>.filled(t.length + 1, 0);
    List<int> v1 = List<int>.filled(t.length + 1, 0);

    for (int i = 0; i < t.length + 1; i++) {
      v0[i] = i;
    }

    for (int i = 0; i < s.length; i++) {
      v1[0] = i + 1;

      for (int j = 0; j < t.length; j++) {
        int cost = (s[i] == t[j]) ? 0 : 1;
        v1[j + 1] = min(v1[j] + 1, min(v0[j + 1] + 1, v0[j] + cost));
      }

      for (int j = 0; j < t.length + 1; j++) {
        v0[j] = v1[j];
      }
    }

    return v1[t.length];
  }
}
