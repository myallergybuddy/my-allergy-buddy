import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'encryption_service.dart';

/// AES-256 storage for on-device health records.
///
/// Ciphertext uses the same `v1.<iv>.<cipher>` format as the private barcode
/// catalog. Existing plain JSON is encrypted in place the next time it is read.
class HealthRecordStore {
  static bool _isEncrypted(String value) => value.startsWith('v1.');

  static Future<String?> readString(
    SharedPreferences prefs,
    String key,
  ) async {
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return raw;
    if (!_isEncrypted(raw)) {
      await writeString(prefs, key, raw);
      return raw;
    }
    try {
      return await EncryptionService.decryptData(raw);
    } catch (e) {
      debugPrint('HealthRecordStore: could not decrypt $key: $e');
      return null;
    }
  }

  static Future<void> writeString(
    SharedPreferences prefs,
    String key,
    String value,
  ) async {
    final encrypted = await EncryptionService.encryptData(value);
    await prefs.setString(key, encrypted);
  }

  static Future<List<String>> readStringList(
    SharedPreferences prefs,
    String key,
  ) async {
    final raw = prefs.getStringList(key);
    if (raw == null) return <String>[];

    final plain = <String>[];
    var needsMigration = false;
    var decryptFailed = false;
    for (final item in raw) {
      if (item.isEmpty || !_isEncrypted(item)) {
        if (item.isNotEmpty) needsMigration = true;
        plain.add(item);
        continue;
      }
      try {
        plain.add(await EncryptionService.decryptData(item));
      } catch (e) {
        decryptFailed = true;
        debugPrint('HealthRecordStore: could not decrypt $key item: $e');
      }
    }

    if (needsMigration && !decryptFailed) {
      await writeStringList(prefs, key, plain);
    }
    return plain;
  }

  static Future<void> writeStringList(
    SharedPreferences prefs,
    String key,
    List<String> values,
  ) async {
    final encrypted = <String>[];
    for (final value in values) {
      encrypted.add(await EncryptionService.encryptData(value));
    }
    await prefs.setStringList(key, encrypted);
  }
}
