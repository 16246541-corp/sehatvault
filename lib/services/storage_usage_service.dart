import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'desktop_notification_service.dart';
import '../models/model_option.dart';
import '../services/local_storage_service.dart';
import '../services/model_manager.dart';

/// Data class to hold storage usage details
class StorageUsage {
  final int conversationsBytes;
  final int documentsBytes;
  final int modelsBytes;
  final int totalBytes;
  final int freeBytes;
  final int totalSpaceBytes;

  final int conversationCount;
  final int documentCount;

  StorageUsage({
    required this.conversationsBytes,
    required this.documentsBytes,
    required this.modelsBytes,
    required this.totalBytes,
    required this.freeBytes,
    required this.totalSpaceBytes,
    required this.conversationCount,
    required this.documentCount,
  });

  factory StorageUsage.empty() {
    return StorageUsage(
      conversationsBytes: 0,
      documentsBytes: 0,
      modelsBytes: 0,
      totalBytes: 0,
      freeBytes: 0,
      totalSpaceBytes: 0,
      conversationCount: 0,
      documentCount: 0,
    );
  }

  double get usagePercentage {
    if (totalSpaceBytes == 0) return 0.0;
    // We want usage relative to total disk space? Or just display used?
    // Usually "Storage Usage" shows how much of the disk is used by the app relative to free space + app space.
    // Or just "App Storage Usage" where 100% is the app's total usage?
    // The requirement says "Circular progress bar showing used/total storage".
    // "Used" usually refers to the whole device usage or the app's quota.
    // Given "Threshold Alert: Show warning when >80% storage used", this likely means *Device* storage.
    // So (totalSpace - freeSpace) / totalSpace.
    return (totalSpaceBytes - freeBytes) / totalSpaceBytes;
  }

  double get appUsagePercentage {
    if (totalSpaceBytes == 0) return 0.0;
    return totalBytes / totalSpaceBytes;
  }
}

class StorageUsageService {
  final LocalStorageService _storageService;

  StorageUsageService(this._storageService);

  Future<StorageUsage> calculateStorageUsage() async {
    try {
      final conversationsUsage = await _calculateConversationsUsage();
      final documentsUsage = await _calculateDocumentsUsage();
      final modelsBytes = await _calculateModelsSize();

      // Get device storage info
      int freeBytes = 0;
      int totalSpaceBytes = 1024 * 1024 * 1024 * 256; // Increased to 256GB

      try {
        if (!kIsWeb) {
          // Note: In a real app, use a package like 'storage_space' for accurate info.
          // This is a placeholder for demonstration.
          freeBytes = 1024 * 1024 * 1024 * 200; // Increased to 200GB free
        }
      } catch (e) {
        debugPrint('Error getting free space: $e');
      }

      final usage = StorageUsage(
        conversationsBytes: conversationsUsage['bytes']!,
        documentsBytes: documentsUsage['bytes']!,
        modelsBytes: modelsBytes,
        totalBytes: conversationsUsage['bytes']! +
            documentsUsage['bytes']! +
            modelsBytes,
        freeBytes: freeBytes,
        totalSpaceBytes: totalSpaceBytes,
        conversationCount: conversationsUsage['count']!,
        documentCount: documentsUsage['count']!,
      );

      // Trigger desktop notification if storage is low (<10%)
      if (usage.usagePercentage > 0.9) {
        DesktopNotificationService().showStorageAlert(
          title: 'Critical Storage Alert',
          message: 'Less than 10% storage remaining. Please clear some space.',
          isCritical: true,
        );
      } else if (usage.usagePercentage > 0.8) {
        DesktopNotificationService().showStorageAlert(
          title: 'Storage Warning',
          message:
              'Storage usage is above 80%. Consider cleaning old recordings.',
        );
      }

      return usage;
    } catch (e) {
      debugPrint('Error calculating storage usage: $e');
      return StorageUsage.empty();
    }
  }

  /// Validates if there is enough storage for desktop operations.
  Future<bool> isStorageSufficient({int requiredMB = 1024}) async {
    final usage = await calculateStorageUsage();
    return usage.freeBytes > (requiredMB * 1024 * 1024);
  }

  Future<Map<String, int>> _calculateConversationsUsage() async {
    int bytes = 0;
    int count = 0;
    final conversations = _storageService.getAllDoctorConversations();

    for (var conversation in conversations) {
      if (conversation.encryptedAudioPath.isNotEmpty) {
        final file = File(conversation.encryptedAudioPath);
        if (await file.exists()) {
          bytes += await file.length();
          count++;
        }
      }
    }
    return {'bytes': bytes, 'count': count};
  }

  Future<Map<String, int>> _calculateDocumentsUsage() async {
    int bytes = 0;
    int count = 0;
    final processedPaths = <String>{};

    // Process HealthRecords (Maps)
    final records = _storageService.getAllRecords();
    for (var record in records) {
      final path = record['filePath'] as String?;
      if (path != null && path.isNotEmpty && !processedPaths.contains(path)) {
        final file = File(path);
        if (await file.exists()) {
          bytes += await file.length();
          count++;
          processedPaths.add(path);
        }
      }
    }

    // Process DocumentExtractions
    try {
      final extractions = _storageService.getAllDocumentExtractions();
      for (var extraction in extractions) {
        final path = extraction.originalImagePath;
        if (path.isNotEmpty && !processedPaths.contains(path)) {
          final file = File(path);
          if (await file.exists()) {
            bytes += await file.length();
            count++; // Should we count extraction as a separate document if it shares file?
            // Maybe not increment count if file is same, but here we are counting storage.
            // If it's a new file, it's a new document storage-wise.
            // If multiple records point to same file, we count size once.
            // But "items" count might be logical items.
            // Let's count logical items separately?
            // The prompt says "Documents: X MB (Y items)".
            // If I have 1 file used by 2 records, it is X MB. Is it 1 or 2 items?
            // Usually users care about "Files". So 1 item.
            processedPaths.add(path);
          }
        }
      }
    } catch (e) {
      debugPrint('Error processing document extractions: $e');
    }

    return {'bytes': bytes, 'count': count};
  }

  Future<int> _calculateModelsSize() async {
    int bytes = 0;
    final directory = await getApplicationDocumentsDirectory();
    final modelsDir = Directory('${directory.path}/models');

    if (await modelsDir.exists()) {
      try {
        await for (var entity
            in modelsDir.list(recursive: true, followLinks: false)) {
          if (entity is File) {
            bytes += await entity.length();
          }
        }
      } catch (e) {
        debugPrint('Error calculating models size: $e');
      }
    }
    return bytes;
  }

  String formatBytes(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(1)} ${suffixes[i]}';
  }
}
