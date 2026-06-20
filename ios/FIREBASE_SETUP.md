# iOS Firebase setup

> **Note:** iOS launch is deferred. The app is Android-first for now; complete these steps when you are ready to ship on the App Store.

Android uses `android/app/google-services.json`. iOS requires a separate config file.

## Required steps (manual, on Mac with Xcode)

1. Open [Firebase Console](https://console.firebase.google.com) → project **my-allergy-buddy**.
2. Add an **iOS app** (or open the existing one) with bundle ID **`com.myallergybuddy.app`** (must match `PRODUCT_BUNDLE_IDENTIFIER` in `Runner.xcodeproj`).
3. Download **`GoogleService-Info.plist`** from Firebase.
4. Place it at **`ios/Runner/GoogleService-Info.plist`** (not the `.example` file).
5. In Xcode, add the plist to the **Runner** target (Copy items if needed + target membership).
6. Run `cd ios && pod install` after `flutter pub get` (requires CocoaPods on macOS).

See `Runner/GoogleService-Info.plist.example` for the expected structure. **Do not commit real credentials** — `GoogleService-Info.plist` is listed in `ios/.gitignore`.

## Push notifications (optional)

If you use Firebase Cloud Messaging on iOS, also enable **Push Notifications** and **Background Modes → Remote notifications** in Xcode, and upload your APNs key in Firebase Console.
