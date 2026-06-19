import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Loads API credentials from secure storage / shared preferences.
class ApiCredentialsService {
  static const _storage = FlutterSecureStorage();
  static const _defaultUsdaKey = 'DEMO_KEY';

  static String _usdaApiKey = _defaultUsdaKey;
  static String? _edamamAppId;
  static String? _edamamAppKey;
  static String? _nutritionixAppId;
  static String? _nutritionixAppKey;

  static Future<void> initialize() async {
    try {
      _usdaApiKey = await _readCredential('usda_api_key') ?? _defaultUsdaKey;
      _edamamAppId = await _readCredential('edamam_app_id');
      _edamamAppKey = await _readCredential('edamam_app_key');
      _nutritionixAppId = await _readCredential('nutritionix_app_id');
      _nutritionixAppKey = await _readCredential('nutritionix_app_key');
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

  static bool get isEdamamConfigured =>
      _hasValidCredential(_edamamAppId) && _hasValidCredential(_edamamAppKey);

  static bool get isNutritionixConfigured =>
      _hasValidCredential(_nutritionixAppId) &&
      _hasValidCredential(_nutritionixAppKey);

  static String? get edamamAppId => _edamamAppId;
  static String? get edamamAppKey => _edamamAppKey;
  static String? get nutritionixAppId => _nutritionixAppId;
  static String? get nutritionixAppKey => _nutritionixAppKey;

  static bool _hasValidCredential(String? value) {
    if (value == null || value.isEmpty) return false;
    return !value.startsWith('YOUR_');
  }
}
