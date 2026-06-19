import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  static FirebaseAnalytics? _analytics;
  static FirebaseMessaging? _messaging;
  static FirebaseCrashlytics? _crashlytics;

  /// Initialize Firebase services
  static Future<void> initialize() async {
    try {
      // Initialize Firebase Core
      await Firebase.initializeApp();
      
      // Initialize Analytics
      _analytics = FirebaseAnalytics.instance;
      
      // Initialize Messaging
      _messaging = FirebaseMessaging.instance;
      
      // Initialize Crashlytics
      _crashlytics = FirebaseCrashlytics.instance;
      
      // Configure Crashlytics
      FlutterError.onError = _crashlytics!.recordFlutterFatalError;
      
      // Request notification permissions
      await _requestNotificationPermissions();
      
      // Set up message handlers
      await _setupMessageHandlers();
      
      debugPrint('Firebase services initialized successfully');
    } catch (e) {
      debugPrint('Error initializing Firebase services: $e');
      _crashlytics?.recordError(e, StackTrace.current);
    }
  }

  /// Request notification permissions
  static Future<void> _requestNotificationPermissions() async {
    try {
      final settings = await _messaging?.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      
      debugPrint('User granted permission: ${settings?.authorizationStatus}');
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
    }
  }

  /// Set up Firebase Cloud Messaging handlers
  static Future<void> _setupMessageHandlers() async {
    try {
      // Handle messages when app is in foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Got a message whilst in the foreground!');
        debugPrint('Message data: ${message.data}');

        if (message.notification != null) {
          debugPrint('Message also contained a notification: ${message.notification}');
        }
      });

      // Handle when app is opened from notification
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('A new onMessageOpenedApp event was published!');
        debugPrint('Message data: ${message.data}');
      });

      // Get the token for this device
      final token = await _messaging?.getToken();
      debugPrint('FCM Token: $token');
    } catch (e) {
      debugPrint('Error setting up message handlers: $e');
    }
  }

  /// Log custom analytics event
  static Future<void> logEvent({
    required String name,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      await _analytics?.logEvent(
        name: name,
        parameters: parameters,
      );
    } catch (e) {
      debugPrint('Error logging analytics event: $e');
    }
  }

  /// Log user property
  static Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    try {
      await _analytics?.setUserProperty(name: name, value: value);
    } catch (e) {
      debugPrint('Error setting user property: $e');
    }
  }

  /// Set user ID for analytics
  static Future<void> setUserId(String userId) async {
    try {
      await _analytics?.setUserId(id: userId);
    } catch (e) {
      debugPrint('Error setting user ID: $e');
    }
  }

  /// Log non-fatal error to Crashlytics
  static Future<void> logError(
    dynamic error,
    StackTrace? stackTrace, {
    String? reason,
  }) async {
    try {
      await _crashlytics?.recordError(
        error,
        stackTrace,
        reason: reason,
      );
    } catch (e) {
      debugPrint('Error logging to Crashlytics: $e');
    }
  }

  /// Log custom key-value pair to Crashlytics
  static Future<void> setCustomKey(String key, dynamic value) async {
    try {
      await _crashlytics?.setCustomKey(key, value);
    } catch (e) {
      debugPrint('Error setting custom key: $e');
    }
  }

  /// Set user identifier in Crashlytics
  static Future<void> setUserIdentifier(String identifier) async {
    try {
      await _crashlytics?.setUserIdentifier(identifier);
    } catch (e) {
      debugPrint('Error setting user identifier: $e');
    }
  }

  /// Get FCM token
  static Future<String?> getFCMToken() async {
    try {
      return await _messaging?.getToken();
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  /// Subscribe to a topic
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging?.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from a topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging?.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Error unsubscribing from topic: $e');
    }
  }

  /// Test Crashlytics by forcing a crash
  static void testCrash() {
    debugPrint('Testing Crashlytics - forcing a crash...');
    // Force a crash to test Crashlytics
    throw Exception('Test crash for Crashlytics verification');
  }

  /// Test Crashlytics with custom error
  static void testCustomCrash(String message) {
    debugPrint('Testing Crashlytics with custom message: $message');
    throw Exception('Custom test crash: $message');
  }

  // MARK: - Custom Analytics Events for Allergy App

  /// Log when user scans a product
  static Future<void> logProductScan({
    required String productName,
    required bool hasAllergens,
    required List<String> detectedAllergens,
  }) async {
    await logEvent(
      name: 'product_scan',
      parameters: {
        'product_name': productName,
        'has_allergens': hasAllergens.toString(),
        'detected_allergens': detectedAllergens.join(', '),
        'allergen_count': detectedAllergens.length,
      },
    );
  }

  /// Log when user adds an allergy
  static Future<void> logAllergyAdded({
    required String allergyName,
    required String severity,
  }) async {
    await logEvent(
      name: 'allergy_added',
      parameters: {
        'allergy_name': allergyName,
        'severity': severity,
      },
    );
  }

  /// Log when user removes an allergy
  static Future<void> logAllergyRemoved({
    required String allergyName,
  }) async {
    await logEvent(
      name: 'allergy_removed',
      parameters: {
        'allergy_name': allergyName,
      },
    );
  }

  /// Log when user adds emergency contact
  static Future<void> logEmergencyContactAdded({
    required String relationship,
  }) async {
    await logEvent(
      name: 'emergency_contact_added',
      parameters: {
        'relationship': relationship,
      },
    );
  }

  /// Log when user makes emergency call
  static Future<void> logEmergencyCall({
    required String contactName,
    required String relationship,
  }) async {
    await logEvent(
      name: 'emergency_call',
      parameters: {
        'contact_name': contactName,
        'relationship': relationship,
      },
    );
  }

  /// Log when user upgrades to premium
  static Future<void> logPremiumUpgrade({
    required String planName,
    required double price,
  }) async {
    await logEvent(
      name: 'premium_upgrade',
      parameters: {
        'plan_name': planName,
        'price': price,
      },
    );
  }

  /// Log when user views settings
  static Future<void> logSettingsViewed() async {
    await logEvent(
      name: 'settings_viewed',
    );
  }

  /// Log when user changes notification settings
  static Future<void> logNotificationSettingsChanged({
    required bool enabled,
  }) async {
    await logEvent(
      name: 'notification_settings_changed',
      parameters: {
        'enabled': enabled,
      },
    );
  }

  /// Log when user views scan history
  static Future<void> logScanHistoryViewed() async {
    await logEvent(
      name: 'scan_history_viewed',
    );
  }

  /// Log when user views scan history with details
  static Future<void> logScanHistoryView({
    required int totalScans,
    required bool hasAllergens,
  }) async {
    await logEvent(
      name: 'scan_history_view',
      parameters: {
        'total_scans': totalScans,
        'has_allergens': hasAllergens,
      },
    );
  }

  /// Log when user deletes scan history item
  static Future<void> logScanHistoryDeleted({
    required String productName,
  }) async {
    await logEvent(
      name: 'scan_history_deleted',
      parameters: {
        'product_name': productName,
      },
    );
  }

  /// Log when user clears all scan history
  static Future<void> logScanHistoryCleared() async {
    await logEvent(
      name: 'scan_history_cleared',
    );
  }

  /// Log when user views privacy policy
  static Future<void> logPrivacyPolicyViewed() async {
    await logEvent(
      name: 'privacy_policy_viewed',
    );
  }

  /// Log when user accepts terms
  static Future<void> logTermsAccepted() async {
    await logEvent(
      name: 'terms_accepted',
    );
  }

  /// Log when user sets passcode
  static Future<void> logPasscodeSet() async {
    await logEvent(
      name: 'passcode_set',
    );
  }

  /// Log when user enables location services
  static Future<void> logLocationEnabled({
    required bool enabled,
  }) async {
    await logEvent(
      name: 'location_enabled',
      parameters: {
        'enabled': enabled,
      },
    );
  }

  /// Log app session start
  static Future<void> logAppSessionStart() async {
    await logEvent(
      name: 'app_session_start',
    );
  }

  /// Log app session end
  static Future<void> logAppSessionEnd({
    required int sessionDurationSeconds,
  }) async {
    await logEvent(
      name: 'app_session_end',
      parameters: {
        'session_duration_seconds': sessionDurationSeconds,
      },
    );
  }

  /// Log feature usage
  static Future<void> logFeatureUsage({
    required String featureName,
    Map<String, dynamic>? additionalParams,
  }) async {
    final parameters = <String, dynamic>{
      'feature_name': featureName,
    };
    
    if (additionalParams != null) {
      parameters.addAll(additionalParams);
    }
    
    await logEvent(
      name: 'feature_usage',
      parameters: parameters,
    );
  }
} 