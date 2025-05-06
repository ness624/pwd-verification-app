// security_utils.dart
import 'dart:convert';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pwd_verification_app/core/utils/logger.dart';

class SecurityUtils {
  static const String _keyName = 'encryption_key';
  final FlutterSecureStorage _secureStorage;
  Key? _encryptionKey;
  
  SecurityUtils(this._secureStorage);
  
  Future<void> initialize() async {
    try {
      // Try to load existing key from secure storage
      final savedKey = await _secureStorage.read(key: _keyName);
      
      if (savedKey != null) {
        // Use existing key
        _encryptionKey = Key.fromBase64(savedKey);
      } else {
        // Generate and save a new key
        await _generateAndSaveKey();
      }
    } catch (e) {
      AppLogger.error('SecurityUtils', 'Error initializing security utils: $e');
      // If there's an error, generate a new key
      await _generateAndSaveKey();
    }
  }
  
  Future<void> _generateAndSaveKey() async {
    try {
      // Generate a new encryption key
      final key = Key.fromSecureRandom(32);
      _encryptionKey = key;
      
      // Save the key to secure storage
      await _secureStorage.write(
        key: _keyName,
        value: key.base64,
      );
    } catch (e) {
      AppLogger.error('SecurityUtils', 'Error generating and saving key: $e');
      throw Exception('Failed to initialize encryption: $e');
    }
  }
  
  Future<String?> decrypt(String encryptedText, IV iv) async {
    try {
      if (_encryptionKey == null) {
        await initialize();
      }
      
      final encrypter = Encrypter(
        AES(_encryptionKey!, mode: AESMode.cbc),
      );
      
      final encrypted = Encrypted.fromBase64(encryptedText);
      final decrypted = encrypter.decrypt(encrypted, iv: iv);
      
      return decrypted;
    } catch (e) {
      AppLogger.error('SecurityUtils', 'Error during decryption: $e');
      return null;
    }
  }
  
  Future<String?> encrypt(String plainText) async {
    try {
      if (_encryptionKey == null) {
        await initialize();
      }
      
      final encrypter = Encrypter(
        AES(_encryptionKey!, mode: AESMode.cbc),
      );
      
      final iv = generateIV();
      final encrypted = encrypter.encrypt(plainText, iv: iv);
      
      // Return IV and encrypted data together
      return '${iv.base64}:${encrypted.base64}';
    } catch (e) {
      AppLogger.error('SecurityUtils', 'Error during encryption: $e');
      return null;
    }
  }
  
  // Added method for QR service
  IV generateIV() {
    return IV.fromSecureRandom(16);
  }
  
  // Added sync method for QR service
  String encryptSync(String plainText, IV iv) {
    if (_encryptionKey == null) {
      throw Exception('Encryption key not initialized');
    }
    
    final encrypter = Encrypter(
      AES(_encryptionKey!, mode: AESMode.cbc),
    );
    
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return encrypted.base64;
  }
}