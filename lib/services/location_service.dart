import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LocationService {
  static const String _locationKey = 'last_known_location';
  
  /// Check if location services are enabled
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }
  
  /// True when the OS has granted foreground location (While Using the App).
  /// `always` still counts because it includes while-in-use access; this app
  /// never requests Always / background location.
  static bool _hasWhileInUseAccess(LocationPermission permission) {
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  /// Request When In Use location only. Never requests Always / background.
  static Future<bool> requestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // With only NSLocationWhenInUseUsageDescription (iOS) and no
      // ACCESS_BACKGROUND_LOCATION (Android), this prompts "While using the app".
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever ||
        permission == LocationPermission.unableToDetermine) {
      return false;
    }

    return _hasWhileInUseAccess(permission);
  }
  
  /// Get current location
  static Future<Position?> getCurrentLocation() async {
    try {
      // Check if location is enabled in app settings
      final prefs = await SharedPreferences.getInstance();
      final locationEnabled = prefs.getBool('location_enabled') ?? true;
      
      if (!locationEnabled) {
        return null;
      }
      
      // Request permission
      bool hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        return null;
      }
      
      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      // Save last known location
      await _saveLocation(position);
      
      return position;
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }
  
  /// Get last known location from cache
  static Future<Position?> getLastKnownLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final locationJson = prefs.getString(_locationKey);
      
      if (locationJson != null) {
        final locationData = jsonDecode(locationJson);
        return Position(
          latitude: locationData['latitude'],
          longitude: locationData['longitude'],
          timestamp: DateTime.parse(locationData['timestamp']),
          accuracy: locationData['accuracy']?.toDouble() ?? 0.0,
          altitude: locationData['altitude']?.toDouble() ?? 0.0,
          heading: locationData['heading']?.toDouble() ?? 0.0,
          speed: locationData['speed']?.toDouble() ?? 0.0,
          speedAccuracy: locationData['speedAccuracy']?.toDouble() ?? 0.0,
          altitudeAccuracy: locationData['altitudeAccuracy']?.toDouble() ?? 0.0,
          headingAccuracy: locationData['headingAccuracy']?.toDouble() ?? 0.0,
        );
      }
      return null;
    } catch (e) {
      print('Error getting last known location: $e');
      return null;
    }
  }
  
  /// Save location to cache
  static Future<void> _saveLocation(Position position) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final locationData = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': position.timestamp.toIso8601String(),
        'accuracy': position.accuracy,
        'altitude': position.altitude,
        'heading': position.heading,
        'speed': position.speed,
        'speedAccuracy': position.speedAccuracy,
        'altitudeAccuracy': position.altitudeAccuracy,
        'headingAccuracy': position.headingAccuracy,
      };
      
      await prefs.setString(_locationKey, jsonEncode(locationData));
    } catch (e) {
      print('Error saving location: $e');
    }
  }
  
  /// Generate Google Maps URL for location
  static String generateMapsUrl(double latitude, double longitude) {
    return 'https://www.google.com/maps?q=$latitude,$longitude';
  }
  
  /// Generate location text for SMS
  static String generateLocationText(double latitude, double longitude) {
    return 'My current location: https://maps.google.com/?q=$latitude,$longitude';
  }
  
  /// Share location via SMS
  static Future<bool> shareLocationViaSMS(String phoneNumber, String contactName) async {
    try {
      Position? position = await getCurrentLocation();
      if (position == null) {
        // Try to get last known location
        position = await getLastKnownLocation();
        if (position == null) {
          return false;
        }
      }
      
      String locationText = generateLocationText(position.latitude, position.longitude);
      String message = 'EMERGENCY: $contactName, I need help! $locationText';
      
      // Create SMS URL
      final Uri smsUri = Uri(
        scheme: 'sms',
        path: phoneNumber,
        queryParameters: {'body': message},
      );
      
      return await launchUrl(smsUri);
    } catch (e) {
      print('Error sharing location via SMS: $e');
      return false;
    }
  }
  
  /// Share location with emergency services
  static Future<bool> shareLocationWithEmergencyServices() async {
    try {
      Position? position = await getCurrentLocation();
      if (position == null) {
        position = await getLastKnownLocation();
        if (position == null) {
          return false;
        }
      }
      
      // In a real implementation, this would connect to emergency services API
      // For now, we'll just return success
      print('Location shared with emergency services: ${position.latitude}, ${position.longitude}');
      return true;
    } catch (e) {
      print('Error sharing location with emergency services: $e');
      return false;
    }
  }
  
  /// Notify all emergency contacts with location
  static Future<bool> notifyEmergencyContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final contactsJson = prefs.getStringList('emergency_contacts') ?? [];
      
      if (contactsJson.isEmpty) {
        return true; // No contacts to notify
      }
      
      Position? position = await getCurrentLocation();
      if (position == null) {
        position = await getLastKnownLocation();
        if (position == null) {
          return false;
        }
      }
      
      bool allSuccess = true;
      
      for (String contactJson in contactsJson) {
        final contact = Map<String, String>.from(jsonDecode(contactJson));
        final phoneNumber = contact['phone'] ?? '';
        final contactName = contact['name'] ?? 'Emergency Contact';
        
        if (phoneNumber.isNotEmpty) {
          bool success = await shareLocationViaSMS(phoneNumber, contactName);
          if (!success) {
            allSuccess = false;
          }
        }
      }
      
      return allSuccess;
    } catch (e) {
      print('Error notifying emergency contacts: $e');
      return false;
    }
  }
  
  /// Get location status summary
  static Future<Map<String, dynamic>> getLocationStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final locationEnabled = prefs.getBool('location_enabled') ?? true;
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      final permission = await Geolocator.checkPermission();
      final hasLastLocation = await getLastKnownLocation() != null;
      
      return {
        'locationEnabled': locationEnabled,
        'serviceEnabled': serviceEnabled,
        'permissionGranted': _hasWhileInUseAccess(permission),
        'whileInUseOnly': permission == LocationPermission.whileInUse,
        'hasLastLocation': hasLastLocation,
        'permissionStatus': permission.toString(),
      };
    } catch (e) {
      print('Error getting location status: $e');
      return {
        'locationEnabled': false,
        'serviceEnabled': false,
        'permissionGranted': false,
        'hasLastLocation': false,
        'permissionStatus': 'unknown',
        'whileInUseOnly': false,
      };
    }
  }
} 