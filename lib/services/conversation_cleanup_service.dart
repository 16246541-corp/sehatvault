import 'dart:io';
import 'package:flutter/foundation.dart';
import 'local_storage_service.dart';
import '../models/doctor_conversation.dart';
import 'local_audit_service.dart';
import 'session_manager.dart';

class ConversationCleanupService {
  final LocalStorageService _storageService;

  ConversationCleanupService(this._storageService);

  Future<void> runDailyCleanup() async {
    debugPrint('Running daily conversation cleanup...');
    final settings = _storageService.getAppSettings();
    final days = settings.autoDeleteRecordingsDays;
    final keepIds = settings.keepAudioIds;

    if (days <= 0) return; // Feature disabled or invalid

    final conversations = _storageService.getAllDoctorConversations();
    final now = DateTime.now();
    // Using start of day for cleaner logic? Or exact time? Exact time is fine.
    final cutoffDate = now.subtract(Duration(days: days));

    int deletedCount = 0;
    int processedCount = 0;

    for (var conversation in conversations) {
      // Check if conversation has an audio file
      if (conversation.encryptedAudioPath.isEmpty) continue;

      // Check age
      if (conversation.createdAt.isAfter(cutoffDate)) continue;

      // Check if user wants to keep it
      if (keepIds.contains(conversation.id)) {
        continue;
      }

      // Check for pending follow-ups
      bool hasPendingFollowUps = false;
      for (var followUpId in conversation.followUpItems) {
        final item = _storageService.getFollowUpItem(followUpId);
        if (item != null && !item.isCompleted) {
          hasPendingFollowUps = true;
          break;
        }
      }

      if (hasPendingFollowUps) {
        debugPrint(
            'Skipping cleanup for ${conversation.id} due to pending follow-ups');
        continue;
      }

      // Proceed to delete audio
      try {
        final file = File(conversation.encryptedAudioPath);
        if (await file.exists()) {
          await file.delete();
          debugPrint('Deleted audio file for conversation ${conversation.id}');
          deletedCount++;
        } else {
          debugPrint(
              'Audio file not found for ${conversation.id}, clearing path');
        }

        // Update conversation to remove path
        conversation.encryptedAudioPath = '';
        await _storageService.saveDoctorConversation(conversation);
        processedCount++;
      } catch (e) {
        debugPrint('Error cleaning up conversation ${conversation.id}: $e');
      }
    }

    if (processedCount > 0) {
      debugPrint(
          'ConversationCleanupService: Processed $processedCount conversations, deleted $deletedCount audio files.');
    } else {
      debugPrint(
          'ConversationCleanupService: No conversations needed cleanup.');
    }
  }
}
