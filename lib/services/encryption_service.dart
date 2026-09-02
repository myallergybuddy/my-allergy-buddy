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
  static const String _barcodeDatabaseAesKeyName =
      'myallergybuddy_barcode_database_aes_key';
  static const String _legacyPrivateCatalogAesKeyName =
      'private_catalog_aes_key';

  /// AES-256 key for myallergybuddy_barcode_database.
  /// Stored in the platform keystore / Keychain via FlutterSecureStorage —
  /// never written next to the ciphertext in SharedPreferences.
  static encrypt.Key? _cachedPrivateCatalogKey;
  

  
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

  /// Encrypt a myallergybuddy_barcode_database JSON blob.
  ///
  /// Format: `v1.<iv_b64>.<cipher_b64>` (AES-256-CBC, random IV per write).
  static Future<String> encryptPrivatePayload(String plaintext) async {
    final key = await _getOrCreatePrivateCatalogKey();
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    final encrypted = encrypter.encrypt(plaintext, iv: iv);
    return 'v1.${iv.base64}.${encrypted.base64}';
  }

  /// Decrypt a payload produced by [encryptPrivatePayload].
  static Future<String> decryptPrivatePayload(String payload) async {
    final parts = payload.split('.');
    if (parts.length != 3 || parts[0] != 'v1') {
      throw const FormatException('Unsupported private payload format');
    }
    final key = await _getOrCreatePrivateCatalogKey();
    final iv = encrypt.IV.fromBase64(parts[1]);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    return encrypter.decrypt64(parts[2], iv: iv);
  }

  /// Encrypt sensitive data (IV-prefixed; same scheme as myallergybuddy_barcode_database).
  static Future<String> encryptData(String data) => encryptPrivatePayload(data);

  /// Decrypt sensitive data produced by [encryptData] / [encryptPrivatePayload].
  static Future<String> decryptData(String encryptedData) =>
      decryptPrivatePayload(encryptedData);

  static Future<encrypt.Key> _getOrCreatePrivateCatalogKey() async {
    if (_cachedPrivateCatalogKey != null) return _cachedPrivateCatalogKey!;

    try {
      final stored = await _secureStorage.read(key: _barcodeDatabaseAesKeyName);
      if (stored != null && stored.isNotEmpty) {
        _cachedPrivateCatalogKey = encrypt.Key.fromBase64(stored);
        return _cachedPrivateCatalogKey!;
      }

      final legacy = await _secureStorage.read(
        key: _legacyPrivateCatalogAesKeyName,
      );
      if (legacy != null && legacy.isNotEmpty) {
        await _secureStorage.write(
          key: _barcodeDatabaseAesKeyName,
          value: legacy,
        );
        _cachedPrivateCatalogKey = encrypt.Key.fromBase64(legacy);
        return _cachedPrivateCatalogKey!;
      }

      final key = encrypt.Key.fromSecureRandom(32);
      await _secureStorage.write(
        key: _barcodeDatabaseAesKeyName,
        value: key.base64,
      );
      _cachedPrivateCatalogKey = key;
      return key;
    } catch (e) {
      // Unit tests and rare plugin failures: session-only key (not persisted).
      debugPrint(
        'EncryptionService: Secure storage unavailable for myallergybuddy_barcode_database: $e',
      );
      _cachedPrivateCatalogKey ??= encrypt.Key.fromSecureRandom(32);
      return _cachedPrivateCatalogKey!;
    }
  }

  @visibleForTesting
  static void resetPrivateCatalogKeyForTest() {
    _cachedPrivateCatalogKey = null;
  }
} 