import 'package:flutter/foundation.dart';
import '../models/conversation_memory.dart';
import 'local_storage_service.dart';
import 'safety_filter_service.dart';
import 'token_counter_service.dart';

class ConversationMemoryService {
  static final ConversationMemoryService _instance =
      ConversationMemoryService._internal();
  factory ConversationMemoryService() => _instance;
  ConversationMemoryService._internal();

  final LocalStorageService _storageService = LocalStorageService();
  final SafetyFilterService _safetyFilter = SafetyFilterService();
  final TokenCounterService _tokenCounter = TokenCounterService();

  /// Default memory constraints
  static const int defaultMaxTokens = 4096;
  static const int defaultMaxMessages = 20;
  static const int retentionBuffer = 2; // Keep at least the first 2 messages

  /// Add a new entry to the conversation memory
  Future<void> addEntry({
    required String conversationId,
    required String role,
    required String content,
    Map<String, dynamic> metadata = const {},
  }) async {
    final memory = _storageService.getConversationMemory(conversationId) ??
        ConversationMemory(
          conversationId: conversationId,
          entries: [],
          lastUpdatedAt: DateTime.now(),
        );

    // 1. Automatic redaction for privacy
    final sanitizedContent = _safetyFilter.sanitize(content);
    final isRedacted = sanitizedContent != content;

    final newEntry = MemoryEntry(
      role: role,
      content: sanitizedContent,
      timestamp: DateTime.now(),
      isRedacted: isRedacted,
      metadata: metadata,
    );

    memory.entries.add(newEntry);

    // 2. Manage context window
    _manageContextWindow(memory);

    // 3. Update metrics
    _updateMetrics(memory, newEntry);

    // 4. Save to persistent storage
    await _storageService.saveConversationMemory(ConversationMemory(
      conversationId: memory.conversationId,
      entries: memory.entries,
      lastUpdatedAt: DateTime.now(),
      metrics: memory.metrics,
    ));
  }

  /// Get formatted context for AI consumption
  List<Map<String, String>> getContext(String conversationId) {
    final memory = _storageService.getConversationMemory(conversationId);
    if (memory == null) return [];

    return memory.entries
        .map((entry) => {
              'role': entry.role,
              'content': entry.content,
            })
        .toList();
  }

  /// Strategic context window management
  void _manageContextWindow(ConversationMemory memory) {
    final settings = _storageService.getAppSettings();
    final maxTokens = settings.aiMaxTokens ?? defaultMaxTokens;
    final maxMessages = settings.aiMaxMessages ?? defaultMaxMessages;

    // 1. Limit by message count
    if (memory.entries.length > maxMessages) {
      final toRemove = memory.entries.length - maxMessages;
      // Keep the first few messages (retentionBuffer) and remove from the middle/start after that
      if (memory.entries.length > retentionBuffer + toRemove) {
        memory.entries.removeRange(retentionBuffer, retentionBuffer + toRemove);
      } else {
        memory.entries.removeRange(0, toRemove);
      }
    }

    // 2. Limit by token count
    int currentTokens = _calculateTotalTokens(memory.entries);
    while (currentTokens > maxTokens &&
        memory.entries.length > retentionBuffer + 1) {
      // Remove oldest entries after the retention buffer, leaving one for potential truncation
      memory.entries.removeAt(retentionBuffer);
      currentTokens = _calculateTotalTokens(memory.entries);
    }

    // Graceful degradation: if still too long, truncate the oldest non-retained message
    if (currentTokens > maxTokens && memory.entries.length > retentionBuffer) {
      final entry = memory.entries[retentionBuffer];
      final targetTokens = (maxTokens / 2).floor();
      final truncatedContent = _truncateToTokens(entry.content, targetTokens);
      memory.entries[retentionBuffer] = MemoryEntry(
        role: entry.role,
        content: truncatedContent,
        timestamp: entry.timestamp,
        isRedacted: entry.isRedacted,
        metadata: {...entry.metadata, 'truncated': true},
      );
    }
  }

  /// Token calculation using TokenCounterService
  int _calculateTotalTokens(List<MemoryEntry> entries) {
    return entries.fold(
        0, (sum, entry) => sum + _tokenCounter.countTokens(entry.content));
  }

  String _truncateToTokens(String content, int targetTokens) {
    if (_tokenCounter.countTokens(content) <= targetTokens) return content;

    // Rough character-based truncation as a fallback
    final charLimit = targetTokens * 4;
    if (content.length <= charLimit) return content;

    return '${content.substring(0, charLimit)}... [truncated]';
  }

  /// Update memory usage metrics
  void _updateMetrics(ConversationMemory memory, MemoryEntry newEntry) {
    final metrics = Map<String, dynamic>.from(memory.metrics);

    metrics['message_count'] = memory.entries.length;
    metrics['total_tokens'] = _calculateTotalTokens(memory.entries);
    metrics['redaction_count'] =
        memory.entries.where((e) => e.isRedacted).length;
    metrics['last_interaction'] = DateTime.now().toIso8601String();

    memory.metrics = metrics;
  }

  /// Clear memory for a conversation
  Future<void> clearMemory(String conversationId) async {
    await _storageService.deleteConversationMemory(conversationId);
  }
}
