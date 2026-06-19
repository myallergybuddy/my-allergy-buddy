import 'package:flutter/foundation.dart';
import 'premium_service.dart';

class PremiumProductService {
  // Premium products database containing products with all allergens
  static final Map<String, Map<String, dynamic>> _premiumProductDatabase = {
    // BODY CARE PRODUCTS
    '9300605001000': { // Dove Sensitive Skin Body Wash
      'name': 'Dove Sensitive Skin Body Wash',
      'brand': 'Dove',
      'category': 'body_care',
      'ingredients': [
        'water',
        'sodium lauryl sulfate',
        'cocamidopropyl betaine',
        'glycerin',
        'stearic acid',
        'cetyl alcohol',
        'fragrance',
        'tocopheryl acetate',
        'guar hydroxypropyltrimonium chloride',
        'tetrasodium edta',
        'methylchloroisothiazolinone',
        'methylisothiazolinone',
        'wheat protein',
        'milk protein',
        'soy protein',
        'almond oil',
        'peanut oil',
        'coconut oil',
        'sesame oil',
        'fish oil',
        'egg protein',
        'shellfish extract'
      ],
      'allergens': ['wheat', 'milk', 'soy', 'tree_nuts', 'peanuts', 'fish', 'eggs', 'shellfish', 'sesame'],
      'image': null,
      'premium_only': true,
    },
    '9300605001001': { // Nivea Men Sensitive Shower Gel
      'name': 'Nivea Men Sensitive Shower Gel',
      'brand': 'Nivea',
      'category': 'body_care',
      'ingredients': [
        'water',
        'sodium laureth sulfate',
        'cocamidopropyl betaine',
        'glycerin',
        'lauryl glucoside',
        'sodium chloride',
        'fragrance',
        'panthenol',
        'bisabolol',
        'tetrasodium edta',
        'methylchloroisothiazolinone',
        'methylisothiazolinone',
        'wheat extract',
        'milk protein',
        'soy lecithin',
        'almond extract',
        'peanut oil',
        'coconut oil',
        'sesame seed oil',
        'fish collagen',
        'egg white protein',
        'oyster shell powder'
      ],
      'allergens': ['wheat', 'milk', 'soy', 'tree_nuts', 'peanuts', 'fish', 'eggs', 'shellfish', 'sesame'],
      'image': null,
      'premium_only': true,
    },
    '9300605001002': { // Palmolive Naturals Body Wash
      'name': 'Palmolive Naturals Body Wash',
      'brand': 'Palmolive',
      'category': 'body_care',
      'ingredients': [
        'water',
        'sodium laureth sulfate',
        'cocamidopropyl betaine',
        'glycerin',
        'sodium chloride',
        'fragrance',
        'aloe barbadensis leaf juice',
        'chamomile extract',
        'lavender extract',
        'tetrasodium edta',
        'methylchloroisothiazolinone',
        'methylisothiazolinone',
        'wheat germ oil',
        'milk protein',
        'soy protein',
        'almond oil',
        'peanut butter',
        'coconut milk',
        'sesame oil',
        'fish oil',
        'egg yolk',
        'shrimp extract'
      ],
      'allergens': ['wheat', 'milk', 'soy', 'tree_nuts', 'peanuts', 'fish', 'eggs', 'shellfish', 'sesame'],
      'image': null,
      'premium_only': true,
    },

    // SKIN CARE PRODUCTS
    '9300605002000': { // Cetaphil Daily Facial Cleanser
      'name': 'Cetaphil Daily Facial Cleanser',
      'brand': 'Cetaphil',
      'category': 'skin_care',
      'ingredients': [
        'water',
        'cetyl alcohol',
        'propylene glycol',
        'sodium lauryl sulfate',
        'stearyl alcohol',
        'methylparaben',
        'propylparaben',
        'butylparaben',
        'fragrance',
        'wheat protein',
        'milk protein',
        'soy protein',
        'almond oil',
        'peanut oil',
        'coconut oil',
        'sesame oil',
        'fish collagen',
        'egg white',
        'oyster shell'
      ],
      'allergens': ['wheat', 'milk', 'soy', 'tree_nuts', 'peanuts', 'fish', 'eggs', 'shellfish', 'sesame'],
      'image': null,
      'premium_only': true,
    },
    '9300605002001': { // Neutrogena Ultra Gentle Cleanser
      'name': 'Neutrogena Ultra Gentle Cleanser',
      'brand': 'Neutrogena',
      'category': 'skin_care',
      'ingredients': [
        'water',
        'glycerin',
        'cetearyl alcohol',
        'cetyl alcohol',
        'stearyl alcohol',
        'sodium lauroyl lactylate',
        'fragrance',
        'phenoxyethanol',
        'ethylhexylglycerin',
        'wheat germ oil',
        'milk protein',
        'soy lecithin',
        'almond extract',
        'peanut butter',
        'coconut milk',
        'sesame seed oil',
        'fish oil',
        'egg yolk',
        'crab extract'
      ],
      'allergens': ['wheat', 'milk', 'soy', 'tree_nuts', 'peanuts', 'fish', 'eggs', 'shellfish', 'sesame'],
      'image': null,
      'premium_only': true,
    },
    '9300605002002': { // Simple Kind to Skin Moisturiser
      'name': 'Simple Kind to Skin Moisturiser',
      'brand': 'Simple',
      'category': 'skin_care',
      'ingredients': [
        'water',
        'glycerin',
        'cetearyl alcohol',
        'cetyl alcohol',
        'stearyl alcohol',
        'dimethicone',
        'panthenol',
        'allantoin',
        'bisabolol',
        'fragrance',
        'phenoxyethanol',
        'methylparaben',
        'propylparaben',
        'wheat protein',
        'milk protein',
        'soy protein',
        'almond oil',
        'peanut oil',
        'coconut oil',
        'sesame oil',
        'fish collagen',
        'egg white protein',
        'mussel extract'
      ],
      'allergens': ['wheat', 'milk', 'soy', 'tree_nuts', 'peanuts', 'fish', 'eggs', 'shellfish', 'sesame'],
      'image': null,
      'premium_only': true,
    },

    // SHAMPOO PRODUCTS
    '9300605003000': { // Head & Shoulders Anti-Dandruff Shampoo
      'name': 'Head & Shoulders Anti-Dandruff Shampoo',
      'brand': 'Head & Shoulders',
      'category': 'shampoo',
      'ingredients': [
        'water',
        'sodium lauryl sulfate',
        'sodium laureth sulfate',
        'cocamidopropyl betaine',
        'zinc pyrithione',
        'sodium chloride',
        'fragrance',
        'dimethicone',
        'guar hydroxypropyltrimonium chloride',
        'tetrasodium edta',
        'methylchloroisothiazolinone',
        'methylisothiazolinone',
        'wheat protein',
        'milk protein',
        'soy protein',
        'almond oil',
        'peanut oil',
        'coconut oil',
        'sesame oil',
        'fish oil',
        'egg protein',
        'shrimp protein'
      ],
      'allergens': ['wheat', 'milk', 'soy', 'tree_nuts', 'peanuts', 'fish', 'eggs', 'shellfish', 'sesame'],
      'image': null,
      'premium_only': true,
    },
    '9300605003001': { // Pantene Pro-V Shampoo
      'name': 'Pantene Pro-V Shampoo',
      'brand': 'Pantene',
      'category': 'shampoo',
      'ingredients': [
        'water',
        'sodium lauryl sulfate',
        'sodium laureth sulfate',
        'cocamidopropyl betaine',
        'glycerin',
        'sodium chloride',
        'fragrance',
        'dimethicone',
        'guar hydroxypropyltrimonium chloride',
        'tetrasodium edta',
        'methylchloroisothiazolinone',
        'methylisothiazolinone',
        'wheat protein',
        'milk protein',
        'soy protein',
        'almond oil',
        'peanut oil',
        'coconut oil',
        'sesame oil',
        'fish collagen',
        'egg white',
        'oyster shell'
      ],
      'allergens': ['wheat', 'milk', 'soy', 'tree_nuts', 'peanuts', 'fish', 'eggs', 'shellfish', 'sesame'],
      'image': null,
      'premium_only': true,
    },
    '9300605003002': { // Herbal Essences Shampoo
      'name': 'Herbal Essences Shampoo',
      'brand': 'Herbal Essences',
      'category': 'shampoo',
      'ingredients': [
        'water',
        'sodium lauryl sulfate',
        'sodium laureth sulfate',
        'cocamidopropyl betaine',
        'glycerin',
        'sodium chloride',
        'fragrance',
        'dimethicone',
        'guar hydroxypropyltrimonium chloride',
        'tetrasodium edta',
        'methylchloroisothiazolinone',
        'methylisothiazolinone',
        'wheat protein',
        'milk protein',
        'soy protein',
        'almond oil',
        'peanut oil',
        'coconut oil',
        'sesame oil',
        'fish oil',
        'egg protein',
        'crab extract'
      ],
      'allergens': ['wheat', 'milk', 'soy', 'tree_nuts', 'peanuts', 'fish', 'eggs', 'shellfish', 'sesame'],
      'image': null,
      'premium_only': true,
    },

    // CONDITIONER PRODUCTS
    '9300605004000': { // Tresemme Moisture Rich Conditioner
      'name': 'Tresemme Moisture Rich Conditioner',
      'brand': 'Tresemme',
      'category': 'conditioner',
      'ingredients': [
        'water',
        'cetearyl alcohol',
        'cetyl alcohol',
        'stearyl alcohol',
        'dimethicone',
        'fragrance',
        'guar hydroxypropyltrimonium chloride',
        'tetrasodium edta',
        'methylchloroisothiazolinone',
        'methylisothiazolinone',
        'wheat protein',
        'milk protein',
        'soy protein',
        'almond oil',
        'peanut oil',
        'coconut oil',
        'sesame oil',
        'fish collagen',
        'egg white',
        'mussel extract'
      ],
      'allergens': ['wheat', 'milk', 'soy', 'tree_nuts', 'peanuts', 'fish', 'eggs', 'shellfish', 'sesame'],
      'image': null,
      'premium_only': true,
    },

    // LOTION PRODUCTS
    '9300605005000': { // Vaseline Intensive Care Lotion
      'name': 'Vaseline Intensive Care Lotion',
      'brand': 'Vaseline',
      'category': 'lotion',
      'ingredients': [
        'water',
        'glycerin',
        'cetearyl alcohol',
        'cetyl alcohol',
        'stearyl alcohol',
        'dimethicone',
        'fragrance',
        'panthenol',
        'allantoin',
        'phenoxyethanol',
        'methylparaben',
        'propylparaben',
        'wheat protein',
        'milk protein',
        'soy protein',
        'almond oil',
        'peanut oil',
        'coconut oil',
        'sesame oil',
        'fish oil',
        'egg yolk',
        'oyster shell'
      ],
      'allergens': ['wheat', 'milk', 'soy', 'tree_nuts', 'peanuts', 'fish', 'eggs', 'shellfish', 'sesame'],
      'image': null,
      'premium_only': true,
    },

    // SUNSCREEN PRODUCTS
    '9300605006000': { // Cancer Council SPF 50+ Sunscreen
      'name': 'Cancer Council SPF 50+ Sunscreen',
      'brand': 'Cancer Council',
      'category': 'sunscreen',
      'ingredients': [
        'water',
        'glycerin',
        'cetearyl alcohol',
        'cetyl alcohol',
        'stearyl alcohol',
        'dimethicone',
        'fragrance',
        'phenoxyethanol',
        'methylparaben',
        'propylparaben',
        'wheat protein',
        'milk protein',
        'soy protein',
        'almond oil',
        'peanut oil',
        'coconut oil',
        'sesame oil',
        'fish oil',
        'egg white',
        'shrimp extract'
      ],
      'allergens': ['wheat', 'milk', 'soy', 'tree_nuts', 'peanuts', 'fish', 'eggs', 'shellfish', 'sesame'],
      'image': null,
      'premium_only': true,
    },
  };

  /// Get premium product by barcode
  static Future<Map<String, dynamic>?> getPremiumProduct(String barcode) async {
    try {
      // Check if user has premium access
      final isPremium = await PremiumService.isPremiumUser();
      if (!isPremium) {
        if (kDebugMode) {
          print('PremiumProductService: User does not have premium access');
        }
        return null;
      }

      // Check if product exists in premium database
      final product = _premiumProductDatabase[barcode];
      if (product != null) {
        if (kDebugMode) {
          print('PremiumProductService: Found premium product: ${product['name']}');
        }
        return product;
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('PremiumProductService: Error getting premium product: $e');
      }
      return null;
    }
  }

  /// Get all premium products by category
  static Future<List<Map<String, dynamic>>> getPremiumProductsByCategory(String category) async {
    try {
      // Check if user has premium access
      final isPremium = await PremiumService.isPremiumUser();
      if (!isPremium) {
        if (kDebugMode) {
          print('PremiumProductService: User does not have premium access');
        }
        return [];
      }

      final products = _premiumProductDatabase.values
          .where((product) => product['category'] == category)
          .toList();

      if (kDebugMode) {
        print('PremiumProductService: Found ${products.length} premium products in category: $category');
      }

      return products;
    } catch (e) {
      if (kDebugMode) {
        print('PremiumProductService: Error getting premium products by category: $e');
      }
      return [];
    }
  }

  /// Get all premium products
  static Future<List<Map<String, dynamic>>> getAllPremiumProducts() async {
    try {
      // Check if user has premium access
      final isPremium = await PremiumService.isPremiumUser();
      if (!isPremium) {
        if (kDebugMode) {
          print('PremiumProductService: User does not have premium access');
        }
        return [];
      }

      final products = _premiumProductDatabase.values.toList();

      if (kDebugMode) {
        print('PremiumProductService: Found ${products.length} premium products');
      }

      return products;
    } catch (e) {
      if (kDebugMode) {
        print('PremiumProductService: Error getting all premium products: $e');
      }
      return [];
    }
  }

  /// Search premium products by name or brand
  static Future<List<Map<String, dynamic>>> searchPremiumProducts(String query) async {
    try {
      // Check if user has premium access
      final isPremium = await PremiumService.isPremiumUser();
      if (!isPremium) {
        if (kDebugMode) {
          print('PremiumProductService: User does not have premium access');
        }
        return [];
      }

      final lowercaseQuery = query.toLowerCase();
      final products = _premiumProductDatabase.values
          .where((product) {
            final name = product['name'].toString().toLowerCase();
            final brand = product['brand'].toString().toLowerCase();
            return name.contains(lowercaseQuery) || brand.contains(lowercaseQuery);
          })
          .toList();

      if (kDebugMode) {
        print('PremiumProductService: Found ${products.length} premium products matching query: $query');
      }

      return products;
    } catch (e) {
      if (kDebugMode) {
        print('PremiumProductService: Error searching premium products: $e');
      }
      return [];
    }
  }

  /// Get premium product categories
  static List<String> getPremiumProductCategories() {
    return [
      'body_care',
      'skin_care',
      'shampoo',
      'conditioner',
      'lotion',
      'sunscreen',
    ];
  }

  /// Get category display name
  static String getCategoryDisplayName(String category) {
    switch (category) {
      case 'body_care':
        return 'Body Care';
      case 'skin_care':
        return 'Skin Care';
      case 'shampoo':
        return 'Shampoo';
      case 'conditioner':
        return 'Conditioner';
      case 'lotion':
        return 'Lotion';
      case 'sunscreen':
        return 'Sunscreen';
      default:
        return category;
    }
  }

  /// Get category icon
  static String getCategoryIcon(String category) {
    switch (category) {
      case 'body_care':
        return '🛁';
      case 'skin_care':
        return '🧴';
      case 'shampoo':
        return '🧴';
      case 'conditioner':
        return '🧴';
      case 'lotion':
        return '🧴';
      case 'sunscreen':
        return '☀️';
      default:
        return '📦';
    }
  }

  /// Check if product contains all major allergens
  static bool containsAllAllergens(Map<String, dynamic> product) {
    final allergens = List<String>.from(product['allergens'] ?? []);
    final majorAllergens = [
      'wheat',
      'milk',
      'soy',
      'tree_nuts',
      'peanuts',
      'fish',
      'eggs',
      'shellfish',
      'sesame'
    ];

    return majorAllergens.every((allergen) => allergens.contains(allergen));
  }

  /// Get premium product statistics
  static Map<String, dynamic> getPremiumProductStatistics() {
    final products = _premiumProductDatabase.values.toList();
    final categoryCounts = <String, int>{};
    final allergenCounts = <String, int>{};

    for (var product in products) {
      final category = product['category'] as String? ?? 'unknown';
      categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;

      final allergens = List<String>.from(product['allergens'] ?? []);
      for (var allergen in allergens) {
        allergenCounts[allergen] = (allergenCounts[allergen] ?? 0) + 1;
      }
    }

    return {
      'totalProducts': products.length,
      'categoryCounts': categoryCounts,
      'allergenCounts': allergenCounts,
      'categories': getPremiumProductCategories(),
    };
  }
} 