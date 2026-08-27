import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_credentials_service.dart';
import 'barcode_utils.dart';

class EdamamService {
  static const String _baseUrl = 'https://api.edamam.com/api/food-database/v2';
  
  static String get _appId => ApiCredentialsService.edamamAppId ?? '';
  static String get _appKey => ApiCredentialsService.edamamAppKey ?? '';
  
  /// Search for foods by query string
  static Future<Map<String, dynamic>> searchFoods({
    required String query,
    int maxResults = 20,
    String category = 'generic-foods',
  }) async {
    if (kDebugMode) {
      print('EdamamService: Searching for foods with query: $query');
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/parser?app_id=$_appId&app_key=$_appKey&ingr=$query&category=$category'),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'MyAllergyBuddy/1.0 (Flutter App)',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (kDebugMode) {
          print('EdamamService: Found ${data['hints']?.length ?? 0} results');
        }
        return {
          'success': true,
          'data': data,
          'query': query,
        };
      } else {
        if (kDebugMode) {
          print('EdamamService: Error response ${response.statusCode}: ${response.body}');
        }
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}',
          'message': response.body,
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('EdamamService: Error searching foods: $e');
      }
      return {
        'success': false,
        'error': 'Network error',
        'message': e.toString(),
      };
    }
  }

  /// Get detailed food information by food ID
  static Future<Map<String, dynamic>> getFoodDetails({
    required String foodId,
  }) async {
    if (kDebugMode) {
      print('EdamamService: Getting food details for ID: $foodId');
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/food/$foodId?app_id=$_appId&app_key=$_appKey'),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'MyAllergyBuddy/1.0 (Flutter App)',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (kDebugMode) {
          print('EdamamService: Retrieved food details for: ${data['label']}');
        }
        return {
          'success': true,
          'data': data,
        };
      } else {
        if (kDebugMode) {
          print('EdamamService: Error response ${response.statusCode}: ${response.body}');
        }
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}',
          'message': response.body,
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('EdamamService: Error getting food details: $e');
      }
      return {
        'success': false,
        'error': 'Network error',
        'message': e.toString(),
      };
    }
  }

  /// Search for foods by barcode (UPC)
  static Future<Map<String, dynamic>> searchByBarcode({
    required String barcode,
  }) async {
    if (!ApiCredentialsService.isEdamamConfigured) {
      return {
        'success': false,
        'message': 'Edamam API credentials not configured',
      };
    }

    if (kDebugMode) {
      print('EdamamService: Searching by barcode: $barcode');
    }

    for (final candidate in BarcodeUtils.lookupCandidates(barcode)) {
      final upcResult = await _parserLookup(upc: candidate);
      if (upcResult['success'] == true) {
        final exact = await _exactUpcMatch(upcResult, barcode);
        if (exact != null) return exact;
      }
    }

    final fallback = await searchFoods(query: barcode, category: 'packaged-foods');
    if (fallback['success'] == true) {
      final exact = await _exactUpcMatch(fallback, barcode);
      if (exact != null) return exact;
    }

    return {
      'success': false,
      'error': 'No food found',
      'message': 'No food found with barcode: $barcode',
    };
  }

  static Future<Map<String, dynamic>> _parserLookup({
    String? upc,
    String? query,
    String category = 'packaged-foods',
  }) async {
    final params = <String, String>{
      'app_id': _appId,
      'app_key': _appKey,
      'category': category,
    };
    if (upc != null) params['upc'] = upc;
    if (query != null) params['ingr'] = query;

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/parser').replace(queryParameters: params),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'MyAllergyBuddy/1.0 (Flutter App)',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}',
          'message': response.body,
        };
      }
      return {
        'success': true,
        'data': json.decode(response.body),
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error',
        'message': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>?> _exactUpcMatch(
    Map<String, dynamic> searchResult,
    String barcode,
  ) async {
    final parsed = searchResult['data']?['parsed'] as List<dynamic>? ?? [];
    final hints = searchResult['data']?['hints'] as List<dynamic>? ?? [];

    Future<Map<String, dynamic>?> asResult(dynamic entry) async {
      if (entry is! Map) return null;
      final food = entry['food'];
      if (food is! Map) return null;
      if (food['foodId'] != null) {
        return await getFoodDetails(foodId: food['foodId'].toString());
      }
      return {
        'success': true,
        'data': Map<String, dynamic>.from(food),
      };
    }

    if (parsed.isNotEmpty) {
      return asResult(parsed.first);
    }

    for (final entry in hints) {
      if (entry is! Map) continue;
      final food = entry['food'];
      if (food is! Map) continue;
      final upc = food['upc']?.toString() ?? '';
      if (BarcodeUtils.matches(upc, barcode)) {
        return asResult(entry);
      }
    }
    return null;
  }

  /// Extract allergen information from Edamam food data
  static Map<String, dynamic> extractAllergenInfo(Map<String, dynamic> foodData) {
    final allergens = <String>[];
    final ingredients = <String>[];
    final nutritionInfo = <String, dynamic>{};

    // Extract food nutrients
    final nutrients = foodData['nutrients'] as Map<String, dynamic>? ?? {};
    
    for (var entry in nutrients.entries) {
      final nutrientName = entry.key.toLowerCase();
      final value = entry.value?.toString() ?? '';
      
      // Check for allergen-related nutrients
      if (nutrientName.contains('protein') || 
          nutrientName.contains('fat') || 
          nutrientName.contains('carbohydrate')) {
        nutritionInfo[nutrientName] = value;
      }
    }

    final label = foodData['label']?.toString() ?? '';
    final foodContentsLabel = foodData['foodContentsLabel']?.toString() ?? '';
    final category = foodData['category']?.toString() ?? '';
    final categoryLabel = foodData['categoryLabel']?.toString() ?? '';

    if (foodContentsLabel.isNotEmpty) {
      ingredients.addAll(
        foodContentsLabel
            .split(RegExp(r'[,;•\n\r]'))
            .map((item) => item.trim())
            .where((item) => item.length > 1),
      );
    } else if (label.isNotEmpty) {
      ingredients.add(label);
    }
    if (category.isNotEmpty) ingredients.add(category);
    if (categoryLabel.isNotEmpty) ingredients.add(categoryLabel);

    final allergenKeywords = {
      'milk': ['milk', 'dairy', 'cheese', 'cream', 'butter', 'whey', 'casein', 'lactose'],
      'eggs': ['egg', 'eggs', 'albumin', 'ovalbumin'],
      'fish': ['fish', 'salmon', 'tuna', 'cod', 'anchovy'],
      'shellfish': ['shellfish', 'shrimp', 'crab', 'lobster', 'oyster'],
      'tree nuts': ['almond', 'walnut', 'pecan', 'cashew', 'pistachio', 'hazelnut', 'macadamia'],
      'peanuts': ['peanut', 'peanuts'],
      'wheat': ['wheat', 'gluten'],
      'soybeans': ['soy', 'soybean', 'soya'],
      'sesame': ['sesame', 'tahini'],
      'sulfites': ['sulfite', 'sulphite', 'sulfur dioxide', 'sulphur dioxide'],
      'mustard': ['mustard'],
      'lupin': ['lupin', 'lupine'],
    };

    final allIngredients = [
      foodContentsLabel,
      ingredients.join(' '),
    ].join(' ').toLowerCase();
    
    for (var entry in allergenKeywords.entries) {
      final allergenName = entry.key;
      final keywords = entry.value;
      
      for (var keyword in keywords) {
        if (allIngredients.contains(keyword)) {
          allergens.add(allergenName);
          break;
        }
      }
    }

    return {
      'allergens': allergens.toSet().toList(), // Remove duplicates
      'ingredients': ingredients,
      'nutritionInfo': nutritionInfo,
      'label': label,
      'category': category,
      'foodId': foodData['foodId']?.toString() ?? '',
      'dataSource': 'Edamam',
    };
  }

  /// Search for foods containing specific allergens
  static Future<List<Map<String, dynamic>>> searchFoodsWithAllergens({
    required List<String> allergens,
    int maxResults = 20,
  }) async {
    if (kDebugMode) {
      print('EdamamService: Searching for foods with allergens: $allergens');
    }

    final results = <Map<String, dynamic>>[];
    
    for (String allergen in allergens) {
      try {
        // Search for foods containing the allergen
        final searchResult = await searchFoods(
          query: allergen,
          maxResults: maxResults,
        );

        if (searchResult['success'] == false) {
          continue;
        }

        final hints = searchResult['data']?['hints'] as List<dynamic>? ?? [];
        
        for (var hint in hints) {
          if (results.length >= maxResults) break;
          
          final food = hint['food'];
          
          // Get detailed information
          final details = await getFoodDetails(foodId: food['foodId']);
          
          if (details['success'] == true) {
            final allergenInfo = extractAllergenInfo(details['data']);
            
            // Check if this food actually contains the searched allergen
            if (allergenInfo['allergens'].contains(allergen)) {
              results.add({
                ...details['data'],
                'searchedAllergen': allergen,
                'allergenInfo': allergenInfo,
              });
            }
          }
        }

        // Add delay to avoid rate limiting
        await Future.delayed(const Duration(milliseconds: 1000));
        
      } catch (e) {
        if (kDebugMode) {
          print('EdamamService: Error searching for allergen $allergen: $e');
        }
      }
    }

    if (kDebugMode) {
      print('EdamamService: Found ${results.length} foods with allergens');
    }

    return results;
  }

  /// Get food categories
  static Future<Map<String, dynamic>> getFoodCategories() async {
    if (kDebugMode) {
      print('EdamamService: Getting food categories');
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/categories?app_id=$_appId&app_key=$_appKey'),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'MyAllergyBuddy/1.0 (Flutter App)',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (kDebugMode) {
          print('EdamamService: Retrieved ${data.length} food categories');
        }
        return {
          'success': true,
          'data': data,
        };
      } else {
        if (kDebugMode) {
          print('EdamamService: Error response ${response.statusCode}: ${response.body}');
        }
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}',
          'message': response.body,
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('EdamamService: Error getting food categories: $e');
      }
      return {
        'success': false,
        'error': 'Network error',
        'message': e.toString(),
      };
    }
  }

  /// Get nutrition information for a food
  static Future<Map<String, dynamic>> getNutritionInfo({
    required String foodId,
    double quantity = 100.0,
    String unit = 'g',
  }) async {
    if (kDebugMode) {
      print('EdamamService: Getting nutrition info for food: $foodId');
    }

    try {
      final response = await http.post(
        Uri.parse('https://api.edamam.com/api/nutrition-details?app_id=$_appId&app_key=$_appKey'),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'MyAllergyBuddy/1.0 (Flutter App)',
        },
        body: json.encode({
          'ingr': ['$quantity $unit $foodId'],
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (kDebugMode) {
          print('EdamamService: Retrieved nutrition info');
        }
        return {
          'success': true,
          'data': data,
        };
      } else {
        if (kDebugMode) {
          print('EdamamService: Error response ${response.statusCode}: ${response.body}');
        }
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}',
          'message': response.body,
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('EdamamService: Error getting nutrition info: $e');
      }
      return {
        'success': false,
        'error': 'Network error',
        'message': e.toString(),
      };
    }
  }
}
