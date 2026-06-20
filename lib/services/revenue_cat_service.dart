import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/revenue_cat_config.dart';
import 'firebase_service.dart';
import 'premium_service.dart';

class RevenueCatService {
  static bool _isInitialized = false;
  static bool _revenueCatConfigured = false;

  static bool get _canUseRevenueCat => !kIsWeb;

  /// Initialize RevenueCat SDK and sync entitlement status to local cache.
  static Future<void> initialize() async {
    if (_isInitialized) return;

    if (!_canUseRevenueCat) {
      _isInitialized = true;
      debugPrint('RevenueCat skipped on web');
      return;
    }

    try {
      if (!RevenueCatConfig.isConfigured) {
        debugPrint(
          'RevenueCat: configure API keys in lib/config/revenue_cat_config.dart',
        );
        _isInitialized = true;
        return;
      }

      await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.info);

      final configuration = PurchasesConfiguration(RevenueCatConfig.apiKey);
      await Purchases.configure(configuration);

      Purchases.addCustomerInfoUpdateListener(_onCustomerInfoUpdated);

      _revenueCatConfigured = true;
      await _syncEntitlementFromRevenueCat();

      _isInitialized = true;
      debugPrint('RevenueCat initialized');
    } catch (e) {
      debugPrint('Error initializing RevenueCat service: $e');
      _isInitialized = true;
    }
  }

  static void _onCustomerInfoUpdated(CustomerInfo customerInfo) {
    _syncPremiumCache(customerInfo);
  }

  static Future<void> _syncEntitlementFromRevenueCat() async {
    if (!_revenueCatConfigured) return;

    try {
      final customerInfo = await Purchases.getCustomerInfo();
      await _syncPremiumCache(customerInfo);
    } catch (e) {
      debugPrint('Error syncing entitlement from RevenueCat: $e');
    }
  }

  static bool _hasPremiumEntitlement(CustomerInfo customerInfo) {
    return customerInfo.entitlements.all[RevenueCatConfig.entitlementId]
            ?.isActive ??
        false;
  }

  static Future<void> _syncPremiumCache(CustomerInfo customerInfo) async {
    final hasPremium = _hasPremiumEntitlement(customerInfo);
    DateTime? expiryDate;

    final entitlement =
        customerInfo.entitlements.all[RevenueCatConfig.entitlementId];
    if (entitlement?.expirationDate != null) {
      expiryDate = DateTime.tryParse(entitlement!.expirationDate!);
    }

    await PremiumService.setPremiumStatus(hasPremium, expiryDate: expiryDate);
  }

  /// Get available subscription products from RevenueCat offerings.
  static Future<List<Map<String, dynamic>>> getProducts() async {
    try {
      if (!_isInitialized) await initialize();

      if (!_revenueCatConfigured) {
        return kDebugMode ? _fallbackProducts() : [];
      }

      final offerings = await Purchases.getOfferings();
      final currentOffering = offerings.current;

      if (currentOffering == null ||
          currentOffering.availablePackages.isEmpty) {
        debugPrint('RevenueCat: no current offering or packages available');
        return kDebugMode ? _fallbackProducts() : [];
      }

      return currentOffering.availablePackages.map(_packageToProductMap).toList();
    } catch (e) {
      debugPrint('Error getting products: $e');
      return kDebugMode ? _fallbackProducts() : [];
    }
  }

  static Map<String, dynamic> _packageToProductMap(Package package) {
    final product = package.storeProduct;
    return {
      'identifier': product.identifier,
      'packageIdentifier': package.identifier,
      'title': product.title,
      'description': product.description,
      'priceString': product.priceString,
      'price': product.price,
      'package': package,
    };
  }

  static List<Map<String, dynamic>> _fallbackProducts() {
    return [
      {
        'identifier': RevenueCatConfig.productWeekly,
        'title': 'Premium Weekly',
        'description': 'Access to all premium features for 1 week',
        'priceString': r'$3.99',
        'price': 3.99,
      },
      {
        'identifier': RevenueCatConfig.productMonthly,
        'title': 'Premium Monthly',
        'description': 'Access to all premium features for 1 month',
        'priceString': r'$8.99',
        'price': 8.99,
      },
      {
        'identifier': RevenueCatConfig.productYearly,
        'title': 'Premium Yearly',
        'description':
            'Access to all premium features for 1 year (Save 30%)',
        'priceString': r'$74.99',
        'price': 74.99,
      },
    ];
  }

  /// Purchase a subscription product via RevenueCat.
  static Future<Map<String, dynamic>?> purchaseProduct(
    Map<String, dynamic> product,
  ) async {
    try {
      if (!_isInitialized) await initialize();

      if (!_revenueCatConfigured) {
        if (kDebugMode) {
          return _simulatePurchase(product);
        }
        return null;
      }

      final package = product['package'] as Package?;
      final CustomerInfo customerInfo;

      if (package != null) {
        customerInfo = await Purchases.purchasePackage(package);
      } else {
        final productId = product['identifier'] as String?;
        if (productId == null) return null;

        final resolvedPackage =
            await _findPackageForProductId(productId);
        if (resolvedPackage != null) {
          customerInfo = await Purchases.purchasePackage(resolvedPackage);
        } else {
          final storeProducts = await Purchases.getProducts([productId]);
          if (storeProducts.isEmpty) {
            debugPrint('RevenueCat: product not found: $productId');
            return null;
          }
          customerInfo =
              await Purchases.purchaseStoreProduct(storeProducts.first);
        }
      }

      await _syncPremiumCache(customerInfo);
      final hasPremium = _hasPremiumEntitlement(customerInfo);

      if (hasPremium) {
        await FirebaseService.logPremiumUpgrade(
          planName: product['identifier']?.toString() ?? 'premium',
          price: (product['price'] as num?)?.toDouble() ?? 0,
        );
      }

      return {
        'hasPremium': hasPremium,
        'productId': product['identifier'],
        'purchaseDate': DateTime.now().toIso8601String(),
      };
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        debugPrint('Purchase cancelled by user');
      } else {
        debugPrint('Purchase error: $errorCode — ${e.message}');
      }
      return null;
    } catch (e) {
      debugPrint('Error purchasing product: $e');
      return null;
    }
  }

  static Future<Package?> _findPackageForProductId(String productId) async {
    try {
      final offerings = await Purchases.getOfferings();
      for (final offering in offerings.all.values) {
        for (final package in offering.availablePackages) {
          if (package.storeProduct.identifier == productId) {
            return package;
          }
        }
      }
    } catch (e) {
      debugPrint('Error finding package for $productId: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> _simulatePurchase(
    Map<String, dynamic> product,
  ) async {
    await PremiumService.setPremiumStatus(true);
    return {
      'hasPremium': true,
      'productId': product['identifier'],
      'purchaseDate': DateTime.now().toIso8601String(),
    };
  }

  /// Check if user has premium access via RevenueCat entitlement.
  static Future<bool> hasPremiumAccess() async {
    try {
      if (!_isInitialized) await initialize();

      if (!_revenueCatConfigured) {
        return PremiumService.isPremiumUser();
      }

      final customerInfo = await Purchases.getCustomerInfo();
      await _syncPremiumCache(customerInfo);
      return _hasPremiumEntitlement(customerInfo);
    } catch (e) {
      debugPrint('Error checking premium access: $e');
      return PremiumService.isPremiumUser();
    }
  }

  /// Get customer info from RevenueCat.
  static Future<Map<String, dynamic>?> getCustomerInfo() async {
    try {
      if (!_isInitialized) await initialize();

      if (!_revenueCatConfigured) {
        final hasPremium = await PremiumService.isPremiumUser();
        final expiryDate = await PremiumService.getPremiumExpiryDate();
        return {
          'hasPremium': hasPremium,
          'expiryDate': expiryDate?.toIso8601String(),
          'originalAppUserId': await getUserId() ?? 'local_user',
        };
      }

      final customerInfo = await Purchases.getCustomerInfo();
      await _syncPremiumCache(customerInfo);

      final entitlement =
          customerInfo.entitlements.all[RevenueCatConfig.entitlementId];

      return {
        'hasPremium': _hasPremiumEntitlement(customerInfo),
        'expiryDate': entitlement?.expirationDate,
        'originalAppUserId': customerInfo.originalAppUserId,
      };
    } catch (e) {
      debugPrint('Error getting customer info: $e');
      return null;
    }
  }

  /// Restore purchases via RevenueCat.
  static Future<Map<String, dynamic>?> restorePurchases() async {
    try {
      if (!_isInitialized) await initialize();

      if (!_revenueCatConfigured) {
        if (kDebugMode) {
          final hasPremium = await PremiumService.isPremiumUser();
          return {'hasPremium': hasPremium, 'restored': hasPremium};
        }
        return null;
      }

      final customerInfo = await Purchases.restorePurchases();
      await _syncPremiumCache(customerInfo);
      final hasPremium = _hasPremiumEntitlement(customerInfo);

      return {
        'hasPremium': hasPremium,
        'restored': hasPremium,
      };
    } catch (e) {
      debugPrint('Error restoring purchases: $e');
      return null;
    }
  }

  /// Get subscription status from RevenueCat.
  static Future<Map<String, dynamic>> getSubscriptionStatus() async {
    try {
      if (!_isInitialized) await initialize();

      if (!_revenueCatConfigured) {
        final hasPremium = await PremiumService.isPremiumUser();
        final expiryDate = await PremiumService.getPremiumExpiryDate();
        return {
          'hasPremium': hasPremium,
          'activeSubscriptions': hasPremium ? [RevenueCatConfig.entitlementId] : [],
          'allPurchasedProductIdentifiers':
              hasPremium ? RevenueCatConfig.productIds : [],
          'latestExpirationDate': expiryDate?.toIso8601String(),
        };
      }

      final customerInfo = await Purchases.getCustomerInfo();
      await _syncPremiumCache(customerInfo);
      final hasPremium = _hasPremiumEntitlement(customerInfo);
      final entitlement =
          customerInfo.entitlements.all[RevenueCatConfig.entitlementId];

      return {
        'hasPremium': hasPremium,
        'activeSubscriptions': hasPremium
            ? [RevenueCatConfig.entitlementId]
            : customerInfo.activeSubscriptions,
        'allPurchasedProductIdentifiers':
            customerInfo.allPurchasedProductIdentifiers,
        'latestExpirationDate': entitlement?.expirationDate,
      };
    } catch (e) {
      debugPrint('Error getting subscription status: $e');
      return {
        'hasPremium': false,
        'activeSubscriptions': [],
        'allPurchasedProductIdentifiers': [],
        'latestExpirationDate': null,
      };
    }
  }

  /// Set RevenueCat app user ID (links purchases to a Firebase/user account).
  static Future<void> setUserId(String userId) async {
    try {
      if (!_isInitialized) await initialize();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', userId);

      if (_revenueCatConfigured) {
        await Purchases.logIn(userId);
      }

      debugPrint('User ID set: $userId');
    } catch (e) {
      debugPrint('Error setting user ID: $e');
    }
  }

  /// Get locally stored user ID.
  static Future<String?> getUserId() async {
    try {
      if (!_isInitialized) await initialize();

      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('user_id');
    } catch (e) {
      debugPrint('Error getting user ID: $e');
      return null;
    }
  }

  /// Simulate premium purchase (debug builds only, when RC is not configured).
  static Future<bool> simulatePremiumPurchase() async {
    if (!kDebugMode) return false;

    try {
      if (!_isInitialized) await initialize();
      return PremiumService.simulatePremiumPurchase();
    } catch (e) {
      debugPrint('Error simulating premium purchase: $e');
      return false;
    }
  }

  /// Simulate premium expiration (debug builds only).
  static Future<bool> simulatePremiumExpiration() async {
    if (!kDebugMode) return false;

    try {
      if (!_isInitialized) await initialize();
      return PremiumService.simulatePremiumExpiration();
    } catch (e) {
      debugPrint('Error simulating premium expiration: $e');
      return false;
    }
  }
}
