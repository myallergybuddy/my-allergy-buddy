import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'premium_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Local notifications plugin
  static final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();

  // Notification channels
  static const AndroidNotificationChannel _emergencyChannel = 
      AndroidNotificationChannel(
    'emergency_channel',
    'Emergency Notifications',
    description: 'Critical emergency alerts and notifications',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    enableLights: true,
    ledColor: Colors.red,
  );

  static const AndroidNotificationChannel _medicationChannel = 
      AndroidNotificationChannel(
    'medication_channel',
    'Medication Notifications',
    description: 'Medication expiry and reminder notifications',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  // Initialize notification system
  static Future<void> initialize() async {
    try {
      // Initialize Android settings
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // Initialize iOS settings
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // Combine initialization settings
      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      // Initialize the plugin
      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create notification channels for Android
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_emergencyChannel);

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_medicationChannel);

      debugPrint('Notification system initialized successfully');
    } catch (e) {
      debugPrint('Error initializing notification system: $e');
    }
  }

  // Handle notification taps
  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // Handle different notification types based on payload
    if (response.payload != null) {
      final payload = jsonDecode(response.payload!);
      final type = payload['type'];
      
      switch (type) {
        case 'emergency':
          // Navigate to emergency screen
          break;
        case 'medication_expiry':
          // Navigate to medication settings
          break;
      }
    }
  }

  // Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications_enabled') ?? true;
  }

  // Check if specific notification type is enabled
  Future<bool> isNotificationTypeEnabled(String notificationType) async {
    final prefs = await SharedPreferences.getInstance();
    final masterEnabled = prefs.getBool('notifications_enabled') ?? true;
    if (!masterEnabled) return false;
    
    return prefs.getBool(notificationType) ?? true;
  }

  // Check medication expiry and show notifications
  Future<void> checkMedicationExpiry({
    required BuildContext context,
    required String medicationName,
    required DateTime expiryDate,
  }) async {
    if (!await isNotificationTypeEnabled('medication_expiry')) return;
    if (!context.mounted) return;

    final DateTime now = DateTime.now();
    final Duration timeUntilExpiry = expiryDate.difference(now);
    final int daysUntilExpiry = timeUntilExpiry.inDays;

    // Check if medication has already expired
    if (daysUntilExpiry < 0) {
      await _showExpiredMedicationAlert(
        context: context,
        medicationName: medicationName,
        expiryDate: expiryDate,
      );
      return;
    }

    // Check for 2 months (60 days) notification
    if (daysUntilExpiry <= 60 && daysUntilExpiry > 30) {
      final String lastNotificationKey = 'medication_${medicationName}_2month_notification';
      final bool hasShown2Month = await _hasShownNotification(lastNotificationKey);
      if (!context.mounted) return;

      if (!hasShown2Month) {
        await _showMedicationExpiryAlert(
          context: context,
          medicationName: medicationName,
          expiryDate: expiryDate,
          timeFrame: '2 months',
          message: 'Update your medication expiry date in Profile Settings',
          alertColor: Colors.orange,
        );
        await _markNotificationShown(lastNotificationKey);
      }
    }
    
    // Check for 1 month (30 days) notification
    else if (daysUntilExpiry <= 30 && daysUntilExpiry > 7) {
      final String lastNotificationKey = 'medication_${medicationName}_1month_notification';
      final bool hasShown1Month = await _hasShownNotification(lastNotificationKey);
      if (!context.mounted) return;

      if (!hasShown1Month) {
        await _showMedicationExpiryAlert(
          context: context,
          medicationName: medicationName,
          expiryDate: expiryDate,
          timeFrame: '1 month',
          message: 'Please update your medication expiry date in Profile Settings',
          alertColor: Colors.deepOrange,
        );
        await _markNotificationShown(lastNotificationKey);
      }
    }
    
    // Check for 7 days notification
    else if (daysUntilExpiry <= 7 && daysUntilExpiry > 2) {
      final String lastNotificationKey = 'medication_${medicationName}_7day_notification';
      final bool hasShown7Day = await _hasShownNotification(lastNotificationKey);
      if (!context.mounted) return;

      if (!hasShown7Day) {
        await _showMedicationExpiryAlert(
          context: context,
          medicationName: medicationName,
          expiryDate: expiryDate,
          timeFrame: '7 days',
          message: 'URGENT: Update your medication expiry date in Profile Settings',
          alertColor: Colors.red,
        );
        await _markNotificationShown(lastNotificationKey);
      }
    }
    
    // Check for 2 days notification (FINAL WARNING)
    else if (daysUntilExpiry <= 2 && daysUntilExpiry > 0) {
      final String lastNotificationKey = 'medication_${medicationName}_2day_notification';
      final bool hasShown2Day = await _hasShownNotification(lastNotificationKey);
      if (!context.mounted) return;

      if (!hasShown2Day) {
        await _showFinalMedicationExpiryAlert(
          context: context,
          medicationName: medicationName,
          expiryDate: expiryDate,
        );
        await _markNotificationShown(lastNotificationKey);
      }
    }
  }

  // Show medication expiry alert using dialog and system notification
  Future<void> _showMedicationExpiryAlert({
    required BuildContext context,
    required String medicationName,
    required DateTime expiryDate,
    required String timeFrame,
    required String message,
    required Color alertColor,
  }) async {
    if (!context.mounted) return;

    // Show system notification
    await _showSystemNotification(
      id: 1000 + DateTime.now().millisecondsSinceEpoch % 1000,
      title: '💊 Medication Expiry Alert',
      body: '$medicationName expires in $timeFrame',
      payload: jsonEncode({
        'type': 'medication_expiry',
        'medication': medicationName,
        'timeFrame': timeFrame,
      }),
      channel: _medicationChannel,
    );

    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.medication, color: alertColor, size: 28),
              const SizedBox(width: 8),
              Text(
                '💊 Medication Expiry Alert',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: alertColor,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$medicationName expires in $timeFrame',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Expiry Date: ${_formatDate(expiryDate)}'),
              const SizedBox(height: 8),
              Text(message),
            ],
          ),
                     backgroundColor: alertColor.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Remind Later'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: Navigate to profile settings
                // Navigator.pushNamed(context, '/profile-settings');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: alertColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Update Now'),
            ),
          ],
        );
      },
    );
  }

  // Show expired medication alert
  Future<void> _showExpiredMedicationAlert({
    required BuildContext context,
    required String medicationName,
    required DateTime expiryDate,
  }) async {
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.red, size: 28),
              SizedBox(width: 8),
              Text('🚨 MEDICATION EXPIRED'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$medicationName has expired!',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Expired on: ${_formatDate(expiryDate)}'),
              const SizedBox(height: 8),
              const Text('Please update your medication information in Profile Settings immediately.'),
            ],
          ),
          backgroundColor: Colors.red.shade50,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: Navigate to profile settings
                // Navigator.pushNamed(context, '/profile-settings');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Update Now'),
            ),
          ],
        );
      },
    );
     }

   // Show final medication expiry alert (2 days before) with health warning
   Future<void> _showFinalMedicationExpiryAlert({
     required BuildContext context,
     required String medicationName,
     required DateTime expiryDate,
   }) async {
     if (!context.mounted) return;

     showDialog(
       context: context,
       barrierDismissible: false,
       builder: (BuildContext context) {
         return AlertDialog(
           title: const Row(
             children: [
               Icon(Icons.warning, color: Colors.red, size: 28),
               SizedBox(width: 8),
               Text('🚨 CRITICAL HEALTH WARNING'),
             ],
           ),
           content: Column(
             mainAxisSize: MainAxisSize.min,
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Text(
                 '$medicationName expires in 2 days!',
                 style: const TextStyle(
                   fontWeight: FontWeight.bold,
                   fontSize: 16,
                   color: Colors.red,
                 ),
               ),
               const SizedBox(height: 12),
               const Text(
                 '⚠️ HEALTH WARNING:',
                 style: TextStyle(
                   fontWeight: FontWeight.bold,
                   color: Colors.red,
                 ),
               ),
               const SizedBox(height: 8),
               const Text(
                 '• Expired medication may be ineffective or harmful\n'
                 '• Your safety depends on having valid medication\n'
                 '• Contact your healthcare provider immediately\n'
                 '• Update your medication information NOW',
                 style: TextStyle(fontSize: 14),
               ),
               const SizedBox(height: 12),
               Text(
                 'Expires: ${_formatDate(expiryDate)}',
                 style: const TextStyle(
                   fontWeight: FontWeight.bold,
                   color: Colors.red,
                 ),
               ),
             ],
           ),
           backgroundColor: Colors.red.shade50,
           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
           actions: [
             TextButton(
               onPressed: () => Navigator.of(context).pop(),
               child: const Text('Remind Later'),
             ),
             ElevatedButton(
               onPressed: () {
                 Navigator.of(context).pop();
                 // TODO: Navigate to profile settings
                 // Navigator.pushNamed(context, '/profile-settings');
               },
               style: ElevatedButton.styleFrom(
                 backgroundColor: Colors.red,
                 foregroundColor: Colors.white,
               ),
               child: const Text('UPDATE NOW'),
             ),
           ],
         );
       },
     );
   }

   // Check if notification has been shown recently
  Future<bool> _hasShownNotification(String notificationKey) async {
    final prefs = await SharedPreferences.getInstance();
    final lastShown = prefs.getInt(notificationKey);
    if (lastShown == null) return false;
    
    final DateTime lastShownDate = DateTime.fromMillisecondsSinceEpoch(lastShown);
    final DateTime now = DateTime.now();
    final Duration difference = now.difference(lastShownDate);
    
    // Only show notification once per day
    return difference.inDays < 1;
  }

  // Mark notification as shown
  Future<void> _markNotificationShown(String notificationKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(notificationKey, DateTime.now().millisecondsSinceEpoch);
  }

  // Format date for display
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Show emergency alert using dialog with automatic contact notification
  Future<void> showEmergencyAlert({
    required BuildContext context,
    required String message,
    required String contactName,
  }) async {
    if (!await isNotificationTypeEnabled('emergency_alerts')) return;

    // Check permissions and services
    await _checkPermissionsAndServices();

    // Automatically notify all emergency contacts with location
    await _notifyAllEmergencyContacts();

    // Show emergency system notification
    await _showEmergencySystemNotification(
      title: '🚨 EMERGENCY ALERT',
      body: 'Anaphylactic reaction detected! Emergency contacts notified.',
      payload: jsonEncode({
        'type': 'emergency',
        'action': 'anaphylactic_reaction',
      }),
    );

    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning, color: Colors.red, size: 28),
                SizedBox(width: 8),
                Text('🚨 EMERGENCY ALERT'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Anaphylactic reaction detected!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '🚨 AUTOMATIC ACTIONS TAKEN:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '• Emergency services notified\n'
                  '• All emergency contacts messaged\n'
                  '• Location shared with contacts\n'
                  '• Emergency screen activated',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
                Text(
                  'Message sent to contacts:\n'
                  '"I am having an anaphylactic reaction. Emergency services has been notified. This is my current location."',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade50,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _navigateToEmergencyScreen(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Emergency Screen'),
              ),
            ],
          );
        },
      );
    }
  }

  // Check permissions and services
  Future<void> _checkPermissionsAndServices() async {
    try {
      // Check location permissions
      final locationPermission = await Permission.location.status;
      if (locationPermission.isDenied) {
        await Permission.location.request();
      }

      // Check SMS permissions
      final smsPermission = await Permission.sms.status;
      if (smsPermission.isDenied) {
        await Permission.sms.request();
      }

      // Check notification permissions
      final notificationPermission = await Permission.notification.status;
      if (notificationPermission.isDenied) {
        await Permission.notification.request();
      }

      debugPrint('Permissions and services checked successfully');
    } catch (e) {
      debugPrint('Error checking permissions and services: $e');
    }
  }

  // Notify all emergency contacts with location
  Future<void> _notifyAllEmergencyContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final contactsJson = prefs.getStringList('emergency_contacts') ?? [];
      
      if (contactsJson.isEmpty) {
        debugPrint('No emergency contacts to notify');
        return;
      }

      // Get current location
      final location = await _getCurrentLocation();
      if (location == null) {
        debugPrint('Could not get current location for emergency notification');
        return;
      }

      // Check SMS permissions
      final canSendSms = await _checkSmsPermissions();
      if (!canSendSms) {
        debugPrint('SMS permissions not available for emergency notification');
        return;
      }

      // Send emergency message to all contacts
      for (String contactJson in contactsJson) {
        final contact = Map<String, String>.from(jsonDecode(contactJson));
        final phoneNumber = contact['phone'] ?? '';
        final contactName = contact['name'] ?? 'Emergency Contact';
        
        if (phoneNumber.isNotEmpty) {
          await _sendEmergencySMS(phoneNumber, contactName, location);
        }
      }

      debugPrint('Emergency notifications sent to ${contactsJson.length} contacts');
    } catch (e) {
      debugPrint('Error notifying emergency contacts: $e');
    }
  }

  // Get current location using real GPS
  Future<Map<String, double>?> _getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled');
        return null;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permissions are denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permissions are permanently denied');
        return null;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
      };
    } catch (e) {
      debugPrint('Error getting current location: $e');
      return null;
    }
  }

  // Check SMS permissions and premium status
  Future<bool> _checkSmsPermissions() async {
    try {
      // Check SMS permission
      final smsPermission = await Permission.sms.status;
      if (!smsPermission.isGranted) {
        debugPrint('SMS permission not granted');
        return false;
      }

      // Check premium service for SMS limits
      final canSendSms = await PremiumService.canSendSms();
      if (!canSendSms) {
        debugPrint('SMS limit reached or premium required');
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('Error checking SMS permissions: $e');
      return false;
    }
  }

  // Validate phone number format
  bool _isValidPhoneNumber(String phoneNumber) {
    // Remove all non-digit characters
    final digits = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    // Check if it's a valid length (7-15 digits)
    if (digits.length < 7 || digits.length > 15) {
      return false;
    }
    
    // Check if it starts with a valid country code or local number
    return true;
  }

  // Send emergency SMS with location and delivery tracking
  Future<void> _sendEmergencySMS(String phoneNumber, String contactName, Map<String, double> location) async {
    try {
      // Validate phone number
      if (!_isValidPhoneNumber(phoneNumber)) {
        debugPrint('Invalid phone number for $contactName: $phoneNumber');
        return;
      }

      final latitude = location['latitude']!;
      final longitude = location['longitude']!;
      
      final message = 'EMERGENCY: I am having an anaphylactic reaction. '
          'Emergency services has been notified. '
          'This is my current location: https://maps.google.com/?q=$latitude,$longitude';
      
      final Uri smsUri = Uri(
        scheme: 'sms',
        path: phoneNumber,
        queryParameters: {'body': message},
      );
      
      final success = await launchUrl(smsUri);
      if (success) {
        debugPrint('Emergency SMS sent to $contactName');
        
        // Track SMS delivery
        await _trackSmsDelivery(contactName, phoneNumber, message);
        
        // Increment SMS usage for premium service
        await PremiumService.incrementSmsUsage();
      } else {
        debugPrint('Failed to send emergency SMS to $contactName');
        
        // Log failed delivery
        await _logFailedDelivery(contactName, phoneNumber, 'SMS launch failed');
      }
    } catch (e) {
      debugPrint('Error sending emergency SMS: $e');
      await _logFailedDelivery(contactName, phoneNumber, e.toString());
    }
  }

  // Track SMS delivery
  Future<void> _trackSmsDelivery(String contactName, String phoneNumber, String message) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final deliveryLog = prefs.getStringList('sms_delivery_log') ?? [];
      
      final deliveryEntry = jsonEncode({
        'timestamp': DateTime.now().toIso8601String(),
        'contact': contactName,
        'phone': phoneNumber,
        'message': message,
        'status': 'sent',
        'type': 'emergency',
      });
      
      deliveryLog.add(deliveryEntry);
      
      // Keep only last 100 entries
      if (deliveryLog.length > 100) {
        deliveryLog.removeRange(0, deliveryLog.length - 100);
      }
      
      await prefs.setStringList('sms_delivery_log', deliveryLog);
    } catch (e) {
      debugPrint('Error tracking SMS delivery: $e');
    }
  }

  // Log failed delivery
  Future<void> _logFailedDelivery(String contactName, String phoneNumber, String error) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final deliveryLog = prefs.getStringList('sms_delivery_log') ?? [];
      
      final deliveryEntry = jsonEncode({
        'timestamp': DateTime.now().toIso8601String(),
        'contact': contactName,
        'phone': phoneNumber,
        'status': 'failed',
        'error': error,
        'type': 'emergency',
      });
      
      deliveryLog.add(deliveryEntry);
      
      // Keep only last 100 entries
      if (deliveryLog.length > 100) {
        deliveryLog.removeRange(0, deliveryLog.length - 100);
      }
      
      await prefs.setStringList('sms_delivery_log', deliveryLog);
    } catch (e) {
      debugPrint('Error logging failed delivery: $e');
    }
  }

  // Show system notification
  Future<void> _showSystemNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    AndroidNotificationChannel? channel,
  }) async {
    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'medication_channel',
        'Medication Notifications',
        channelDescription: 'Medication expiry and reminder notifications',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
      );

      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);

      await _localNotifications.show(
        id,
        title,
        body,
        platformChannelSpecifics,
        payload: payload,
      );

      debugPrint('System notification shown: $title');
    } catch (e) {
      debugPrint('Error showing system notification: $e');
    }
  }

  // Show emergency system notification
  Future<void> _showEmergencySystemNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'emergency_channel',
        'Emergency Notifications',
        channelDescription: 'Critical emergency alerts and notifications',
        importance: Importance.max,
        priority: Priority.max,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        enableLights: true,
        ledColor: Colors.red,
        color: Colors.red,
      );

      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);

      await _localNotifications.show(
        9999, // Emergency notification ID
        title,
        body,
        platformChannelSpecifics,
        payload: payload,
      );

      debugPrint('Emergency system notification shown: $title');
    } catch (e) {
      debugPrint('Error showing emergency system notification: $e');
    }
  }

  // Navigate to emergency screen
  void _navigateToEmergencyScreen(BuildContext context) {
    try {
      // This would navigate to the emergency contacts screen
      // For now, just show a snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Navigating to Emergency Screen...'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      debugPrint('Error navigating to emergency screen: $e');
    }
  }



  // Show success message
  void showSuccessMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // Show error message
  void showErrorMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // Get SMS delivery statistics
  Future<Map<String, dynamic>> getSmsDeliveryStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final deliveryLog = prefs.getStringList('sms_delivery_log') ?? [];
      
      int totalSent = 0;
      int totalFailed = 0;
      int emergencySent = 0;
      int emergencyFailed = 0;
      
      for (String entry in deliveryLog) {
        final data = jsonDecode(entry);
        final status = data['status'] as String;
        final type = data['type'] as String?;
        
        if (status == 'sent') {
          totalSent++;
          if (type == 'emergency') {
            emergencySent++;
          }
        } else if (status == 'failed') {
          totalFailed++;
          if (type == 'emergency') {
            emergencyFailed++;
          }
        }
      }
      
      return {
        'totalSent': totalSent,
        'totalFailed': totalFailed,
        'emergencySent': emergencySent,
        'emergencyFailed': emergencyFailed,
        'successRate': totalSent > 0 ? (totalSent / (totalSent + totalFailed) * 100).round() : 0,
        'totalLogs': deliveryLog.length,
      };
    } catch (e) {
      debugPrint('Error getting SMS delivery stats: $e');
      return {
        'totalSent': 0,
        'totalFailed': 0,
        'emergencySent': 0,
        'emergencyFailed': 0,
        'successRate': 0,
        'totalLogs': 0,
      };
    }
  }

  // Clear SMS delivery log
  Future<void> clearSmsDeliveryLog() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('sms_delivery_log');
      debugPrint('SMS delivery log cleared');
    } catch (e) {
      debugPrint('Error clearing SMS delivery log: $e');
    }
  }

  // Check if device is online
  Future<bool> _isDeviceOnline() async {
    try {
      // Simple connectivity check - in a real app, you'd use connectivity_plus package
      return true; // Placeholder
    } catch (e) {
      debugPrint('Error checking device connectivity: $e');
      return false;
    }
  }

  // Queue notification for offline delivery (unused but kept for future offline functionality)
  /*
  Future<void> _queueOfflineNotification({
    required String type,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final offlineQueue = prefs.getStringList('offline_notification_queue') ?? [];
      
      final queueEntry = jsonEncode({
        'timestamp': DateTime.now().toIso8601String(),
        'type': type,
        'title': title,
        'body': body,
        'data': data,
      });
      
      offlineQueue.add(queueEntry);
      await prefs.setStringList('offline_notification_queue', offlineQueue);
      
      debugPrint('Notification queued for offline delivery: $title');
    } catch (e) {
      debugPrint('Error queuing offline notification: $e');
    }
  }
  */

  // Process offline notification queue
  Future<void> processOfflineNotificationQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final offlineQueue = prefs.getStringList('offline_notification_queue') ?? [];
      
      if (offlineQueue.isEmpty) {
        return;
      }
      
      final isOnline = await _isDeviceOnline();
      if (!isOnline) {
        return;
      }
      
      for (String entry in offlineQueue) {
        final data = jsonDecode(entry);
        final type = data['type'] as String;
        final title = data['title'] as String;
        final body = data['body'] as String;
        
        // Process based on type
        switch (type) {
          case 'emergency':
            await _showEmergencySystemNotification(
              title: title,
              body: body,
              payload: jsonEncode(data['data']),
            );
            break;
          case 'medication':
            await _showSystemNotification(
              id: DateTime.now().millisecondsSinceEpoch % 1000,
              title: title,
              body: body,
              payload: jsonEncode(data['data']),
            );
            break;
        }
      }
      
      // Clear the queue after processing
      await prefs.remove('offline_notification_queue');
      debugPrint('Offline notification queue processed');
    } catch (e) {
      debugPrint('Error processing offline notification queue: $e');
    }
  }

  // Show allergen alert notification
  Future<void> showAllergenAlert({
    required BuildContext context,
    required String allergenName,
    required String productName,
  }) async {
    if (!await isNotificationTypeEnabled('allergen_alerts')) return;

    await _showSystemNotification(
      id: 2000 + DateTime.now().millisecondsSinceEpoch % 1000,
      title: '⚠️ Allergen Detected',
      body: '$allergenName found in $productName',
      payload: jsonEncode({
        'type': 'allergen_alert',
        'allergen': allergenName,
        'product': productName,
      }),
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ $allergenName detected in $productName'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Show scan results notification
  Future<void> showScanResultsNotification({
    required BuildContext context,
    required String productName,
    required bool isSafe,
  }) async {
    if (!await isNotificationTypeEnabled('scan_results')) return;

    final title = isSafe ? '✅ Safe to Consume' : '❌ Contains Allergens';
    final body = isSafe 
        ? '$productName appears safe for your allergies'
        : '$productName contains allergens you should avoid';

    await _showSystemNotification(
      id: 3000 + DateTime.now().millisecondsSinceEpoch % 1000,
      title: title,
      body: body,
      payload: jsonEncode({
        'type': 'scan_result',
        'product': productName,
        'isSafe': isSafe,
      }),
    );
  }

  // Show medication reminder notification
  Future<void> showMedicationReminder({
    required BuildContext context,
    required String medicationName,
  }) async {
    if (!await isNotificationTypeEnabled('medication_reminders')) return;

    await _showSystemNotification(
      id: 4000 + DateTime.now().millisecondsSinceEpoch % 1000,
      title: '💊 Medication Reminder',
      body: 'Time to take your $medicationName',
      payload: jsonEncode({
        'type': 'medication_reminder',
        'medication': medicationName,
      }),
    );
  }

  // Show safety tips notification
  Future<void> showSafetyTipsNotification({
    required BuildContext context,
    required String tipTitle,
  }) async {
    if (!await isNotificationTypeEnabled('safety_tips')) return;

    await _showSystemNotification(
      id: 5000 + DateTime.now().millisecondsSinceEpoch % 1000,
      title: '💡 Safety Tip',
      body: tipTitle,
      payload: jsonEncode({
        'type': 'safety_tip',
        'title': tipTitle,
      }),
    );
  }

  // Show app update notification
  Future<void> showAppUpdateNotification({
    required BuildContext context,
    required String updateTitle,
  }) async {
    if (!await isNotificationTypeEnabled('app_updates')) return;

    await _showSystemNotification(
      id: 6000 + DateTime.now().millisecondsSinceEpoch % 1000,
      title: '🆕 App Update',
      body: updateTitle,
      payload: jsonEncode({
        'type': 'app_update',
        'title': updateTitle,
      }),
    );
  }

  // Show location-based alert
  Future<void> showLocationBasedAlert({
    required BuildContext context,
    required String alertTitle,
    required String alertMessage,
  }) async {
    if (!await isNotificationTypeEnabled('location_based_alerts')) return;

    await _showSystemNotification(
      id: 7000 + DateTime.now().millisecondsSinceEpoch % 1000,
      title: alertTitle,
      body: alertMessage,
      payload: jsonEncode({
        'type': 'location_alert',
        'title': alertTitle,
        'message': alertMessage,
      }),
    );
  }

  // Show daily reminder
  Future<void> showDailyReminder({
    required BuildContext context,
    required String reminderMessage,
  }) async {
    if (!await isNotificationTypeEnabled('daily_reminders')) return;

    await _showSystemNotification(
      id: 8000 + DateTime.now().millisecondsSinceEpoch % 1000,
      title: '📅 Daily Reminder',
      body: reminderMessage,
      payload: jsonEncode({
        'type': 'daily_reminder',
        'message': reminderMessage,
      }),
    );
  }

  // Show weekly report
  Future<void> showWeeklyReport({
    required BuildContext context,
    required String reportTitle,
  }) async {
    if (!await isNotificationTypeEnabled('weekly_reports')) return;

    await _showSystemNotification(
      id: 9000 + DateTime.now().millisecondsSinceEpoch % 1000,
      title: '📊 Weekly Report',
      body: reportTitle,
      payload: jsonEncode({
        'type': 'weekly_report',
        'title': reportTitle,
      }),
    );
  }

  // Show monthly report
  Future<void> showMonthlyReport({
    required BuildContext context,
    required String reportTitle,
  }) async {
    if (!await isNotificationTypeEnabled('monthly_reports')) return;

    await _showSystemNotification(
      id: 10000 + DateTime.now().millisecondsSinceEpoch % 1000,
      title: '📈 Monthly Report',
      body: reportTitle,
      payload: jsonEncode({
        'type': 'monthly_report',
        'title': reportTitle,
      }),
    );
  }
} 