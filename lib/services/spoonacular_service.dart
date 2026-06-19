import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SpoonacularService {
  // Spoonacular API configuration
  static const String baseUrl = 'https://api.spoonacular.com/food';
  static String? _apiKey;
  
  /// Initialize the API key from SharedPreferences
  static Future<void> initializeApiKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _apiKey = prefs.getString('spoonacular_api_key');
    } catch (e) {
      if (kDebugMode) {
        print('Spoonacular: Error loading API key: $e');
      }
    }
  }
  
  /// Get the current API key
  static String? get apiKey => _apiKey;
  
  // Cache for recently fetched products
  static final Map<String, Map<String, dynamic>> _cache = {};
  static const int _maxCacheSize = 50;

  /// Get product information by UPC/barcode
  static Future<Map<String, dynamic>?> getProductByUPC(String upc) async {
    if (kDebugMode) {
      print('Spoonacular: Looking up product with UPC: $upc');
    }

    // Check cache first
    if (_cache.containsKey(upc)) {
      if (kDebugMode) {
        print('Spoonacular: Found product in cache: $upc');
      }
      return _cache[upc];
    }

    try {
      if (apiKey == null) {
        if (kDebugMode) {
          print('Spoonacular: API key not configured');
        }
        return null;
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl/products/upc/$upc?apiKey=$apiKey'),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'MyAllergyBuddy/1.0 (Flutter App)',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['id'] != null) {
          final product = _parseProductData(data);
          _addToCache(upc, product);
          
          if (kDebugMode) {
            print('Spoonacular: Successfully retrieved product: ${product['name']}');
          }
          
          return product;
        } else {
          if (kDebugMode) {
            print('Spoonacular: Product not found in database');
          }
          return null;
        }
      } else {
        if (kDebugMode) {
          print('Spoonacular: HTTP error ${response.statusCode}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Spoonacular: Error retrieving product: $e');
      }
      return null;
    }
  }

  /// Get detailed product information by ID
  static Future<Map<String, dynamic>?> getProductInformation(int productId) async {
    try {
      if (apiKey == null) {
        if (kDebugMode) {
          print('Spoonacular: API key not configured');
        }
        return null;
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl/products/$productId?apiKey=$apiKey'),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'MyAllergyBuddy/1.0 (Flutter App)',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseDetailedProductData(data);
      } else {
        if (kDebugMode) {
          print('Spoonacular: HTTP error ${response.statusCode} for product $productId');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Spoonacular: Error retrieving product information: $e');
      }
      return null;
    }
  }

  /// Search products by query
  static Future<List<Map<String, dynamic>>> searchProducts(String query, {int maxResults = 10}) async {
    try {
      if (apiKey == null) {
        if (kDebugMode) {
          print('Spoonacular: API key not configured');
        }
        return [];
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl/products/search?query=${Uri.encodeComponent(query)}&number=$maxResults&apiKey=$apiKey'),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'MyAllergyBuddy/1.0 (Flutter App)',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final products = data['products'] as List<dynamic>? ?? [];
        
        return products
            .map((product) => _parseProductData(product))
            .cast<Map<String, dynamic>>()
            .toList();
      } else {
        if (kDebugMode) {
          print('Spoonacular: Search HTTP error ${response.statusCode}');
        }
        return [];
      }
    } catch (e) {
      if (kDebugMode) {
        print('Spoonacular: Search error: $e');
      }
      return [];
    }
  }

  /// Get ingredient information
  static Future<Map<String, dynamic>?> getIngredientInformation(int ingredientId) async {
    try {
      if (apiKey == null) {
        if (kDebugMode) {
          print('Spoonacular: API key not configured');
        }
        return null;
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl/ingredients/$ingredientId/information?apiKey=$apiKey'),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'MyAllergyBuddy/1.0 (Flutter App)',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseIngredientData(data);
      } else {
        if (kDebugMode) {
          print('Spoonacular: Ingredient HTTP error ${response.statusCode}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Spoonacular: Error retrieving ingredient information: $e');
      }
      return null;
    }
  }

  /// Parse basic product data from Spoonacular response
  static Map<String, dynamic> _parseProductData(Map<String, dynamic> data) {
    return {
      'id': data['id'],
      'name': data['title'] ?? data['name'] ?? 'Unknown Product',
      'brand': data['brand'] ?? 'Unknown Brand',
      'upc': data['upc'] ?? data['code'],
      'image': data['image'],
      'ingredients': _extractIngredients(data),
      'allergens': _extractAllergens(data),
      'nutrition': _extractNutrition(data),
      'data_source': 'Spoonacular',
      'confidence_score': 0.85, // High confidence for Spoonacular data
      'analysis_method': 'Spoonacular API',
      'processing_time': 'API Response',
      'is_from_cache': false,
      'cache_age': null,
      'scan_date': DateTime.now().toIso8601String(),
    };
  }

  /// Parse detailed product data
  static Map<String, dynamic> _parseDetailedProductData(Map<String, dynamic> data) {
    return {
      'id': data['id'],
      'name': data['title'] ?? data['name'] ?? 'Unknown Product',
      'brand': data['brand'] ?? 'Unknown Brand',
      'upc': data['upc'] ?? data['code'],
      'image': data['image'],
      'ingredients': _extractIngredients(data),
      'allergens': _extractAllergens(data),
      'nutrition': _extractNutrition(data),
      'serving_size': data['servingSize'],
      'servings_per_container': data['servingsPerContainer'],
      'data_source': 'Spoonacular',
      'confidence_score': 0.90, // Very high confidence for detailed data
      'analysis_method': 'Spoonacular Detailed API',
      'processing_time': 'API Response',
      'is_from_cache': false,
      'cache_age': null,
      'scan_date': DateTime.now().toIso8601String(),
    };
  }

  /// Parse ingredient data
  static Map<String, dynamic> _parseIngredientData(Map<String, dynamic> data) {
    return {
      'id': data['id'],
      'name': data['name'],
      'image': data['image'],
      'allergens': _extractAllergensFromIngredient(data),
      'nutrition': _extractNutrition(data),
      'data_source': 'Spoonacular Ingredient',
      'confidence_score': 0.95,
      'analysis_method': 'Spoonacular Ingredient API',
      'processing_time': 'API Response',
      'is_from_cache': false,
      'cache_age': null,
      'scan_date': DateTime.now().toIso8601String(),
    };
  }

  /// Extract ingredients from product data
  static List<String> _extractIngredients(Map<String, dynamic> data) {
    final ingredients = <String>[];
    
    // Try different possible ingredient fields
    if (data['ingredients'] != null) {
      if (data['ingredients'] is String) {
        // Parse ingredient string
        final ingredientText = data['ingredients'] as String;
        ingredients.addAll(_parseIngredientText(ingredientText));
      } else if (data['ingredients'] is List) {
        // Parse ingredient list
        final ingredientList = data['ingredients'] as List;
        for (var ingredient in ingredientList) {
          if (ingredient is Map<String, dynamic>) {
            if (ingredient['name'] != null) {
              ingredients.add(ingredient['name'].toString());
            }
          } else if (ingredient is String) {
            ingredients.add(ingredient);
          }
        }
      }
    }
    
    // Try nutrition facts for additional ingredient info
    if (data['nutrition'] != null && data['nutrition']['ingredients'] != null) {
      final nutritionIngredients = data['nutrition']['ingredients'] as List?;
      if (nutritionIngredients != null) {
        for (var ingredient in nutritionIngredients) {
          if (ingredient is Map<String, dynamic> && ingredient['name'] != null) {
            ingredients.add(ingredient['name'].toString());
          }
        }
      }
    }
    
    return ingredients.toSet().toList(); // Remove duplicates
  }

  /// Parse ingredient text into list
  static List<String> _parseIngredientText(String text) {
    if (text.isEmpty) return [];
    
    return text
        .split(RegExp(r'[,;•\n\r]'))
        .map((ingredient) => ingredient.trim())
        .where((ingredient) => ingredient.isNotEmpty)
        .where((ingredient) => ingredient.length > 2)
        .toList();
  }

  /// Extract allergens from product data
  static List<String> _extractAllergens(Map<String, dynamic> data) {
    final allergens = <String>[];
    
    // Check for allergen tags
    if (data['allergens'] != null) {
      if (data['allergens'] is List) {
        final allergenList = data['allergens'] as List;
        for (var allergen in allergenList) {
          if (allergen is String) {
            allergens.add(allergen.toLowerCase());
          }
        }
      }
    }
    
    // Check nutrition facts for allergen information
    if (data['nutrition'] != null && data['nutrition']['allergens'] != null) {
      final nutritionAllergens = data['nutrition']['allergens'] as List?;
      if (nutritionAllergens != null) {
        for (var allergen in nutritionAllergens) {
          if (allergen is String) {
            allergens.add(allergen.toLowerCase());
          }
        }
      }
    }
    
    // Extract allergens from ingredients text
    if (data['ingredients'] != null && data['ingredients'] is String) {
      final ingredientText = data['ingredients'] as String;
      allergens.addAll(_extractAllergensFromText(ingredientText));
    }
    
    return allergens.toSet().toList(); // Remove duplicates
  }

  /// Extract allergens from ingredient data
  static List<String> _extractAllergensFromIngredient(Map<String, dynamic> data) {
    final allergens = <String>[];
    
    // Check for allergen properties
    if (data['allergens'] != null) {
      if (data['allergens'] is List) {
        final allergenList = data['allergens'] as List;
        for (var allergen in allergenList) {
          if (allergen is String) {
            allergens.add(allergen.toLowerCase());
          }
        }
      }
    }
    
    return allergens;
  }

  /// Extract allergens from text using keyword matching
  static List<String> _extractAllergensFromText(String text) {
    final allergens = <String>[];
    final lowerText = text.toLowerCase();
    
    // Common allergen keywords
    final allergenKeywords = {
      'peanuts': ['peanut', 'peanuts', 'arachis hypogaea'],
      'tree nuts': ['almond', 'almonds', 'walnut', 'walnuts', 'cashew', 'cashews', 'pecan', 'pecans', 'pistachio', 'pistachios', 'hazelnut', 'hazelnuts', 'macadamia', 'macadamias', 'brazil nut', 'brazil nuts'],
      'milk': ['milk', 'dairy', 'cream', 'butter', 'cheese', 'yogurt', 'yoghurt', 'whey', 'casein', 'lactose'],
      'eggs': ['egg', 'eggs', 'egg white', 'egg yolk', 'albumin', 'ovalbumin'],
      'soy': ['soy', 'soya', 'soybean', 'soybeans', 'soy lecithin', 'soy protein'],
      'wheat': ['wheat', 'wheat flour', 'wheat protein', 'gluten'],
      'fish': ['fish', 'salmon', 'tuna', 'cod', 'haddock', 'anchovy', 'anchovies'],
      'shellfish': ['shrimp', 'prawn', 'crab', 'lobster', 'oyster', 'clam', 'mussel', 'scallop'],
      'sesame': ['sesame', 'sesame seed', 'sesame seeds', 'tahini'],
      'sulfites': ['sulfite', 'sulfites', 'sulphite', 'sulphites'],
      'mustard': ['mustard', 'mustard seed', 'mustard powder'],
      'celery': ['celery', 'celery seed', 'celery salt'],
      'lupin': ['lupin', 'lupine', 'lupini'],
      'molluscs': ['mollusc', 'molluscs', 'snail', 'snails', 'abalone'],
    };
    
    for (String allergen in allergenKeywords.keys) {
      for (String keyword in allergenKeywords[allergen]!) {
        if (lowerText.contains(keyword)) {
          if (!allergens.contains(allergen)) {
            allergens.add(allergen);
          }
          break;
        }
      }
    }
    
    return allergens;
  }

  /// Extract nutrition information
  static Map<String, dynamic> _extractNutrition(Map<String, dynamic> data) {
    final nutrition = <String, dynamic>{};
    
    if (data['nutrition'] != null) {
      final nutritionData = data['nutrition'] as Map<String, dynamic>;
      
      // Extract basic nutrition facts
      if (nutritionData['nutrients'] != null) {
        final nutrients = nutritionData['nutrients'] as List;
        for (var nutrient in nutrients) {
          if (nutrient is Map<String, dynamic>) {
            final name = nutrient['name']?.toString().toLowerCase();
            final amount = nutrient['amount'];
            final unit = nutrient['unit'];
            
            if (name != null && amount != null) {
              nutrition[name] = {
                'amount': amount,
                'unit': unit ?? 'g',
              };
            }
          }
        }
      }
      
      // Extract serving information
      if (nutritionData['servingSize'] != null) {
        nutrition['serving_size'] = nutritionData['servingSize'];
      }
      
      if (nutritionData['servingsPerContainer'] != null) {
        nutrition['servings_per_container'] = nutritionData['servingsPerContainer'];
      }
    }
    
    return nutrition;
  }

  /// Add product to cache
  static void _addToCache(String upc, Map<String, dynamic> product) {
    if (_cache.length >= _maxCacheSize) {
      // Remove oldest entry
      String oldestKey = _cache.keys.first;
      _cache.remove(oldestKey);
    }
    _cache[upc] = product;
  }

  /// Clear cache
  static void clearCache() {
    _cache.clear();
  }

  /// Get cache statistics
  static Map<String, dynamic> getCacheStats() {
    return {
      'cache_size': _cache.length,
      'max_cache_size': _maxCacheSize,
    };
  }

  /// Check if API key is configured
  static bool isApiKeyConfigured() {
    return apiKey != null && apiKey!.isNotEmpty;
  }

  /// Get API usage information
  static Future<Map<String, dynamic>?> getApiUsage() async {
    if (!isApiKeyConfigured()) {
      return null;
    }

    try {
      if (apiKey == null) {
        return null;
      }
      
      final response = await http.get(
        Uri.parse('https://api.spoonacular.com/food/ingredients/search?apiKey=$apiKey&query=test&number=1'),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'MyAllergyBuddy/1.0 (Flutter App)',
        },
      ).timeout(const Duration(seconds: 5));

      // Extract usage info from headers
      final usage = <String, dynamic>{};
      
      if (response.headers.containsKey('x-quota-used')) {
        usage['quota_used'] = int.tryParse(response.headers['x-quota-used'] ?? '0') ?? 0;
      }
      
      if (response.headers.containsKey('x-quota-left')) {
        usage['quota_left'] = int.tryParse(response.headers['x-quota-left'] ?? '0') ?? 0;
      }
      
      if (response.headers.containsKey('x-quota-reset')) {
        usage['quota_reset'] = response.headers['x-quota-reset'];
      }
      
      return usage;
    } catch (e) {
      if (kDebugMode) {
        print('Spoonacular: Error getting API usage: $e');
      }
      return null;
    }
  }
} 