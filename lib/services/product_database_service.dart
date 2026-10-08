
import 'package:flutter/foundation.dart';
import 'barcode_utils.dart';
import 'html_text_utils.dart';
import 'australian_curated_product_database.dart';
import 'open_food_facts_service.dart';
import '../tree_nuts_grouping.dart';

class ProductDatabaseService {
  /// Runtime catalog. Bundled placeholder barcodes were removed.
  /// [initialize] loads the curated products; learned scans are added later.
  static final Map<String, Map<String, dynamic>> _productDatabase = {};

  // Enhanced allergen synonyms and variations with comprehensive international support
  static final Map<String, List<String>> _allergenSynonyms = {
    'peanuts': ['peanut', 'peanuts', 'arachis hypogaea', 'groundnut', 'ground nuts', 'monkey nuts', 'peanut oil', 'peanut flour', 'peanut protein', 'cacahuète', 'cacahuètes', 'arachide', 'arachides'],
    'tree nuts': ['tree nuts', 'tree nut', 'nuts', 'nut', 'almond', 'almonds', 'walnut', 'walnuts', 'cashew', 'cashews', 'pecan', 'pecans', 'pistachio', 'pistachios', 'hazelnut', 'hazelnuts', 'macadamia', 'macadamias', 'brazil nut', 'brazil nuts', 'pine nut', 'pine nuts', 'chestnut', 'chestnuts', 'almond oil', 'walnut oil', 'cashew oil', 'macadamia oil', 'amande', 'amandes', 'noix', 'noisette', 'noisettes', 'noix de cajou', 'noix de pécan', 'pistache', 'pistaches'],
    'almond': ['almond', 'almonds', 'almond oil', 'almond flour', 'almond meal', 'almond protein', 'amande', 'amandes'],
    'cashew': ['cashew', 'cashews', 'cashew oil', 'cashew butter', 'noix de cajou'],
    'hazelnut': ['hazelnut', 'hazelnuts', 'hazelnut oil', 'hazelnut flour', 'noisette', 'noisettes'],
    'pecan': ['pecan', 'pecans', 'pecan oil', 'noix de pécan'],
    'walnut': ['walnut', 'walnuts', 'walnut oil', 'walnut flour'],
    'chestnut': ['chestnut', 'chestnuts', 'chestnut flour'],
    'milk': ['milk', 'dairy', 'cream', 'butter', 'cheese', 'yogurt', 'yoghurt', 'whey', 'casein', 'lactose', 'milk powder', 'milk protein', 'skim milk', 'full cream milk', 'whole milk', 'low fat milk', 'milk solids', 'milk fat', 'milk sugar', 'lactose', 'lactoglobulin', 'lactalbumin', 'cheese powder', 'dairy powder', 'cream powder', 'butter powder', 'lait', 'crème', 'beurre', 'fromage', 'yaourt', 'lactosérum', 'caséine', 'lactose', 'poudre de lait', 'protéine de lait', 'solides de lait'],
    'eggs': ['egg', 'eggs', 'egg white', 'egg yolk', 'albumin', 'ovalbumin', 'lysozyme', 'vitellin', 'livetin', 'apovitellenin', 'phosvitin', 'egg powder', 'dried egg', 'egg protein', 'egg solids', 'œuf', 'œufs', 'blanc d\'œuf', 'jaune d\'œuf', 'albumine', 'ovalbumine'],
    'soy': ['soy', 'soya', 'soybean', 'soybeans', 'soy lecithin', 'soy protein', 'tofu', 'miso', 'tempeh', 'edamame', 'soy flour', 'soy oil', 'soy sauce', 'soy milk', 'soy isolate', 'soy concentrate', 'lécithine de soja', 'soja', 'lécithine', 'soja', 'soybean', 'haricot de soja', 'haricots de soja', 'sauce soja'],
    'wheat': ['wheat', 'wheat flour', 'wheat protein', 'gluten', 'bread', 'pasta', 'cereal', 'durum wheat', 'spelt', 'kamut', 'wheat starch', 'wheat bran', 'wheat germ', 'wheat gluten', 'vital wheat gluten', 'wheat protein isolate', 'farine de blé', 'farine blé', 'blé', 'farine', 'blé dur', 'épeautre', 'amidon de blé', 'son de blé', 'germe de blé', 'gluten de blé'],
    'fish': ['fish', 'salmon', 'tuna', 'cod', 'haddock', 'anchovy', 'anchovies', 'bass', 'flounder', 'mackerel', 'sardines', 'fish oil', 'fish sauce', 'fish protein', 'fish gelatin', 'fish collagen', 'poisson', 'saumon', 'thon', 'morue', 'anchois', 'bar', 'flétan', 'maquereau', 'sardines', 'huile de poisson', 'sauce de poisson'],
    'shellfish': ['shrimp', 'prawn', 'crab', 'lobster', 'oyster', 'clam', 'mussel', 'scallop', 'crayfish', 'yabby', 'marron', 'moreton bay bug', 'shrimp paste', 'prawn paste', 'crab meat', 'lobster meat', 'crevette', 'crevettes', 'crabe', 'homard', 'huître', 'huîtres', 'palourde', 'moule', 'moules', 'coquille saint-jacques', 'écrevisse'],
    'sesame': ['sesame', 'sesame seed', 'sesame seeds', 'tahini', 'sesame oil', 'benne', 'gingelly', 'sesame flour', 'sesame protein', 'sésame', 'graine de sésame', 'graines de sésame', 'huile de sésame'],
    'sulfites': ['sulfite', 'sulfites', 'sulphite', 'sulphites', 'sulfur dioxide', 'sulphur dioxide', 'sodium metabisulphite', 'potassium metabisulphite', 'sodium sulfite', 'potassium sulfite', 'sulfite', 'sulfites', 'dioxyde de soufre', 'métabisulfite de sodium', 'métabisulfite de potassium'],
    'mustard': ['mustard', 'mustard seed', 'mustard powder', 'mustard oil', 'mustard flour', 'mustard protein', 'moutarde', 'graine de moutarde', 'poudre de moutarde', 'huile de moutarde'],
    'celery': ['celery', 'celery seed', 'celery salt', 'celery root', 'celeriac', 'celery powder', 'céleri', 'graine de céleri', 'sel de céleri', 'céleri-rave'],
    'lupin': ['lupin', 'lupine', 'lupini', 'lupin flour', 'lupin bean', 'lupin protein', 'lupin', 'lupine', 'farine de lupin', 'haricot de lupin'],
    'molluscs': ['mollusc', 'molluscs', 'snail', 'snails', 'abalone', 'whelk', 'periwinkle', 'pipi', 'cockle', 'mussel', 'oyster', 'clam', 'scallop', 'mollusque', 'mollusques', 'escargot', 'escargots', 'ormeau', 'buccin', 'bigorneau', 'coque', 'moule', 'huître', 'palourde'],
    // Additional grains
    'corn': ['corn', 'maize', 'corn flour', 'corn starch', 'corn syrup', 'corn oil', 'corn meal', 'corn grits', 'corn protein', 'maïs', 'farine de maïs', 'amidon de maïs', 'sirop de maïs', 'huile de maïs'],
    'rice': ['rice', 'rice flour', 'rice starch', 'rice syrup', 'rice protein', 'brown rice', 'white rice', 'wild rice', 'rice bran', 'rice germ', 'riz', 'farine de riz', 'amidon de riz', 'sirop de riz'],
    'oats': ['oats', 'oat flour', 'oat bran', 'oat protein', 'rolled oats', 'steel cut oats', 'oatmeal', 'avoine', 'farine d\'avoine', 'son d\'avoine'],
    'barley': ['barley', 'barley flour', 'barley malt', 'barley protein', 'pearl barley', 'barley starch', 'orge', 'farine d\'orge', 'malt d\'orge'],
    'rye': ['rye', 'rye flour', 'rye bread', 'rye protein', 'seigle', 'farine de seigle', 'pain de seigle'],
    'quinoa': ['quinoa', 'quinoa flour', 'quinoa protein', 'quinoa seeds', 'quinoa flakes'],
    'buckwheat': ['buckwheat', 'buckwheat flour', 'buckwheat groats', 'buckwheat protein', 'sarrasin', 'farine de sarrasin'],
    // Additional nuts
    'coconut': ['coconut', 'coconut oil', 'coconut flour', 'coconut milk', 'coconut cream', 'coconut protein', 'coconut sugar', 'coconut water', 'noix de coco', 'huile de noix de coco', 'farine de noix de coco', 'lait de noix de coco'],
    'brazil nut': ['brazil nut', 'brazil nuts', 'brazil nut oil', 'brazil nut flour', 'noix du brésil', 'noix du brésil', 'huile de noix du brésil'],
    'pistachio': ['pistachio', 'pistachios', 'pistachio oil', 'pistachio flour', 'pistachio protein', 'pistache', 'pistaches', 'huile de pistache'],
    'macadamia': ['macadamia', 'macadamias', 'macadamia nut', 'macadamia nuts', 'macadamia oil', 'macadamia flour', 'macadamia protein', 'noix de macadamia', 'huile de macadamia'],
    'pine nut': ['pine nut', 'pine nuts', 'pignoli', 'pignolia', 'pine kernel', 'pine kernels', 'pignon', 'pignons'],
    // Fruits and vegetables
    'kiwi': ['kiwi', 'kiwi fruit', 'kiwifruit', 'kiwi protein', 'kiwi extract'],
    'banana': ['banana', 'bananas', 'banana flour', 'banana protein', 'banana extract', 'banane', 'bananes'],
    'tomato': ['tomato', 'tomatoes', 'tomato paste', 'tomato sauce', 'tomato powder', 'tomato protein', 'tomate', 'tomates'],
    'strawberry': ['strawberry', 'strawberries', 'strawberry extract', 'strawberry protein', 'fraise', 'fraises'],
  };

  static Future<Map<String, dynamic>?> getProductByBarcode(String barcode) async {
    await initialize();

    for (final candidate in BarcodeUtils.lookupCandidates(barcode)) {
      final product = _productDatabase[candidate];
      if (product != null) return product;
    }

    return null;
  }

  /// Word-boundary match so "nuts" does not hit "peanuts" and "tree nut" hits
  /// both "tree nut" and the pack phrasing "tree nuts".
  static bool textContainsAllergenTerm(String text, String term) {
    final trimmed = term.trim();
    if (trimmed.isEmpty) return false;
    return RegExp(
      '\\b${RegExp.escape(trimmed)}\\b',
      caseSensitive: false,
    ).hasMatch(text);
  }

  static const List<String> _individualTreeNutKeys = [
    'almond',
    'cashew',
    'hazelnut',
    'pecan',
    'walnut',
    'brazil nut',
    'pistachio',
    'macadamia',
    'pine nut',
    'chestnut',
  ];

  /// Pack-level "tree nuts" / "nuts" / en:nuts traces — not a specific nut.
  static const List<String> _genericTreeNutWarningTerms = [
    'tree nuts',
    'tree nut',
    'nuts',
    'nut',
    'en:nuts',
  ];

  static bool _isIndividualTreeNutAllergy(String allergyName) {
    final lower = allergyName.toLowerCase().trim();
    if (lower == 'tree nuts' || lower == 'tree nut') return false;
    if (_genericTreeNutWarningTerms.contains(lower)) return false;
    if (_individualTreeNutKeys.contains(lower)) return true;
    for (final key in _individualTreeNutKeys) {
      if (_allergenSynonyms[key]?.contains(lower) == true) return true;
    }
    return _allergenSynonyms['tree nuts']!.contains(lower);
  }

  /// Synonyms used to match a saved user allergy against ingredients / traces.
  ///
  /// "Tree Nuts" matches any tree nut. An individual nut matches only that nut,
  /// plus generic pack traces ("tree nuts", "nuts", en:nuts).
  /// When Tree Nuts is saved with a child subset, the parent matches generic
  /// traces only; selected children match their own ingredients.
  static List<String> _synonymsForUserAllergy(
    String allergyName, {
    bool treeNutsGenericOnly = false,
  }) {
    final lower = allergyName.toLowerCase().trim();
    if (lower.isEmpty) return const [];

    if (lower == 'tree nuts' || lower == 'tree nut') {
      if (treeNutsGenericOnly) {
        return List<String>.from(_genericTreeNutWarningTerms);
      }
      return List<String>.from(_allergenSynonyms['tree nuts']!);
    }

    if (_allergenSynonyms.containsKey(lower)) {
      return List<String>.from(_allergenSynonyms[lower]!);
    }

    for (final entry in _allergenSynonyms.entries) {
      if (entry.key == 'tree nuts') continue;
      if (entry.value.contains(lower)) {
        return List<String>.from(entry.value);
      }
    }

    if (_allergenSynonyms['tree nuts']!.contains(lower) &&
        !_genericTreeNutWarningTerms.contains(lower)) {
      return [lower];
    }

    return [lower];
  }

  static List<String> _warningSynonymsForUserAllergy(
    String allergyName, {
    bool treeNutsGenericOnly = false,
    bool skipExtraGenericTreeNutTerms = false,
  }) {
    final synonyms = _synonymsForUserAllergy(
      allergyName,
      treeNutsGenericOnly: treeNutsGenericOnly,
    );
    if (skipExtraGenericTreeNutTerms) {
      return synonyms;
    }
    return _withGenericTreeNutTermsIfNeeded(allergyName, synonyms);
  }

  static List<String> _withGenericTreeNutTermsIfNeeded(
    String keyOrName,
    List<String> synonyms,
  ) {
    final result = List<String>.from(synonyms);
    if (_isIndividualTreeNutAllergy(keyOrName)) {
      for (final term in _genericTreeNutWarningTerms) {
        if (!result.contains(term)) result.add(term);
      }
    }
    return result;
  }

  static List<Map<String, dynamic>> analyzeAllergens(
    List<String> ingredients,
    List<Map<String, dynamic>> userAllergies,
  ) {
    List<Map<String, dynamic>> detectedAllergens = [];
    
    // Convert ingredients to lowercase for matching
    List<String> lowerIngredients = ingredients.map((e) => e.toLowerCase()).toList();
    
    // Also create a combined string for complex ingredient lists
    String combinedIngredients = lowerIngredients.join(' ');
    
    if (kDebugMode) {
      print('ProductDatabaseService: Analyzing allergens');
      print('ProductDatabaseService: Ingredients: $ingredients');
      print('ProductDatabaseService: Lower ingredients: $lowerIngredients');
      print('ProductDatabaseService: Combined ingredients: $combinedIngredients');
      print('ProductDatabaseService: User allergies: ${userAllergies.length}');
      for (var allergy in userAllergies) {
        print('ProductDatabaseService: User allergy - ${allergy['name']} (${allergy['severity']})');
      }
    }
    
    // Parse ingredients to separate actual ingredients from warnings
    Map<String, dynamic> parsedIngredients = parseIngredientsWithWarnings(ingredients);
    List<String> actualIngredients = parsedIngredients['actualIngredients'];
    List<String> crossContaminationWarnings = parsedIngredients['crossContaminationWarnings'];
    List<String> processingFacilityWarnings = parsedIngredients['processingFacilityWarnings'];
    
    if (kDebugMode) {
      print('ProductDatabaseService: Actual ingredients: $actualIngredients');
      print('ProductDatabaseService: Cross-contamination warnings: $crossContaminationWarnings');
      print('ProductDatabaseService: Processing facility warnings: $processingFacilityWarnings');
    }
    
    final allergyNames = userAllergies
        .map((allergy) => allergy['name']?.toString() ?? '')
        .toList();
    final treeNutsSubset = TreeNutsGrouping.isSubset(allergyNames);
    final hasTreeNutsParent = TreeNutsGrouping.hasParent(allergyNames);

    for (Map<String, dynamic> allergy in userAllergies) {
      String allergyName = allergy['name'].toString().toLowerCase();
      
      if (kDebugMode) {
        print('ProductDatabaseService: Checking allergy: $allergyName');
      }
      
      // Check if this allergy is in the allergen synonyms
      bool found = false;
      String matchedIngredient = '';
      String allergenCategory = '';
      String detectionMethod = '';
      bool isCrossContamination = false;

      final treeNutsGenericOnly =
          treeNutsSubset && TreeNutsGrouping.isParentName(allergyName);
      final skipExtraGenericTreeNutTerms = hasTreeNutsParent &&
          _isIndividualTreeNutAllergy(allergyName);
      final synonyms = _synonymsForUserAllergy(
        allergyName,
        treeNutsGenericOnly: treeNutsGenericOnly,
      );
      final warningSynonyms = _warningSynonymsForUserAllergy(
        allergyName,
        treeNutsGenericOnly: treeNutsGenericOnly,
        skipExtraGenericTreeNutTerms: skipExtraGenericTreeNutTerms,
      );
      if (synonyms.isNotEmpty) {
        if (kDebugMode) {
          print('ProductDatabaseService: Found allergy "$allergyName" synonyms: $synonyms');
        }
        allergenCategory = (allergyName == 'tree nuts' || allergyName == 'tree nut')
            ? 'tree nuts'
            : allergyName;

        for (String synonym in warningSynonyms) {
          for (String warning in crossContaminationWarnings) {
            if (textContainsAllergenTerm(warning, synonym)) {
              if (kDebugMode) {
                print('ProductDatabaseService: CROSS-CONTAMINATION MATCH FOUND! Synonym "$synonym" found in warning "$warning"');
              }
              found = true;
              matchedIngredient = warning;
              detectionMethod = 'Cross-contamination warning';
              isCrossContamination = true;
              break;
            }
          }
          if (found) break;
        }

        if (!found) {
          for (String synonym in synonyms) {
            if (kDebugMode) {
              print('ProductDatabaseService: Checking synonym "$synonym" in actual ingredients');
            }
            for (String ingredient in actualIngredients) {
              if (textContainsAllergenTerm(ingredient, synonym)) {
                if (kDebugMode) {
                  print('ProductDatabaseService: ACTUAL INGREDIENT MATCH FOUND! Synonym "$synonym" found in ingredient "$ingredient"');
                }
                found = true;
                matchedIngredient = ingredient;
                detectionMethod = 'Actual ingredient match';
                isCrossContamination = false;
                break;
              }
            }
            if (found) break;
          }

          if (!found) {
            String combinedActual = actualIngredients.join(' ').toLowerCase();
            for (String synonym in synonyms) {
              if (textContainsAllergenTerm(combinedActual, synonym)) {
                if (kDebugMode) {
                  print('ProductDatabaseService: COMBINED INGREDIENT MATCH FOUND! Synonym "$synonym" found in combined ingredients');
                }
                found = true;
                matchedIngredient = 'Found in ingredient list';
                detectionMethod = 'Combined ingredient match';
                isCrossContamination = false;
                break;
              }
            }
          }
        }
      }
      
             // Also check direct ingredient match (prioritize cross-contamination)
       if (!found) {
         // Check cross-contamination warnings for direct match first
         for (String warning in crossContaminationWarnings) {
           if (textContainsAllergenTerm(warning, allergyName)) {
             if (kDebugMode) {
               print('ProductDatabaseService: DIRECT CROSS-CONTAMINATION MATCH FOUND! Allergy "$allergyName" found in warning "$warning"');
             }
             found = true;
             matchedIngredient = warning;
             allergenCategory = allergyName;
             detectionMethod = 'Direct cross-contamination warning';
             isCrossContamination = true;
             break;
           }
         }
         
         // If not found in cross-contamination, check actual ingredients
         if (!found) {
           for (String ingredient in actualIngredients) {
             if (textContainsAllergenTerm(ingredient, allergyName)) {
               if (kDebugMode) {
                 print('ProductDatabaseService: DIRECT ACTUAL INGREDIENT MATCH FOUND! Allergy "$allergyName" found in ingredient "$ingredient"');
               }
               found = true;
               matchedIngredient = ingredient;
               allergenCategory = allergyName;
               detectionMethod = 'Direct actual ingredient match';
               isCrossContamination = false;
               break;
             }
           }
         }
       }
      
      if (found) {
        if (kDebugMode) {
          print('ProductDatabaseService: FOUND ALLERGEN - ${allergy['name']} in ingredient: $matchedIngredient (Method: $detectionMethod, Cross-contamination: $isCrossContamination)');
        }
        detectedAllergens.add({
          'name': allergy['name'],
          'severity': allergy['severity'],
          'category': allergy['category'],
          'matchedIngredient': matchedIngredient,
          'allergenCategory': allergenCategory,
          'notes': allergy['notes'],
          'detectionMethod': detectionMethod,
          'isCrossContamination': isCrossContamination,
          'confidence': isCrossContamination ? 0.7 : 1.0, // Lower confidence for cross-contamination
        });
      } else {
        if (kDebugMode) {
          print('ProductDatabaseService: NO MATCH found for allergy: ${allergy['name']}');
        }
      }
    }
    
    return detectedAllergens;
  }

  /// Parse ingredients to separate actual ingredients from warnings
  static Map<String, dynamic> parseIngredientsWithWarnings(List<String> ingredients) {
    List<String> actualIngredients = [];
    List<String> crossContaminationWarnings = [];
    List<String> processingFacilityWarnings = [];
    
    // Common cross-contamination phrases
    List<String> crossContaminationPhrases = [
      'may contain',
      'may contain traces',
      'may contain traces of',
      'may contain small amounts',
      'may contain minute amounts',
      'may contain trace amounts',
      'may contain small traces',
      'allergen information',
      'allergen advice',
      'allergen warning',
      'contains traces',
      'contains small amounts',
      'may be present',
      'may be present in small amounts',
      'produced in a facility',
      'manufactured in a facility',
      'packaged in a facility',
      'processed in a facility',
      'made in a facility',
      'handled in a facility',
    ];
    
    // Common processing facility phrases
    List<String> processingFacilityPhrases = [
      'processed in a facility',
      'manufactured in a facility',
      'packaged in a facility',
      'produced in a facility',
      'made in a facility',
      'handled in a facility',
      'facility processes',
      'facility that processes',
      'facility that manufactures',
      'facility that packages',
    ];
    
    if (kDebugMode) {
      print('ProductDatabaseService: parseIngredientsWithWarnings - Input ingredients: $ingredients');
    }
    
    for (String ingredient in ingredients) {
      String lowerIngredient = ingredient.toLowerCase();
      bool isWarning = false;
      
      if (kDebugMode) {
        print('ProductDatabaseService: Processing ingredient: "$ingredient"');
      }
      
      // Check for cross-contamination warnings
      for (String phrase in crossContaminationPhrases) {
        if (lowerIngredient.contains(phrase)) {
          if (kDebugMode) {
            print('ProductDatabaseService: Found cross-contamination phrase "$phrase" in ingredient "$ingredient"');
          }
          crossContaminationWarnings.add(ingredient);
          isWarning = true;
          break;
        }
      }
      
      // Check for processing facility warnings
      if (!isWarning) {
        for (String phrase in processingFacilityPhrases) {
          if (lowerIngredient.contains(phrase)) {
            if (kDebugMode) {
              print('ProductDatabaseService: Found processing facility phrase "$phrase" in ingredient "$ingredient"');
            }
            processingFacilityWarnings.add(ingredient);
            isWarning = true;
            break;
          }
        }
      }
      
      // If not a warning, it's an actual ingredient
      if (!isWarning) {
        if (kDebugMode) {
          print('ProductDatabaseService: Adding as actual ingredient: "$ingredient"');
        }
        actualIngredients.add(ingredient);
      }
    }
    
    if (kDebugMode) {
      print('ProductDatabaseService: parseIngredientsWithWarnings - Results:');
      print('  Actual ingredients: $actualIngredients');
      print('  Cross-contamination warnings: $crossContaminationWarnings');
      print('  Processing facility warnings: $processingFacilityWarnings');
    }
    
    return {
      'actualIngredients': actualIngredients,
      'crossContaminationWarnings': crossContaminationWarnings,
      'processingFacilityWarnings': processingFacilityWarnings,
    };
  }

  /// Extract individual items listed in "may contain" sections of ingredient text.
  static List<String> extractMayContainListing(List<String> ingredients) {
    if (ingredients.isEmpty) return [];

    final items = <String>[];
    final seen = <String>{};

    void addFromListing(String listing) {
      var cleaned = listing.trim();
      if (cleaned.isEmpty) return;

      cleaned = cleaned
          .replaceAll(
            RegExp(r'^(may contain( traces( of)?)?|contains traces( of)?|may be present)[:\s]*', caseSensitive: false),
            '',
          )
          .replaceAll(RegExp(r'\.$'), '')
          .trim();

      if (cleaned.isEmpty) return;

      for (final part in cleaned.split(RegExp(r',|\band\b', caseSensitive: false))) {
        final item = part.trim();
        if (item.length <= 1) continue;
        final formatted = _formatMayContainItem(item);
        if (formatted.length > 1 && seen.add(formatted.toLowerCase())) {
          items.add(formatted);
        }
      }
    }

    final combined = ingredients.join(' ');
    final mayContainPattern = RegExp(
      r'may contain(?: traces(?: of)?)?[:\s]+([^\.]+)',
      caseSensitive: false,
    );
    for (final match in mayContainPattern.allMatches(combined)) {
      addFromListing(match.group(1) ?? '');
    }

    // "Egg, peanuts, sesame, and other tree nuts may be present"
    final mayBePresentIndex = combined.toLowerCase().indexOf('may be present');
    if (mayBePresentIndex > 0) {
      var listing = combined.substring(0, mayBePresentIndex).trim();
      final lastPeriod = listing.lastIndexOf('.');
      if (lastPeriod >= 0) {
        listing = listing.substring(lastPeriod + 1).trim();
      }
      addFromListing(listing);
    }

    // "May contain traces of Peanut, Egg, Sesame and tree Nut"
    final tracesOfPattern = RegExp(
      r'(?:may contain )?traces of[:\s]+([^\.]+)',
      caseSensitive: false,
    );
    for (final match in tracesOfPattern.allMatches(combined)) {
      addFromListing(match.group(1) ?? '');
    }

    final parsed = parseIngredientsWithWarnings(ingredients);
    for (final warning in parsed['crossContaminationWarnings'] as List<String>) {
      addFromListing(warning);
    }

    return items;
  }

  /// Collect may-contain items from ingredient text and product metadata.
  static List<String> collectMayContainItems({
    required List<String> ingredients,
    Map<String, dynamic>? product,
  }) {
    final seen = <String>{};
    final items = <String>[];

    void addItem(String value) {
      final trimmed = HtmlTextUtils.strip(value);
      if (trimmed.length <= 1) return;
      // Canonicalize first so Peanut/peanuts and nuts/Tree Nuts collapse.
      // Do not expand Tree Nuts into child nuts for the label list.
      final formatted = _formatMayContainItem(trimmed);
      if (formatted.length <= 1) return;
      if (seen.add(formatted.toLowerCase())) {
        items.add(formatted);
      }
    }

    for (final item in extractMayContainListing(ingredients)) {
      addItem(item);
    }

    if (product == null) return items;

    _addTraceTagItems(product['traces_tags'], addItem);
    for (final trace in (product['traces']?.toString() ?? '').split(',')) {
      addItem(trace.replaceAll('_', ' '));
    }

    for (final item in product['mayContainItems'] as List<dynamic>? ?? []) {
      addItem(item.toString());
    }

    for (final entry in product['crossContamination'] as List<dynamic>? ?? []) {
      final text = entry.toString().trim();
      if (text.isEmpty) continue;
      if (text.toLowerCase().contains('may contain')) {
        for (final item in extractMayContainListing([text])) {
          addItem(item);
        }
      } else {
        addItem(text);
      }
    }

    for (final warning in product['crossContaminationWarnings'] as List<dynamic>? ?? []) {
      if (warning is Map<String, dynamic>) {
        final allergen = warning['allergen']?.toString();
        if (allergen != null && allergen.isNotEmpty && allergen.toLowerCase() != 'unknown') {
          addItem(allergen);
        }
        final original = warning['originalWarning']?.toString();
        if (original != null && original.isNotEmpty) {
          for (final item in extractMayContainListing([original])) {
            addItem(item);
          }
        }
      } else if (warning is String) {
        for (final item in extractMayContainListing([warning])) {
          addItem(item);
        }
      }
    }

    return items;
  }

  static const Map<String, String> _traceTagNames = {
    'peanuts': 'Peanut',
    'tree-nuts': 'Tree Nuts',
    'nuts': 'Tree Nuts',
    'milk': 'Milk',
    'eggs': 'Egg',
    'egg': 'Egg',
    'soybeans': 'Soy',
    'soy': 'Soy',
    'wheat': 'Wheat',
    'gluten': 'Gluten',
    'fish': 'Fish',
    'crustaceans': 'Shellfish',
    'sesame-seeds': 'Sesame',
    'sesame': 'Sesame',
    'sulphur-dioxide-and-sulphites': 'Sulphites',
    'mustard': 'Mustard',
    'celery': 'Celery',
    'lupin': 'Lupin',
    'molluscs': 'Molluscs',
    'almonds': 'Almond',
    'cashew-nuts': 'Cashew',
    'macadamia-nuts': 'Macadamia',
  };

  static void _addTraceTagItems(dynamic tags, void Function(String) addItem) {
    if (tags is! List) return;
    for (final tag in tags) {
      final raw = tag.toString().replaceFirst(RegExp(r'^en:'), '').toLowerCase();
      addItem(_traceTagNames[raw] ?? raw.replaceAll('-', ' '));
    }
  }

  static const Map<String, String> _mayContainCanonicalNames = {
    'nuts': 'Tree Nuts',
    'nut': 'Tree Nuts',
    'tree nut': 'Tree Nuts',
    'tree nuts': 'Tree Nuts',
    'tree-nuts': 'Tree Nuts',
    'en:nuts': 'Tree Nuts',
    'en:tree-nuts': 'Tree Nuts',
    'peanut': 'Peanut',
    'peanuts': 'Peanut',
    'en:peanuts': 'Peanut',
    'almond': 'Almond',
    'almonds': 'Almond',
    'en:almonds': 'Almond',
    'cashew': 'Cashew',
    'cashews': 'Cashew',
    'cashew nut': 'Cashew',
    'cashew nuts': 'Cashew',
    'cashew-nuts': 'Cashew',
    'en:cashew-nuts': 'Cashew',
    'macadamia': 'Macadamia',
    'macadamias': 'Macadamia',
    'macadamia nut': 'Macadamia',
    'macadamia nuts': 'Macadamia',
    'macadamia-nuts': 'Macadamia',
    'en:macadamia-nuts': 'Macadamia',
    'soy': 'Soy',
    'soya': 'Soy',
    'soybean': 'Soy',
    'soybeans': 'Soy',
    'en:soybeans': 'Soy',
    'egg': 'Egg',
    'eggs': 'Egg',
    'en:eggs': 'Egg',
    'sesame': 'Sesame',
    'sesame seed': 'Sesame',
    'sesame seeds': 'Sesame',
    'sesame-seeds': 'Sesame',
    'en:sesame-seeds': 'Sesame',
  };

  static String _formatMayContainItem(String item) {
    final collapsed = item
        .split(' ')
        .where((word) => word.isNotEmpty)
        .join(' ');
    final canonical = _mayContainCanonicalNames[collapsed.toLowerCase()];
    if (canonical != null) return canonical;
    return collapsed
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  static bool _initialized = false;

  /// Load the curated barcode catalog into the runtime map.
  static Future<void> initialize() async {
    if (_initialized) return;
    await AustralianCuratedProductDatabase.ensureLoaded();
    _initialized = true;

    for (final entry in OpenFoodFactsService.manualProductDatabase.entries) {
      _productDatabase[entry.key] = Map<String, dynamic>.from(entry.value);
    }

    if (kDebugMode) {
      print('ProductDatabaseService: initialized with ${_productDatabase.length} products');
    }
  }

  /// Replace a runtime entry entirely (used to restore curated data).
  static void replaceProduct(String barcode, Map<String, dynamic> product) {
    _productDatabase[barcode] = Map<String, dynamic>.from(product);
  }

  /// True when an ingredient row is a may-contain / traces statement, not a recipe item.
  static bool isMayContainStatement(String item) {
    final text = item.toLowerCase().trim();
    return text.contains('may contain') ||
        text.contains('may be present') ||
        text.contains('contains traces') ||
        text.startsWith('traces of');
  }

  /// Ingredient chips should not also list the may-contain sentence.
  static List<String> ingredientsExcludingMayContain(List<String> ingredients) {
    return ingredients
        .map(HtmlTextUtils.strip)
        .where((item) => item.isNotEmpty && !isMayContainStatement(item))
        .toList();
  }

  static Map<String, Map<String, dynamic>> getAllProducts() {
    return Map.from(_productDatabase);
  }
} 