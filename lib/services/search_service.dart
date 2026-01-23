import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/document_extraction.dart';
import 'local_storage_service.dart';
import 'dart:math';

/// Service for indexing and searching extracted text
class SearchService {
  final LocalStorageService _storageService;

  SearchService(this._storageService);

  Box get _indexBox => _storageService.searchIndexBox;

  /// Index a document's extracted text
  Future<void> indexDocument(DocumentExtraction doc) async {
    final tokens = _tokenize(doc.extractedText);
    
    for (var token in tokens) {
      // Get existing list of IDs for this token
      List<String> currentIds = List<String>.from(
        _indexBox.get(token, defaultValue: <String>[]) as List
      );
      
      if (!currentIds.contains(doc.id)) {
        currentIds.add(doc.id);
        await _indexBox.put(token, currentIds);
      }
    }
    debugPrint('Indexed document ${doc.id} with ${tokens.length} tokens');
  }

  /// Remove a document from the index
  Future<void> removeDocument(String docId) async {
    final keys = _indexBox.keys;
    for (var key in keys) {
      List<String> ids = List<String>.from(
        _indexBox.get(key, defaultValue: <String>[]) as List
      );
      
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
     return text.toLowerCase()
       .replaceAll(RegExp(r'[^\w\s]'), ' ') // Replace punctuation with space
       .split(RegExp(r'\s+'))
       .where((s) => s.length > 2) // Filter out very short words
       .toSet();
  }

  /// Rebuild the entire index from existing documents
  Future<void> rebuildIndex() async {
    debugPrint('Rebuilding search index...');
    await _indexBox.clear();
    final docs = _storageService.getAllDocumentExtractions();
    for (var doc in docs) {
      await indexDocument(doc);
    }
    debugPrint('Search index rebuild complete. Indexed ${docs.length} documents.');
  }

  /// Ensure all documents are indexed (run on app start)
  /// Only runs if index is empty but documents exist
  Future<void> ensureIndexed() async {
    if (_indexBox.isEmpty) {
      final docs = _storageService.getAllDocumentExtractions();
      if (docs.isNotEmpty) {
        debugPrint('Search index empty but documents exist. indexing...');
        for (var doc in docs) {
          await indexDocument(doc);
        }
      }
    }
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
