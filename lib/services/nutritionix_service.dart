import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_credentials_service.dart';

class NutritionixService {
  static const String _baseUrl = 'https://trackapi.nutritionix.com/v2';
  
  static String get _appId => ApiCredentialsService.nutritionixAppId ?? '';
  static String get _appKey => ApiCredentialsService.nutritionixAppKey ?? '';
  
  /// Search for foods by query string
  static Future<Map<String, dynamic>> searchFoods({
    required String query,
    int maxResults = 20,
    String locale = 'en_US',
  }) async {
    if (kDebugMode) {
      print('NutritionixService: Searching for foods with query: $query');
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/search/instant'),
        headers: {
          'Content-Type': 'application/json',
          'x-app-id': _appId,
          'x-app-key': _appKey,
          'x-remote-user-id': '0',
        },
        body: json.encode({
          'query': query,
          'detailed': true,
          'branded': true,
          'common': true,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (kDebugMode) {
          print('NutritionixService: Found ${data['common']?.length ?? 0} common and ${data['branded']?.length ?? 0} branded results');
        }
        return {
          'success': true,
          'data': data,
          'query': query,
        };
      } else {
        if (kDebugMode) {
          print('NutritionixService: Error response ${response.statusCode}: ${response.body}');
        }
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}',
          'message': response.body,
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('NutritionixService: Error searching foods: $e');
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
    String type = 'branded', // 'branded' or 'common'
  }) async {
    if (kDebugMode) {
      print('NutritionixService: Getting food details for ID: $foodId');
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/natural/nutrients'),
        headers: {
          'Content-Type': 'application/json',
          'x-app-id': _appId,
          'x-app-key': _appKey,
          'x-remote-user-id': '0',
        },
        body: json.encode({
          'query': foodId,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (kDebugMode) {
          print('NutritionixService: Retrieved food details');
        }
        return {
          'success': true,
          'data': data,
        };
      } else {
        if (kDebugMode) {
          print('NutritionixService: Error response ${response.statusCode}: ${response.body}');
        }
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}',
          'message': response.body,
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('NutritionixService: Error getting food details: $e');
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
    if (!ApiCredentialsService.isNutritionixConfigured) {
      return {
        'success': false,
        'message': 'Nutritionix API credentials not configured',
      };
    }

    if (kDebugMode) {
      print('NutritionixService: Searching by barcode: $barcode');
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/search/item?upc=$barcode'),
        headers: {
          'Content-Type': 'application/json',
          'x-app-id': _appId,
          'x-app-key': _appKey,
          'x-remote-user-id': '0',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (kDebugMode) {
          print('NutritionixService: Found product by barcode: ${data['foods']?[0]?['food_name']}');
        }
        return {
          'success': true,
          'data': data,
        };
      } else {
        if (kDebugMode) {
          print('NutritionixService: Error response ${response.statusCode}: ${response.body}');
        }
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}',
          'message': response.body,
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('NutritionixService: Error searching by barcode: $e');
      }
      return {
        'success': false,
        'error': 'Network error',
        'message': e.toString(),
      };
    }
  }

  /// Extract allergen information from Nutritionix food data
  static Map<String, dynamic> extractAllergenInfo(Map<String, dynamic> foodData) {
    final allergens = <String>[];
    final ingredients = <String>[];
    final nutritionInfo = <String, dynamic>{};

    // Extract food nutrients
    final foods = foodData['foods'] as List<dynamic>? ?? [];
    if (foods.isNotEmpty) {
      final food = foods.first;
      final nutrients = food['full_nutrients'] as List<dynamic>? ?? [];
      
      for (var nutrient in nutrients) {
        final nutrientId = nutrient[0]?.toString() ?? '';
        final value = nutrient[1]?.toString() ?? '';
        
        // Map nutrient IDs to names
        final nutrientName = getNutrientName(nutrientId);
        if (nutrientName.isNotEmpty) {
          nutritionInfo[nutrientName] = value;
        }
      }

      // Extract ingredients from food name and tags
      final foodName = food['food_name']?.toString() ?? '';
      final brandName = food['brand_name']?.toString() ?? '';
      final tags = food['tags']?.toString() ?? '';
      final servingUnit = food['serving_unit']?.toString() ?? '';
      
      if (foodName.isNotEmpty) {
        ingredients.add(foodName);
      }
      if (brandName.isNotEmpty) {
        ingredients.add(brandName);
      }
      if (tags.isNotEmpty) {
        ingredients.add(tags);
      }
      if (servingUnit.isNotEmpty) {
        ingredients.add(servingUnit);
      }
    }

    // Check for common allergens in ingredients
    final allergenKeywords = {
      'milk': ['milk', 'dairy', 'cheese', 'cream', 'butter', 'whey', 'casein', 'lactose'],
      'eggs': ['egg', 'eggs', 'albumin', 'ovalbumin'],
      'fish': ['fish', 'salmon', 'tuna', 'cod', 'anchovy'],
      'shellfish': ['shellfish', 'shrimp', 'crab', 'lobster', 'oyster'],
      'tree nuts': ['almond', 'walnut', 'pecan', 'cashew', 'pistachio', 'hazelnut'],
      'peanuts': ['peanut', 'peanuts'],
      'wheat': ['wheat', 'gluten', 'flour'],
      'soybeans': ['soy', 'soybean', 'soya'],
    };

    final allIngredients = ingredients.join(' ').toLowerCase();
    
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
      'foodName': foods.isNotEmpty ? foods.first['food_name']?.toString() ?? '' : '',
      'brandName': foods.isNotEmpty ? foods.first['brand_name']?.toString() ?? '' : '',
      'dataSource': 'Nutritionix',
    };
  }

  /// Get nutrient name from Nutritionix nutrient ID
  static String getNutrientName(String nutrientId) {
    final nutrientMap = {
      '203': 'protein',
      '204': 'fat',
      '205': 'carbohydrate',
      '208': 'calories',
      '269': 'sugar',
      '291': 'fiber',
      '301': 'calcium',
      '303': 'iron',
      '304': 'magnesium',
      '305': 'phosphorus',
      '306': 'potassium',
      '307': 'sodium',
      '309': 'zinc',
      '320': 'vitamin_a',
      '401': 'vitamin_c',
      '404': 'thiamin',
      '405': 'riboflavin',
      '406': 'niacin',
      '410': 'pantothenic_acid',
      '415': 'vitamin_b6',
      '418': 'vitamin_b12',
      '430': 'vitamin_k',
      '601': 'cholesterol',
    };
    
    return nutrientMap[nutrientId] ?? 'nutrient_$nutrientId';
  }

  /// Search for foods containing specific allergens
  static Future<List<Map<String, dynamic>>> searchFoodsWithAllergens({
    required List<String> allergens,
    int maxResults = 20,
  }) async {
    if (kDebugMode) {
      print('NutritionixService: Searching for foods with allergens: $allergens');
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

        final common = searchResult['data']?['common'] as List<dynamic>? ?? [];
        final branded = searchResult['data']?['branded'] as List<dynamic>? ?? [];
        
        // Process common foods
        for (var food in common) {
          if (results.length >= maxResults) break;
          
          // Get detailed information
          final details = await getFoodDetails(foodId: food['food_name']);
          
          if (details['success'] == true) {
            final allergenInfo = extractAllergenInfo(details['data']);
            
            // Check if this food actually contains the searched allergen
            if (allergenInfo['allergens'].contains(allergen)) {
              results.add({
                ...details['data'],
                'searchedAllergen': allergen,
                'allergenInfo': allergenInfo,
                'foodType': 'common',
              });
            }
          }
        }

        // Process branded foods
        for (var food in branded) {
          if (results.length >= maxResults) break;
          
          // Get detailed information
          final details = await getFoodDetails(foodId: food['food_name']);
          
          if (details['success'] == true) {
            final allergenInfo = extractAllergenInfo(details['data']);
            
            // Check if this food actually contains the searched allergen
            if (allergenInfo['allergens'].contains(allergen)) {
              results.add({
                ...details['data'],
                'searchedAllergen': allergen,
                'allergenInfo': allergenInfo,
                'foodType': 'branded',
              });
            }
          }
        }

        // Add delay to avoid rate limiting
        await Future.delayed(const Duration(milliseconds: 1000));
        
      } catch (e) {
        if (kDebugMode) {
          print('NutritionixService: Error searching for allergen $allergen: $e');
        }
      }
    }

    if (kDebugMode) {
      print('NutritionixService: Found ${results.length} foods with allergens');
    }

    return results;
  }

  /// Get food categories
  static Future<Map<String, dynamic>> getFoodCategories() async {
    if (kDebugMode) {
      print('NutritionixService: Getting food categories');
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/categories'),
        headers: {
          'Content-Type': 'application/json',
          'x-app-id': _appId,
          'x-app-key': _appKey,
          'x-remote-user-id': '0',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (kDebugMode) {
          print('NutritionixService: Retrieved food categories');
        }
        return {
          'success': true,
          'data': data,
        };
      } else {
        if (kDebugMode) {
          print('NutritionixService: Error response ${response.statusCode}: ${response.body}');
        }
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}',
          'message': response.body,
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('NutritionixService: Error getting food categories: $e');
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
    required String foodName,
    double quantity = 100.0,
    String unit = 'g',
  }) async {
    if (kDebugMode) {
      print('NutritionixService: Getting nutrition info for food: $foodName');
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/natural/nutrients'),
        headers: {
          'Content-Type': 'application/json',
          'x-app-id': _appId,
          'x-app-key': _appKey,
          'x-remote-user-id': '0',
        },
        body: json.encode({
          'query': '$quantity $unit $foodName',
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (kDebugMode) {
          print('NutritionixService: Retrieved nutrition info');
        }
        return {
          'success': true,
          'data': data,
        };
      } else {
        if (kDebugMode) {
          print('NutritionixService: Error response ${response.statusCode}: ${response.body}');
        }
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}',
          'message': response.body,
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('NutritionixService: Error getting nutrition info: $e');
      }
      return {
        'success': false,
        'error': 'Network error',
        'message': e.toString(),
      };
    }
  }

  /// Get branded food information
  static Future<Map<String, dynamic>> getBrandedFood({
    required String foodId,
  }) async {
    if (kDebugMode) {
      print('NutritionixService: Getting branded food info for ID: $foodId');
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/search/item?nix_item_id=$foodId'),
        headers: {
          'Content-Type': 'application/json',
          'x-app-id': _appId,
          'x-app-key': _appKey,
          'x-remote-user-id': '0',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (kDebugMode) {
          print('NutritionixService: Retrieved branded food info');
        }
        return {
          'success': true,
          'data': data,
        };
      } else {
        if (kDebugMode) {
          print('NutritionixService: Error response ${response.statusCode}: ${response.body}');
        }
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}',
          'message': response.body,
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('NutritionixService: Error getting branded food info: $e');
      }
      return {
        'success': false,
        'error': 'Network error',
        'message': e.toString(),
      };
    }
  }
}
