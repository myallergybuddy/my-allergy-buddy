import 'package:flutter/foundation.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EncryptionService {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const String _barcodeDatabaseAesKeyName =
      'myallergybuddy_barcode_database_aes_key';
  static const String _legacyPrivateCatalogAesKeyName =
      'private_catalog_aes_key';

  /// AES-256 key for myallergybuddy_barcode_database.
  /// Stored in the platform keystore / Keychain via FlutterSecureStorage —
  /// never written next to the ciphertext in SharedPreferences.
  static encrypt.Key? _cachedPrivateCatalogKey;

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
