import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EncryptionService {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const String _keyName = 'passcode_encryption_key';
  static const String _ivName = 'passcode_encryption_iv';
  

  
  /// Get or create encryption key
  static Future<String?> _getEncryptionKey() async {
    String? key = await _secureStorage.read(key: _keyName);
    return key;
  }
  
  /// Get or create initialization vector (IV)
  static Future<String?> _getEncryptionIV() async {
    String? iv = await _secureStorage.read(key: _ivName);
    return iv;
  }
  
  /// Encrypt passcode
  static Future<String> encryptPasscode(String passcode) async {
    try {
      final key = await _getEncryptionKey();
      final iv = await _getEncryptionIV();
      
      final encrypter = encrypt.Encrypter(encrypt.AES(encrypt.Key.fromBase64(key!)));
      final encrypted = encrypter.encrypt(passcode, iv: encrypt.IV.fromBase64(iv!));
      
      return encrypted.base64;
    } catch (e) {
      debugPrint('Encryption error: $e');
      // Fallback to hashing if encryption fails
      return _hashPasscode(passcode);
    }
  }
  
  /// Decrypt passcode
  static Future<String?> decryptPasscode(String encryptedPasscode) async {
    try {
      final key = await _getEncryptionKey();
      final iv = await _getEncryptionIV();
      
      final encrypter = encrypt.Encrypter(encrypt.AES(encrypt.Key.fromBase64(key!)));
      final decrypted = encrypter.decrypt64(encryptedPasscode, iv: encrypt.IV.fromBase64(iv!));
      
      return decrypted;
    } catch (e) {
      debugPrint('Decryption error: $e');
      return null;
    }
  }
  
  /// Hash passcode as fallback (one-way encryption)
  static String _hashPasscode(String passcode) {
    final bytes = utf8.encode(passcode);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  /// Verify passcode (for hashed passcodes)
  static bool verifyPasscode(String inputPasscode, String storedHash) {
    final inputHash = _hashPasscode(inputPasscode);
    return inputHash == storedHash;
  }
  
  /// Check if stored passcode is encrypted or hashed
  static bool isEncrypted(String storedPasscode) {
    try {
      // Try to decode as base64 (encrypted)
      base64.decode(storedPasscode);
      return true;
    } catch (e) {
      // Not base64, likely hashed or plain text
      return false;
    }
  }
  
  /// Check if stored passcode is hashed (SHA-256)
  static bool isHashed(String storedPasscode) {
    // SHA-256 hash is 64 characters long and contains only hex characters
    return storedPasscode.length == 64 && 
           RegExp(r'^[a-fA-F0-9]+$').hasMatch(storedPasscode);
  }
  
  /// Migrate existing plain text passcodes to encrypted
  static Future<void> migratePlainTextPasscode() async {
    final prefs = await SharedPreferences.getInstance();
    final plainTextPasscode = prefs.getString('passcode');
    final isEncrypted = prefs.getBool('passcode_encrypted') ?? false;
    
    if (!isEncrypted && plainTextPasscode != null && 
        plainTextPasscode.length == 4 && 
        !isHashed(plainTextPasscode)) {
      // This is likely a plain text passcode, encrypt it
      final encryptedPasscode = await encryptPasscode(plainTextPasscode);
      await prefs.setString('passcode', encryptedPasscode);
      await prefs.setBool('passcode_encrypted', true);
      debugPrint('Migrated plain text passcode to encrypted format');
    }
  }
  
  /// Clear all encryption keys (for testing or security reset)
  static Future<void> clearEncryptionKeys() async {
    await _secureStorage.delete(key: _keyName);
    await _secureStorage.delete(key: _ivName);
  }
  
  /// Get encryption status
  static Future<Map<String, dynamic>> getEncryptionStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final storedPasscode = prefs.getString('passcode') ?? '';
    final isEncrypted = prefs.getBool('passcode_encrypted') ?? false;
    
    String status = 'None';
    if (storedPasscode.isNotEmpty) {
      if (isEncrypted) {
        status = 'Encrypted (AES-256)';
      } else if (isHashed(storedPasscode)) {
        status = 'Hashed (SHA-256)';
      } else {
        status = 'Plain Text (Legacy)';
      }
    }
    
    return {
      'status': status,
      'isEncrypted': isEncrypted,
      'isHashed': isHashed(storedPasscode),
      'hasPasscode': storedPasscode.isNotEmpty,
    };
  }

  /// Encrypt sensitive data
  static Future<String> encryptData(String data) async {
    try {
      final key = await _getOrGenerateKey();
      final iv = encrypt.IV.fromLength(16);
      final encrypter = encrypt.Encrypter(encrypt.AES(key));
      final encrypted = encrypter.encrypt(data, iv: iv);
      debugPrint('Data encrypted successfully');
      return encrypted.base64;
    } catch (e) {
      debugPrint('Error encrypting data: $e');
      rethrow;
    }
  }

  /// Decrypt sensitive data
  static Future<String> decryptData(String encryptedData) async {
    try {
      final key = await _getOrGenerateKey();
      final iv = encrypt.IV.fromLength(16);
      final encrypter = encrypt.Encrypter(encrypt.AES(key));
      final decrypted = encrypter.decrypt64(encryptedData, iv: iv);
      debugPrint('Data decrypted successfully');
      return decrypted;
    } catch (e) {
      debugPrint('Error decrypting data: $e');
      rethrow;
    }
  }

  /// Generate a secure key
  static Future<encrypt.Key> _getOrGenerateKey() async {
    // On web, use a simpler approach since FlutterSecureStorage has limitations
    if (kIsWeb) {
      // For web, generate a key based on a hash of some browser-specific data
      final keyString = 'myallergybuddy_web_key_2024';
      final bytes = sha256.convert(utf8.encode(keyString)).bytes;
      return encrypt.Key(Uint8List.fromList(bytes.take(32).toList()));
    }
    
    const storage = FlutterSecureStorage();
    String? storedKey = await storage.read(key: 'encryption_key');
    
    if (storedKey != null) {
      return encrypt.Key.fromBase64(storedKey);
    } else {
      // Generate a new key if none exists
      final key = encrypt.Key.fromSecureRandom(32);
      final keyBase64 = key.base64;
      await storage.write(key: 'encryption_key', value: keyBase64);
      return key;
    }
  }
} 