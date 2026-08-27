import 'package:flutter/foundation.dart';
import 'api_credentials_service.dart';
import 'australian_curated_product_database.dart';
import 'australian_food_database_service.dart';
import 'open_food_facts_service.dart';
import 'product_database_service.dart';
import 'usda_fooddata_service.dart';
import 'edamam_service.dart';
import 'nutritionix_service.dart';
import 'spoonacular_service.dart';
import 'user_learned_product_store.dart';

class ProductLookupService {
  static const bool _enableOnlineLookup = true;
  static const bool _enableLocalFallback = true;
  static const bool _enableCaching = true;

  static Map<String, dynamic> _productResult(
    String dataSource,
    Map<String, dynamic> product,
  ) {
    return {
      'success': true,
      'message': 'Product found in $dataSource',
      'dataSource': dataSource,
      'product': product,
    };
  }

  /// Lookup product by barcode with multiple data sources
  static Future<Map<String, dynamic>> lookupProductByBarcode(String barcode) async {
    if (kDebugMode) {
      print('ProductLookup: Starting barcode lookup for: $barcode');
    }

    await ProductDatabaseService.initialize();
    await UserLearnedProductStore.initialize();
    final result = await _lookupProductByBarcodeFromSources(barcode);
    return UserLearnedProductStore.applyToLookupResult(barcode, result);
  }

  static Future<Map<String, dynamic>> _lookupProductByBarcodeFromSources(
    String barcode,
  ) async {
    // 1. Local bundled / curated database (fastest).
    // Unverified synthetic 93006050000xx SKUs are deferred so they cannot
    // shadow a real Open Food Facts product on the same barcode.
    final curated = AustralianCuratedProductDatabase.lookup(barcode);
    if (curated != null &&
        !ProductDatabaseService.isUnverifiedSyntheticBarcode(barcode)) {
      if (kDebugMode) {
        print('ProductLookup: Using curated allergen statements for $barcode');
      }
      return _productResult(
        'Local Database',
        Map<String, dynamic>.from(curated),
      );
    }

    Map<String, dynamic>? localResult;
    if (_enableLocalFallback) {
      localResult = await ProductDatabaseService.getProductByBarcode(barcode);
      if (localResult != null &&
          !ProductDatabaseService.isUnverifiedSyntheticBarcode(barcode)) {
        if (kDebugMode) {
          print('ProductLookup: Found product in local database');
        }
        return _productResult('Local Database', localResult);
      }
    }

    if (!_enableOnlineLookup) {
      if (_enableLocalFallback && localResult != null) {
        return _productResult('Local Database', localResult);
      }
      return _notFound();
    }

    // 2. Open Food Facts (premium, manual, cache, API v3/v2/v0)
    final openFoodFactsResult = await OpenFoodFactsService.getProduct(barcode);
    if (openFoodFactsResult != null) {
      if (kDebugMode) {
        print('ProductLookup: Found product in Open Food Facts');
      }

      if (openFoodFactsResult['isAustralianProduct'] == true) {
        final enhanced = await AustralianFoodDatabaseService.enhanceAndCacheProduct(
          openFoodFactsResult,
        );
        if (enhanced != null) {
          return _productResult('Australian Food Database', enhanced);
        }
      }

      return _productResult(
        openFoodFactsResult['data_source']?.toString() ?? 'Open Food Facts',
        openFoodFactsResult,
      );
    }

    // 3. Previously downloaded Australian products
    final cachedAustralian = AustralianFoodDatabaseService.getProductByBarcode(barcode);
    if (cachedAustralian != null) {
      if (kDebugMode) {
        print('ProductLookup: Found product in Australian cache');
      }
      return _productResult('Australian Food Database', cachedAustralian);
    }

    // 4. USDA FoodData Central
    final usdaResult = await searchUSDAByBarcode(barcode);
    if (usdaResult['success'] == true) {
      if (kDebugMode) {
        print('ProductLookup: Found product in USDA FoodData Central');
      }
      return usdaResult;
    }

    // 5. Edamam (requires configured API keys)
    if (ApiCredentialsService.isEdamamConfigured) {
      final edamamResult = await searchEdamamByBarcode(barcode);
      if (edamamResult['success'] == true) {
        if (kDebugMode) {
          print('ProductLookup: Found product in Edamam');
        }
        return edamamResult;
      }
    }

    // 6. Nutritionix (requires configured API keys)
    if (ApiCredentialsService.isNutritionixConfigured) {
      final nutritionixResult = await searchNutritionixByBarcode(barcode);
      if (nutritionixResult['success'] == true) {
        if (kDebugMode) {
          print('ProductLookup: Found product in Nutritionix');
        }
        return nutritionixResult;
      }
    }

    // 7. Spoonacular (requires configured API key)
    final spoonacularResult = await searchSpoonacularByBarcode(barcode);
    if (spoonacularResult['success'] == true) {
      if (kDebugMode) {
        print('ProductLookup: Found product in Spoonacular');
      }
      return spoonacularResult;
    }

    if (_enableLocalFallback && localResult != null) {
      if (kDebugMode) {
        print('ProductLookup: Falling back to local synthetic placeholder');
      }
      return _productResult('Local Database', localResult);
    }

    if (kDebugMode) {
      print('ProductLookup: Product not found in any data source');
    }

    return _notFound();
  }

  static Map<String, dynamic> _notFound() => {
        'success': false,
        'message': 'Product not found in any available data source',
        'dataSource': 'None',
      };

  /// Analyze product for allergens
  static Future<Map<String, dynamic>> analyzeProduct(
    String barcode,
    List<Map<String, dynamic>> userAllergies,
  ) async {
    final product = await lookupProductByBarcode(barcode);
    
    if (product['success'] == false) {
      return {
        'success': false,
        'message': product['message'],
        'dataSource': product['dataSource'],
      };
    }

    final productData = product['product'] as Map<String, dynamic>? ?? {};
    final rawIngredientStrings = (productData['ingredients'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    final ingredientStrings =
        ProductDatabaseService.ingredientsExcludingMayContain(rawIngredientStrings);
    productData['ingredients'] = ingredientStrings;

    // Recompute warnings from label data — cached products may contain stale entries.
    final crossContaminationWarnings =
        AustralianFoodDatabaseService.detectCrossContaminationWarnings(
      rawIngredientStrings,
    );
    final processingFacilityWarnings =
        AustralianFoodDatabaseService.computeProcessingFacilityWarnings(productData);

    // Analyze ingredients for allergens
    final detectedAllergens = ProductDatabaseService.analyzeAllergens(
      rawIngredientStrings,
      userAllergies,
    );
    
    // Get processing facility warnings from ProductDatabaseService (but not cross-contamination)
    final parsedIngredients =
        ProductDatabaseService.parseIngredientsWithWarnings(rawIngredientStrings);
    final productDbProcessingFacility = parsedIngredients['processingFacilityWarnings'] as List<String>;

    // Combine cross-contamination warnings from all sources
    List<Map<String, dynamic>> finalCrossContaminationWarnings = [];
    
    finalCrossContaminationWarnings.addAll(crossContaminationWarnings);

    if (kDebugMode) {
      print('ProductLookup: Found ${detectedAllergens.length} detected allergens');
      print('ProductLookup: Found ${finalCrossContaminationWarnings.length} cross-contamination warnings');
      print('ProductLookup: Found ${processingFacilityWarnings.length} processing facility warnings');
    }

    // Combine processing facility warnings from all sources
    List<Map<String, dynamic>> finalProcessingFacilityWarnings = [];
    
    finalProcessingFacilityWarnings.addAll(processingFacilityWarnings);
    for (String warning in productDbProcessingFacility) {
      finalProcessingFacilityWarnings.add({
        'type': 'processing_facility',
        'message': warning,
        'allergen': 'Unknown',
        'riskLevel': 'Medium',
        'confidence': 0.8,
        'detectionMethod': 'ProductDatabaseService processing facility detection',
      });
    }

    productData['mayContainItems'] = ProductDatabaseService.collectMayContainItems(
      ingredients: rawIngredientStrings,
      product: productData,
    );

    return {
      'success': true,
      'message': 'Product analyzed successfully',
      'product': productData,
      'detectedAllergens': detectedAllergens,
      'crossContaminationWarnings': finalCrossContaminationWarnings,
      'processingFacilityWarnings': finalProcessingFacilityWarnings,
      'scanDate': DateTime.now().toIso8601String(),
      'isSafe': detectedAllergens.isEmpty && finalCrossContaminationWarnings.isEmpty,
      'data_source': product['dataSource']?.toString() ??
          productData['dataSource']?.toString() ??
          productData['data_source']?.toString() ??
          'Unknown',
      'lookup_timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Search for products by name
  static Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    if (!_enableOnlineLookup) {
      return [];
    }

    try {
      return await OpenFoodFactsService.searchProducts(query);
    } catch (e) {
      if (kDebugMode) {
        print('ProductLookup: Search error: $e');
      }
      return [];
    }
  }

  /// Search USDA FoodData Central by barcode
  static Future<Map<String, dynamic>> searchUSDAByBarcode(String barcode) async {
    if (kDebugMode) {
      print('ProductLookup: Searching USDA FoodData Central for barcode: $barcode');
    }

    try {
      final usdaResult = await USDAFoodDataService.searchByBarcode(barcode: barcode);
      
      if (usdaResult['success'] == false) {
        if (kDebugMode) {
          print('ProductLookup: USDA search failed: ${usdaResult['message']}');
        }
        return {
          'success': false,
          'message': 'Product not found in USDA FoodData Central',
          'dataSource': 'USDA FoodData Central',
        };
      }

      final allergenInfo = USDAFoodDataService.extractAllergenInfo(usdaResult);
      
      final product = {
        'barcode': barcode,
        'name': usdaResult['description']?.toString() ?? 'Unknown Product',
        'brand': usdaResult['brandOwner']?.toString() ?? usdaResult['brandName']?.toString() ?? 'Unknown Brand',
        'ingredients': allergenInfo['ingredients'] ?? [],
        'allergens': allergenInfo['allergens'] ?? [],
        'nutritionInfo': allergenInfo['nutritionInfo'] ?? {},
        'dataSource': 'USDA FoodData Central',
        'fdcId': usdaResult['fdcId']?.toString() ?? '',
        'isAustralianProduct': false,
      };

      return {
        'success': true,
        'message': 'Product found in USDA FoodData Central',
        'dataSource': 'USDA FoodData Central',
        'product': product,
      };

    } catch (e) {
      if (kDebugMode) {
        print('ProductLookup: Error searching USDA: $e');
      }
      return {
        'success': false,
        'message': 'Error searching USDA FoodData Central: $e',
        'dataSource': 'USDA FoodData Central',
      };
    }
  }

  /// Search Edamam by barcode
  static Future<Map<String, dynamic>> searchEdamamByBarcode(String barcode) async {
    if (kDebugMode) {
      print('ProductLookup: Searching Edamam for barcode: $barcode');
    }

    try {
      final edamamResult = await EdamamService.searchByBarcode(barcode: barcode);
      
      if (edamamResult['success'] == false) {
        return {
          'success': false,
          'message': 'Product not found in Edamam',
          'dataSource': 'Edamam',
        };
      }

      final allergenInfo = EdamamService.extractAllergenInfo(edamamResult['data']);
      
      final product = {
        'barcode': barcode,
        'name': edamamResult['data']['label']?.toString() ?? 'Unknown Product',
        'brand': edamamResult['data']['brandOwner']?.toString() ?? 'Unknown Brand',
        'ingredients': allergenInfo['ingredients'] ?? [],
        'allergens': allergenInfo['allergens'] ?? [],
        'nutritionInfo': allergenInfo['nutritionInfo'] ?? {},
        'dataSource': 'Edamam',
        'foodId': edamamResult['data']['foodId']?.toString() ?? '',
        'isAustralianProduct': false,
      };

      return {
        'success': true,
        'message': 'Product found in Edamam',
        'dataSource': 'Edamam',
        'product': product,
      };

    } catch (e) {
      if (kDebugMode) {
        print('ProductLookup: Error searching Edamam: $e');
      }
      return {
        'success': false,
        'message': 'Error searching Edamam: $e',
        'dataSource': 'Edamam',
      };
    }
  }

  /// Search Nutritionix by barcode
  static Future<Map<String, dynamic>> searchNutritionixByBarcode(String barcode) async {
    if (kDebugMode) {
      print('ProductLookup: Searching Nutritionix for barcode: $barcode');
    }

    try {
      final nutritionixResult = await NutritionixService.searchByBarcode(barcode: barcode);
      
      if (nutritionixResult['success'] == false) {
        return {
          'success': false,
          'message': 'Product not found in Nutritionix',
          'dataSource': 'Nutritionix',
        };
      }

      final allergenInfo = NutritionixService.extractAllergenInfo(nutritionixResult['data']);
      
      final product = {
        'barcode': barcode,
        'name': allergenInfo['foodName'] ?? 'Unknown Product',
        'brand': allergenInfo['brandName'] ?? 'Unknown Brand',
        'ingredients': allergenInfo['ingredients'] ?? [],
        'allergens': allergenInfo['allergens'] ?? [],
        'nutritionInfo': allergenInfo['nutritionInfo'] ?? {},
        'dataSource': 'Nutritionix',
        'nixItemId': nutritionixResult['data']['foods']?[0]?['nix_item_id']?.toString() ?? '',
        'isAustralianProduct': false,
      };

      return {
        'success': true,
        'message': 'Product found in Nutritionix',
        'dataSource': 'Nutritionix',
        'product': product,
      };

    } catch (e) {
      if (kDebugMode) {
        print('ProductLookup: Error searching Nutritionix: $e');
      }
      return {
        'success': false,
        'message': 'Error searching Nutritionix: $e',
        'dataSource': 'Nutritionix',
      };
    }
  }

  /// Search Spoonacular by barcode
  static Future<Map<String, dynamic>> searchSpoonacularByBarcode(String barcode) async {
    if (kDebugMode) {
      print('ProductLookup: Searching Spoonacular for barcode: $barcode');
    }

    try {
      final product = await SpoonacularService.getProductByUPC(barcode);
      if (product == null) {
        return {
          'success': false,
          'message': 'Product not found in Spoonacular',
          'dataSource': 'Spoonacular',
        };
      }

      return _productResult('Spoonacular', {
        'barcode': barcode,
        'name': product['name'] ?? 'Unknown Product',
        'brand': product['brand'] ?? 'Unknown Brand',
        'ingredients': product['ingredients'] ?? [],
        'allergens': product['allergens'] ?? [],
        'image': product['image'],
        'nutritionInfo': product['nutrition'] ?? {},
        'dataSource': 'Spoonacular',
        'data_source': 'Spoonacular',
        'isAustralianProduct': false,
      });
    } catch (e) {
      if (kDebugMode) {
        print('ProductLookup: Error searching Spoonacular: $e');
      }
      return {
        'success': false,
        'message': 'Error searching Spoonacular: $e',
        'dataSource': 'Spoonacular',
      };
    }
  }

  /// Get cache statistics
  static Map<String, dynamic> getCacheStats() {
    return OpenFoodFactsService.getCacheStats();
  }

  /// Clear all caches
  static void clearCache() {
    OpenFoodFactsService.clearCache();
  }

  /// Add a product to the local database (for testing or user contributions)
  static void addProductToLocalDatabase(String barcode, Map<String, dynamic> product) {
    ProductDatabaseService.addProduct(barcode, product);
  }

  /// Get all products from local database (for testing)
  static Map<String, Map<String, dynamic>> getAllLocalProducts() {
    return ProductDatabaseService.getAllProducts();
  }

  /// Check if online lookup is enabled
  static bool get isOnlineLookupEnabled => _enableOnlineLookup;

  /// Check if local fallback is enabled
  static bool get isLocalFallbackEnabled => _enableLocalFallback;

  /// Check if caching is enabled
  static bool get isCachingEnabled => _enableCaching;
}
