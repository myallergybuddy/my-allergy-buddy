import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'usda_fooddata_service.dart';
import 'edamam_service.dart';
import 'nutritionix_service.dart';
import 'open_food_facts_service.dart';
import 'product_database_service.dart';
import 'barcode_utils.dart';

class AustralianFoodDatabaseService {
  // Open Food Facts structured search for Australian products
  static const String openFoodFactsUrl = 'https://world.openfoodfacts.org/api/v2/search';
  
  // FoodSwitch API for Australian supermarkets (currently unavailable)
  static const String foodSwitchBaseUrl = 'https://api.foodswitch.com.au';
  static const String foodSwitchApiKey = ''; // FoodSwitch website currently unavailable
  
  // Alternative Australian food databases
  static const String nutritionAustraliaUrl = 'https://www.nutritionaustralia.org/';
  static const String allergyAustraliaUrl = 'https://allergy.org.au/';
  static const String coeliacAustraliaUrl = 'https://www.coeliac.org.au/';
  
  // FSANZ (Food Standards Australia New Zealand) - Note: Limited public API access
  static const String fanzsBaseUrl = 'https://www.foodstandards.gov.au/';
  
  // GS1 Australia - Commercial database (requires subscription)
  static const String gs1AustraliaUrl = 'https://www.gs1au.org/';
  
  // Australian supermarket identifiers
  static const List<String> _australianSupermarkets = [
    'coles',
    'woolworths',
    'aldi',
    'iga',
    'foodland',
    'drakes',
    'spudshed',
    'harris farm',
  ];
  
  // Australian brand identifiers
  static const List<String> _australianBrands = [
    'arnott\'s',
    'sanitarium',
    'bega',
    'cadbury',
    'kraft',
    'nestle',
    'unilever',
    'mars',
    'coca-cola',
    'pepsico',
    'san remo',
    'masterfoods',
    'continental',
    'maggi',
    'uncle tobys',
    'kellogg\'s',
    'campbell\'s',
    'heinz',
    's&w',
    'golden circle',
    'berri',
    'dairy farmers',
    'devondale',
    'a2',
    'liddells',
    'so good',
    'vitasoy',
    'sanitarium so good',
    'freedom foods',
    'pureharvest',
    'macro',
    'organic times',
    'ceres organics',
    'honest to goodness',
    'the source bulk foods',
    'wholefoods house',
    'thomas dux',
    'harris farm markets',
    'about life',
    'flannerys',
    'natures harvest',
    'health food store',
    'vitamin king',
    'go vita',
    'health food emporium',
    'organic markets',
    'fresh food people',
    'everyday rewards',
    'flybuys',
    'coles brand',
    'woolworths brand',
    'aldi brand',
    'homebrand',
    'coles finest',
    'woolworths select',
    'woolworths macro',
    'coles organic',
    'woolworths organic',
    'aldi organic',
    'coles gluten free',
    'woolworths gluten free',
    'aldi gluten free',
    'coles dairy free',
    'woolworths dairy free',
    'aldi dairy free',
    'coles vegan',
    'woolworths vegan',
    'aldi vegan',
    'coles paleo',
    'woolworths paleo',
    'aldi paleo',
    'coles keto',
    'woolworths keto',
    'aldi keto',
    'coles low fodmap',
    'woolworths low fodmap',
    'aldi low fodmap',
    'coles nut free',
    'woolworths nut free',
    'aldi nut free',
    'coles egg free',
    'woolworths egg free',
    'aldi egg free',
    'coles soy free',
    'woolworths soy free',
    'aldi soy free',
    'coles wheat free',
    'woolworths wheat free',
    'aldi wheat free',
    'coles fish free',
    'woolworths fish free',
    'aldi fish free',
    'coles shellfish free',
    'woolworths shellfish free',
    'aldi shellfish free',
    'coles sesame free',
    'woolworths sesame free',
    'aldi sesame free',
    'coles sulfite free',
    'woolworths sulfite free',
    'aldi sulfite free',
    'coles mustard free',
    'woolworths mustard free',
    'aldi mustard free',
    'coles celery free',
    'woolworths celery free',
    'aldi celery free',
    'coles lupin free',
    'woolworths lupin free',
    'aldi lupin free',
    'coles mollusc free',
    'woolworths mollusc free',
    'aldi mollusc free',
  ];
  
  // Local storage for downloaded products
  static final Map<String, Map<String, dynamic>> _downloadedProducts = {};
  static const String _storageFileName = 'australian_food_database.json';
  


  // Allergen categories for filtering
  static const List<String> _allergenCategories = [
    'peanuts',
    'tree nuts',
    'milk',
    'eggs',
    'soy',
    'wheat',
    'fish',
    'shrimp',
    'crab',
    'lobster',
    'oysters',
    'mussels',
    'clams',
    'scallops',
    'squid',
    'octopus',
    'anchovies',
    'tuna',
    'salmon',
    'cod',
    'mackerel',
    'sardines',
    'trout',
    'bass',
    'snapper',
    'grouper',
    'mahi mahi',
    'halibut',
    'flounder',
    'sole',
    'perch',
    'catfish',
    'tilapia',
    'sea bass',
    'red snapper',
    'yellowfin tuna',
    'albacore tuna',
    'skipjack tuna',
    'bluefin tuna',
    'atlantic salmon',
    'pacific salmon',
    'rainbow trout',
    'brook trout',
    'brown trout',
    'lake trout',
    'arctic char',
    'whitefish',
    'herring',
    'pike',
    'walleye',
    'bluefish',
    'striped bass',
    'rockfish',
    'monkfish',
    'swordfish',
    'marlin',
    'shark',
    'ray',
    'eel',
    'sea urchin',
    'abalone',
    'conch',
    'whelk',
    'periwinkle',
    'limpet',
    'chiton',
    'sesame',
    'sulfites',
    'mustard',
    'celery',
    'lupin',
    'molluscs',
    'gluten',
    'lactose',
    'casein',
    // Additional grains
    'corn',
    'rice',
    'oats',
    'barley',
    'rye',
    'quinoa',
    'buckwheat',
    // Additional nuts
    'coconut',
    'brazil nut',
    'pistachio',
    'macadamia',
    'pine nut',
    'chestnut',
    // Fruits and vegetables
    'kiwi',
    'banana',
    'tomato',
    'strawberry',
    'apple',
    'peach',
    'pear',
    'melon',
    'cherry',
    'plum',
    'apricot',
    'grapes',
    'orange',
    'lemon',
    'lime',
    'mandarin',
    'mango',
    'avocado',
    'carrot',
    'potato',
    'sweet potato',
    'capsicum',
    'chilli',
    'cucumber',
    'zucchini',
    'peas',
    'lentils',
    'chickpeas',
    'spinach',
    'lettuce',
  ];

  /// Search and download Australian products containing specific allergens
  static Future<Map<String, dynamic>> searchAndDownloadProductsWithAllergens({
    required List<String> allergens,
    int maxProducts = 1000,
    bool includeCrossContamination = true,
    bool includeProcessingFacility = true,
  }) async {
    if (kDebugMode) {
      print('AustralianFoodDatabase: Starting search for products with allergens: $allergens');
    }

    final results = {
      'success': false,
      'message': '',
      'products': <Map<String, dynamic>>[],
      'statistics': <String, dynamic>{},
      'downloadDate': DateTime.now().toIso8601String(),
    };

    try {
      // 1. Search Open Food Facts for Australian products with allergens
      final openFoodFactsResults = await _searchOpenFoodFactsForAllergens(
        allergens: allergens,
        maxProducts: maxProducts,
      );

      // 2. Search FoodSwitch API for Australian supermarket products
      final foodSwitchResults = await _searchFoodSwitchForAllergens(
        allergens: allergens,
        maxProducts: maxProducts,
      );

      // 3. Search FSANZ database (if available)
      final fanzsResults = await _searchFSANZForAllergens(
        allergens: allergens,
        maxProducts: maxProducts,
      );

      // 4. Search Australian allergy organizations
      final australianAllergyResults = await _searchAustralianAllergyOrganizations(
        allergens: allergens,
        maxProducts: maxProducts,
      );

      // 5. Search Woolworths API for Australian products
      final woolworthsResults = await _searchWoolworthsForAllergens(
        allergens: allergens,
        maxProducts: maxProducts,
      );

      // 6. Search Coles API for Australian products
      final colesResults = await _searchColesForAllergens(
        allergens: allergens,
        maxProducts: maxProducts,
      );

      // 7. Search IGA API for Australian products
      final igaResults = await _searchIGAForAllergens(
        allergens: allergens,
        maxProducts: maxProducts,
      );

      // 8. Search Australian Food Standards database
      final foodStandardsResults = await _searchFoodStandardsForAllergens(
        allergens: allergens,
        maxProducts: maxProducts,
      );

      // 9. Search Allergy & Anaphylaxis Australia database
      final allergyAnaphylaxisResults = await _searchAllergyAnaphylaxisForAllergens(
        allergens: allergens,
        maxProducts: maxProducts,
      );

      // 10. Search Coeliac Australia database
      final coeliacResults = await _searchCoeliacAustraliaForAllergens(
        allergens: allergens,
        maxProducts: maxProducts,
      );

      // 11. Search USDA FoodData Central for Australian products
      final usdaResults = await _searchUSDAForAllergens(
        allergens: allergens,
        maxProducts: maxProducts,
      );

      // 12. Search Edamam for Australian products
      final edamamResults = await _searchEdamamForAllergens(
        allergens: allergens,
        maxProducts: maxProducts,
      );

      // 13. Search Nutritionix for Australian products
      final nutritionixResults = await _searchNutritionixForAllergens(
        allergens: allergens,
        maxProducts: maxProducts,
      );

      // Combine all results
      final allProducts = <Map<String, dynamic>>[];
      allProducts.addAll(openFoodFactsResults);
      allProducts.addAll(foodSwitchResults);
      allProducts.addAll(fanzsResults);
      allProducts.addAll(australianAllergyResults);
      allProducts.addAll(woolworthsResults);
      allProducts.addAll(colesResults);
      allProducts.addAll(igaResults);
      allProducts.addAll(foodStandardsResults);
      allProducts.addAll(allergyAnaphylaxisResults);
      allProducts.addAll(coeliacResults);
      allProducts.addAll(usdaResults);
      allProducts.addAll(edamamResults);
      allProducts.addAll(nutritionixResults);

      // Filter and enhance products
      final enhancedProducts = await _enhanceProductsWithAllergenInfo(
        products: allProducts,
        allergens: allergens,
        includeCrossContamination: includeCrossContamination,
        includeProcessingFacility: includeProcessingFacility,
      );

      // Save to local storage
      await _saveProductsToLocalStorage(enhancedProducts);

      // Update results
      results['success'] = true;
      results['products'] = enhancedProducts;
      results['statistics'] = {
        'totalProducts': enhancedProducts.length,
        'productsWithAllergens': enhancedProducts.where((p) => 
          (p['detectedAllergens'] as List).isNotEmpty).length,
        'allergensFound': allergens,
        'dataSources': [
          'Open Food Facts', 
          'FoodSwitch', 
          'FSANZ', 
          'Australian Allergy Organizations',
          'Woolworths',
          'Coles',
          'IGA',
          'Food Standards Australia',
          'Allergy & Anaphylaxis Australia',
          'Coeliac Australia',
          'USDA FoodData Central',
          'Edamam',
          'Nutritionix'
        ],
        'downloadTimestamp': DateTime.now().toIso8601String(),
      };

      if (kDebugMode) {
        print('AustralianFoodDatabase: Successfully downloaded ${enhancedProducts.length} products');
        final stats = results['statistics'] as Map<String, dynamic>?;
        print('AustralianFoodDatabase: Products with allergens: ${stats?['productsWithAllergens']}');
      }

    } catch (e) {
      results['message'] = 'Error downloading products: $e';
      if (kDebugMode) {
        print('AustralianFoodDatabase: Error downloading products: $e');
      }
    }

    return results;
  }

  /// Search Open Food Facts for Australian products with specific allergens
  static Future<List<Map<String, dynamic>>> _searchOpenFoodFactsForAllergens({
    required List<String> allergens,
    required int maxProducts,
  }) async {
    final products = <Map<String, dynamic>>[];
    
    try {
      for (String allergen in allergens) {
        if (kDebugMode) {
          print('AustralianFoodDatabase: Searching Open Food Facts for allergen: $allergen');
        }

        final parsedProducts = await OpenFoodFactsService.searchAustralianProducts(
          allergen: allergen,
          pageSize: 50,
        );

        for (final parsed in parsedProducts) {
          if (products.length >= maxProducts) break;
          final product = _mapParsedOffProduct(parsed, allergen);
          if (product != null) {
            products.add(product);
          }
        }

        await Future.delayed(const Duration(milliseconds: 500));
      }
    } catch (e) {
      if (kDebugMode) {
        print('AustralianFoodDatabase: Error searching Open Food Facts: $e');
      }
    }

    return products;
  }

  static Map<String, dynamic>? _mapParsedOffProduct(
    Map<String, dynamic> parsed,
    String searchedAllergen,
  ) {
    final brand = parsed['brand']?.toString().toLowerCase() ?? '';
    final name = parsed['name']?.toString().toLowerCase() ?? '';
    final categories = parsed['categories'] as List<dynamic>? ?? [];
    if (parsed['isAustralianProduct'] != true &&
        !_isAustralianBrand(brand) &&
        !_isAustralianSupermarketProduct(name, brand, categories)) {
      return null;
    }

    final allergens = (parsed['allergens'] as List<dynamic>? ?? [])
        .map((item) => item.toString().toLowerCase())
        .toList();
    if (searchedAllergen.isNotEmpty &&
        !_containsAllergen(allergens, searchedAllergen)) {
      return null;
    }

    return {
      ...parsed,
      'searchedAllergen': searchedAllergen,
      'image': OpenFoodFactsService.absoluteImageUrl(parsed['image']) ?? parsed['image'],
      'dataSource': 'Open Food Facts',
      'isAustralianProduct': true,
      'downloadDate': DateTime.now().toIso8601String(),
    };
  }

  static bool _containsAllergen(List<String> allergens, String searchedAllergen) {
    final searched = searchedAllergen.toLowerCase().trim();
    if (allergens.contains(searched)) return true;
    final searchedTag = OpenFoodFactsService.allergenToOffTag(searched);
    if (searchedTag == null) return false;
    return allergens.any(
      (allergen) => OpenFoodFactsService.allergenToOffTag(allergen) == searchedTag,
    );
  }

  /// Search FSANZ database for allergens (limited access)
  static Future<List<Map<String, dynamic>>> _searchFSANZForAllergens({
    required List<String> allergens,
    required int maxProducts,
  }) async {
    final products = <Map<String, dynamic>>[];
    
    // Note: FSANZ doesn't provide a public API for product searches
    // This is a placeholder for when/if they provide API access
    if (kDebugMode) {
      print('AustralianFoodDatabase: FSANZ API not publicly available');
    }

    return products;
  }

  /// Search Australian allergy organizations for additional allergen information
  static Future<List<Map<String, dynamic>>> _searchAustralianAllergyOrganizations({
    required List<String> allergens,
    required int maxProducts,
  }) async {
    final products = <Map<String, dynamic>>[];
    
    try {
      // Search Allergy Australia database
      for (String allergen in allergens) {
        if (kDebugMode) {
          print('AustralianFoodDatabase: Searching Australian allergy organizations for: $allergen');
        }

        // This would integrate with Allergy Australia's database if they provide API access
        // For now, this is a placeholder for future integration
        
        // Add delay to avoid rate limiting
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } catch (e) {
      if (kDebugMode) {
        print('AustralianFoodDatabase: Error searching Australian allergy organizations: $e');
      }
    }

    return products;
  }

  /// Search FoodSwitch API for Australian supermarket products
  static Future<List<Map<String, dynamic>>> _searchFoodSwitchForAllergens({
    required List<String> allergens,
    required int maxProducts,
  }) async {
    final products = <Map<String, dynamic>>[];
    
    // Note: FoodSwitch website is currently unavailable
    if (kDebugMode) {
      print('AustralianFoodDatabase: FoodSwitch website currently unavailable');
    }
    
    return products;
  }

  /// Search Woolworths API for Australian products
  static Future<List<Map<String, dynamic>>> _searchWoolworthsForAllergens({
    required List<String> allergens,
    required int maxProducts,
  }) async {
    final products = <Map<String, dynamic>>[];
    
    try {
      for (String allergen in allergens) {
        if (kDebugMode) {
          print('AustralianFoodDatabase: Searching Woolworths for allergen: $allergen');
        }

        // Woolworths API endpoint (if available)
        // Note: This is a placeholder for when Woolworths provides public API access
        final response = await http.get(
          Uri.parse('https://www.woolworths.com.au/api/v3/ui/search?searchTerm=$allergen&pageNumber=1&pageSize=50&url=&userSearchTerm=&searchType=&productGridLayoutType=grid&isSpecial=false&sortType=TraderRelevance&enableFilters=true&groupEditable=false&showNotAvailableProducts=false&isMobile=false&recipeUUID=&recipeType=&recipeName=&searchScope=SearchTermKeyword'),
          headers: {
            'User-Agent': 'MyAllergyBuddy/1.0 (Flutter App)',
            'Accept': 'application/json',
          },
        ).timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final productList = data?['Products'] as List<dynamic>? ?? [];

          for (var productData in productList) {
            if (products.length >= maxProducts) break;

            final product = _parseWoolworthsProduct(productData, allergen);
            if (product != null) {
              products.add(product);
            }
          }
        }

        // Add delay to avoid rate limiting
        await Future.delayed(const Duration(milliseconds: 1000));
      }
    } catch (e) {
      if (kDebugMode) {
        print('AustralianFoodDatabase: Error searching Woolworths: $e');
      }
    }
    
    return products;
  }

  /// Search Coles API for Australian products
  static Future<List<Map<String, dynamic>>> _searchColesForAllergens({
    required List<String> allergens,
    required int maxProducts,
  }) async {
    final products = <Map<String, dynamic>>[];
    
    // Note: Coles API is not publicly available
    if (kDebugMode) {
      print('AustralianFoodDatabase: Coles API not publicly available');
    }
    
    return products;
  }

  /// Search IGA API for Australian products
  static Future<List<Map<String, dynamic>>> _searchIGAForAllergens({
    required List<String> allergens,
    required int maxProducts,
  }) async {
    final products = <Map<String, dynamic>>[];
    
    // Note: IGA API is not publicly available
    if (kDebugMode) {
      print('AustralianFoodDatabase: IGA API not publicly available');
    }
    
    return products;
  }

  /// Search USDA FoodData Central for Australian products
  static Future<List<Map<String, dynamic>>> _searchUSDAForAllergens({
    required List<String> allergens,
    required int maxProducts,
  }) async {
    final products = <Map<String, dynamic>>[];
    
    try {
      if (kDebugMode) {
        print('AustralianFoodDatabase: Searching USDA FoodData Central for allergens: $allergens');
      }

      // Search for foods with allergens using USDA service
      final usdaResults = await USDAFoodDataService.searchFoodsWithAllergens(
        allergens: allergens,
        maxResults: maxProducts,
      );

      // Convert USDA results to our format
      for (var usdaFood in usdaResults) {
        if (products.length >= maxProducts) break;

        final allergenInfo = usdaFood['allergenInfo'] as Map<String, dynamic>? ?? {};
        final allergens = allergenInfo['allergens'] as List<dynamic>? ?? [];
        final ingredients = allergenInfo['ingredients'] as List<dynamic>? ?? [];

        // Convert to our product format
        final product = {
          'barcode': usdaFood['fdcId']?.toString() ?? '',
          'name': usdaFood['description']?.toString() ?? 'Unknown Product',
          'brand': usdaFood['brandOwner']?.toString() ?? usdaFood['brandName']?.toString() ?? 'Unknown Brand',
          'ingredients': ingredients.map((e) => e.toString()).toList(),
          'allergens': allergens.map((e) => e.toString()).toList(),
          'searchedAllergen': usdaFood['searchedAllergen']?.toString() ?? '',
          'image': null, // USDA doesn't provide images
          'supermarket': 'USDA FoodData Central',
          'nutritionGrade': null,
          'quantity': null,
          'categories': [usdaFood['foodCategory']?.toString() ?? ''],
          'dataSource': 'USDA FoodData Central',
          'isAustralianProduct': false, // USDA is US-focused
          'downloadDate': DateTime.now().toIso8601String(),
          'nutritionInfo': allergenInfo['nutritionInfo'] ?? {},
          'fdcId': usdaFood['fdcId']?.toString() ?? '',
        };

        products.add(product);
      }

      if (kDebugMode) {
        print('AustralianFoodDatabase: Found ${products.length} products from USDA FoodData Central');
      }

    } catch (e) {
      if (kDebugMode) {
        print('AustralianFoodDatabase: Error searching USDA FoodData Central: $e');
      }
    }
    
    return products;
  }

  /// Search Edamam for Australian products
  static Future<List<Map<String, dynamic>>> _searchEdamamForAllergens({
    required List<String> allergens,
    required int maxProducts,
  }) async {
    final products = <Map<String, dynamic>>[];
    
    try {
      if (kDebugMode) {
        print('AustralianFoodDatabase: Searching Edamam for allergens: $allergens');
      }

      // Search for foods with allergens using Edamam service
      final edamamResults = await EdamamService.searchFoodsWithAllergens(
        allergens: allergens,
        maxResults: maxProducts,
      );

      // Convert Edamam results to our format
      for (var edamamFood in edamamResults) {
        if (products.length >= maxProducts) break;

        final allergenInfo = edamamFood['allergenInfo'] as Map<String, dynamic>? ?? {};
        final allergens = allergenInfo['allergens'] as List<dynamic>? ?? [];
        final ingredients = allergenInfo['ingredients'] as List<dynamic>? ?? [];

        // Convert to our product format
        final product = {
          'barcode': edamamFood['foodId']?.toString() ?? '',
          'name': edamamFood['label']?.toString() ?? 'Unknown Product',
          'brand': edamamFood['brandOwner']?.toString() ?? 'Unknown Brand',
          'ingredients': ingredients.map((e) => e.toString()).toList(),
          'allergens': allergens.map((e) => e.toString()).toList(),
          'searchedAllergen': edamamFood['searchedAllergen']?.toString() ?? '',
          'image': null, // Edamam doesn't provide images
          'supermarket': 'Edamam',
          'nutritionGrade': null,
          'quantity': null,
          'categories': [edamamFood['category']?.toString() ?? ''],
          'dataSource': 'Edamam',
          'isAustralianProduct': false, // Edamam is global
          'downloadDate': DateTime.now().toIso8601String(),
          'nutritionInfo': allergenInfo['nutritionInfo'] ?? {},
          'foodId': edamamFood['foodId']?.toString() ?? '',
        };

        products.add(product);
      }

      if (kDebugMode) {
        print('AustralianFoodDatabase: Found ${products.length} products from Edamam');
      }

    } catch (e) {
      if (kDebugMode) {
        print('AustralianFoodDatabase: Error searching Edamam: $e');
      }
    }
    
    return products;
  }

  /// Search Nutritionix for Australian products
  static Future<List<Map<String, dynamic>>> _searchNutritionixForAllergens({
    required List<String> allergens,
    required int maxProducts,
  }) async {
    final products = <Map<String, dynamic>>[];
    
    try {
      if (kDebugMode) {
        print('AustralianFoodDatabase: Searching Nutritionix for allergens: $allergens');
      }

      // Search for foods with allergens using Nutritionix service
      final nutritionixResults = await NutritionixService.searchFoodsWithAllergens(
        allergens: allergens,
        maxResults: maxProducts,
      );

      // Convert Nutritionix results to our format
      for (var nutritionixFood in nutritionixResults) {
        if (products.length >= maxProducts) break;

        final allergenInfo = nutritionixFood['allergenInfo'] as Map<String, dynamic>? ?? {};
        final allergens = allergenInfo['allergens'] as List<dynamic>? ?? [];
        final ingredients = allergenInfo['ingredients'] as List<dynamic>? ?? [];

        // Convert to our product format
        final product = {
          'barcode': nutritionixFood['nix_item_id']?.toString() ?? '',
          'name': allergenInfo['foodName']?.toString() ?? 'Unknown Product',
          'brand': allergenInfo['brandName']?.toString() ?? 'Unknown Brand',
          'ingredients': ingredients.map((e) => e.toString()).toList(),
          'allergens': allergens.map((e) => e.toString()).toList(),
          'searchedAllergen': nutritionixFood['searchedAllergen']?.toString() ?? '',
          'image': nutritionixFood['photo']?['thumb']?.toString(),
          'supermarket': 'Nutritionix',
          'nutritionGrade': null,
          'quantity': nutritionixFood['serving_qty']?.toString(),
          'categories': [nutritionixFood['foodType']?.toString() ?? ''],
          'dataSource': 'Nutritionix',
          'isAustralianProduct': false, // Nutritionix is global
          'downloadDate': DateTime.now().toIso8601String(),
          'nutritionInfo': allergenInfo['nutritionInfo'] ?? {},
          'nixItemId': nutritionixFood['nix_item_id']?.toString() ?? '',
        };

        products.add(product);
      }

      if (kDebugMode) {
        print('AustralianFoodDatabase: Found ${products.length} products from Nutritionix');
      }

    } catch (e) {
      if (kDebugMode) {
        print('AustralianFoodDatabase: Error searching Nutritionix: $e');
      }
    }
    
    return products;
  }

  /// Search Australian Food Standards database
  static Future<List<Map<String, dynamic>>> _searchFoodStandardsForAllergens({
    required List<String> allergens,
    required int maxProducts,
  }) async {
    final products = <Map<String, dynamic>>[];
    
    // Note: Australian Food Standards database is not publicly available
    if (kDebugMode) {
      print('AustralianFoodDatabase: Australian Food Standards database not publicly available');
    }
    
    return products;
  }

  /// Search Allergy & Anaphylaxis Australia database
  static Future<List<Map<String, dynamic>>> _searchAllergyAnaphylaxisForAllergens({
    required List<String> allergens,
    required int maxProducts,
  }) async {
    final products = <Map<String, dynamic>>[];
    
    // Note: Allergy & Anaphylaxis Australia database is not publicly available
    if (kDebugMode) {
      print('AustralianFoodDatabase: Allergy & Anaphylaxis Australia database not publicly available');
    }
    
    return products;
  }

  /// Search Coeliac Australia database
  static Future<List<Map<String, dynamic>>> _searchCoeliacAustraliaForAllergens({
    required List<String> allergens,
    required int maxProducts,
  }) async {
    final products = <Map<String, dynamic>>[];
    
    // Note: Coeliac Australia database is not publicly available
    if (kDebugMode) {
      print('AustralianFoodDatabase: Coeliac Australia database not publicly available');
    }
    
    return products;
  }

  /// Parse Woolworths product data
  static Map<String, dynamic>? _parseWoolworthsProduct(
    Map<String, dynamic> productData,
    String searchedAllergen,
  ) {
    try {
      // Extract allergen information
      final allergens = <String>[];
      final allergenList = productData['Allergens'] as List<dynamic>? ?? [];
      
      for (var allergen in allergenList) {
        final allergenName = allergen.toString().toLowerCase();
        if (_allergenCategories.contains(allergenName)) {
          allergens.add(allergenName);
        }
      }

      // Check if the searched allergen is present
      if (searchedAllergen.isNotEmpty && !allergens.contains(searchedAllergen)) {
        return null;
      }

      // Parse ingredients
      final ingredients = <String>[];
      if (productData['Ingredients'] != null) {
        ingredients.addAll(_parseIngredients(productData['Ingredients']));
      }

      return {
        'barcode': productData['Barcode'],
        'name': productData['Name'] ?? 'Unknown Product',
        'brand': productData['Brand'] ?? 'Unknown Brand',
        'ingredients': ingredients,
        'allergens': allergens,
        'searchedAllergen': searchedAllergen,
        'image': productData['Image'],
        'supermarket': 'Woolworths',
        'nutritionGrade': productData['HealthStarRating'],
        'quantity': productData['Quantity'],
        'categories': productData['Categories'],
        'dataSource': 'Woolworths',
        'isAustralianProduct': true,
        'downloadDate': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      if (kDebugMode) {
        print('AustralianFoodDatabase: Error parsing Woolworths product: $e');
      }
      return null;
    }
  }

  /// Parse ingredients text into list
  static List<String> _parseIngredients(String ingredientsText) {
    if (ingredientsText.isEmpty) return [];

    return ingredientsText
        .split(RegExp(r'[,;•\n\r]'))
        .map((ingredient) => ingredient.trim())
        .where((ingredient) => ingredient.isNotEmpty)
        .where((ingredient) => ingredient.length > 2)
        .toList();
  }

  /// Check if a brand is an Australian brand
  static bool _isAustralianBrand(String brand) {
    return _australianBrands.any((australianBrand) => 
        brand.contains(australianBrand.toLowerCase()));
  }

  /// Check if a product is from an Australian supermarket
  static bool _isAustralianSupermarketProduct(String productName, String brand, List<dynamic> categories) {
    // Check if product name or brand contains supermarket identifiers
    final combinedText = '${productName.toLowerCase()} ${brand.toLowerCase()}';
    
    return _australianSupermarkets.any((supermarket) => 
        combinedText.contains(supermarket.toLowerCase())) ||
        // Check for supermarket-specific categories
        categories.any((category) => 
            category.toString().toLowerCase().contains('australia') ||
            category.toString().toLowerCase().contains('coles') ||
            category.toString().toLowerCase().contains('woolworths') ||
            category.toString().toLowerCase().contains('aldi'));
  }

  /// Enhance products with additional allergen information
  static Future<List<Map<String, dynamic>>> _enhanceProductsWithAllergenInfo({
    required List<Map<String, dynamic>> products,
    required List<String> allergens,
    required bool includeCrossContamination,
    required bool includeProcessingFacility,
  }) async {
    final enhancedProducts = <Map<String, dynamic>>[];

    for (var product in products) {
      final enhancedProduct = Map<String, dynamic>.from(product);
      
      // Add allergen detection details
      enhancedProduct['detectedAllergens'] = _detectAllergensInProduct(
        product['ingredients'] as List<String>,
        allergens,
      );

      // Add cross-contamination warnings
      if (includeCrossContamination) {
        enhancedProduct['crossContaminationWarnings'] = _checkCrossContamination(
          product['ingredients'] as List<String>,
          allergens,
        );
      }

      // Add processing facility warnings
      if (includeProcessingFacility) {
        enhancedProduct['processingFacilityWarnings'] = _checkProcessingFacility(
          product,
          allergens,
        );
      }

      // Add risk assessment
      enhancedProduct['riskAssessment'] = _assessRisk(
        enhancedProduct['detectedAllergens'] as List<Map<String, dynamic>>,
        enhancedProduct['crossContaminationWarnings'] as List<Map<String, dynamic>>,
        enhancedProduct['processingFacilityWarnings'] as List<Map<String, dynamic>>,
      );

      enhancedProducts.add(enhancedProduct);
    }

    return enhancedProducts;
  }

  /// Detect allergens in product ingredients
  static List<Map<String, dynamic>> _detectAllergensInProduct(
    List<String> ingredients,
    List<String> allergens,
  ) {
    final detectedAllergens = <Map<String, dynamic>>[];
    final lowerIngredients = ingredients.map((e) => e.toLowerCase()).toList();
    final combinedIngredients = lowerIngredients.join(' ');

    // French allergen name mappings (unused but kept for future internationalization)
    /*
    final Map<String, List<String>> frenchAllergenNames = {
      'peanuts': ['cacahuetes', 'cacahuètes', 'arachides', 'cacahuete', 'cacahuète'],
      'tree_nuts': ['noix d\'arbres', 'noix d\'arbre', 'noix', 'amandes', 'noisettes', 'pistaches', 'noix de cajou'],
      'milk': ['lait', 'laitier', 'lactose', 'caséine', 'lactosérum'],
      'eggs': ['œufs', 'oeufs', 'œuf', 'oeuf', 'ovalbumine'],
      'soy': ['soja', 'soya', 'lécithine de soja', 'lécithine de soya'],
      'wheat': ['blé', 'gluten', 'céréales contenant du gluten'],
      'fish': ['poisson', 'poissons'],
      'shellfish': ['crustacés', 'mollusques', 'fruits de mer'],
      'sesame': ['sésame', 'sesame'],
      'sulfites': ['sulfites', 'sulfite'],
      'mustard': ['moutarde'],
      'celery': ['céleri', 'celeri'],
      'lupin': ['lupin'],
      'molluscs': ['mollusques'],
      // Fruits and vegetables
      'apple': ['pomme', 'pommes'],
      'peach': ['pêche', 'pêches'],
      'pear': ['poire', 'poires'],
      'melon': ['melon', 'melons'],
      'cherry': ['cerise', 'cerises'],
      'plum': ['prune', 'prunes'],
      'apricot': ['abricot', 'abricots'],
      'grapes': ['raisin', 'raisins'],
      'orange': ['orange', 'oranges'],
      'lemon': ['citron', 'citrons'],
      'lime': ['citron vert', 'citrons verts'],
      'mandarin': ['mandarine', 'mandarines'],
      'mango': ['mangue', 'mangues'],
      'avocado': ['avocat', 'avocats'],
      'carrot': ['carotte', 'carottes'],
      'potato': ['pomme de terre', 'pommes de terre'],
      'sweet_potato': ['patate douce', 'patates douces'],
      'capsicum': ['poivron', 'poivrons'],
      'chilli': ['piment', 'piments'],
      'cucumber': ['concombre', 'concombres'],
      'zucchini': ['courgette', 'courgettes'],
      'peas': ['petit pois', 'petits pois'],
      'lentils': ['lentille', 'lentilles'],
      'chickpeas': ['pois chiche', 'pois chiches'],
      'spinach': ['épinard', 'épinards'],
      'lettuce': ['laitue', 'laitues'],
    };
    */

    if (kDebugMode) {
      print('AustralianFoodDatabase: _detectAllergensInProduct called');
      print('AustralianFoodDatabase: Ingredients: $ingredients');
      print('AustralianFoodDatabase: Allergens to check: $allergens');
    }
    
    for (String allergen in allergens) {
      if (kDebugMode) {
        print('AustralianFoodDatabase: Checking for allergen: $allergen');
      }
      
      bool found = false;
      String matchedIngredient = '';
      bool isCrossContamination = false;
      String detectionMethod = 'Ingredient analysis';
      double confidence = 0.9;
      String riskLevel = 'High';

      // Create comprehensive allergen name variations for better detection
      final allergenLower = allergen.toLowerCase();
      final allergenVariations = <String>[
        allergenLower,
        allergenLower.replaceAll(' ', ''),
        allergenLower.replaceAll(' ', '_'),
        allergenLower.replaceAll('_', ' '),
      ];
      
      // Add common variations for specific allergens
      if (allergenLower == 'wheat') {
        allergenVariations.addAll(['wheat', 'wheat flour', 'wheat starch', 'wheat protein', 'wheat germ']);
      } else if (allergenLower == 'tree nuts') {
        allergenVariations.addAll(['nuts', 'tree nuts', 'almonds', 'walnuts', 'cashews', 'pistachios', 'pecans', 'hazelnuts', 'macadamia', 'brazil nuts']);
      } else if (allergenLower == 'peanuts') {
        allergenVariations.addAll(['peanuts', 'peanut', 'groundnuts', 'arachis']);
      } else if (allergenLower == 'milk') {
        allergenVariations.addAll(['milk', 'dairy', 'lactose', 'casein', 'whey', 'butter', 'cream']);
      } else if (allergenLower == 'egg') {
        allergenVariations.addAll(['egg', 'eggs', 'ovalbumin', 'albumin']);
      } else if (allergenLower == 'soy') {
        allergenVariations.addAll(['soy', 'soya', 'soybean', 'soybeans', 'soy protein', 'soy lecithin']);
      } else if (allergenLower == 'fish') {
        allergenVariations.addAll(['fish', 'seafood', 'tuna', 'salmon', 'cod', 'mackerel']);
      } else if (allergenLower == 'shellfish') {
        allergenVariations.addAll(['shellfish', 'shrimp', 'crab', 'lobster', 'oysters', 'mussels', 'clams']);
      } else if (allergenLower == 'sesame') {
        allergenVariations.addAll(['sesame', 'sesame seeds', 'tahini']);
      }
      
      final allAllergenNames = allergenVariations;
      
      if (kDebugMode) {
        print('AustralianFoodDatabase: Allergen variations for $allergen: $allAllergenNames');
      }

      // Check for cross-contamination phrases first
       final crossContaminationPhrases = [
         'may contain',
         'may contain traces',
         'may contain traces of',
         'processed in a facility',
         'manufactured in a facility',
       ];

      // First, check if the allergen appears in a cross-contamination context
      for (String phrase in crossContaminationPhrases) {
        for (String allergenName in allAllergenNames) {
          final patterns = [
            '$phrase $allergenName',
            '$phrase $allergenName,',
            '$phrase $allergenName.',
            '$phrase $allergenName;',
            '$phrase traces of $allergenName',
            '$phrase traces of $allergenName,',
            '$phrase traces of $allergenName.',
            '$phrase traces of $allergenName;',
          ];

          for (String pattern in patterns) {
            if (combinedIngredients.contains(pattern.toLowerCase())) {
              found = true;
              isCrossContamination = true;
              matchedIngredient = pattern;
              detectionMethod = 'Cross-contamination warning';
              confidence = 0.8;
              riskLevel = 'Medium';
              break;
            }
          }
          if (found) break;
        }
        if (found) break;
      }

      // If not found as cross-contamination, check for direct ingredient presence
      if (!found) {
        // Check if the allergen appears in a "may contain" context anywhere in the ingredients
        final mayContainIndex = combinedIngredients.indexOf('may contain');
        if (mayContainIndex >= 0) {
          // Look for the allergen within 200 characters after "may contain"
          final contextStart = mayContainIndex;
          final contextEnd = (mayContainIndex + 200).clamp(0, combinedIngredients.length);
          final context = combinedIngredients.substring(contextStart, contextEnd);
          
          for (String allergenName in allAllergenNames) {
            if (context.contains(allergenName.toLowerCase())) {
              found = true;
              isCrossContamination = true;
              matchedIngredient = 'Found in may contain section';
              detectionMethod = 'Cross-contamination warning';
              confidence = 0.8;
              riskLevel = 'Medium';
              break;
            }
          }
        }
        
        // If still not found, check for direct ingredient presence
        if (!found) {
          // Check individual ingredients for exact and partial matches
          for (String ingredient in lowerIngredients) {
            for (String allergenName in allAllergenNames) {
              // Check for exact match
              if (ingredient == allergenName.toLowerCase()) {
                found = true;
                matchedIngredient = ingredient;
                confidence = 0.95;
                break;
              }
              // Check for contains match (e.g., "drum wheat" contains "wheat")
              else if (ingredient.contains(allergenName.toLowerCase())) {
                found = true;
                matchedIngredient = ingredient;
                confidence = 0.9;
                break;
              }
              // Check for word boundary matches (e.g., "wheat flour" matches "wheat")
              else if (RegExp(r'\b' + RegExp.escape(allergenName.toLowerCase()) + r'\b').hasMatch(ingredient)) {
                found = true;
                matchedIngredient = ingredient;
                confidence = 0.9;
                break;
              }
            }
            if (found) break;
          }

          // Check combined ingredients for partial matches
          if (!found) {
            for (String allergenName in allAllergenNames) {
              if (combinedIngredients.contains(allergenName.toLowerCase())) {
                found = true;
                matchedIngredient = 'Found in ingredient list';
                confidence = 0.85;
                break;
              }
            }
          }
        }
      }

             if (found) {
                   // Format ingredient text for display
          String translatedMatchedIngredient = matchedIngredient;
          if (matchedIngredient.isNotEmpty) {
            translatedMatchedIngredient = _formatWarningMessage(matchedIngredient);
          }
         
         detectedAllergens.add({
           'name': allergen,
           'matchedIngredient': translatedMatchedIngredient,
           'detectionMethod': detectionMethod,
           'confidence': confidence,
           'riskLevel': riskLevel,
           'isCrossContamination': isCrossContamination,
           'originalMatchedIngredient': matchedIngredient,
         });
         
         if (kDebugMode) {
           print('AustralianFoodDatabase: ✅ FOUND ALLERGEN $allergen');
           print('AustralianFoodDatabase: Detection method: $detectionMethod');
           print('AustralianFoodDatabase: Matched ingredient: $matchedIngredient');
           print('AustralianFoodDatabase: Is cross-contamination: $isCrossContamination');
           print('AustralianFoodDatabase: Confidence: $confidence');
           print('AustralianFoodDatabase: Risk level: $riskLevel');
         }
       } else {
         if (kDebugMode) {
           print('AustralianFoodDatabase: ❌ NO ALLERGEN FOUND for $allergen');
         }
       }
    }

    if (kDebugMode) {
      print('AustralianFoodDatabase: Total allergens detected: ${detectedAllergens.length}');
      for (var allergen in detectedAllergens) {
        print('AustralianFoodDatabase: Detected: ${allergen['name']} (${allergen['detectionMethod']})');
      }
    }

    return detectedAllergens;
  }

  /// Check for cross-contamination warnings
  static List<Map<String, dynamic>> _checkCrossContamination(
    List<String> ingredients,
    List<String> allergens,
  ) {
    final warnings = <Map<String, dynamic>>[];
    final combinedIngredients = ingredients.join(' ').toLowerCase();
    
    if (kDebugMode) {
      print('AustralianFoodDatabase: _checkCrossContamination called');
      print('AustralianFoodDatabase: Ingredients: $ingredients');
      print('AustralianFoodDatabase: Combined ingredients: $combinedIngredients');
      print('AustralianFoodDatabase: Allergens to check: $allergens');
    }

                   // Check for common cross-contamination phrases in English only
      final crossContaminationPhrases = [
        'may contain',
        'may contain traces',
        'may contain traces of',
        'processed in a facility',
        'manufactured in a facility',
        'packaged in a facility',
        'produced in a facility',
        'made in a facility',
        'handled in a facility',
        'processed on equipment',
        'manufactured on equipment',
        'packaged on equipment',
        'produced on equipment',
        'made on equipment',
        'handled on equipment',
        'processed in the same facility',
        'manufactured in the same facility',
        'packaged in the same facility',
        'produced in the same facility',
        'made in the same facility',
        'handled in the same facility',
      ];

    // First, look for specific "may contain" statements with allergen names
    for (String phrase in crossContaminationPhrases) {
      if (combinedIngredients.contains(phrase)) {
                // Find the allergen names that appear after the cross-contamination phrase
        for (String allergen in allergens) {
          final allergenLower = allergen.toLowerCase();
          
          // Create comprehensive allergen name variations for cross-contamination detection
          final allergenVariations = <String>[
            allergenLower,
            allergenLower.replaceAll(' ', ''),
            allergenLower.replaceAll(' ', '_'),
            allergenLower.replaceAll('_', ' '),
          ];
          
          // Add common variations for specific allergens
          if (allergenLower == 'wheat') {
            allergenVariations.addAll(['wheat', 'wheat flour', 'wheat starch', 'wheat protein', 'wheat germ']);
          } else if (allergenLower == 'tree nuts') {
            allergenVariations.addAll(['nuts', 'tree nuts', 'almonds', 'walnuts', 'cashews', 'pistachios', 'pecans', 'hazelnuts', 'macadamia', 'brazil nuts']);
          } else if (allergenLower == 'peanuts') {
            allergenVariations.addAll(['peanuts', 'peanut', 'groundnuts', 'arachis']);
          } else if (allergenLower == 'milk') {
            allergenVariations.addAll(['milk', 'dairy', 'lactose', 'casein', 'whey', 'butter', 'cream']);
          } else if (allergenLower == 'egg') {
            allergenVariations.addAll(['egg', 'eggs', 'ovalbumin', 'albumin']);
          } else if (allergenLower == 'soy') {
            allergenVariations.addAll(['soy', 'soya', 'soybean', 'soybeans', 'soy protein', 'soy lecithin']);
          } else if (allergenLower == 'fish') {
            allergenVariations.addAll(['fish', 'seafood', 'tuna', 'salmon', 'cod', 'mackerel']);
          } else if (allergenLower == 'shellfish') {
            allergenVariations.addAll(['shellfish', 'shrimp', 'crab', 'lobster', 'oysters', 'mussels', 'clams']);
          } else if (allergenLower == 'sesame') {
            allergenVariations.addAll(['sesame', 'sesame seeds', 'tahini']);
          }
          
          final allAllergenNames = allergenVariations;
          
          // Look for patterns like "may contain nuts" or "may contain traces of milk"
          for (String allergenName in allAllergenNames) {
            final patterns = [
              '$phrase $allergenName',
              '$phrase $allergenName,',
              '$phrase $allergenName.',
              '$phrase $allergenName;',
              '$phrase traces of $allergenName',
              '$phrase traces of $allergenName,',
              '$phrase traces of $allergenName.',
              '$phrase traces of $allergenName;',

            ];
            
                         for (String pattern in patterns) {
               if (combinedIngredients.contains(pattern)) {
                 // Extract the actual warning text from the ingredients
                 String actualWarning = '';
                 for (String ingredient in ingredients) {
                   if (ingredient.toLowerCase().contains(pattern.toLowerCase())) {
                     actualWarning = ingredient;
                     break;
                   }
                 }
                 
                 // Use English warning message
                 String translatedMessage = 'Product may contain traces of $allergen';
                 
                 warnings.add({
                   'type': 'cross_contamination',
                   'message': translatedMessage,
                   'allergen': allergen,
                   'phrase': phrase,
                   'riskLevel': 'Medium',
                   'confidence': 0.8,
                   'detectionMethod': 'Cross-contamination phrase detection',
                   'originalWarning': actualWarning,
                 });
                 
                 if (kDebugMode) {
                   print('AustralianFoodDatabase: ✅ FOUND CROSS-CONTAMINATION WARNING');
                   print('AustralianFoodDatabase: Allergen: $allergen');
                   print('AustralianFoodDatabase: Pattern: $pattern');
                   print('AustralianFoodDatabase: Message: $translatedMessage');
                 }
                 
                 break; // Don't add duplicate warnings for the same allergen
               }
             }
          }
        }
      }
    }

    // Also check for general cross-contamination warnings without specific allergen names
    for (String phrase in crossContaminationPhrases) {
      if (combinedIngredients.contains(phrase)) {
        // Look for allergen names near the cross-contamination phrase
        final phraseIndex = combinedIngredients.indexOf(phrase);
        if (phraseIndex >= 0) {
          // Check for allergens within 100 characters of the phrase
          final contextStart = (phraseIndex - 50).clamp(0, combinedIngredients.length);
          final contextEnd = (phraseIndex + 150).clamp(0, combinedIngredients.length);
          final context = combinedIngredients.substring(contextStart, contextEnd);
          
                     for (String allergen in allergens) {
             final allergenLower = allergen.toLowerCase();
             
             // Create comprehensive allergen name variations for context-based detection
             final allergenVariations = <String>[
               allergenLower,
               allergenLower.replaceAll(' ', ''),
               allergenLower.replaceAll(' ', '_'),
               allergenLower.replaceAll('_', ' '),
             ];
             
             // Add common variations for specific allergens
             if (allergenLower == 'wheat') {
               allergenVariations.addAll(['wheat', 'wheat flour', 'wheat starch', 'wheat protein', 'wheat germ']);
             } else if (allergenLower == 'tree nuts') {
               allergenVariations.addAll(['nuts', 'tree nuts', 'almonds', 'walnuts', 'cashews', 'pistachios', 'pecans', 'hazelnuts', 'macadamia', 'brazil nuts']);
             } else if (allergenLower == 'peanuts') {
               allergenVariations.addAll(['peanuts', 'peanut', 'groundnuts', 'arachis']);
             } else if (allergenLower == 'milk') {
               allergenVariations.addAll(['milk', 'dairy', 'lactose', 'casein', 'whey', 'butter', 'cream']);
             } else if (allergenLower == 'egg') {
               allergenVariations.addAll(['egg', 'eggs', 'ovalbumin', 'albumin']);
             } else if (allergenLower == 'soy') {
               allergenVariations.addAll(['soy', 'soya', 'soybean', 'soybeans', 'soy protein', 'soy lecithin']);
             } else if (allergenLower == 'fish') {
               allergenVariations.addAll(['fish', 'seafood', 'tuna', 'salmon', 'cod', 'mackerel']);
             } else if (allergenLower == 'shellfish') {
               allergenVariations.addAll(['shellfish', 'shrimp', 'crab', 'lobster', 'oysters', 'mussels', 'clams']);
             } else if (allergenLower == 'sesame') {
               allergenVariations.addAll(['sesame', 'sesame seeds', 'tahini']);
             }
             
             final allAllergenNames = allergenVariations;
            
            bool foundInContext = false;
            for (String allergenName in allAllergenNames) {
              if (context.contains(allergenName)) {
                foundInContext = true;
                break;
              }
            }
            
                         if (foundInContext) {
               // Check if this allergen hasn't already been added
               if (!warnings.any((w) => w['allergen'] == allergen)) {
                 // Extract the actual warning text from the context
                 String actualWarning = context;
                 
                 // Use English warning message
                 String translatedMessage = 'Product may contain traces of $allergen';
                 
                 warnings.add({
                   'type': 'cross_contamination',
                   'message': translatedMessage,
                   'allergen': allergen,
                   'phrase': phrase,
                   'riskLevel': 'Medium',
                   'confidence': 0.6,
                   'detectionMethod': 'Context-based cross-contamination detection',
                   'originalWarning': actualWarning,
                 });
               }
             }
          }
        }
      }
    }
    
         // Remove test warning - we want to show real warnings only
     if (kDebugMode && warnings.isEmpty) {
       debugPrint('AustralianFoodDatabase: No cross-contamination warnings found');
     }
     
     if (kDebugMode) {
       print('AustralianFoodDatabase: _checkCrossContamination completed');
       print('AustralianFoodDatabase: Found ${warnings.length} cross-contamination warnings');
       for (var warning in warnings) {
         print('AustralianFoodDatabase: Warning - ${warning['allergen']}: ${warning['message']}');
       }
     }

          return warnings;
   }

   /// Extract allergen names from cross-contamination warnings
   static List<String> _extractAllergensFromCrossContaminationWarning(String warning) {
     final extractedAllergens = <String>[];
     final warningLower = warning.toLowerCase();
     
     // Map allergen keywords to proper allergen names
     final allergenKeywordMap = {
       // Peanuts
       'peanuts': 'Peanuts',
       'peanut': 'Peanuts',
       'groundnuts': 'Peanuts',
       'arachis': 'Peanuts',
       
       // Tree Nuts
       'nuts': 'Tree Nuts',
       'nut': 'Tree Nuts', // Add singular form
       'tree nuts': 'Tree Nuts',
       'tree nut': 'Tree Nuts', // Add singular form
       'almonds': 'Tree Nuts',
       'walnuts': 'Tree Nuts',
       'cashews': 'Tree Nuts',
       'pistachios': 'Tree Nuts',
       'pecans': 'Tree Nuts',
       'hazelnuts': 'Tree Nuts',
       'macadamia': 'Tree Nuts',
       'brazil nuts': 'Tree Nuts',
       
       // Milk
       'milk': 'Milk',
       'dairy': 'Milk',
       'lactose': 'Milk',
       'casein': 'Milk',
       'whey': 'Milk',
       'butter': 'Milk',
       'cream': 'Milk',
       
       // Eggs
       'eggs': 'Egg',
       'egg': 'Egg',
       'ovalbumin': 'Egg',
       'albumin': 'Egg',
       
       // Soy
       'soy': 'Soy',
       'soya': 'Soy',
       'soybean': 'Soy',
       'soybeans': 'Soy',
       'soy protein': 'Soy',
       'soy lecithin': 'Soy',
       
       // Wheat
       'wheat': 'Wheat',
       'wheat flour': 'Wheat',
       'wheat starch': 'Wheat',
       'wheat protein': 'Wheat',
       'wheat germ': 'Wheat',
       'gluten': 'Wheat',
       
       // Fish
       'fish': 'Fish',
       'seafood': 'Fish',
       'tuna': 'Fish',
       'salmon': 'Fish',
       'cod': 'Fish',
       'mackerel': 'Fish',
       
       // Shellfish
       'shellfish': 'Shellfish',
       'shrimp': 'Shrimp',
       'crab': 'Crab',
       'lobster': 'Lobster',
       'oysters': 'Oysters',
       'mussels': 'Mussels',
       'clams': 'Clams',
       
       // Other allergens
       'sesame': 'Sesame',
       'sesame seeds': 'Sesame',
       'tahini': 'Sesame',
       'sulfites': 'Sulfites',
       'sulfite': 'Sulfites',
       'mustard': 'Mustard',
       'celery': 'Celery',
       'lupin': 'Lupin',
       'molluscs': 'Molluscs',
       'mollusks': 'Molluscs',
     };
     
     // Check for each allergen keyword and map to proper name
     for (String keyword in allergenKeywordMap.keys) {
       if (warningLower.contains(keyword.toLowerCase())) {
         final properName = allergenKeywordMap[keyword]!;
         if (!extractedAllergens.contains(properName)) {
           extractedAllergens.add(properName);
         }
         
         // Special handling for generic "nut" - add both Tree Nuts and Peanuts
         if (keyword.toLowerCase() == 'nut' && !extractedAllergens.contains('Peanuts')) {
           extractedAllergens.add('Peanuts');
         }
       }
     }
     
     if (kDebugMode) {
       print('AustralianFoodDatabase: Extracted allergens from warning "$warning": $extractedAllergens');
     }
     
     return extractedAllergens;
   }

      /// Public method to check for cross-contamination warnings
   static List<Map<String, dynamic>> checkCrossContaminationWarnings(
     List<String> ingredients,
     List<String> allergens,
   ) {
     return _checkCrossContamination(ingredients, allergens);
   }

   /// Enhanced method to detect cross-contamination warnings and extract allergen names
   static List<Map<String, dynamic>> detectCrossContaminationWarnings(
     List<String> ingredients,
   ) {
     final warnings = <Map<String, dynamic>>[];
     final combinedIngredients = ingredients.join(' ').toLowerCase();
     
     if (kDebugMode) {
       print('AustralianFoodDatabase: detectCrossContaminationWarnings called');
       print('AustralianFoodDatabase: Ingredients: $ingredients');
       print('AustralianFoodDatabase: Combined ingredients: $combinedIngredients');
     }
     
     // Check for cross-contamination phrases
     final crossContaminationPhrases = [
       'may contain',
       'may contain traces',
       'may contain traces of',
       'processed in a facility',
       'manufactured in a facility',
       'packaged in a facility',
       'produced in a facility',
       'made in a facility',
       'handled in a facility',
     ];
     
     // Look for cross-contamination phrases in ingredients
     for (String phrase in crossContaminationPhrases) {
       if (combinedIngredients.contains(phrase)) {
         // Find the ingredient that contains this phrase
         for (String ingredient in ingredients) {
           if (ingredient.toLowerCase().contains(phrase)) {
             // Extract allergen names from this warning
             final extractedAllergens = _extractAllergensFromCrossContaminationWarning(ingredient);
             
             for (String extractedAllergen in extractedAllergens) {
               warnings.add({
                 'type': 'cross_contamination',
                 'message': 'Product may contain traces of $extractedAllergen',
                 'allergen': extractedAllergen,
                 'phrase': phrase,
                 'riskLevel': 'Medium',
                 'confidence': 0.8,
                 'detectionMethod': 'Cross-contamination warning extraction',
                 'originalWarning': ingredient,
               });
               
               if (kDebugMode) {
                 print('AustralianFoodDatabase: ✅ EXTRACTED CROSS-CONTAMINATION WARNING');
                 print('AustralianFoodDatabase: Allergen: $extractedAllergen');
                 print('AustralianFoodDatabase: Original warning: $ingredient');
                 print('AustralianFoodDatabase: Message: Product may contain traces of $extractedAllergen');
               }
             }
           }
         }
       }
     }
     
     if (kDebugMode) {
       print('AustralianFoodDatabase: detectCrossContaminationWarnings completed');
       print('AustralianFoodDatabase: Found ${warnings.length} cross-contamination warnings');
       for (var warning in warnings) {
         print('AustralianFoodDatabase: Warning - ${warning['allergen']}: ${warning['message']}');
       }
     }
     
     return warnings;
   }



  /// Format warning message in English
  static String _formatWarningMessage(String warning) {
    // Simply return the warning as-is since we're only using English
    if (warning.isNotEmpty) {
      String formattedWarning = warning[0].toUpperCase() + warning.substring(1);
      if (!formattedWarning.endsWith('.') && !formattedWarning.endsWith('!') && !formattedWarning.endsWith('?')) {
        formattedWarning += '.';
      }
      return formattedWarning;
    }
    return warning;
  }

  /// Check for processing facility warnings
  static List<Map<String, dynamic>> _checkProcessingFacility(
    Map<String, dynamic> product,
    List<String> allergens,
  ) {
    final warnings = <Map<String, dynamic>>[];
    final facilityText = [
      product['manufacturingPlaces']?.toString() ?? '',
      product['origins']?.toString() ?? '',
      product['packaging']?.toString() ?? '',
    ].join(' ').toLowerCase();

    if (facilityText.trim().isEmpty) return warnings;

    const facilityPhrases = [
      'processed in a facility',
      'manufactured in a facility',
      'packaged in a facility',
      'produced in a facility',
      'facility processes',
      'facility that processes',
    ];

    for (final phrase in facilityPhrases) {
      if (facilityText.contains(phrase)) {
        warnings.add({
          'type': 'processing_facility',
          'message': 'Label mentions shared processing facility information',
          'allergen': 'Unknown',
          'facility': product['manufacturingPlaces'] ?? product['origins'] ?? product['brand'],
          'riskLevel': 'Low',
          'confidence': 0.6,
          'detectionMethod': 'Label facility statement',
        });
        break;
      }
    }

    return warnings;
  }

  /// Assess overall risk level
  static Map<String, dynamic> _assessRisk(
    List<Map<String, dynamic>> detectedAllergens,
    List<Map<String, dynamic>> crossContaminationWarnings,
    List<Map<String, dynamic>> processingFacilityWarnings,
  ) {
    double riskScore = 0.0;
    String riskLevel = 'Low';

    // Calculate risk score based on detected allergens
    riskScore += detectedAllergens.length * 0.8;
    
    // Add cross-contamination risk
    riskScore += crossContaminationWarnings.length * 0.4;
    
    // Add processing facility risk
    riskScore += processingFacilityWarnings.length * 0.2;

    // Determine risk level
    if (riskScore >= 1.0) {
      riskLevel = 'High';
    } else if (riskScore >= 0.5) {
      riskLevel = 'Medium';
    } else {
      riskLevel = 'Low';
    }

    return {
      'riskScore': riskScore,
      'riskLevel': riskLevel,
      'isSafe': detectedAllergens.isEmpty && crossContaminationWarnings.isEmpty,
      'recommendation': riskLevel == 'High' 
          ? 'Avoid this product' 
          : riskLevel == 'Medium' 
              ? 'Use caution' 
              : 'Likely safe',
    };
  }

  /// Save products to local storage
  static Future<void> _saveProductsToLocalStorage(List<Map<String, dynamic>> products) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_storageFileName');
      
      final data = {
        'products': products,
        'downloadDate': DateTime.now().toIso8601String(),
        'totalProducts': products.length,
      };

      await file.writeAsString(json.encode(data));
      
      // Update in-memory cache
      for (var product in products) {
        _downloadedProducts[product['barcode']] = product;
      }

      if (kDebugMode) {
        print('AustralianFoodDatabase: Saved ${products.length} products to local storage');
      }
    } catch (e) {
      if (kDebugMode) {
        print('AustralianFoodDatabase: Error saving to local storage: $e');
      }
    }
  }

  /// Load products from local storage
  static Future<List<Map<String, dynamic>>> loadProductsFromLocalStorage() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_storageFileName');
      
      if (await file.exists()) {
        final data = json.decode(await file.readAsString());
        final products = List<Map<String, dynamic>>.from(data['products'] ?? []);
        
        // Update in-memory cache
        for (var product in products) {
          _downloadedProducts[product['barcode']] = product;
        }

        if (kDebugMode) {
          print('AustralianFoodDatabase: Loaded ${products.length} products from local storage');
        }

        return products;
      }
    } catch (e) {
      if (kDebugMode) {
        print('AustralianFoodDatabase: Error loading from local storage: $e');
      }
    }

    return [];
  }

  /// Enhance a product with Australian allergen analysis and cache locally.
  static Future<Map<String, dynamic>?> enhanceAndCacheProduct(
    Map<String, dynamic> product,
  ) async {
    final enhanced = await _enhanceProductsWithAllergenInfo(
      products: [product],
      allergens: _allergenCategories,
      includeCrossContamination: true,
      includeProcessingFacility: true,
    );
    if (enhanced.isEmpty) return null;

    final result = enhanced.first;
    // Allergen matching against user profile is handled by ProductLookupService.
    result['detectedAllergens'] = [];
    result['mayContainItems'] = ProductDatabaseService.collectMayContainItems(
      ingredients: List<String>.from(result['ingredients'] ?? []),
      product: result,
    );
    final barcode = result['barcode']?.toString();
    if (barcode != null && barcode.isNotEmpty) {
      _downloadedProducts[barcode] = result;
      await _saveProductsToLocalStorage(_downloadedProducts.values.toList());
    }
    return result;
  }

  /// Recompute processing facility warnings from label fields (ignores stale cache).
  static List<Map<String, dynamic>> computeProcessingFacilityWarnings(
    Map<String, dynamic> product,
  ) {
    return _checkProcessingFacility(product, const []);
  }

  /// Strip stale allergen analysis from cached downloads.
  static Map<String, dynamic> sanitizeStoredProduct(Map<String, dynamic> product) {
    final sanitized = Map<String, dynamic>.from(product);
    sanitized['detectedAllergens'] = <Map<String, dynamic>>[];
    sanitized['processingFacilityWarnings'] =
        computeProcessingFacilityWarnings(sanitized);
    sanitized['mayContainItems'] = ProductDatabaseService.collectMayContainItems(
      ingredients: List<String>.from(sanitized['ingredients'] ?? []),
      product: sanitized,
    );
    return sanitized;
  }

  /// Get product by barcode from downloaded database
  static Map<String, dynamic>? getProductByBarcode(String barcode) {
    for (final candidate in BarcodeUtils.lookupCandidates(barcode)) {
      final product = _downloadedProducts[candidate];
      if (product != null) return sanitizeStoredProduct(product);
    }
    return null;
  }

  /// Get product by barcode with auto-download if not found locally
  static Future<Map<String, dynamic>?> getProductByBarcodeWithAutoDownload(String barcode) async {
    // First check local database
    final localProduct = getProductByBarcode(barcode);
    if (localProduct != null) {
      if (kDebugMode) {
        print('AustralianFoodDatabase: Found product locally: ${localProduct['name']}');
      }
      return sanitizeStoredProduct(localProduct);
    }

    // If not found locally, try to download from Open Food Facts
    if (kDebugMode) {
      print('AustralianFoodDatabase: Product not found locally, attempting to download: $barcode');
    }

    try {
      final downloadedProduct = await _downloadProductByBarcode(barcode);
      if (downloadedProduct != null) {
        // Save to local storage
        _downloadedProducts[barcode] = downloadedProduct;
        await _saveProductsToLocalStorage(_downloadedProducts.values.toList());
        
        if (kDebugMode) {
          print('AustralianFoodDatabase: Successfully downloaded and saved product: ${downloadedProduct['name']}');
        }
        return downloadedProduct;
      }
    } catch (e) {
      if (kDebugMode) {
        print('AustralianFoodDatabase: Error auto-downloading product: $e');
      }
    }

    return null;
  }

  /// Download a specific product by barcode from Open Food Facts
  static Future<Map<String, dynamic>?> _downloadProductByBarcode(String barcode) async {
    try {
      final offProduct = await OpenFoodFactsService.getProduct(barcode);
      if (offProduct == null) return null;

      if (offProduct['isAustralianProduct'] != true &&
          !_isAustralianBrand(offProduct['brand']?.toString().toLowerCase() ?? '')) {
        final countries = offProduct['countries'] as List<dynamic>? ?? [];
        final origins = offProduct['origins']?.toString() ?? '';
        final isAustralian = countries.contains('en:australia') ||
            origins.toLowerCase().contains('australia');
        if (!isAustralian) return null;
      }

      final product = Map<String, dynamic>.from(offProduct);
      product['isAustralianProduct'] = true;
      product['dataSource'] = 'Australian Food Database (Open Food Facts)';

      return enhanceAndCacheProduct(product);
    } catch (e) {
      if (kDebugMode) {
        print('AustralianFoodDatabase: Error downloading product by barcode: $e');
      }
    }

    return null;
  }

  /// Search products by allergen
  static List<Map<String, dynamic>> searchProductsByAllergen(String allergen) {
    return _downloadedProducts.values
        .where((product) {
          final detectedAllergens = product['detectedAllergens'] as List<dynamic>? ?? [];
          return detectedAllergens.any((a) => a['name'] == allergen);
        })
        .toList();
  }

  /// Get statistics about downloaded database
  static Map<String, dynamic> getDatabaseStatistics() {
    final products = _downloadedProducts.values.toList();
    final allergenCounts = <String, int>{};

    for (var product in products) {
      final allergens = product['allergens'] as List<dynamic>? ?? [];
      for (var allergen in allergens) {
        allergenCounts[allergen] = (allergenCounts[allergen] ?? 0) + 1;
      }
    }

    return {
      'totalProducts': products.length,
      'allergenCounts': allergenCounts,
      'dataSources': products.map((p) => p['dataSource']).toSet().toList(),
      'downloadDate': products.isNotEmpty ? products.first['downloadDate'] : null,
    };
  }

  /// Clear downloaded database
  static Future<void> clearDatabase() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_storageFileName');
      
      if (await file.exists()) {
        await file.delete();
      }
      
      _downloadedProducts.clear();

      if (kDebugMode) {
        print('AustralianFoodDatabase: Cleared database');
      }
    } catch (e) {
      if (kDebugMode) {
        print('AustralianFoodDatabase: Error clearing database: $e');
      }
    }
  }

  /// Check if a product exists in Open Food Facts database
  static Future<Map<String, dynamic>> checkProductExistsInOpenFoodFacts(String barcode) async {
    try {
      final product = await OpenFoodFactsService.getProduct(barcode);
      if (product != null) {
        final countries = product['countries'] as List<dynamic>? ?? [];
        final origins = product['origins']?.toString() ?? '';
        final isAustralianProduct = product['isAustralianProduct'] == true ||
            countries.contains('en:australia') ||
            origins.toLowerCase().contains('australia');

        return {
          'exists': true,
          'isAustralian': isAustralianProduct,
          'productName': product['name'] ?? 'Unknown',
          'brand': product['brand'] ?? 'Unknown',
          'countries': countries,
          'origins': origins,
          'status': isAustralianProduct ? 'found_australian' : 'found_not_australian',
          'message': isAustralianProduct 
              ? 'Found Australian product in Open Food Facts'
              : 'Found product in Open Food Facts (not Australian)',
        };
      }

      return {
        'exists': false,
        'isAustralian': false,
        'status': 'not_found',
        'message': 'Product not found in Open Food Facts',
      };
    } catch (e) {
      if (kDebugMode) {
        print('AustralianFoodDatabase: Error checking product existence: $e');
      }
      return {
        'exists': false,
        'isAustralian': false,
        'status': 'error',
        'message': e.toString(),
      };
    }
  }

  /// Additional data sources for barcode and ingredient information
  /// 
  /// **Australian Sources:**
  /// 1. Woolworths - API available but requires authentication
  /// 2. Coles - API available but requires authentication  
  /// 3. IGA - No public API
  /// 4. Aldi - No public API
  /// 5. Food Standards Australia New Zealand (FSANZ) - Limited public access
  /// 6. Allergy & Anaphylaxis Australia - No public API
  /// 7. Coeliac Australia - No public API
  /// 8. Australian Food and Grocery Council - No public API
  /// 9. Australian Competition and Consumer Commission (ACCC) - Product recalls
  /// 10. Therapeutic Goods Administration (TGA) - Limited food data
  /// 
  /// **International Sources:**
  /// 11. Open Food Facts - ✅ Currently integrated
  /// 12. FoodSwitch - ❌ Website down
  /// 13. USDA FoodData Central - Free API available
  /// 14. European Food Safety Authority (EFSA) - Limited public access
  /// 15. Health Canada - Limited public access
  /// 16. Food Standards Agency (UK) - Limited public access
  /// 17. Food Safety and Standards Authority of India - Limited public access
  /// 
  /// **Commercial APIs:**
  /// 18. Spoonacular - ✅ Available (requires API key)
  /// 19. Edamam - Available (requires API key)
  /// 20. Nutritionix - Available (requires API key)
  /// 21. Calorie Mama - Available (requires API key)
  /// 22. FoodData Central API - Free tier available
  /// 
  /// **Scraping Sources (if APIs unavailable):**
  /// 23. Woolworths website scraping
  /// 24. Coles website scraping
  /// 25. IGA website scraping
  /// 26. Aldi website scraping
  /// 27. Manufacturer websites
  /// 28. Supermarket websites
  /// 
  /// **Community Sources:**
  /// 29. User-submitted data
  /// 30. Crowdsourced ingredient lists
  /// 31. Allergy community databases
  /// 32. Health professional submissions
  /// 
  /// **Government Sources:**
  /// 33. Product recall databases
  /// 34. Food safety alerts
  /// 35. Import/export databases
  /// 36. Food composition databases
  static const Map<String, Map<String, dynamic>> _dataSources = {
    'open_food_facts': {
      'name': 'Open Food Facts',
      'status': 'active',
      'api_url': 'https://world.openfoodfacts.org/api/v3/product/',
      'requires_auth': false,
      'rate_limit': 'moderate',
      'coverage': 'global',
      'australian_products': 'good',
    },
    'woolworths': {
      'name': 'Woolworths',
      'status': 'limited',
      'api_url': 'https://www.woolworths.com.au/api/v3/ui/search',
      'requires_auth': true,
      'rate_limit': 'strict',
      'coverage': 'australia',
      'australian_products': 'excellent',
    },
    'coles': {
      'name': 'Coles',
      'status': 'limited',
      'api_url': 'https://shop.coles.com.au/api/v1/search',
      'requires_auth': true,
      'rate_limit': 'strict',
      'coverage': 'australia',
      'australian_products': 'excellent',
    },
    'usda_fooddata': {
      'name': 'USDA FoodData Central',
      'status': 'available',
      'api_url': 'https://api.nal.usda.gov/fdc/v1/',
      'requires_auth': false,
      'rate_limit': 'moderate',
      'coverage': 'global',
      'australian_products': 'limited',
    },
    'spoonacular': {
      'name': 'Spoonacular',
      'status': 'available',
      'api_url': 'https://api.spoonacular.com/food/',
      'requires_auth': true,
      'rate_limit': 'moderate',
      'coverage': 'global',
      'australian_products': 'good',
    },
    'edamam': {
      'name': 'Edamam',
      'status': 'available',
      'api_url': 'https://api.edamam.com/api/food-database/v2/',
      'requires_auth': true,
      'rate_limit': 'moderate',
      'coverage': 'global',
      'australian_products': 'moderate',
    },
    'nutritionix': {
      'name': 'Nutritionix',
      'status': 'available',
      'api_url': 'https://trackapi.nutritionix.com/v2/',
      'requires_auth': true,
      'rate_limit': 'moderate',
      'coverage': 'global',
      'australian_products': 'moderate',
    },
  };

  /// Get available data sources
  static Map<String, Map<String, dynamic>> getAvailableDataSources() {
    return _dataSources;
  }

  /// Get data source status
  static String getDataSourceStatus(String sourceKey) {
    return _dataSources[sourceKey]?['status'] ?? 'unknown';
  }

  /// Check if data source requires authentication
  static bool requiresAuthentication(String sourceKey) {
    return _dataSources[sourceKey]?['requires_auth'] ?? false;
  }
} 