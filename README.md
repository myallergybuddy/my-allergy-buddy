# My Allergy Buddy

Flutter app for scanning food labels and barcodes to help identify potential allergens.

**Launch focus: Android (Google Play) first.** iOS platform code remains for a future launch; no need to configure iOS keys or Firebase until then.

## Android setup (release)

1. **Package ID:** `com.myallergybuddy.app` (already set in `android/app/build.gradle.kts`).
2. **Firebase:** Place `google-services.json` in `android/app/` (see Firebase Console → project **my-allergy-buddy**).
3. **RevenueCat:** Create project at [RevenueCat](https://app.revenuecat.com), add the Android app, and set `androidApiKey` in `lib/config/revenue_cat_config.dart` (`goog_...`). iOS key can stay as placeholder for now.
4. **Google Play Console:** Create subscription products (`premium_weekly`, `premium_monthly`, `premium_yearly`) matching RevenueCat offering IDs and link them in RevenueCat.
5. **Release signing:** Configure a release keystore and signing in `android/app/build.gradle.kts` before uploading to Play Console (do not ship debug signing).

## Local development

```bash
flutter pub get
flutter run
```

`BILLING` permission is declared in `AndroidManifest.xml` for in-app purchases.

## iOS (deferred)

When ready for App Store launch, see `ios/FIREBASE_SETUP.md` and configure `iosApiKey` in `lib/config/revenue_cat_config.dart`.
