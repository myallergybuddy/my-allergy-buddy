import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Loads the free USDA FoodData Central API key.
class ApiCredentialsService {
  static const _storage = FlutterSecureStorage();
  static const _defaultUsdaKey = 'DEMO_KEY';

  static String _usdaApiKey = _defaultUsdaKey;

  static Future<void> initialize() async {
    try {
      _usdaApiKey = await _readCredential('usda_api_key') ?? _defaultUsdaKey;
    } catch (e) {
      if (kDebugMode) {
        print('ApiCredentialsService: init error: $e');
      }
    }
  }

  static Future<String?> _readCredential(String key) async {
    final secure = await _storage.read(key: key);
    if (secure != null && secure.isNotEmpty) return secure;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  static String get usdaApiKey => _usdaApiKey;

  static bool get isUsdaConfigured =>
      _usdaApiKey.isNotEmpty && _usdaApiKey != _defaultUsdaKey;
}
