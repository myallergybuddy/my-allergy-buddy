import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_credentials_service.dart';
import 'barcode_utils.dart';

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

    final candidates = BarcodeUtils.lookupCandidates(barcode);
    for (final candidate in candidates) {
      final match = await _searchBrandedByGtin(candidate, barcode);
      if (match != null) return match;
    }

    return {
      'success': false,
      'error': 'No food found',
      'message': 'No food found with barcode: $barcode',
    };
  }

  static Future<Map<String, dynamic>?> _searchBrandedByGtin(
    String query,
    String originalBarcode,
  ) async {
    final searchResult = await searchFoods(
      query: query,
      dataType: 'Branded',
      pageSize: 25,
    );
    if (searchResult['success'] == false) return null;

    final foods = searchResult['foods'] as List<dynamic>? ?? [];
    for (final food in foods) {
      if (food is! Map) continue;
      final gtinUpc = food['gtinUpc']?.toString() ?? '';
      if (BarcodeUtils.matches(gtinUpc, originalBarcode) ||
          BarcodeUtils.matches(gtinUpc, query)) {
        return await getFoodDetails(fdcId: food['fdcId']);
      }
    }

    if (foods.isEmpty) {
      final broadSearch = await searchFoods(query: query, pageSize: 25);
      if (broadSearch['success'] == false) return null;
      final broadFoods = broadSearch['foods'] as List<dynamic>? ?? [];
      for (final food in broadFoods) {
        if (food is! Map) continue;
        final gtinUpc = food['gtinUpc']?.toString() ?? '';
        if (BarcodeUtils.matches(gtinUpc, originalBarcode)) {
          return await getFoodDetails(fdcId: food['fdcId']);
        }
      }
    }
    return null;
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

    final description = foodData['description']?.toString() ?? '';
    final ingredientsStatement = foodData['ingredients']?.toString() ?? '';
    final additionalDescriptions = foodData['additionalDescriptions']?.toString() ?? '';

    if (ingredientsStatement.isNotEmpty) {
      ingredients.addAll(
        ingredientsStatement
            .split(RegExp(r'[,;•\n\r]'))
            .map((item) => item.trim())
            .where((item) => item.length > 1),
      );
    } else {
      if (description.isNotEmpty) ingredients.add(description);
      if (additionalDescriptions.isNotEmpty) ingredients.add(additionalDescriptions);
    }

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
      ingredientsStatement,
      ingredients.join(' '),
      foodData['foodAllergen']?.toString() ?? '',
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
