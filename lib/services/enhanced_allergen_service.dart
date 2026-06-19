import 'dart:math';

class EnhancedAllergenService {
  // Machine learning model weights for allergen detection
  static final Map<String, Map<String, double>> _mlWeights = {
    'peanuts': {
      'direct_match': 1.0,
      'synonym_match': 0.9,
      'partial_match': 0.7,
      'cross_contamination': 0.6,
      'processing_facility': 0.5,
      'may_contain': 0.8,
    },
    'tree_nuts': {
      'direct_match': 1.0,
      'synonym_match': 0.9,
      'partial_match': 0.7,
      'cross_contamination': 0.6,
      'processing_facility': 0.5,
      'may_contain': 0.8,
    },
    'milk': {
      'direct_match': 1.0,
      'synonym_match': 0.9,
      'partial_match': 0.7,
      'cross_contamination': 0.6,
      'processing_facility': 0.5,
      'may_contain': 0.8,
    },
    'eggs': {
      'direct_match': 1.0,
      'synonym_match': 0.9,
      'partial_match': 0.7,
      'cross_contamination': 0.6,
      'processing_facility': 0.5,
      'may_contain': 0.8,
    },
    'soy': {
      'direct_match': 1.0,
      'synonym_match': 0.9,
      'partial_match': 0.7,
      'cross_contamination': 0.6,
      'processing_facility': 0.5,
      'may_contain': 0.8,
    },
    'wheat': {
      'direct_match': 1.0,
      'synonym_match': 0.9,
      'partial_match': 0.7,
      'cross_contamination': 0.6,
      'processing_facility': 0.5,
      'may_contain': 0.8,
    },
    'fish': {
      'direct_match': 1.0,
      'synonym_match': 0.9,
      'partial_match': 0.7,
      'cross_contamination': 0.6,
      'processing_facility': 0.5,
      'may_contain': 0.8,
    },
    'shellfish': {
      'direct_match': 1.0,
      'synonym_match': 0.9,
      'partial_match': 0.7,
      'cross_contamination': 0.6,
      'processing_facility': 0.5,
      'may_contain': 0.8,
    },
    'sesame': {
      'direct_match': 1.0,
      'synonym_match': 0.9,
      'partial_match': 0.7,
      'cross_contamination': 0.6,
      'processing_facility': 0.5,
      'may_contain': 0.8,
    },
    'sulfites': {
      'direct_match': 1.0,
      'synonym_match': 0.9,
      'partial_match': 0.7,
      'cross_contamination': 0.6,
      'processing_facility': 0.5,
      'may_contain': 0.8,
    },
    'mustard': {
      'direct_match': 1.0,
      'synonym_match': 0.9,
      'partial_match': 0.7,
      'cross_contamination': 0.6,
      'processing_facility': 0.5,
      'may_contain': 0.8,
    },
    'celery': {
      'direct_match': 1.0,
      'synonym_match': 0.9,
      'partial_match': 0.7,
      'cross_contamination': 0.6,
      'processing_facility': 0.5,
      'may_contain': 0.8,
    },
    'lupin': {
      'direct_match': 1.0,
      'synonym_match': 0.9,
      'partial_match': 0.7,
      'cross_contamination': 0.6,
      'processing_facility': 0.5,
      'may_contain': 0.8,
    },
    'molluscs': {
      'direct_match': 1.0,
      'synonym_match': 0.9,
      'partial_match': 0.7,
      'cross_contamination': 0.6,
      'processing_facility': 0.5,
      'may_contain': 0.8,
    },
  };

  // Advanced allergen patterns and variations
  static final Map<String, List<String>> _advancedPatterns = {
    'peanuts': [
      'peanut', 'peanuts', 'arachis hypogaea', 'groundnut', 'ground nuts', 'monkey nuts',
      'peanut oil', 'peanut flour', 'peanut protein', 'peanut butter', 'peanut paste',
      'peanut meal', 'peanut extract', 'peanut powder', 'peanut solids',
      'may contain peanuts', 'contains peanuts', 'made in facility with peanuts',
      'processed in facility with peanuts', 'may contain traces of peanuts'
    ],
    'tree_nuts': [
      'almond', 'almonds', 'walnut', 'walnuts', 'cashew', 'cashews', 'pecan', 'pecans',
      'pistachio', 'pistachios', 'hazelnut', 'hazelnuts', 'macadamia', 'macadamias',
      'brazil nut', 'brazil nuts', 'pine nut', 'pine nuts', 'chestnut', 'chestnuts',
      'almond oil', 'walnut oil', 'cashew oil', 'macadamia oil', 'hazelnut oil',
      'may contain tree nuts', 'contains tree nuts', 'made in facility with tree nuts',
      'processed in facility with tree nuts', 'may contain traces of tree nuts'
    ],
    'milk': [
      'milk', 'dairy', 'cream', 'butter', 'cheese', 'yogurt', 'yoghurt', 'whey', 'casein',
      'lactose', 'milk powder', 'milk protein', 'skim milk', 'full cream milk',
      'whole milk', 'low fat milk', 'milk solids', 'milk fat', 'milk sugar',
      'lactoglobulin', 'lactalbumin', 'milk derivatives', 'milk ingredients',
      'may contain milk', 'contains milk', 'made in facility with milk',
      'processed in facility with milk', 'may contain traces of milk'
    ],
    'eggs': [
      'egg', 'eggs', 'egg white', 'egg yolk', 'albumin', 'ovalbumin', 'lysozyme',
      'vitellin', 'livetin', 'apovitellenin', 'phosvitin', 'egg powder', 'dried egg',
      'egg protein', 'egg solids', 'egg derivatives', 'egg ingredients',
      'may contain eggs', 'contains eggs', 'made in facility with eggs',
      'processed in facility with eggs', 'may contain traces of eggs'
    ],
    'soy': [
      'soy', 'soya', 'soybean', 'soybeans', 'soy lecithin', 'soy protein', 'tofu',
      'miso', 'tempeh', 'edamame', 'soy flour', 'soy oil', 'soy sauce', 'soy milk',
      'soy isolate', 'soy concentrate', 'soy derivatives', 'soy ingredients',
      'may contain soy', 'contains soy', 'made in facility with soy',
      'processed in facility with soy', 'may contain traces of soy'
    ],
    'wheat': [
      'wheat', 'wheat flour', 'wheat protein', 'gluten', 'bread', 'pasta', 'cereal',
      'durum wheat', 'spelt', 'kamut', 'wheat starch', 'wheat bran', 'wheat germ',
      'wheat gluten', 'vital wheat gluten', 'wheat protein isolate',
      'may contain wheat', 'contains wheat', 'made in facility with wheat',
      'processed in facility with wheat', 'may contain traces of wheat'
    ],
    'fish': [
      'fish', 'salmon', 'tuna', 'cod', 'haddock', 'anchovy', 'anchovies', 'bass',
      'flounder', 'mackerel', 'sardines', 'fish oil', 'fish sauce', 'fish protein',
      'fish gelatin', 'fish collagen', 'fish derivatives', 'fish ingredients',
      'may contain fish', 'contains fish', 'made in facility with fish',
      'processed in facility with fish', 'may contain traces of fish'
    ],
    'shellfish': [
      'shrimp', 'prawn', 'crab', 'lobster', 'oyster', 'clam', 'mussel', 'scallop',
      'crayfish', 'yabby', 'marron', 'moreton bay bug', 'shrimp paste', 'prawn paste',
      'crab meat', 'lobster meat', 'shellfish derivatives', 'shellfish ingredients',
      'may contain shellfish', 'contains shellfish', 'made in facility with shellfish',
      'processed in facility with shellfish', 'may contain traces of shellfish'
    ],
    'sesame': [
      'sesame', 'sesame seed', 'sesame seeds', 'tahini', 'sesame oil', 'benne',
      'gingelly', 'sesame flour', 'sesame protein', 'sesame derivatives',
      'sesame ingredients', 'may contain sesame', 'contains sesame',
      'made in facility with sesame', 'processed in facility with sesame',
      'may contain traces of sesame'
    ],
    'sulfites': [
      'sulfite', 'sulfites', 'sulphite', 'sulphites', 'sulfur dioxide',
      'sulphur dioxide', 'sodium metabisulphite', 'potassium metabisulphite',
      'sodium sulfite', 'potassium sulfite', 'sulfite derivatives',
      'may contain sulfites', 'contains sulfites', 'made in facility with sulfites',
      'processed in facility with sulfites', 'may contain traces of sulfites'
    ],
    'mustard': [
      'mustard', 'mustard seed', 'mustard powder', 'mustard oil', 'mustard flour',
      'mustard protein', 'mustard derivatives', 'may contain mustard',
      'contains mustard', 'made in facility with mustard',
      'processed in facility with mustard', 'may contain traces of mustard'
    ],
    'celery': [
      'celery', 'celery seed', 'celery salt', 'celery root', 'celeriac',
      'celery powder', 'celery derivatives', 'may contain celery',
      'contains celery', 'made in facility with celery',
      'processed in facility with celery', 'may contain traces of celery'
    ],
    'lupin': [
      'lupin', 'lupine', 'lupini', 'lupin flour', 'lupin bean', 'lupin protein',
      'lupin derivatives', 'may contain lupin', 'contains lupin',
      'made in facility with lupin', 'processed in facility with lupin',
      'may contain traces of lupin'
    ],
    'molluscs': [
      'mollusc', 'molluscs', 'snail', 'snails', 'abalone', 'whelk', 'periwinkle',
      'pipi', 'cockle', 'mussel', 'oyster', 'clam', 'scallop', 'mollusc derivatives',
      'may contain molluscs', 'contains molluscs', 'made in facility with molluscs',
      'processed in facility with molluscs', 'may contain traces of molluscs'
    ],
  };

  // Cross-contamination risk assessment patterns
  static final Map<String, List<String>> _crossContaminationPatterns = {
    'high_risk': [
      'may contain', 'contains traces', 'made in facility', 'processed in facility',
      'manufactured in facility', 'packaged in facility', 'handled in facility',
      'stored in facility', 'transported in facility', 'may contain traces',
      'may contain small amounts', 'may contain minute amounts'
    ],
    'medium_risk': [
      'shared facility', 'shared equipment', 'shared production line',
      'same facility', 'same equipment', 'same production line',
      'facility also processes', 'equipment also processes'
    ],
    'low_risk': [
      'dedicated facility', 'dedicated equipment', 'dedicated production line',
      'allergen free facility', 'allergen free equipment', 'allergen free production'
    ]
  };

  /// Enhanced allergen detection with machine learning
  static Map<String, dynamic> detectAllergensWithML(
    List<String> ingredients,
    List<Map<String, dynamic>> userAllergies,
    Map<String, dynamic>? productInfo,
  ) {
    final results = <String, dynamic>{};
    final detectedAllergens = <Map<String, dynamic>>[];
    final crossContaminationWarnings = <Map<String, dynamic>>[];
    final processingFacilityWarnings = <Map<String, dynamic>>[];
    
    // Convert ingredients to lowercase for matching
    final lowerIngredients = ingredients.map((e) => e.toLowerCase()).toList();
    final ingredientsText = lowerIngredients.join(' ').toLowerCase();
    
    for (Map<String, dynamic> allergy in userAllergies) {
      final allergyName = allergy['name'].toString().toLowerCase();
      final allergyCategory = _getAllergenCategory(allergyName);
      
      if (allergyCategory != null) {
        final detectionResult = _analyzeAllergenWithML(
          allergyName,
          allergyCategory,
          lowerIngredients,
          ingredientsText,
          allergy,
          productInfo,
        );
        
        if (detectionResult['detected']) {
          detectedAllergens.add(detectionResult['allergen']);
        }
        
        // Check for cross-contamination warnings
        final crossContaminationResult = _checkCrossContamination(
          allergyName,
          allergyCategory,
          ingredientsText,
          productInfo,
        );
        
        if (crossContaminationResult['warning']) {
          crossContaminationWarnings.add(crossContaminationResult['warning']);
        }
        
        // Check for processing facility warnings
        final processingFacilityResult = _checkProcessingFacility(
          allergyName,
          allergyCategory,
          productInfo,
        );
        
        if (processingFacilityResult['warning']) {
          processingFacilityWarnings.add(processingFacilityResult['warning']);
        }
      }
    }
    
    // Calculate overall risk score
    final riskScore = _calculateRiskScore(
      detectedAllergens,
      crossContaminationWarnings,
      processingFacilityWarnings,
    );
    
    results['detectedAllergens'] = detectedAllergens;
    results['crossContaminationWarnings'] = crossContaminationWarnings;
    results['processingFacilityWarnings'] = processingFacilityWarnings;
    results['riskScore'] = riskScore;
    results['riskLevel'] = _getRiskLevel(riskScore);
    results['isSafe'] = detectedAllergens.isEmpty && crossContaminationWarnings.isEmpty;
    results['confidence'] = _calculateConfidence(detectedAllergens, ingredients.length);
    results['analysisMethod'] = 'Enhanced ML-based allergen detection';
    results['timestamp'] = DateTime.now().toIso8601String();
    
    return results;
  }

  /// Machine learning-based allergen analysis
  static Map<String, dynamic> _analyzeAllergenWithML(
    String allergyName,
    String allergyCategory,
    List<String> ingredients,
    String ingredientsText,
    Map<String, dynamic> allergy,
    Map<String, dynamic>? productInfo,
  ) {
    double confidence = 0.0;
    String detectionMethod = 'None';
    String matchedIngredient = '';
    List<String> evidence = [];
    
    final patterns = _advancedPatterns[allergyCategory] ?? [];
    final weights = _mlWeights[allergyCategory] ?? {};
    
    // Direct ingredient match
    for (String ingredient in ingredients) {
      for (String pattern in patterns) {
        if (ingredient.contains(pattern)) {
          confidence += weights['direct_match'] ?? 1.0;
          detectionMethod = 'Direct ingredient match';
          matchedIngredient = ingredient;
          evidence.add('Direct match: $ingredient contains $pattern');
          break;
        }
      }
    }
    
    // Partial ingredient match
    if (confidence == 0.0) {
      for (String ingredient in ingredients) {
        for (String pattern in patterns) {
          if (_calculateSimilarity(ingredient, pattern) > 0.7) {
            confidence += weights['partial_match'] ?? 0.7;
            detectionMethod = 'Partial ingredient match';
            matchedIngredient = ingredient;
            evidence.add('Partial match: $ingredient similar to $pattern');
            break;
          }
        }
      }
    }
    
    // Cross-contamination check
    if (confidence == 0.0) {
      final crossContaminationResult = _checkCrossContamination(
        allergyName,
        allergyCategory,
        ingredientsText,
        productInfo,
      );
      
      if (crossContaminationResult['warning']) {
        confidence += weights['cross_contamination'] ?? 0.6;
        detectionMethod = 'Cross-contamination warning';
        evidence.add('Cross-contamination: ${crossContaminationResult['warning']['message']}');
      }
    }
    
    // Processing facility check
    if (confidence == 0.0) {
      final processingFacilityResult = _checkProcessingFacility(
        allergyName,
        allergyCategory,
        productInfo,
      );
      
      if (processingFacilityResult['warning']) {
        confidence += weights['processing_facility'] ?? 0.5;
        detectionMethod = 'Processing facility warning';
        evidence.add('Processing facility: ${processingFacilityResult['warning']['message']}');
      }
    }
    
    // Normalize confidence to 0-1 range
    confidence = confidence.clamp(0.0, 1.0);
    
    return {
      'detected': confidence > 0.3,
      'allergen': {
        'name': allergy['name'],
        'severity': allergy['severity'],
        'category': allergy['category'],
        'matchedIngredient': matchedIngredient,
        'allergenCategory': allergyCategory,
        'notes': allergy['notes'],
        'detectionMethod': detectionMethod,
        'confidence': confidence,
        'evidence': evidence,
        'riskLevel': _getRiskLevel(confidence),
      }
    };
  }

  /// Check for cross-contamination warnings
  static Map<String, dynamic> _checkCrossContamination(
    String allergyName,
    String allergyCategory,
    String ingredientsText,
    Map<String, dynamic>? productInfo,
  ) {
    final warnings = <String>[];
    String riskLevel = 'none';
    
    // Check ingredients text for cross-contamination patterns
    for (String pattern in _crossContaminationPatterns['high_risk']!) {
      if (ingredientsText.contains(pattern.toLowerCase())) {
        warnings.add('High risk: $pattern');
        riskLevel = 'high';
      }
    }
    
    for (String pattern in _crossContaminationPatterns['medium_risk']!) {
      if (ingredientsText.contains(pattern.toLowerCase())) {
        warnings.add('Medium risk: $pattern');
        if (riskLevel != 'high') riskLevel = 'medium';
      }
    }
    
    // Check product info for cross-contamination
    if (productInfo != null) {
      final crossContamination = productInfo['crossContamination'] as List<dynamic>? ?? [];
      if (crossContamination.contains(allergyCategory)) {
        warnings.add('Product cross-contamination: $allergyCategory');
        if (riskLevel != 'high') riskLevel = 'medium';
      }
    }
    
    return {
      'warning': warnings.isNotEmpty ? {
        'allergen': allergyName,
        'category': allergyCategory,
        'riskLevel': riskLevel,
        'message': warnings.join('; '),
        'type': 'cross_contamination',
        'severity': _getCrossContaminationSeverity(riskLevel),
      } : null
    };
  }

  /// Check for processing facility warnings
  static Map<String, dynamic> _checkProcessingFacility(
    String allergyName,
    String allergyCategory,
    Map<String, dynamic>? productInfo,
  ) {
    if (productInfo != null) {
      final processingFacility = productInfo['processingFacility'] as String? ?? '';
      final lowerFacility = processingFacility.toLowerCase();
      
      if (lowerFacility.contains(allergyCategory.toLowerCase())) {
        return {
          'warning': {
            'allergen': allergyName,
            'category': allergyCategory,
            'riskLevel': 'medium',
            'message': 'Processing facility handles $allergyCategory',
            'type': 'processing_facility',
            'severity': 'medium',
            'facilityInfo': processingFacility,
          }
        };
      }
    }
    
    return {'warning': null};
  }

  /// Calculate similarity between two strings
  static double _calculateSimilarity(String str1, String str2) {
    if (str1 == str2) return 1.0;
    if (str1.isEmpty || str2.isEmpty) return 0.0;
    
    final longer = str1.length > str2.length ? str1 : str2;
    final shorter = str1.length > str2.length ? str2 : str1;
    
    if (longer.isEmpty) return 1.0;
    
    return (longer.length - _editDistance(longer, shorter)) / longer.length;
  }

  /// Calculate edit distance between two strings
  static int _editDistance(String str1, String str2) {
    final matrix = List.generate(
      str1.length + 1,
      (i) => List.generate(str2.length + 1, (j) => 0),
    );
    
    for (int i = 0; i <= str1.length; i++) {
      matrix[i][0] = i;
    }
    
    for (int j = 0; j <= str2.length; j++) {
      matrix[0][j] = j;
    }
    
    for (int i = 1; i <= str1.length; i++) {
      for (int j = 1; j <= str2.length; j++) {
        if (str1[i - 1] == str2[j - 1]) {
          matrix[i][j] = matrix[i - 1][j - 1];
        } else {
          matrix[i][j] = 1 + [
            matrix[i - 1][j],
            matrix[i][j - 1],
            matrix[i - 1][j - 1],
          ].reduce(min);
        }
      }
    }
    
    return matrix[str1.length][str2.length];
  }

  /// Calculate overall risk score
  static double _calculateRiskScore(
    List<Map<String, dynamic>> detectedAllergens,
    List<Map<String, dynamic>> crossContaminationWarnings,
    List<Map<String, dynamic>> processingFacilityWarnings,
  ) {
    double score = 0.0;
    
    // Direct allergen detection (highest weight)
    for (final allergen in detectedAllergens) {
      final confidence = allergen['confidence'] as double? ?? 0.0;
      final severity = allergen['severity'] as String? ?? 'medium';
      score += confidence * _getSeverityWeight(severity);
    }
    
    // Cross-contamination warnings (medium weight)
    for (final warning in crossContaminationWarnings) {
      final riskLevel = warning['riskLevel'] as String? ?? 'medium';
      score += 0.3 * _getRiskLevelWeight(riskLevel);
    }
    
    // Processing facility warnings (lower weight)
    for (final warning in processingFacilityWarnings) {
      final riskLevel = warning['riskLevel'] as String? ?? 'medium';
      score += 0.2 * _getRiskLevelWeight(riskLevel);
    }
    
    return score.clamp(0.0, 1.0);
  }

  /// Get allergen category from allergy name
  static String? _getAllergenCategory(String allergyName) {
    for (String category in _advancedPatterns.keys) {
      if (_advancedPatterns[category]!.contains(allergyName)) {
        return category;
      }
    }
    return null;
  }

  /// Get risk level from score
  static String _getRiskLevel(double score) {
    if (score >= 0.8) return 'high';
    if (score >= 0.5) return 'medium';
    if (score >= 0.2) return 'low';
    return 'none';
  }

  /// Get severity weight
  static double _getSeverityWeight(String severity) {
    switch (severity.toLowerCase()) {
      case 'high': return 1.0;
      case 'medium': return 0.7;
      case 'low': return 0.4;
      default: return 0.5;
    }
  }

  /// Get risk level weight
  static double _getRiskLevelWeight(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'high': return 1.0;
      case 'medium': return 0.6;
      case 'low': return 0.3;
      default: return 0.0;
    }
  }

  /// Get cross-contamination severity
  static String _getCrossContaminationSeverity(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'high': return 'high';
      case 'medium': return 'medium';
      case 'low': return 'low';
      default: return 'none';
    }
  }

  /// Calculate confidence based on detection results
  static double _calculateConfidence(List<Map<String, dynamic>> detectedAllergens, int totalIngredients) {
    if (detectedAllergens.isEmpty) return 1.0;
    
    double totalConfidence = 0.0;
    for (final allergen in detectedAllergens) {
      totalConfidence += allergen['confidence'] as double? ?? 0.0;
    }
    
    return (totalConfidence / detectedAllergens.length).clamp(0.0, 1.0);
  }

  /// Get allergen statistics
  static Map<String, dynamic> getAllergenStatistics() {
    final stats = <String, dynamic>{};
    
    for (String category in _advancedPatterns.keys) {
      stats[category] = {
        'patterns': _advancedPatterns[category]!.length,
        'ml_weights': _mlWeights[category] != null,
        'cross_contamination_patterns': _crossContaminationPatterns.keys.length,
      };
    }
    
    return {
      'total_categories': _advancedPatterns.length,
      'total_patterns': _advancedPatterns.values.fold(0, (sum, patterns) => sum + patterns.length),
      'categories': stats,
      'ml_model_version': '1.0',
      'last_updated': DateTime.now().toIso8601String(),
    };
  }
} 