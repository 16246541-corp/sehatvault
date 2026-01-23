import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;

class ConversationRecorderService {
  FlutterSoundRecorder? _recorder;
  bool _isRecorderInitialized = false;

  bool get isRecording => _recorder?.isRecording ?? false;
  bool get isPaused => _recorder?.isPaused ?? false;
  Stream<RecordingDisposition>? get onProgress => _recorder?.onProgress;

  Future<void> init() async {
    if (_isRecorderInitialized) return;

    _recorder = FlutterSoundRecorder();
    await _recorder!.openRecorder();
    await _recorder!.setSubscriptionDuration(const Duration(milliseconds: 100));
    _isRecorderInitialized = true;
  }

  Future<void> dispose() async {
    if (!_isRecorderInitialized) return;
    await _recorder!.closeRecorder();
    _recorder = null;
    _isRecorderInitialized = false;
  }

  /// Starts recording to a temporary file.
  /// Throws [Exception] if permission is not granted or recorder not initialized.
  Future<void> startRecording() async {
    if (!_isRecorderInitialized) {
      await init();
    }

    final status = await Permission.microphone.status;
    if (!status.isGranted) {
      throw Exception('Microphone permission not granted');
    }

    // Start recording to a temporary file
    final tempDir = await getTemporaryDirectory();
    final tempPath = path.join(tempDir.path, 'temp_recording.wav');

    // Ensure the file exists/can be written to
    final file = File(tempPath);
    if (await file.exists()) {
      await file.delete();
    }

    await _recorder!.startRecorder(
      toFile: tempPath,
      codec: Codec.pcm16WAV,
      sampleRate: 16000,
      numChannels: 1,
    );
  }

  Future<void> pauseRecording() async {
    if (!_isRecorderInitialized || !isRecording) return;
    await _recorder!.pauseRecorder();
  }

  Future<void> resumeRecording() async {
    if (!_isRecorderInitialized || !isPaused) return;
    await _recorder!.resumeRecorder();
  }

  /// Stops recording, encrypts the file with AES-256, and saves it to the specified path.
  /// Returns the path to the encrypted file.
  /// [encryptionKey] must be a 32-character string (256 bits) or base64 encoded equivalent.
  Future<String> stopRecordingAndSaveEncrypted({
    required String destinationPath,
    required String encryptionKey,
  }) async {
    if (!_isRecorderInitialized || !isRecording) {
      throw Exception('Recorder is not recording');
    }

    final tempPath = await _recorder!.stopRecorder();

    if (tempPath == null || !File(tempPath).existsSync()) {
      throw Exception('Failed to retrieve recording file');
    }

    // Read the recorded file
    final File recordedFile = File(tempPath);
    final Uint8List fileBytes = await recordedFile.readAsBytes();

    // Encrypt the data
    // We use a random IV for security, and prepend it to the encrypted data
    // so it can be used for decryption.
    final key = encrypt.Key.fromBase64(encryptionKey);
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    final encrypted = encrypter.encryptBytes(fileBytes, iv: iv);

    // Combine IV and Encrypted Bytes: IV (16 bytes) + CipherText
    final combinedData = Uint8List.fromList(iv.bytes + encrypted.bytes);

    // Save to destination
    final destinationFile = File(destinationPath);
    await destinationFile.writeAsBytes(combinedData);

    // Clean up temp file
    await recordedFile.delete();

    return destinationPath;
  }

  /// Helper to generate a secure random key for AES-256 (returns base64 string)
  static String generateRandomKey() {
    final key = encrypt.Key.fromSecureRandom(32);
    return key.base64;
  }
}
