import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../models/doctor_conversation.dart';
import 'local_storage_service.dart';
import 'encryption_service.dart';
import 'biometric_service.dart';
import 'auth_audit_service.dart';

class AudioPlaybackService {
  final LocalStorageService _storageService;
  final EncryptionService _encryptionService;
  final BiometricService _biometricService;

  AudioPlaybackService(
    this._storageService,
    this._encryptionService,
    this._biometricService,
  );

  Future<Uint8List> decryptAudio(String conversationId) async {
    // 1. Get record
    final conversations = _storageService.getAllDoctorConversations();
    final conversation = conversations.firstWhere(
      (c) => c.id == conversationId,
      orElse: () => throw Exception('Conversation not found'),
    );

    // 2. Check Biometrics
    bool authenticated = false;
    final settings = _storageService.getAppSettings();

    // Check if biometric auth is required for sensitive data
    if (!settings.enhancedPrivacySettings.requireBiometricsForSensitiveData) {
      authenticated = true;
    } else {
      try {
        authenticated = await _biometricService.authenticate(
          reason: 'Authenticate to play doctor recording',
          sessionId: _biometricService.sessionId,
        );
      } on BiometricAuthException catch (e) {
        debugPrint('Biometric auth error: ${e.message}');
        authenticated = false;
      }
    }

    if (!authenticated) {
      debugPrint(
          'Biometric authentication failed or disabled. Returning stub audio.');
      // Stub Implementation: Return mock audio bytes with delay
      await Future.delayed(const Duration(seconds: 1));

      // Return 1 second of silence (PCM 16-bit, 16kHz mono = 32000 bytes)
      return Uint8List(32000);
    }

    // 3. Decrypt
    final file = File(conversation.encryptedAudioPath);
    if (!await file.exists()) {
      throw Exception(
          'Audio file not found at ${conversation.encryptedAudioPath}');
    }

    final encryptedBytes = await file.readAsBytes();

    // Audit log
    await _logAudit(conversationId, true);

    try {
      return _encryptionService.decryptData(encryptedBytes);
    } catch (e) {
      debugPrint('Decryption failed: $e');
      await _logAudit(conversationId, false);
      rethrow;
    }
  }

  Future<void> _logAudit(String conversationId, bool success) async {
    final authAuditService = AuthAuditService(_storageService);
    await authAuditService.logEvent(
      action: 'view_recording',
      success: success,
      failureReason:
          success ? null : 'Decryption/Access failed for $conversationId',
    );
  }
}
