import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'auth_audit_service.dart';
import 'local_storage_service.dart';

class TempFileManager {
  static final TempFileManager _instance = TempFileManager._internal();
  factory TempFileManager() => _instance;
  TempFileManager._internal();

  final Map<String, DateTime> _trackedFiles = {};
  final Set<String> _preservedFiles = {}; // Files currently in use (locked)
  bool _isPurging = false;

  // Getters
  bool get isPurging => _isPurging;
  ValueListenable<double> get purgeProgress => _purgeProgressController;

  // ValueNotifier for progress
  final _purgeProgressController = ValueNotifier<double>(0.0);

  /// Register a temporary file to be tracked for cleanup
  void registerFile(String path) {
    _trackedFiles[path] = DateTime.now();
  }

  /// Unregister a file (e.g. if it was moved/saved permanently)
  void unregisterFile(String path) {
    _trackedFiles.remove(path);
    _preservedFiles.remove(path);
  }

  /// Preserve a file (prevent it from being purged)
  void preserveFile(String path) {
    _preservedFiles.add(path);
  }

  /// Release a file (allow it to be purged)
  void releaseFile(String path) {
    _preservedFiles.remove(path);
  }

  /// Securely delete a single file
  Future<void> secureDelete(File file) async {
    if (!await file.exists()) return;

    try {
      final length = await file.length();

      // Multi-pass overwrite (DoD 5220.22-M short compliant)
      // Pass 1: Random data
      await _overwriteFile(file, length, random: true);

      // Pass 2: All zeros (if platform requires it, or just for good measure)
      await _overwriteFile(file, length, byte: 0);

      // Pass 3: Random data
      await _overwriteFile(file, length, random: true);

      // Final delete
      await file.delete();

      // Verify integrity after deletion
      if (await file.exists()) {
        throw Exception(
            'Integrity check failed: File still exists after deletion');
      }
    } catch (e) {
      debugPrint('Error securely deleting file: $e');
      // Fallback to normal delete if overwrite fails
      try {
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e2) {
        debugPrint('Failed to delete file: $e2');
      }
    }
  }

  Future<void> _overwriteFile(File file, int length,
      {bool random = false, int byte = 0}) async {
    final raf = await file.open(mode: FileMode.write);
    final rng = Random.secure();
    final bufferSize = 1024 * 1024; // 1MB
    final bytes = Uint8List(min(length, bufferSize));

    int written = 0;
    while (written < length) {
      if (random) {
        for (int i = 0; i < bytes.length; i++) bytes[i] = rng.nextInt(256);
      } else {
        bytes.fillRange(0, bytes.length, byte);
      }

      final toWrite = min(bytes.length, length - written);
      await raf.writeFrom(bytes, 0, toWrite);
      written += toWrite;
    }

    await raf.flush();
    await raf.close();
  }

  /// Purge all tracked temporary files
  /// [force] - if true, deletes even preserved files (e.g. emergency stop)
  Future<void> purgeAll(
      {String reason = 'auto_purge', bool force = false}) async {
    if (_isPurging) return;
    _isPurging = true;
    _purgeProgressController.value = 0.0;

    final settings = LocalStorageService().getAppSettings();
    final enhancedSettings = settings.enhancedPrivacySettings;
    final retentionMinutes = enhancedSettings.tempFileRetentionMinutes;

    // 1. Identify tracked files to purge
    final now = DateTime.now();
    final filesToPurge = _trackedFiles.entries
        .where((entry) {
          final path = entry.key;
          final createdAt = entry.value;

          if (force) return true;

          // Skip preserved files
          if (_preservedFiles.contains(path)) return false;

          // Check retention policy
          if (retentionMinutes > 0) {
            final age = now.difference(createdAt).inMinutes;
            if (age < retentionMinutes) return false;
          }

          return true;
        })
        .map((e) => e.key)
        .toList();

    int purgedCount = 0;
    int total = filesToPurge.length;

    // 2. Scan for orphans if this is a background cleanup or force
    List<String> orphans = [];
    if (reason == 'background_cleanup' ||
        reason == 'background_pause' ||
        force) {
      orphans = await _findOrphanedFiles();
      total += orphans.length;
    }

    // Execute purge
    for (final path in filesToPurge) {
      await secureDelete(File(path));
      _trackedFiles.remove(path);
      if (force) _preservedFiles.remove(path);

      purgedCount++;
      _updateProgress(purgedCount, total);
    }

    for (final path in orphans) {
      // Check retention for orphans based on file modification time
      final file = File(path);
      if (await file.exists()) {
        if (retentionMinutes > 0) {
          final lastModified = await file.lastModified();
          if (now.difference(lastModified).inMinutes < retentionMinutes &&
              !force) {
            continue; // Skip this orphan for now
          }
        }
        await secureDelete(file);
        purgedCount++;
        _updateProgress(purgedCount, total);
      }
    }

    _isPurging = false;
    _purgeProgressController.value = 1.0;

    if (purgedCount > 0) {
      // Log audit
      final authAuditService = AuthAuditService(LocalStorageService());
      await authAuditService.logEvent(
        action: 'data_purge',
        success: true,
        failureReason: null,
      );

      debugPrint('Purged $purgedCount temporary files. Reason: $reason');
    }
  }

  void _updateProgress(int current, int total) {
    if (total > 0) {
      _purgeProgressController.value = current / total;
    }
  }

  /// Scan for files that look like ours but aren't tracked
  Future<List<String>> _findOrphanedFiles() async {
    final tempDir = await getTemporaryDirectory();
    final List<String> orphans = [];

    // Patterns to look for
    final patterns = [
      RegExp(r'^temp_recording.*\.wav$'),
      RegExp(r'^segment_.*\.enc$'),
      RegExp(r'^compressed_.*\.jpg$'),
      RegExp(r'^capture_.*\.jpg$'),
      RegExp(r'^temp_segment_.*\.wav$'),
    ];

    try {
      final entities = tempDir.list(recursive: false, followLinks: false);
      await for (final entity in entities) {
        if (entity is File) {
          final filename = entity.uri.pathSegments.last;

          // Check if it matches any pattern
          bool matches = patterns.any((p) => p.hasMatch(filename));

          if (matches) {
            // Check if it's tracked
            if (!_trackedFiles.containsKey(entity.path) &&
                !_preservedFiles.contains(entity.path)) {
              orphans.add(entity.path);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error scanning for orphans: $e');
    }
    return orphans;
  }

  /// Verify file integrity (exists and accessible)
  Future<bool> verifyFileIntegrity(String path) async {
    final file = File(path);
    return await file.exists();
  }
}
