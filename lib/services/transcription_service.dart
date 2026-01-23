import 'dart:io';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:path_provider/path_provider.dart';
import 'package:whisper_flutter_new/whisper_flutter_new.dart';
import 'package:path/path.dart' as path;
import '../models/doctor_conversation.dart';

class TranscriptionResult {
  final String fullText;
  final List<ConversationSegment> segments;

  TranscriptionResult(this.fullText, this.segments);
}

/// Service for handling audio transcription using Whisper.cpp (offline).
class TranscriptionService {
  /// Transcribes the given audio file.
  /// 
  /// [encryptedAudio] is the encrypted audio file.
  /// [encryptionKey] is the key used to encrypt the audio.
  /// Returns a [Future] that resolves to the [TranscriptionResult].
  Future<TranscriptionResult> transcribeAudio(File encryptedAudio, {String encryptionKey = '12345678901234567890123456789012'}) async {
    try {
      // 1. Decrypt
      final bytes = await encryptedAudio.readAsBytes();
      if (bytes.length < 16) {
        throw Exception("Invalid audio file");
      }
      
      final iv = encrypt.IV(bytes.sublist(0, 16));
      final cipherText = encrypt.Encrypted(bytes.sublist(16));
      
      final key = encrypt.Key.fromBase64(encryptionKey);
      final encrypter = encrypt.Encrypter(encrypt.AES(key));
      
      final decryptedBytes = encrypter.decryptBytes(cipherText, iv: iv);
      
      // 2. Save decrypted to temp WAV
      final tempDir = await getTemporaryDirectory();
      final tempWavPath = path.join(tempDir.path, 'temp_transcribe.wav');
      final tempWavFile = File(tempWavPath);
      
      // Ensure we write it cleanly
      if (await tempWavFile.exists()) {
        await tempWavFile.delete();
      }
      await tempWavFile.writeAsBytes(decryptedBytes);
      
      // 3. Whisper Transcription
      // Use 'base' model for balance of speed and accuracy.
      final Whisper whisper = Whisper(
        model: WhisperModel.base,
        downloadHost: "https://huggingface.co/ggerganov/whisper.cpp/resolve/main"
      );
      
      final String? whisperVersion = await whisper.getVersion();
      print("Whisper Version: $whisperVersion");
      
      // Enable timestamps to parse segments
      final String rawTranscription = await whisper.transcribe(
        transcribeRequest: TranscribeRequest(
          audio: tempWavPath,
          isTranslate: false,
          isNoTimestamps: false, // Enable timestamps
          splitOnWord: false,
        ),
      );
      
      // Cleanup
      if (await tempWavFile.exists()) {
        await tempWavFile.delete();
      }
      
      // 4. Parse and Process
      return _processTranscription(rawTranscription);
      
    } catch (e) {
      print("Transcription Error: $e");
      // Return empty result on error for now, or rethrow
      return TranscriptionResult("Error transcribing audio: $e", []);
    }
  }

  TranscriptionResult _processTranscription(String rawText) {
    final List<ConversationSegment> segments = [];
    final StringBuffer fullTextBuffer = StringBuffer();
    
    // Regex to match timestamps like [00:00:00.000 --> 00:00:05.000]
    final RegExp regex = RegExp(r'\[(\d{2}:\d{2}:\d{2}\.\d{3}) --> (\d{2}:\d{2}:\d{2}\.\d{3})\]\s*(.*)');
    
    String currentSpeaker = "User"; // Start with User usually
    int lastEndTimeMs = 0;
    
    // Split by lines
    final lines = rawText.split('\n');
    
    for (final line in lines) {
      final match = regex.firstMatch(line.trim());
      if (match != null) {
        final startStr = match.group(1)!;
        final endStr = match.group(2)!;
        final text = match.group(3)?.trim() ?? "";
        
        if (text.isEmpty) continue;
        
        final startTimeMs = _parseTimestamp(startStr);
        final endTimeMs = _parseTimestamp(endStr);
        
        // Speaker Diarization Logic (Silence Gap Heuristic)
        // If gap > 1.5 seconds, switch speaker
        if (startTimeMs - lastEndTimeMs > 1500) {
           currentSpeaker = (currentSpeaker == "User") ? "Doctor" : "User";
        }
        
        segments.add(ConversationSegment(
          text: text,
          startTimeMs: startTimeMs,
          endTimeMs: endTimeMs,
          speaker: currentSpeaker,
        ));
        
        fullTextBuffer.writeln(text);
        lastEndTimeMs = endTimeMs;
      } else {
        // Fallback for lines without timestamps (shouldn't happen with whisper output usually)
        if (line.trim().isNotEmpty) {
           fullTextBuffer.writeln(line.trim());
        }
      }
    }
    
    return TranscriptionResult(fullTextBuffer.toString().trim(), segments);
  }

  int _parseTimestamp(String timestamp) {
    // Format: HH:MM:SS.mmm
    try {
      final parts = timestamp.split(':');
      final hours = int.parse(parts[0]);
      final minutes = int.parse(parts[1]);
      final secondsParts = parts[2].split('.');
      final seconds = int.parse(secondsParts[0]);
      final millis = int.parse(secondsParts[1]);
      
      return (hours * 3600000) + (minutes * 60000) + (seconds * 1000) + millis;
    } catch (e) {
      return 0;
    }
  }
}
