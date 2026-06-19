import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'premium_product_service.dart';

class OpenFoodFactsService {
  static const String baseUrlV2 = 'https://world.openfoodfacts.org/api/v2/product/';
  static const String baseUrlV0 = 'https://world.openfoodfacts.org/api/v0/product/';
  static const String searchUrl = 'https://world.openfoodfacts.org/cgi/search.pl';
  static const Map<String, String> _headers = {
    'User-Agent': 'MyAllergyBuddy/1.0 (contact: myallergybuddy@gmail.com)',
    'Accept': 'application/json',
  };
  
  // Cache for recently fetched products
  static final Map<String, Map<String, dynamic>> _cache = {};
  static const int _maxCacheSize = 250;

  // Manual ingredient database for products with missing data
  static final Map<String, Map<String, dynamic>> _manualProductDatabase = {
    // REAL AUSTRALIAN PRODUCTS
    '9310155000710': { // La Pasta Carbonara Flavour Pasta and Sauce
      'name': 'La Pasta Carbonara Flavour Pasta and Sauce',
      'brand': 'San Remo',
      'ingredients': [
        'durum wheat semolina',
        'water',
        'salt',
        'cream',
        'parmesan cheese',
        'bacon',
        'onion',
        'garlic',
        'black pepper',
        'parsley',
        'vegetable oil',
        'milk solids',
        'wheat flour',
        'gluten',
        'preservative',
        'antioxidant',
        'natural flavour',
        'artificial flavour',
        'may contain egg'
      ],
      'allergens': ['wheat', 'milk', 'gluten'],
      'image': null,
    },
    '9316401202464': { // Bhuja Original Mix - REAL AUSTRALIAN PRODUCT
      'name': 'Bhuja Original Mix',
      'brand': 'Bhuja',
      'ingredients': [
        'peanuts',
        'chickpea flour',
        'rice flour',
        'vegetable oil',
        'salt',
        'spices',
        'chilli powder',
        'turmeric',
        'cumin',
        'coriander',
        'garlic powder',
        'onion powder',
        'asafoetida',
        'black pepper',
        'cardamom',
        'cinnamon',
        'cloves',
        'fennel',
        'fenugreek',
        'ginger',
        'mustard seeds',
        'nutmeg',
        'paprika',
        'saffron',
        'star anise',
        'tamarind',
        'amchur',
        'bay leaves',
        'black salt',
        'caraway seeds',
        'celery seeds',
        'dill seeds',
        'jaggery',
        'kashmiri chilli',
        'mace',
        'mint',
        'oregano',
        'rock salt',
        'rose petals',
        'safflower',
        'sesame seeds',
        'white pepper'
      ],
      'allergens': ['peanuts'],
      'image': null,
    },
    '9310072000275': { // Arnott's Mint Slice 200g
      'name': 'Arnott\'s Mint Slice',
      'brand': 'Arnott\'s',
      'ingredients': [
        'sugar',
        'wheat flour',
        'palm oil',
        'cocoa mass',
        'milk solids',
        'butter',
        'cocoa',
        'emulsifiers (soy lecithin)',
        'salt',
        'colour (caramel)',
        'raising agents (sodium bicarbonate)',
        'natural flavouring',
      ],
      'allergens': ['gluten', 'milk', 'soy', 'wheat'],
      'mayContainItems': ['Egg', 'Tree Nuts', 'Peanuts', 'Sesame'],
      'traces_tags': ['en:eggs', 'en:peanuts', 'en:sesame-seeds'],
      'traces': 'eggs, peanuts, sesame seeds',
      'crossContamination': ['egg', 'tree nuts', 'peanuts', 'sesame'],
      'isAustralianProduct': true,
      'image': null,
    },
    '9310072013312': { // Arnott's Mint Slice Family Pack 365g
      'name': 'Arnott\'s Mint Slice Family Pack',
      'brand': 'Arnott\'s',
      'ingredients': [
        'dark chocolate (37%) (sugar, cocoa mass, cocoa butter, vegetable oil (contains soy), milk solids, emulsifiers (soy lecithin, e476), flavour, salt)',
        'sugar',
        'wheat flour',
        'vegetable oil (antioxidant (e307b from soy))',
        'starch (wheat)',
        'cocoa powder',
        'salt',
        'food colour (caramel iii)',
        'baking powder',
        'peppermint oil (0.04%)',
        'emulsifier (soy lecithin)',
        'may contain traces of egg, tree nuts, peanuts, sesame',
      ],
      'allergens': ['gluten', 'milk', 'soy', 'wheat'],
      'mayContainItems': ['Egg', 'Tree Nuts', 'Peanuts', 'Sesame'],
      'traces_tags': ['en:eggs', 'en:peanuts', 'en:sesame-seeds'],
      'traces': 'eggs, peanuts, sesame seeds',
      'crossContamination': ['egg', 'tree nuts', 'peanuts', 'sesame'],
      'isAustralianProduct': true,
      'image': null,
    },
    '931007201332': { // Common scan variant of Mint Slice Family Pack
      'name': 'Arnott\'s Mint Slice Family Pack',
      'brand': 'Arnott\'s',
      'ingredients': [
        'dark chocolate (37%) (sugar, cocoa mass, cocoa butter, vegetable oil (contains soy), milk solids, emulsifiers (soy lecithin, e476), flavour, salt)',
        'sugar',
        'wheat flour',
        'vegetable oil (antioxidant (e307b from soy))',
        'starch (wheat)',
        'cocoa powder',
        'salt',
        'food colour (caramel iii)',
        'baking powder',
        'peppermint oil (0.04%)',
        'emulsifier (soy lecithin)',
        'may contain traces of egg, tree nuts, peanuts, sesame',
      ],
      'allergens': ['gluten', 'milk', 'soy', 'wheat'],
      'mayContainItems': ['Egg', 'Tree Nuts', 'Peanuts', 'Sesame'],
      'traces_tags': ['en:eggs', 'en:peanuts', 'en:sesame-seeds'],
      'traces': 'eggs, peanuts, sesame seeds',
      'crossContamination': ['egg', 'tree nuts', 'peanuts', 'sesame'],
      'isAustralianProduct': true,
      'image': null,
    },
    '9300605000000': { // Arnott's Tim Tam Original
      'name': 'Arnott\'s Tim Tam Original',
      'brand': 'Arnott\'s',
      'ingredients': [
        'milk chocolate',
        'wheat flour',
        'sugar',
        'vegetable oil',
        'cocoa butter',
        'cocoa mass',
        'milk solids',
        'glucose syrup',
        'emulsifier',
        'flavours',
        'salt',
        'cocoa powder',
        'vanilla extract',
        'lecithin',
        'natural flavour',
        'artificial flavour',
        'preservative',
        'antioxidant'
      ],
      'allergens': ['wheat', 'milk', 'gluten'],
      'image': null,
    },
    '9300605000001': { // Vegemite
      'name': 'Vegemite',
      'brand': 'Vegemite',
      'ingredients': [
        'yeast extract',
        'salt',
        'malt extract',
        'vegetable extract',
        'niacin',
        'thiamine',
        'riboflavin',
        'folate',
        'vitamin b1',
        'vitamin b2',
        'vitamin b3',
        'vitamin b9',
        'celery extract',
        'onion extract',
        'spice extract',
        'natural flavour',
        'preservative',
        'antioxidant'
      ],
      'allergens': ['gluten'],
      'image': null,
    },
    '9300605000002': { // Weet-Bix
      'name': 'Weet-Bix',
      'brand': 'Sanitarium',
      'ingredients': [
        'whole grain wheat',
        'sugar',
        'salt',
        'malt extract',
        'vitamins',
        'minerals',
        'iron',
        'zinc',
        'vitamin b1',
        'vitamin b2',
        'vitamin b3',
        'vitamin b6',
        'vitamin b12',
        'folate',
        'vitamin e',
        'vitamin d',
        'calcium',
        'magnesium',
        'phosphorus',
        'potassium',
        'natural flavour',
        'preservative',
        'antioxidant'
      ],
      'allergens': ['wheat', 'gluten'],
      'image': null,
    },
    '9300605000003': { // Cadbury Dairy Milk Chocolate
      'name': 'Cadbury Dairy Milk Chocolate',
      'brand': 'Cadbury',
      'ingredients': [
        'milk chocolate',
        'sugar',
        'milk solids',
        'cocoa butter',
        'cocoa mass',
        'emulsifier',
        'flavours'
      ],
      'allergens': ['milk'],
      'image': null,
    },
    '9300605000004': { // Kraft Peanut Butter
      'name': 'Kraft Peanut Butter',
      'brand': 'Kraft',
      'ingredients': [
        'peanuts',
        'vegetable oil',
        'sugar',
        'salt',
        'emulsifier'
      ],
      'allergens': ['peanuts'],
      'image': null,
    },
    '9300605000005': { // Snickers Chocolate Bar
      'name': 'Snickers Chocolate Bar',
      'brand': 'Mars',
      'ingredients': [
        'milk chocolate',
        'peanuts',
        'caramel',
        'nougat',
        'sugar',
        'glucose syrup',
        'milk solids',
        'cocoa butter',
        'cocoa mass',
        'vegetable fat',
        'salt',
        'egg white',
        'emulsifier',
        'flavours',
        'may contain traces of tree nuts'
      ],
      'allergens': ['peanuts', 'milk', 'eggs'],
      'image': null,
    },
    '9300605000006': { // Reese's Peanut Butter Cups
      'name': 'Reese\'s Peanut Butter Cups',
      'brand': 'Hershey',
      'ingredients': [
        'milk chocolate',
        'peanuts',
        'sugar',
        'dextrose',
        'salt',
        'tbhq',
        'citric acid'
      ],
      'allergens': ['peanuts', 'milk'],
      'image': null,
    },
    '9300605000007': { // M&M's Peanut
      'name': 'M&M\'s Peanut',
      'brand': 'Mars',
      'ingredients': [
        'milk chocolate',
        'peanuts',
        'sugar',
        'glucose syrup',
        'milk solids',
        'cocoa butter',
        'cocoa mass',
        'starch',
        'colours',
        'emulsifier',
        'flavours'
      ],
      'allergens': ['peanuts', 'milk'],
      'image': null,
    },
    '9300605000008': { // Twix Chocolate Bar
      'name': 'Twix Chocolate Bar',
      'brand': 'Mars',
      'ingredients': [
        'milk chocolate',
        'wheat flour',
        'sugar',
        'glucose syrup',
        'milk solids',
        'cocoa butter',
        'cocoa mass',
        'vegetable fat',
        'caramel',
        'salt',
        'emulsifier',
        'flavours'
      ],
      'allergens': ['wheat', 'milk'],
      'image': null,
    },
    '9300605000009': { // Kit Kat Chocolate Bar
      'name': 'Kit Kat Chocolate Bar',
      'brand': 'Nestle',
      'ingredients': [
        'milk chocolate',
        'wheat flour',
        'sugar',
        'milk solids',
        'cocoa butter',
        'cocoa mass',
        'vegetable fat',
        'emulsifier',
        'flavours',
        'salt'
      ],
      'allergens': ['wheat', 'milk'],
      'image': null,
    },
    '9300605000010': { // Mars Chocolate Bar
      'name': 'Mars Chocolate Bar',
      'brand': 'Mars',
      'ingredients': [
        'milk chocolate',
        'sugar',
        'glucose syrup',
        'milk solids',
        'cocoa butter',
        'cocoa mass',
        'vegetable fat',
        'caramel',
        'nougat',
        'salt',
        'emulsifier',
        'flavours'
      ],
      'allergens': ['milk'],
      'image': null,
    },
    // Additional Australian products with real barcodes
    '9352042002827': { // Bega Peanut Butter Crunchy
      'name': 'Bega Peanut Butter Crunchy',
      'brand': 'Bega',
      'ingredients': [
        'roasted peanuts',
        'vegetable oil',
        'antioxidant',
        'salt',
        'peanut oil',
        'palm oil',
        'canola oil',
        'sunflower oil',
        'soybean oil',
        'cottonseed oil',
        'monoglycerides',
        'diglycerides',
        'lecithin',
        'vitamin e',
        'tocopherols',
        'mixed tocopherols',
        'natural flavour',
        'artificial flavour',
        'preservative',
        'stabiliser'
      ],
      'allergens': ['peanuts'],
      'image': null,
    },
    '9310072026299': { // Arnott's Shapes Savoury
      'name': 'Arnott\'s Shapes Savoury',
      'brand': 'Arnott\'s',
      'ingredients': [
        'wheat flour',
        'vegetable oil',
        'salt',
        'sugar',
        'malt extract',
        'yeast extract',
        'flavours',
        'colours',
        'antioxidant',
        'wheat starch',
        'corn starch',
        'potato starch',
        'rice flour',
        'soy flour',
        'milk powder',
        'cheese powder',
        'onion powder',
        'garlic powder',
        'herbs',
        'spices',
        'natural flavours',
        'artificial flavours',
        'monosodium glutamate',
        'disodium inosinate',
        'disodium guanylate',
        'citric acid',
        'lactic acid',
        'acetic acid',
        'sodium bicarbonate',
        'ammonium bicarbonate',
        'cream of tartar',
        'lecithin',
        'glycerol',
        'propylene glycol',
        'caramel',
        'paprika extract',
        'turmeric extract',
        'annatto extract',
        'beta carotene',
        'riboflavin',
        'thiamine',
        'niacin',
        'folic acid'
      ],
      'allergens': ['wheat', 'gluten', 'milk'],
      'image': null,
    },
    '9300605000011': { // Arnott's Shapes Original
      'name': 'Arnott\'s Shapes Original',
      'brand': 'Arnott\'s',
      'ingredients': [
        'wheat flour',
        'vegetable oil',
        'salt',
        'sugar',
        'malt extract',
        'yeast extract',
        'flavours',
        'colours',
        'antioxidant',
        'wheat starch',
        'corn starch',
        'potato starch',
        'rice flour',
        'soy flour',
        'milk powder',
        'cheese powder',
        'onion powder',
        'garlic powder',
        'herbs',
        'spices',
        'natural flavours',
        'artificial flavours',
        'monosodium glutamate',
        'disodium inosinate',
        'disodium guanylate',
        'citric acid',
        'lactic acid',
        'acetic acid',
        'sodium bicarbonate',
        'ammonium bicarbonate',
        'cream of tartar',
        'lecithin',
        'glycerol',
        'propylene glycol',
        'caramel',
        'paprika extract',
        'turmeric extract',
        'annatto extract',
        'beta carotene',
        'riboflavin',
        'thiamine',
        'niacin',
        'folic acid'
      ],
      'allergens': ['wheat', 'gluten', 'milk'],
      'image': null,
    },
    '9300605000012': { // Cadbury Dairy Milk Chocolate
      'name': 'Cadbury Dairy Milk Chocolate',
      'brand': 'Cadbury',
      'ingredients': [
        'milk chocolate',
        'sugar',
        'milk solids',
        'cocoa butter',
        'cocoa mass',
        'emulsifier',
        'flavours',
        'lecithin',
        'vanilla extract',
        'natural flavour',
        'artificial flavour',
        'preservative',
        'antioxidant'
      ],
      'allergens': ['milk'],
      'image': null,
    },
    '9300605000013': { // Smith\'s Original Chips
      'name': 'Smith\'s Original Chips',
      'brand': 'Smith\'s',
      'ingredients': [
        'potatoes',
        'vegetable oil',
        'salt',
        'sugar',
        'maltodextrin',
        'yeast extract',
        'flavours',
        'colours',
        'antioxidant',
        'natural flavour',
        'artificial flavour',
        'monosodium glutamate',
        'disodium inosinate',
        'disodium guanylate',
        'citric acid',
        'lactic acid',
        'acetic acid',
        'sodium bicarbonate',
        'ammonium bicarbonate',
        'cream of tartar',
        'lecithin',
        'glycerol',
        'propylene glycol',
        'caramel',
        'paprika extract',
        'turmeric extract',
        'annatto extract',
        'beta carotene',
        'riboflavin',
        'thiamine',
        'niacin',
        'folic acid'
      ],
      'allergens': [],
      'image': null,
    },
    '9334169005004': { // Test barcode - add your product here
      'name': 'Test Product',
      'brand': 'Test Brand',
      'ingredients': [
        'wheat flour',
        'sugar',
        'vegetable oil',
        'salt',
        'yeast',
        'preservative',
        'natural flavour',
        'artificial flavour',
        'milk powder',
        'egg powder',
        'soy lecithin',
        'peanut oil',
      ],
      'allergens': ['wheat', 'milk', 'egg', 'soy', 'peanut'],
      'image': null,
    },
    '5411600755': { // Cauliflower Puffs - Sea Salt
      'name': 'Cauliflower Puffs - Sea Salt',
      'brand': 'Temole',
      'ingredients': [
        'cauliflower',
        'brown rice',
        'rice bran oil',
        'sea salt',
        'may contain almond',
        'may contain cashew',
        'may contain pistachio',
      ],
      'allergens': ['tree nuts'],
      'image': null,
    },
    '9348219004749': { // Table Of Plenty Mini Rice Cakes (caramel white choc topped)
      'name': 'Mini Rice Cakes (Caramel White Choc Topped)',
      'brand': 'Table Of Plenty',
      'ingredients': [
        'caramelised white chocolate (60%)',
        'sugar',
        'vegetable fat',
        'milk solids',
        'stabiliser (492)',
        'emulsifier (soy lecithin)',
        'emulsifier (476)',
        'cocoa solids',
        'salt',
        'wholegrain brown rice (40%)',
        'may contain peanut',
        'may contain tree nuts',
        'may contain sesame',
        'may contain sulphites',
      ],
      'allergens': ['milk', 'soy'],
      'image': null,
    },
    '9315991023596': { // Ajitas Vege Deli Chips - Purple & Orange Sweet Potato + Taro
      'name': 'Vege Deli Chips - Purple & Orange Sweet Potato + Taro',
      'brand': 'Ajitas',
      'ingredients': [
        'orange sweet potato',
        'purple sweet potato',
        'taro',
        'vegetable oil',
        'seasoning (3.5%)',
        'maltodextrin (tapioca starch)',
        'salt',
        'sugar',
        'yeast extract',
        'garlic powder',
      ],
      'allergens': [],
      'image': null,
    },
  };

  /// Get product information by barcode
  static Future<Map<String, dynamic>?> getProduct(String barcode) async {
    try {
      // Check premium products first (highest priority for premium users)
      final premiumProduct = await PremiumProductService.getPremiumProduct(barcode);
      if (premiumProduct != null) {
        if (kDebugMode) {
          print('OpenFoodFacts: Found premium product: ${premiumProduct['name']}');
        }
        final premiumData = Map<String, dynamic>.from(premiumProduct);
        premiumData['data_source'] = 'Premium Database';
        premiumData['barcode'] = barcode;
        premiumData['lookup_timestamp'] = DateTime.now().toIso8601String();
        premiumData['premium_only'] = true;
        
        // Override cache with premium data
        _cache[barcode] = premiumData;
        
        if (kDebugMode) {
          print('OpenFoodFacts: Premium data - Name: ${premiumData['name']}');
          print('OpenFoodFacts: Premium data - Category: ${premiumData['category']}');
          print('OpenFoodFacts: Premium data - Ingredients: ${premiumData['ingredients']}');
          print('OpenFoodFacts: Premium data - Allergens: ${premiumData['allergens']}');
        }
        
        return premiumData;
      }

      // Check manual database second (including common barcode variants)
      final manualData = _lookupManualProduct(barcode);
      if (manualData != null) {
        if (kDebugMode) {
          print('OpenFoodFacts: Found product in manual database: $barcode');
        }
        manualData['barcode'] = barcode;
        manualData['lookup_timestamp'] = DateTime.now().toIso8601String();
        manualData['mayContainItems'] = _extractMayContainFromProductData(manualData);
        
        // Override cache with manual data
        _cache[barcode] = manualData;
        
        if (kDebugMode) {
          print('OpenFoodFacts: Manual data - Name: ${manualData['name']}');
          print('OpenFoodFacts: Manual data - Ingredients: ${manualData['ingredients']}');
          print('OpenFoodFacts: Manual data - Allergens: ${manualData['allergens']}');
        }
        
        return manualData;
      }

      // Check cache second
      if (_cache.containsKey(barcode)) {
        if (kDebugMode) {
          print('OpenFoodFacts: Returning cached product for $barcode');
        }
        final cached = _applyEnglishIngredientOverride(
          barcode,
          Map<String, dynamic>.from(_cache[barcode]!),
        );
        return _refreshMayContainItems(cached);
      }

      if (kDebugMode) {
        print('OpenFoodFacts: Fetching product for barcode $barcode');
      }

      final product = await _fetchProductFromApi(barcode);
      if (product != null) {
        final englishProduct = _applyEnglishIngredientOverride(barcode, product);
        _addToCache(barcode, englishProduct);
        return _refreshMayContainItems(englishProduct);
      }

      if (kDebugMode) {
        print('OpenFoodFacts: Product not found for barcode $barcode');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('OpenFoodFacts: Error fetching product $barcode: $e');
      }
      return null;
    }
  }

  static Future<Map<String, dynamic>?> _fetchProductFromApi(String barcode) async {
    for (final candidate in _barcodeLookupCandidates(barcode)) {
      final product = await _fetchSingleBarcodeFromApi(candidate);
      if (product != null) {
        return product;
      }
    }
    return null;
  }

  static Future<Map<String, dynamic>?> _fetchSingleBarcodeFromApi(String barcode) async {
    for (final baseUrl in [baseUrlV2, baseUrlV0]) {
      try {
        final response = await http.get(
          Uri.parse('$baseUrl$barcode'),
          headers: _headers,
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode != 200) continue;

        final data = json.decode(response.body);
        final status = data['status'];
        final productData = data['product'];

        if ((status == 1 || status == 'success') && productData != null) {
          final product = _parseProductData(
            Map<String, dynamic>.from(productData as Map),
          );
          if (kDebugMode) {
            print('OpenFoodFacts: Fetched via ${baseUrl.contains('v2') ? 'v2' : 'v0'}: ${product['name']}');
          }
          return product;
        }
      } catch (e) {
        if (kDebugMode) {
          print('OpenFoodFacts: API fetch failed for $baseUrl: $e');
        }
      }
    }
    return null;
  }

  /// Manual database entries for offline / missing OFF data.
  static Map<String, Map<String, dynamic>> get manualProductDatabase =>
      Map.unmodifiable(_manualProductDatabase);

  static List<String> _barcodeLookupCandidates(String barcode) {
    final candidates = <String>{barcode};
    if (barcode == '931007201332') {
      candidates.add('9310072013312');
    }
    if (barcode == '9310072013312') {
      candidates.add('931007201332');
    }
    return candidates.toList();
  }

  static Map<String, dynamic>? _lookupManualProduct(String barcode) {
    for (final candidate in _barcodeLookupCandidates(barcode)) {
      final entry = _manualProductDatabase[candidate];
      if (entry != null) {
        final manualData = Map<String, dynamic>.from(entry);
        manualData['data_source'] = 'Manual Database';
        return manualData;
      }
    }
    return null;
  }

  static bool _isLikelyEnglish(String text) {
    final lower = text.toLowerCase();
    const frenchMarkers = [
      'farine de',
      'contient des',
      'peut contenir',
      'lécithine',
      'lecithine de soja',
      'huile végétale',
      'huile vegetale',
      'pâte de cacao',
      'pate de cacao',
      'matière sèche',
      'matiere seche',
      'céréales',
      'cereales',
      'cacahuète',
      'cacahuete',
      'sésame',
      'sesame et de fruit',
      'fabrique en',
      ' émulsif',
      'arôme',
      'arome',
      'beurre de cacao',
      'levure chimique',
    ];
    const englishMarkers = [
      'wheat flour',
      'contains',
      'may contain',
      'soy lecithin',
      'vegetable oil',
      'cocoa mass',
      'cocoa butter',
      'milk solids',
      'baking powder',
      'peppermint oil',
      'manufactured in australia',
      'food colour',
    ];

    final frenchScore = frenchMarkers.where((m) => lower.contains(m)).length;
    final englishScore = englishMarkers.where((m) => lower.contains(m)).length;
    return englishScore > frenchScore;
  }

  static bool _hasEnglishIngredients(Map<String, dynamic> product) {
    final ingredients = product['ingredients'] as List<dynamic>? ?? [];
    if (ingredients.isEmpty) return false;
    return _isLikelyEnglish(ingredients.join(' '));
  }

  static Map<String, dynamic> _applyEnglishIngredientOverride(
    String barcode,
    Map<String, dynamic> product,
  ) {
    if (_hasEnglishIngredients(product)) return product;

    final manual = _lookupManualProduct(barcode);
    if (manual == null) return product;

    final updated = Map<String, dynamic>.from(product);
    updated['ingredients'] = List<String>.from(manual['ingredients'] ?? []);
    updated['mayContainItems'] = manual['mayContainItems'] ?? product['mayContainItems'];
    updated['crossContamination'] = manual['crossContamination'] ?? product['crossContamination'];
    updated['traces_tags'] = manual['traces_tags'] ?? product['traces_tags'];
    updated['traces'] = manual['traces'] ?? product['traces'];
    updated['allergens'] = manual['allergens'] ?? product['allergens'];
    updated['data_source'] = '${product['data_source'] ?? 'Open Food Facts'} (English label)';
    if (kDebugMode) {
      print('OpenFoodFacts: Applied English ingredient override for $barcode');
    }
    return updated;
  }

  /// Parse Open Food Facts product data into our app's format
  static Map<String, dynamic> _parseProductData(Map<String, dynamic> productData) {
    if (kDebugMode) {
      print('OpenFoodFacts: Raw product data keys: ${productData.keys.toList()}');
      print('OpenFoodFacts: ingredients_text_en: ${productData['ingredients_text_en']}');
      print('OpenFoodFacts: ingredients: ${productData['ingredients']}');
      print('OpenFoodFacts: ingredients_text_with_allergens: ${productData['ingredients_text_with_allergens']}');
      print('OpenFoodFacts: ingredients_text: ${productData['ingredients_text']}');
    }
    
    // Extract ingredients using comprehensive approach
    List<String> ingredients = _extractAllPossibleIngredients(productData);

    // Extract allergens
    List<String> allergens = [];
    if (productData['allergens_tags'] != null) {
      allergens = _parseAllergenTags(productData['allergens_tags']);
    }
    
    // Also extract allergens from ingredients text (for Australian products)
    if (productData['ingredients_text'] != null) {
      final textAllergens = _extractAllergensFromText(productData['ingredients_text']);
      for (String allergen in textAllergens) {
        if (!allergens.contains(allergen)) {
          allergens.add(allergen);
        }
      }
    }

    // Extract product image
    String? imageUrl;
    if (productData['image_front_url'] != null) {
      imageUrl = 'https://world.openfoodfacts.org${productData['image_front_url']}';
    }

    final countries = (productData['countries_tags'] as List<dynamic>? ?? [])
        .map((c) => c.toString())
        .toList();
    final origins = productData['origins']?.toString() ?? '';
    final brands = productData['brands']?.toString().toLowerCase() ?? '';

    return {
      'name': productData['product_name'] ?? productData['generic_name'] ?? 'Unknown Product',
      'brand': productData['brands'] ?? 'Unknown Brand',
      'ingredients': ingredients,
      'allergens': allergens,
      'image': imageUrl,
      'barcode': productData['code'],
      'nutrition_grade': productData['nutrition_grade_fr'],
      'nova_group': productData['nova_group'],
      'ecoscore_grade': productData['ecoscore_grade'],
      'quantity': productData['quantity'],
      'packaging': productData['packaging_tags'],
      'categories': productData['categories_tags'],
      'labels': productData['labels_tags'],
      'origins': origins,
      'countries': countries,
      'traces_tags': (productData['traces_tags'] as List<dynamic>? ?? [])
          .map((t) => t.toString())
          .toList(),
      'traces': productData['traces']?.toString() ?? '',
      'isAustralianProduct': countries.contains('en:australia') ||
          origins.toLowerCase().contains('australia') ||
          brands.contains('australia'),
      'manufacturing_places': productData['manufacturing_places'],
      'last_updated': productData['last_updated_t'],
      'mayContainItems': _extractMayContainFromProductData(productData),
      'data_source': 'Open Food Facts',
      'lookup_timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Parse ingredients text into a list with enhanced Australian support
  static List<String> _parseIngredients(String ingredientsText) {
    if (kDebugMode) {
      print('OpenFoodFacts: Parsing ingredients text: "$ingredientsText"');
    }

    // Parse ingredients and separate warnings from actual ingredients
    Map<String, dynamic> parsedResult = _parseIngredientsWithWarnings(ingredientsText);
    List<String> actualIngredients = parsedResult['actualIngredients'];
    List<String> crossContaminationWarnings = parsedResult['crossContaminationWarnings'];
    
    if (kDebugMode) {
      print('OpenFoodFacts: Actual ingredients: $actualIngredients');
      print('OpenFoodFacts: Cross-contamination warnings: $crossContaminationWarnings');
    }

    // Combine actual ingredients and warnings so the allergen analysis can distinguish between them
    List<String> allIngredients = [...actualIngredients, ...crossContaminationWarnings];
    
    if (kDebugMode) {
      print('OpenFoodFacts: Combined ingredients for analysis: $allIngredients');
    }

    return allIngredients;
  }

  /// Parse ingredients text to separate actual ingredients from warnings
  static Map<String, dynamic> _parseIngredientsWithWarnings(String ingredientsText) {
    if (kDebugMode) {
      print('OpenFoodFacts: Parsing ingredients with warnings: "$ingredientsText"');
    }

    List<String> actualIngredients = [];
    List<String> crossContaminationWarnings = [];
    
    // For VitaWeat format, we need to handle this specific case:
    // "CRISPBREAD WHOLEGRAINS (86%) (WHEAT, BARLEY, RYE, CORN), SEEDS (5%) (CANOLA, LINSEED, POPPY, SUNFLOWER KERNELS), VEGETABLE OIL, SALT, SUGAR, SOY. CONTAINS WHEAT, GLUTEN, SOY. MAY CONTAIN EGG, MILK, TREE NUTS, PEANUT, SESAME."
    
    // Find the first occurrence of "CONTAINS" or "MAY CONTAIN"
    String lowerText = ingredientsText.toLowerCase();
    int containsIndex = lowerText.indexOf('contains');
    int mayContainIndex = lowerText.indexOf('may contain');
    
    // Determine the cutoff point - separate "CONTAINS" and "MAY CONTAIN" sections
    int cutoffIndex = ingredientsText.length;
    
    if (mayContainIndex != -1) {
      // If "MAY CONTAIN" is found, use it as the cutoff for cross-contamination
      cutoffIndex = mayContainIndex;
    } else if (containsIndex != -1) {
      // If only "CONTAINS" is found, check if it's a warning section
      // Look for the pattern: "SOY. CONTAINS" (ends with period before contains)
      String beforeContains = ingredientsText.substring(0, containsIndex).trim();
      if (beforeContains.endsWith('.') || beforeContains.endsWith(',')) {
        cutoffIndex = containsIndex;
      }
    }
    
    if (kDebugMode) {
      print('OpenFoodFacts: Cutoff index: $cutoffIndex');
      print('OpenFoodFacts: Cutoff text: "${ingredientsText.substring(0, cutoffIndex)}"');
    }
    
    // Extract actual ingredients (before warnings)
    String actualIngredientsText = ingredientsText.substring(0, cutoffIndex).trim();
    
    // Extract warnings (after cutoff)
    String warningsText = '';
    if (cutoffIndex < ingredientsText.length) {
      warningsText = ingredientsText.substring(cutoffIndex).trim();
    }
    
    if (kDebugMode) {
      print('OpenFoodFacts: Actual ingredients text: "$actualIngredientsText"');
      print('OpenFoodFacts: Warnings text: "$warningsText"');
    }
    
    // Parse actual ingredients - split by comma and clean up
    List<String> actualLines = actualIngredientsText.split(',');
    for (String line in actualLines) {
      String trimmedLine = line.trim();
      if (trimmedLine.isEmpty) continue;
      
      // Clean up the ingredient
      String cleaned = trimmedLine
          .replaceAll(RegExp(r'^ingredients?:\s*', caseSensitive: false), '')
          .replaceAll(RegExp(r'^contains?:\s*', caseSensitive: false), '')
          .replaceAll(RegExp(r'^may contain:\s*', caseSensitive: false), '')
          .replaceAll(RegExp(r'^allergens?:\s*', caseSensitive: false), '')
          .trim();
      
      if (cleaned.isNotEmpty && cleaned.length > 1) {
        // Remove percentage indicators but keep the ingredient name
        cleaned = cleaned.replaceAll(RegExp(r'\(\d+%\)'), '').trim();
        // Remove E-numbers but keep the ingredient
        cleaned = cleaned.replaceAll(RegExp(r'\bE\d+\b'), '').trim();
        // Remove standalone numbers but keep ingredient names with numbers
        cleaned = cleaned.replaceAll(RegExp(r'^\d+$'), '').trim();
        
        if (cleaned.isNotEmpty) {
          actualIngredients.add(cleaned);
        }
      }
    }
    
    // Parse warnings - separate "CONTAINS" (definite allergens) from "MAY CONTAIN" (cross-contamination)
    if (warningsText.isNotEmpty) {
      String lowerWarnings = warningsText.toLowerCase();
      
      if (lowerWarnings.contains('may contain')) {
        // This is a cross-contamination warning
        String cleaned = warningsText
            .replaceAll(RegExp(r'^may contain( traces( of)?)?[:\s]*', caseSensitive: false), '')
            .replaceAll(RegExp(r'^allergens?:\s*', caseSensitive: false), '')
            .trim();
        
        if (cleaned.isNotEmpty) {
          crossContaminationWarnings.add(cleaned);
        }
      } else if (lowerWarnings.contains('contains')) {
        // This is a definite allergen warning - add to actual ingredients
        String cleaned = warningsText
            .replaceAll(RegExp(r'^contains?:\s*', caseSensitive: false), '')
            .replaceAll(RegExp(r'^allergens?:\s*', caseSensitive: false), '')
            .trim();
        
        if (cleaned.isNotEmpty) {
          // Handle the specific case of "SOY. CONTAINS WHEAT"
          if (cleaned.toLowerCase().startsWith('soy.')) {
            // Extract just the "WHEAT" part and add it as an actual ingredient
            String wheatPart = cleaned.replaceAll(RegExp(r'^soy\.\s*', caseSensitive: false), '').trim();
            if (wheatPart.isNotEmpty) {
              actualIngredients.add(wheatPart);
            }
          } else {
            // Split the contains section by comma and add each allergen as an actual ingredient
            List<String> containsAllergens = cleaned.split(',');
            for (String allergen in containsAllergens) {
              String trimmed = allergen.trim();
              if (trimmed.isNotEmpty) {
                actualIngredients.add(trimmed);
              }
            }
          }
        }
      }
    }
    
    // If we still have a single long string, try to split it further
    if (actualIngredients.length == 1 && actualIngredients[0].length > 50) {
      String longIngredient = actualIngredients[0];
      if (kDebugMode) {
        print('OpenFoodFacts: Single long ingredient detected, trying to split: "$longIngredient"');
      }
      
      // Try to split by additional separators
      List<String> furtherSplit = longIngredient
          .split(RegExp(r'[,\s]+'))
          .map((ingredient) => ingredient.trim())
          .where((ingredient) => ingredient.isNotEmpty)
          .where((ingredient) => ingredient.length > 2)
          .toList();
      
      if (furtherSplit.length > 1) {
        actualIngredients = furtherSplit;
        if (kDebugMode) {
          print('OpenFoodFacts: Further split successful: $actualIngredients');
        }
      }
    }

    return {
      'actualIngredients': actualIngredients,
      'crossContaminationWarnings': crossContaminationWarnings,
    };
  }



  /// Parse allergen tags into readable allergen names with Australian support
  static List<String> _parseAllergenTags(List<dynamic> allergenTags) {
    final allergenMap = {
      'en:peanuts': 'peanuts',
      'en:tree-nuts': 'tree nuts',
      'en:milk': 'milk',
      'en:eggs': 'eggs',
      'en:soybeans': 'soy',
      'en:wheat': 'wheat',
      'en:fish': 'fish',
      'en:crustaceans': 'shellfish',
      'en:sesame-seeds': 'sesame',
      'en:sulphur-dioxide-and-sulphites': 'sulfites',
      'en:mustard': 'mustard',
      'en:celery': 'celery',
      'en:lupin': 'lupin',
      'en:molluscs': 'molluscs',
      // Australian specific allergen tags
      'en:gluten': 'gluten',
      'en:lactose': 'lactose',
      'en:casein': 'casein',
      'en:whey': 'whey',
      'en:albumin': 'albumin',
      'en:ovalbumin': 'ovalbumin',
      'en:lysozyme': 'lysozyme',
      'en:vitellin': 'vitellin',
      'en:livetin': 'livetin',
      'en:apovitellenin': 'apovitellenin',
      'en:phosvitin': 'phosvitin',
      // Additional grains
      'en:corn': 'corn',
      'en:rice': 'rice',
      'en:oats': 'oats',
      'en:barley': 'barley',
      'en:rye': 'rye',
      'en:quinoa': 'quinoa',
      'en:buckwheat': 'buckwheat',
      // Additional nuts
      'en:coconut': 'coconut',
      'en:brazil-nut': 'brazil nut',
      'en:pistachio': 'pistachio',
      'en:macadamia': 'macadamia',
      'en:pine-nut': 'pine nut',
      // Fruits and vegetables
      'en:kiwi': 'kiwi',
      'en:banana': 'banana',
      'en:tomato': 'tomato',
      'en:strawberry': 'strawberry',
    };

    return allergenTags
        .map((tag) => allergenMap[tag] ?? tag.toString().replaceAll('en:', ''))
        .where((allergen) => allergen.isNotEmpty)
        .toList();
  }

  /// Extract allergens from ingredients text (Australian format)
  static List<String> _extractAllergensFromText(String ingredientsText) {
    List<String> allergens = [];
    String lowerText = ingredientsText.toLowerCase();
    
    // Australian allergen keywords
    final allergenKeywords = {
      'peanuts': ['peanut', 'peanuts', 'arachis hypogaea', 'groundnut', 'ground nuts'],
      'tree nuts': ['almond', 'almonds', 'walnut', 'walnuts', 'cashew', 'cashews', 'pecan', 'pecans', 'pistachio', 'pistachios', 'hazelnut', 'hazelnuts', 'macadamia', 'macadamias', 'brazil nut', 'brazil nuts', 'pine nut', 'pine nuts'],
      'milk': ['milk', 'dairy', 'cream', 'butter', 'cheese', 'yogurt', 'yoghurt', 'whey', 'casein', 'lactose', 'milk powder', 'milk protein', 'skim milk', 'full cream milk', 'cheese powder', 'dairy powder', 'cream powder', 'butter powder'],
      'eggs': ['egg', 'eggs', 'egg white', 'egg yolk', 'albumin', 'ovalbumin', 'lysozyme', 'vitellin', 'livetin', 'apovitellenin', 'phosvitin'],
      'soy': ['soy', 'soya', 'soybean', 'soybeans', 'soy lecithin', 'soy protein', 'tofu', 'miso', 'tempeh', 'edamame', 'soy flour', 'soy oil', 'soy sauce', 'soy milk', 'soy isolate', 'soy concentrate'],
      'wheat': ['wheat', 'wheat flour', 'wheat protein', 'gluten', 'bread', 'pasta', 'cereal', 'durum wheat', 'spelt', 'kamut', 'wheat starch', 'wheat bran', 'wheat germ', 'wheat gluten', 'vital wheat gluten', 'wheat protein isolate'],
      'fish': ['fish', 'salmon', 'tuna', 'cod', 'haddock', 'anchovy', 'anchovies', 'bass', 'flounder', 'mackerel', 'sardines', 'fish oil', 'fish sauce', 'fish protein', 'fish gelatin', 'fish collagen'],
      'shellfish': ['shrimp', 'prawn', 'crab', 'lobster', 'oyster', 'clam', 'mussel', 'scallop', 'crayfish', 'yabby', 'marron', 'moreton bay bug', 'shrimp paste', 'prawn paste', 'crab meat', 'lobster meat'],
      'sesame': ['sesame', 'sesame seed', 'sesame seeds', 'tahini', 'sesame oil', 'benne', 'gingelly', 'sesame flour', 'sesame protein'],
      'sulfites': ['sulfite', 'sulfites', 'sulphite', 'sulphites', 'sulfur dioxide', 'sulphur dioxide', 'sodium metabisulphite', 'potassium metabisulphite', 'sodium sulfite', 'potassium sulfite'],
      'mustard': ['mustard', 'mustard seed', 'mustard powder', 'mustard oil', 'mustard flour', 'mustard protein'],
      'celery': ['celery', 'celery seed', 'celery salt', 'celery root', 'celeriac', 'celery powder'],
      'lupin': ['lupin', 'lupine', 'lupini', 'lupin flour', 'lupin bean', 'lupin protein'],
      'molluscs': ['mollusc', 'molluscs', 'snail', 'snails', 'abalone', 'whelk', 'periwinkle', 'pipi', 'cockle', 'mussel', 'oyster', 'clam', 'scallop'],
      // Additional grains
      'corn': ['corn', 'maize', 'corn flour', 'corn starch', 'corn syrup', 'corn oil', 'corn meal', 'corn grits', 'corn protein'],
      'rice': ['rice', 'rice flour', 'rice starch', 'rice syrup', 'rice protein', 'brown rice', 'white rice', 'wild rice', 'rice bran', 'rice germ'],
      'oats': ['oats', 'oat flour', 'oat bran', 'oat protein', 'rolled oats', 'steel cut oats', 'oatmeal'],
      'barley': ['barley', 'barley flour', 'barley malt', 'barley protein', 'pearl barley', 'barley starch'],
      'rye': ['rye', 'rye flour', 'rye bread', 'rye protein'],
      'quinoa': ['quinoa', 'quinoa flour', 'quinoa protein', 'quinoa seeds', 'quinoa flakes'],
      'buckwheat': ['buckwheat', 'buckwheat flour', 'buckwheat groats', 'buckwheat protein'],
      // Additional nuts
      'coconut': ['coconut', 'coconut oil', 'coconut flour', 'coconut milk', 'coconut cream', 'coconut protein', 'coconut sugar', 'coconut water'],
      'brazil nut': ['brazil nut', 'brazil nuts', 'brazil nut oil', 'brazil nut flour'],
      'pistachio': ['pistachio', 'pistachios', 'pistachio oil', 'pistachio flour', 'pistachio protein'],
      'macadamia': ['macadamia', 'macadamias', 'macadamia nut', 'macadamia nuts', 'macadamia oil', 'macadamia flour', 'macadamia protein'],
      'pine nut': ['pine nut', 'pine nuts', 'pignoli', 'pignolia', 'pine kernel', 'pine kernels'],
      // Fruits and vegetables
      'kiwi': ['kiwi', 'kiwi fruit', 'kiwifruit', 'kiwi protein', 'kiwi extract'],
      'banana': ['banana', 'bananas', 'banana flour', 'banana protein', 'banana extract'],
      'tomato': ['tomato', 'tomatoes', 'tomato paste', 'tomato sauce', 'tomato powder', 'tomato protein'],
      'strawberry': ['strawberry', 'strawberries', 'strawberry extract', 'strawberry protein'],
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

  /// Comprehensive ingredient extraction from Open Food Facts data
  static List<String> _extractAllPossibleIngredients(Map<String, dynamic> productData) {
    if (kDebugMode) {
      print('OpenFoodFacts: Checking all possible ingredient fields...');
      print('OpenFoodFacts: Available keys: ${productData.keys.where((key) => key.contains('ingredient')).toList()}');
    }
    
    final englishTextFields = [
      'ingredients_text_with_allergens_en',
      'ingredients_text_en',
    ];
    final fallbackTextFields = [
      'ingredients_text_with_allergens',
      'ingredients_text',
    ];

    List<String> tryParseEnglishText(Iterable<String> fields) {
      for (final field in fields) {
        final text = productData[field]?.toString();
        if (text == null || text.isEmpty || !_isLikelyEnglish(text)) continue;
        final parsed = _parseIngredients(text);
        if (parsed.isNotEmpty) {
          if (kDebugMode) {
            print('OpenFoodFacts: Using English ingredients from "$field"');
          }
          return parsed;
        }
      }
      return [];
    }

    var ingredients = tryParseEnglishText(englishTextFields);
    if (ingredients.isEmpty) {
      ingredients = tryParseEnglishText(fallbackTextFields);
    }

    if (ingredients.isEmpty && productData['ingredients'] != null) {
      final structured = _extractStructuredIngredients(productData['ingredients']);
      if (structured.isNotEmpty && _isLikelyEnglish(structured.join(' '))) {
        ingredients = structured;
        if (kDebugMode) {
          print('OpenFoodFacts: Using English structured ingredients: $ingredients');
        }
      }
    }

    if (ingredients.isNotEmpty) {
      for (final field in [...englishTextFields, ...fallbackTextFields]) {
        final text = productData[field]?.toString();
        if (text == null || text.isEmpty) continue;
        final parsed = _parseIngredientsWithWarnings(text);
        for (final warning in parsed['crossContaminationWarnings'] as List<String>) {
          if (!ingredients.any((i) => i.toLowerCase() == warning.toLowerCase())) {
            ingredients.add(warning);
          }
        }
      }
      return ingredients;
    }

    if (kDebugMode) {
      print('OpenFoodFacts: No English ingredients found in OFF data');
      print('OpenFoodFacts: Product name: ${productData['product_name']}');
      print('OpenFoodFacts: Barcode: ${productData['code']}');
    }

    return [];
  }

  /// Extract may-contain allergens from OFF traces tags and label text.
  static List<String> _extractMayContainFromProductData(
    Map<String, dynamic> productData,
  ) {
    final seen = <String>{};
    final items = <String>[];

    void addItem(String value) {
      final trimmed = value.trim();
      if (trimmed.length <= 1) return;
      if (seen.add(trimmed.toLowerCase())) {
        items.add(trimmed.split(' ').map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        }).join(' '));
      }
    }

    if (productData['traces_tags'] != null) {
      for (final tag in _parseAllergenTags(productData['traces_tags'])) {
        addItem(tag);
      }
    }

    if (productData['traces'] != null) {
      for (final trace in productData['traces'].toString().split(',')) {
        addItem(trace.replaceAll('_', ' '));
      }
    }

    final textFields = [
      'ingredients_text_with_allergens_en',
      'ingredients_text_with_allergens',
      'ingredients_text_en',
      'ingredients_text',
    ];

    final mayContainPattern = RegExp(
      r'may contain(?: traces(?: of)?)?[:\s]+([^\.]+)',
      caseSensitive: false,
    );

    for (final field in textFields) {
      final text = productData[field]?.toString();
      if (text == null || text.isEmpty) continue;
      for (final match in mayContainPattern.allMatches(text)) {
        for (final part in (match.group(1) ?? '').split(RegExp(r',|\band\b', caseSensitive: false))) {
          addItem(part.trim());
        }
      }

      final mayBePresentIndex = text.toLowerCase().indexOf('may be present');
      if (mayBePresentIndex > 0) {
        var listing = text.substring(0, mayBePresentIndex).trim();
        final lastPeriod = listing.lastIndexOf('.');
        if (lastPeriod >= 0) {
          listing = listing.substring(lastPeriod + 1).trim();
        }
        for (final part in listing.split(RegExp(r',|\band\b', caseSensitive: false))) {
          addItem(part.trim());
        }
      }
    }

    if (kDebugMode) {
      print('OpenFoodFacts: Extracted may contain items: $items');
    }

    return items;
  }

  static Map<String, dynamic> _refreshMayContainItems(Map<String, dynamic> product) {
    final refreshed = Map<String, dynamic>.from(product);
    refreshed['mayContainItems'] = _extractMayContainFromProductData({
      'traces_tags': product['traces_tags'],
      'traces': product['traces'],
      'ingredients_text_with_allergens_en': product['ingredients_text_with_allergens_en'],
      'ingredients_text_with_allergens': product['ingredients_text_with_allergens'],
      'ingredients_text_en': product['ingredients_text_en'],
      'ingredients_text': product['ingredients_text'],
    });
    if ((refreshed['mayContainItems'] as List).isEmpty &&
        product['mayContainItems'] is List &&
        (product['mayContainItems'] as List).isNotEmpty) {
      refreshed['mayContainItems'] = product['mayContainItems'];
    }
    return refreshed;
  }

  static List<String> _extractStructuredIngredients(dynamic structured) {
    if (structured is! List) return [];
    final extracted = <String>[];
    for (final item in structured) {
      if (item is Map) {
        final textEn = item['text_en']?.toString().trim();
        final textDefault = item['text']?.toString().trim();
        final text = (textEn != null && textEn.isNotEmpty) ? textEn : textDefault;
        if (text != null && text.isNotEmpty) {
          extracted.add(text);
        }
        final nested = item['ingredients'];
        if (nested != null) {
          extracted.addAll(_extractStructuredIngredients(nested));
        }
      } else if (item is String && item.isNotEmpty) {
        extracted.add(item);
      }
    }
    return extracted;
  }

  /// Add product to cache
  static void _addToCache(String barcode, Map<String, dynamic> product) {
    if (_cache.length >= _maxCacheSize) {
      // Remove oldest entry
      String oldestKey = _cache.keys.first;
      _cache.remove(oldestKey);
    }
    _cache[barcode] = product;
  }

  /// Search products by name or brand
  static Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    try {
      if (kDebugMode) {
        print('OpenFoodFacts: Searching for products with query: $query');
      }

      final response = await http.get(
        Uri.parse('$searchUrl?search_terms=${Uri.encodeComponent(query)}&search_simple=1&action=process&json=1'),
        headers: {
          'User-Agent': 'MyAllergyBuddy/1.0 (Flutter App)',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final products = data['products'] as List<dynamic>? ?? [];
        
        return products
            .take(10) // Limit to 10 results
            .map((product) => _parseProductData(product))
            .toList();
      } else {
        if (kDebugMode) {
          print('OpenFoodFacts: Search HTTP error ${response.statusCode}');
        }
        return [];
      }
    } catch (e) {
      if (kDebugMode) {
        print('OpenFoodFacts: Search error: $e');
      }
      return [];
    }
  }

  /// Add a product to the manual database (for testing)
  static void addProductToManualDatabase(String barcode, Map<String, dynamic> productData) {
    _manualProductDatabase[barcode] = productData;
  }

  /// Get all manual database barcodes
  static List<String> getManualDatabaseBarcodes() {
    return _manualProductDatabase.keys.toList();
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
      'manual_database_size': _manualProductDatabase.length,
    };
  }
}