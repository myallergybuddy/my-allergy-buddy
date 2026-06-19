import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_credentials_service.dart';

class USDAFoodDataService {
  static const String _baseUrl = 'https://api.nal.usda.gov/fdc/v1';
  
  static String get _apiKey => ApiCredentialsService.usdaApiKey;
  
  /// Search for foods by query string
  static Future<Map<String, dynamic>> searchFoods({
    required String query,
    int pageSize = 25,
    int pageNumber = 1,
    String dataType = 'Foundation,SR Legacy',
  }) async {
    if (kDebugMode) {
      print('USDAFoodDataService: Searching for foods with query: $query');
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/foods/search?api_key=$_apiKey&query=$query&pageSize=$pageSize&pageNumber=$pageNumber&dataType=$dataType'),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'MyAllergyBuddy/1.0 (Flutter App)',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (kDebugMode) {
          print('USDAFoodDataService: Found ${data['totalHits']} results');
        }
        return data;
      } else {
        if (kDebugMode) {
          print('USDAFoodDataService: Error response ${response.statusCode}: ${response.body}');
        }
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}',
          'message': response.body,
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('USDAFoodDataService: Error searching foods: $e');
      }
      return {
        'success': false,
        'error': 'Network error',
        'message': e.toString(),
      };
    }
  }

  /// Get detailed food information by FDC ID
  static Future<Map<String, dynamic>> getFoodDetails({
    required int fdcId,
  }) async {
    if (kDebugMode) {
      print('USDAFoodDataService: Getting food details for FDC ID: $fdcId');
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/food/$fdcId?api_key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'MyAllergyBuddy/1.0 (Flutter App)',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (kDebugMode) {
          print('USDAFoodDataService: Retrieved food details for: ${data['description']}');
        }
        return data;
      } else {
        if (kDebugMode) {
          print('USDAFoodDataService: Error response ${response.statusCode}: ${response.body}');
        }
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}',
          'message': response.body,
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('USDAFoodDataService: Error getting food details: $e');
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
    if (kDebugMode) {
      print('USDAFoodDataService: Searching by barcode: $barcode');
    }

    // Search branded foods first for better UPC matches
    final searchResult = await searchFoods(
      query: barcode,
      dataType: 'Branded',
      pageSize: 10,
    );
    
    if (searchResult['success'] == false) {
      return searchResult;
    }

    final foods = searchResult['foods'] as List<dynamic>? ?? [];
    
    // Look for exact barcode match
    for (var food in foods) {
      final gtinUpc = food['gtinUpc']?.toString() ?? '';
      
      if (gtinUpc == barcode) {
        return await getFoodDetails(fdcId: food['fdcId']);
      }
    }

    // Retry without data type filter
    if (foods.isEmpty) {
      final broadSearch = await searchFoods(query: barcode, pageSize: 10);
      if (broadSearch['success'] != false) {
        final broadFoods = broadSearch['foods'] as List<dynamic>? ?? [];
        for (var food in broadFoods) {
          final gtinUpc = food['gtinUpc']?.toString() ?? '';
          if (gtinUpc == barcode) {
            return await getFoodDetails(fdcId: food['fdcId']);
          }
        }
      }
    }

    return {
      'success': false,
      'error': 'No food found',
      'message': 'No food found with barcode: $barcode',
    };
  }

  /// Extract allergen information from USDA food data
  static Map<String, dynamic> extractAllergenInfo(Map<String, dynamic> foodData) {
    final allergens = <String>[];
    final ingredients = <String>[];
    final nutritionInfo = <String, dynamic>{};

    // Extract food nutrients
    final foodNutrients = foodData['foodNutrients'] as List<dynamic>? ?? [];
    
    for (var nutrient in foodNutrients) {
      final nutrientName = nutrient['nutrient']?['name']?.toString().toLowerCase() ?? '';
      final value = nutrient['amount']?.toString() ?? '';
      
      // Check for allergen-related nutrients
      if (nutrientName.contains('protein') || 
          nutrientName.contains('fat') || 
          nutrientName.contains('carbohydrate')) {
        nutritionInfo[nutrientName] = value;
      }
    }

    // Extract ingredients from description or additional descriptions
    final description = foodData['description']?.toString() ?? '';
    final additionalDescriptions = foodData['additionalDescriptions']?.toString() ?? '';
    
    if (description.isNotEmpty) {
      ingredients.add(description);
    }
    if (additionalDescriptions.isNotEmpty) {
      ingredients.add(additionalDescriptions);
    }

    // Check for common allergens in ingredients
    final allergenKeywords = {
      'milk': ['milk', 'dairy', 'cheese', 'cream', 'butter', 'whey', 'casein'],
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
      'description': description,
      'brandOwner': foodData['brandOwner']?.toString() ?? '',
      'brandName': foodData['brandName']?.toString() ?? '',
      'fdcId': foodData['fdcId']?.toString() ?? '',
      'dataSource': 'USDA FoodData Central',
    };
  }

  /// Search for foods containing specific allergens
  static Future<List<Map<String, dynamic>>> searchFoodsWithAllergens({
    required List<String> allergens,
    int maxResults = 50,
  }) async {
    if (kDebugMode) {
      print('USDAFoodDataService: Searching for foods with allergens: $allergens');
    }

    final results = <Map<String, dynamic>>[];
    
    for (String allergen in allergens) {
      try {
        // Search for foods containing the allergen
        final searchResult = await searchFoods(
          query: allergen,
          pageSize: maxResults,
        );

        if (searchResult['success'] == false) {
          continue;
        }

        final foods = searchResult['foods'] as List<dynamic>? ?? [];
        
        for (var food in foods) {
          if (results.length >= maxResults) break;
          
          // Get detailed information
          final details = await getFoodDetails(fdcId: food['fdcId']);
          
          if (details['success'] != false) {
            final allergenInfo = extractAllergenInfo(details);
            
            // Check if this food actually contains the searched allergen
            if (allergenInfo['allergens'].contains(allergen)) {
              results.add({
                ...details,
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
          print('USDAFoodDataService: Error searching for allergen $allergen: $e');
        }
      }
    }

    if (kDebugMode) {
      print('USDAFoodDataService: Found ${results.length} foods with allergens');
    }

    return results;
  }

  /// Get food categories
  static Future<Map<String, dynamic>> getFoodCategories() async {
    if (kDebugMode) {
      print('USDAFoodDataService: Getting food categories');
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/food-categories?api_key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'MyAllergyBuddy/1.0 (Flutter App)',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (kDebugMode) {
          print('USDAFoodDataService: Retrieved ${data.length} food categories');
        }
        return data;
      } else {
        if (kDebugMode) {
          print('USDAFoodDataService: Error response ${response.statusCode}: ${response.body}');
        }
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}',
          'message': response.body,
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('USDAFoodDataService: Error getting food categories: $e');
      }
      return {
        'success': false,
        'error': 'Network error',
        'message': e.toString(),
      };
    }
  }

  /// Get nutrient information
  static Future<Map<String, dynamic>> getNutrients() async {
    if (kDebugMode) {
      print('USDAFoodDataService: Getting nutrients');
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/nutrients?api_key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'MyAllergyBuddy/1.0 (Flutter App)',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (kDebugMode) {
          print('USDAFoodDataService: Retrieved ${data.length} nutrients');
        }
        return data;
      } else {
        if (kDebugMode) {
          print('USDAFoodDataService: Error response ${response.statusCode}: ${response.body}');
        }
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}',
          'message': response.body,
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('USDAFoodDataService: Error getting nutrients: $e');
      }
      return {
        'success': false,
        'error': 'Network error',
        'message': e.toString(),
      };
    }
  }
}
