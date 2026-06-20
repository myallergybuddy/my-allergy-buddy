import 'package:flutter/foundation.dart';

/// RevenueCat configuration constants.
///
/// Launch focus: Android first. Configure [androidApiKey] before release;
/// [iosApiKey] is optional until iOS launch.
///
/// Manual setup:
/// 1. Create a RevenueCat project at https://app.revenuecat.com
/// 2. Add Android app (package: com.myallergybuddy.app); add iOS when ready
/// 3. Paste the public API keys below (Android: goog_..., iOS: appl_...)
/// 4. Create entitlement identifier [entitlementId] and attach subscription products
/// 5. Create products in Google Play Console / App Store Connect with matching IDs
/// 6. Link store products to RevenueCat offerings (default offering recommended)
///
/// iOS: Enable In-App Purchase capability in Xcode (Signing & Capabilities).
/// Android: BILLING permission is already declared in AndroidManifest.xml.
class RevenueCatConfig {
  /// Entitlement identifier in RevenueCat dashboard.
  /// Attach premium_weekly, premium_monthly, and premium_yearly to this entitlement.
  static const String entitlementId = 'premium';

  /// Store product IDs — must match Play Console / App Store Connect exactly.
  static const String productWeekly = 'premium_weekly';
  static const String productMonthly = 'premium_monthly';
  static const String productYearly = 'premium_yearly';

  static const List<String> productIds = [
    productWeekly,
    productMonthly,
    productYearly,
  ];

  /// Public RevenueCat API key for Android (starts with goog_).
  /// RevenueCat → Project Settings → API Keys → App-specific keys → Android
  static const String androidApiKey = 'goog_CuJuvZUFSeqNpuglnSeOloqEmjZ';

  /// Public RevenueCat API key for iOS (starts with appl_).
  /// Optional until iOS launch — placeholder is fine for Android-only builds.
  /// RevenueCat → Project Settings → API Keys → App-specific keys → iOS
  static const String iosApiKey = 'appl_YOUR_IOS_API_KEY';

  static String get apiKey {
    if (kIsWeb) return '';
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return iosApiKey;
      case TargetPlatform.android:
        return androidApiKey;
      default:
        return '';
    }
  }

  static bool get isConfigured {
    final key = apiKey;
    if (key.isEmpty) return false;
    return !key.contains('YOUR_');
  }
}
