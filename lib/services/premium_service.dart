import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class PremiumService {
  static const String _premiumKey = 'is_premium_user';
  static const String _premiumExpiryKey = 'premium_expiry_date';
  static const String _smsUsageKey = 'sms_usage_count';
  static const String _smsResetDateKey = 'sms_reset_date';
  
  /// Premium features available
  static const List<String> premiumFeatures = [
    'Advanced allergen database (10,000+ allergens)',
    'Custom allergen alerts',
    'Increased emergency contacts (up to 10 contacts)',
    'Premium customer support',
    'Custom emergency contact groups',
    'Unlimited emergency SMS alerts',
  ];
  
  /// Check if user has premium access
  static Future<bool> isPremiumUser() async {
    // Debug/test builds: unlock all premium features without payment.
    if (kDebugMode) {
      return true;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final isPremium = prefs.getBool(_premiumKey) ?? false;
      
      if (isPremium) {
        // Check if premium has expired
        final expiryDate = prefs.getString(_premiumExpiryKey);
        if (expiryDate != null) {
          final expiry = DateTime.tryParse(expiryDate);
          if (expiry != null && DateTime.now().isAfter(expiry)) {
            // Premium has expired
            await _setPremiumStatus(false);
            return false;
          }
        }
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('Error checking premium status: $e');
      return false;
    }
  }
  
  /// Set premium status
  static Future<void> setPremiumStatus(bool isPremium, {DateTime? expiryDate}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_premiumKey, isPremium);
      
      if (expiryDate != null) {
        await prefs.setString(_premiumExpiryKey, expiryDate.toIso8601String());
      } else if (isPremium) {
        // Set default expiry to 1 year from now
        final defaultExpiry = DateTime.now().add(const Duration(days: 365));
        await prefs.setString(_premiumExpiryKey, defaultExpiry.toIso8601String());
      } else {
        // Remove expiry date if not premium
        await prefs.remove(_premiumExpiryKey);
      }
    } catch (e) {
      debugPrint('Error setting premium status: $e');
    }
  }
  
  /// Set premium status (private method)
  static Future<void> _setPremiumStatus(bool isPremium) async {
    await setPremiumStatus(isPremium);
  }
  
  /// Get premium expiry date
  static Future<DateTime?> getPremiumExpiryDate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final expiryDate = prefs.getString(_premiumExpiryKey);
      if (expiryDate != null) {
        return DateTime.tryParse(expiryDate);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting premium expiry date: $e');
      return null;
    }
  }
  
  /// Simulate premium purchase (for testing)
  static Future<bool> simulatePremiumPurchase() async {
    try {
      await setPremiumStatus(true);
      debugPrint('Premium purchase simulated successfully');
      return true;
    } catch (e) {
      debugPrint('Error simulating premium purchase: $e');
      return false;
    }
  }
  
  /// Simulate premium expiration (for testing)
  static Future<bool> simulatePremiumExpiration() async {
    try {
      await setPremiumStatus(false);
      debugPrint('Premium expiration simulated successfully');
      return true;
    } catch (e) {
      debugPrint('Error simulating premium expiration: $e');
      return false;
    }
  }
  
  /// Get days remaining in premium subscription
  static Future<int> getDaysRemaining() async {
    final expiryDate = await getPremiumExpiryDate();
    if (expiryDate == null) return 0;
    
    final now = DateTime.now();
    final difference = expiryDate.difference(now);
    return difference.inDays;
  }
  
  /// Check if premium feature is available
  static Future<bool> hasPremiumFeature(String feature) async {
    try {
      final isPremium = await isPremiumUser();
      return isPremium && premiumFeatures.contains(feature);
    } catch (e) {
      debugPrint('Error checking premium feature "$feature": $e');
      return false;
    }
  }
  
  /// Validate if a feature name is valid
  static bool isValidFeature(String feature) {
    return premiumFeatures.contains(feature);
  }
  
  /// Get all available premium features
  static List<String> getAvailableFeatures() {
    return List.from(premiumFeatures);
  }
  
  /// Get premium subscription plans
  static List<PremiumPlan> getPremiumPlans() {
    return [
      PremiumPlan(
        id: 'weekly',
        name: 'Weekly Premium',
        price: 3.99,
        currency: 'AUD',
        duration: '1 week',
        description: 'Full premium access for 1 week',
        features: premiumFeatures,
        isPopular: false,
      ),
      PremiumPlan(
        id: 'monthly',
        name: 'Monthly Premium',
        price: 8.99,
        currency: 'AUD',
        duration: '1 month',
        description: 'Full premium access for 1 month',
        features: premiumFeatures,
        isPopular: false,
      ),
      PremiumPlan(
        id: 'yearly',
        name: 'Yearly Premium',
        price: 74.99,
        currency: 'AUD',
        duration: '12 months',
        description: 'Full premium access for 12 months (Save 30%)',
        features: premiumFeatures,
        isPopular: true,
        savings: 'Save 30%',
      ),
    ];
  }
  

  
  /// Get premium status summary
  static Future<Map<String, dynamic>> getPremiumStatus() async {
    final isPremium = await isPremiumUser();
    final expiryDate = await getPremiumExpiryDate();
    final daysRemaining = await getDaysRemaining();
    
    return {
      'isPremium': isPremium,
      'expiryDate': expiryDate?.toIso8601String(),
      'daysRemaining': daysRemaining,
      'features': premiumFeatures,
    };
  }
  
  /// Get free plan limits
  static Map<String, dynamic> getFreePlanLimits() {
    return {
      'allergenDatabase': 'Basic database (1,000+ allergens)',
      'emergencyContacts': 'Up to 1 emergency contact',
      'customerSupport': 'Standard support',
      'customAlerts': 'Basic alerts only',
    };
  }
  
  /// Get premium plan benefits
  static Map<String, dynamic> getPremiumPlanBenefits() {
    return {
      'allergenDatabase': 'Advanced database (10,000+ allergens)',
      'emergencyContacts': 'Up to 10 emergency contacts',
      'customerSupport': 'Priority premium support',
      'customAlerts': 'Advanced custom alerts',
    };
  }

  /// Get current SMS usage count for the month
  static Future<int> getSmsUsageCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final resetDate = prefs.getString(_smsResetDateKey);
      final now = DateTime.now();
      
      // Check if we need to reset the counter (new month)
      if (resetDate != null) {
        final lastReset = DateTime.parse(resetDate);
        if (now.year != lastReset.year || now.month != lastReset.month) {
          // New month, reset counter
          await prefs.setInt(_smsUsageKey, 0);
          await prefs.setString(_smsResetDateKey, now.toIso8601String());
          return 0;
        }
      } else {
        // First time, set reset date
        await prefs.setString(_smsResetDateKey, now.toIso8601String());
        await prefs.setInt(_smsUsageKey, 0);
        return 0;
      }
      
      return prefs.getInt(_smsUsageKey) ?? 0;
    } catch (e) {
      debugPrint('Error getting SMS usage count: $e');
      return 0;
    }
  }

  /// Increment SMS usage count
  static Future<void> incrementSmsUsage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentCount = await getSmsUsageCount();
      await prefs.setInt(_smsUsageKey, currentCount + 1);
    } catch (e) {
      debugPrint('Error incrementing SMS usage: $e');
    }
  }

  /// Check if user can send SMS (basic users limited to 1 per month)
  static Future<bool> canSendSms() async {
    try {
      final isPremium = await isPremiumUser();
      if (isPremium) {
        return true; // Premium users have unlimited SMS
      }
      
      final usageCount = await getSmsUsageCount();
      return usageCount < 1; // Basic users limited to 1 SMS per month
    } catch (e) {
      debugPrint('Error checking SMS permission: $e');
      return false;
    }
  }

  /// Get SMS usage info for display
  static Future<Map<String, dynamic>> getSmsUsageInfo() async {
    try {
      final isPremium = await isPremiumUser();
      final usageCount = await getSmsUsageCount();
      
      return {
        'isPremium': isPremium,
        'usageCount': usageCount,
        'limit': isPremium ? -1 : 1, // -1 means unlimited
        'canSend': await canSendSms(),
        'remaining': isPremium ? -1 : (1 - usageCount),
      };
    } catch (e) {
      debugPrint('Error getting SMS usage info: $e');
      return {
        'isPremium': false,
        'usageCount': 0,
        'limit': 1,
        'canSend': false,
        'remaining': 0,
      };
    }
  }
}

class PremiumPlan {
  final String id;
  final String name;
  final double price;
  final String currency;
  final String duration;
  final String description;
  final List<String> features;
  final bool isPopular;
  final String? savings;
  
  PremiumPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.currency,
    required this.duration,
    required this.description,
    required this.features,
    required this.isPopular,
    this.savings,
  });
} 