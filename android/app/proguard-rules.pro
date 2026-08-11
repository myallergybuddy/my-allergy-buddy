# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# If your project uses WebView with JS, uncomment the following
# and specify the fully qualified class name to the JavaScript interface
# class:
#-keepclassmembers class fqcn.of.javascript.interface.for.webview {
#   public *;
#}

# Preserve line numbers for Crashlytics / stack traces
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions

# Suppress accessibility warnings
-dontwarn android.view.accessibility.**
-dontwarn android.util.LongArray
-dontwarn android.view.accessibility.AccessibilityNodeInfo
-dontwarn android.view.accessibility.AccessibilityRecord

# Keep Flutter classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep Firebase classes
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Keep camera, scanner, and ML Kit classes
-keep class com.google.android.gms.vision.** { *; }
-keep class com.google.android.gms.common.** { *; }
-keep class com.google.mlkit.** { *; }

# Keep RevenueCat / Play Billing
-keep class com.revenuecat.purchases.** { *; }
-keep class com.android.billingclient.** { *; }

# Suppress reflection warnings
-dontwarn sun.misc.**
-dontwarn java.lang.reflect.**
