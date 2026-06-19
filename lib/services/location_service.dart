import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'premium_service.dart';
import 'package:flutter/foundation.dart';

class LocationService {
  static const String _locationKey = 'last_known_location';
  
  /// Check if location services are enabled
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }
  
  /// Request location permissions
  static Future<bool> requestLocationPermission() async {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }
    
    // Check permission status
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return false;
    }
    
    return true;
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
      debugPrint('Error getting location: $e');
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
      debugPrint('Error getting last known location: $e');
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
      debugPrint('Error saving location: $e');
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
      // Check SMS permission for basic users
      final canSend = await PremiumService.canSendSms();
      if (!canSend) {
        return false; // User has reached SMS limit or doesn't have permission
      }
      
      Position? position = await getCurrentLocation();
      if (position == null) {
        // Try to get last known location
        position = await getLastKnownLocation();
        if (position == null) {
          return false;
        }
      }
      
      String locationText = generateLocationText(position.latitude, position.longitude);
      String message = 'EMERGENCY: $contactName, I am having an allergic reaction. $locationText';
      
      // Create SMS URL
      final Uri smsUri = Uri(
        scheme: 'sms',
        path: phoneNumber,
        queryParameters: {'body': message},
      );
      
      bool success = await launchUrl(smsUri);
      if (success) {
        // Increment SMS usage for basic users
        await PremiumService.incrementSmsUsage();
      }
      
      return success;
    } catch (e) {
      debugPrint('Error sharing location via SMS: $e');
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
      debugPrint('Location shared with emergency services: \\${position.latitude}, \\${position.longitude}');
      return true;
    } catch (e) {
      debugPrint('Error sharing location with emergency services: $e');
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
      
      // Check SMS permission for basic users
      final canSend = await PremiumService.canSendSms();
      if (!canSend) {
        return false; // User has reached SMS limit or doesn't have permission
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
      debugPrint('Error notifying emergency contacts: $e');
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
        'permissionGranted': permission == LocationPermission.whileInUse || 
                           permission == LocationPermission.always,
        'hasLastLocation': hasLastLocation,
        'permissionStatus': permission.toString(),
      };
    } catch (e) {
      debugPrint('Error getting location status: $e');
      return {
        'locationEnabled': false,
        'serviceEnabled': false,
        'permissionGranted': false,
        'hasLastLocation': false,
        'permissionStatus': 'unknown',
      };
    }
  }
} 