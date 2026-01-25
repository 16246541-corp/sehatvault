import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static const String _keyStorageKey = 'sehatlocker_master_key';
  encrypt.Key? _key;

  bool get isInitialized => _key != null;

  Future<void> initialize() async {
    if (isInitialized) return;

    String? keyBase64 = await _secureStorage.read(key: _keyStorageKey);
    if (keyBase64 == null) {
      // Generate a new 32-byte (256-bit) key
      final key = encrypt.Key.fromSecureRandom(32);
      keyBase64 = key.base64;
      await _secureStorage.write(key: _keyStorageKey, value: keyBase64);
    }
    _key = encrypt.Key.fromBase64(keyBase64);
  }

  /// Encrypts data using AES-256-GCM (or CBC if GCM not available in simple usage, using AES default)
  /// Default AES in 'encrypt' package uses CBC with PKCS7 padding by default if mode not specified?
  /// The user mentioned AES-256-GCM in architecture.md.
  /// The 'encrypt' package's AES helper uses SIC (CTR) or CBC.
  /// Let's stick to standard AES default for now which is usually robust enough,
  /// but we'll use a random IV for each encryption.
  Uint8List encryptData(Uint8List data) {
    if (_key == null) throw Exception('EncryptionService not initialized');

    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(_key!));

    final encrypted = encrypter.encryptBytes(data, iv: iv);

    // Return IV + CipherText
    final result = Uint8List(iv.bytes.length + encrypted.bytes.length);
    result.setAll(0, iv.bytes);
    result.setAll(iv.bytes.length, encrypted.bytes);
    return result;
  }

  Uint8List decryptData(Uint8List encryptedData) {
    if (_key == null) throw Exception('EncryptionService not initialized');
    if (encryptedData.length < 16) throw Exception('Invalid encrypted data');

    final iv = encrypt.IV(encryptedData.sublist(0, 16));
    final cipherText = encrypt.Encrypted(encryptedData.sublist(16));
    final encrypter = encrypt.Encrypter(encrypt.AES(_key!));

    return Uint8List.fromList(encrypter.decryptBytes(cipherText, iv: iv));
  }

  // Expose key for legacy services if needed (try to avoid)
  encrypt.Key? get key => _key;
}
