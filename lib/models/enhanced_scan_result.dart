import 'dart:convert';

class EnhancedScanResult {
  final String barcode;
  final String productName;
  final String brand;
  final List<String> ingredients;
  final List<String> mayContainItems;
  final List<Map<String, dynamic>> detectedAllergens;
  final List<Map<String, dynamic>> crossContaminationWarnings;
  final List<Map<String, dynamic>> processingFacilityWarnings;
  final Map<String, dynamic> safetyAssessment;
  final DateTime scanDate;
  final bool isSafe;
  final String? image;
  final String dataSource;
  final String analysisMethod;
  final double confidenceScore;
  final String riskLevel;
  final int processingTimeMs;
  final Map<String, dynamic> allergenAnalysis;
  final Map<String, dynamic> crossContaminationRisk;

  EnhancedScanResult({
    required this.barcode,
    required this.productName,
    required this.brand,
    required this.ingredients,
    this.mayContainItems = const [],
    required this.detectedAllergens,
    required this.crossContaminationWarnings,
    required this.processingFacilityWarnings,
    required this.safetyAssessment,
    required this.scanDate,
    required this.isSafe,
    this.image,
    required this.dataSource,
    required this.analysisMethod,
    required this.confidenceScore,
    required this.riskLevel,
    required this.processingTimeMs,
    required this.allergenAnalysis,
    required this.crossContaminationRisk,
  });

  factory EnhancedScanResult.fromJson(Map<String, dynamic> json) {
    return EnhancedScanResult(
      barcode: json['barcode'],
      productName: json['productName'],
      brand: json['brand'],
      ingredients: List<String>.from(json['ingredients']),
      mayContainItems: List<String>.from(json['mayContainItems'] ?? []),
      detectedAllergens: List<Map<String, dynamic>>.from(json['detectedAllergens']),
      crossContaminationWarnings: List<Map<String, dynamic>>.from(json['crossContaminationWarnings']),
      processingFacilityWarnings: List<Map<String, dynamic>>.from(json['processingFacilityWarnings']),
      safetyAssessment: Map<String, dynamic>.from(json['safetyAssessment']),
      scanDate: DateTime.parse(json['scanDate']),
      isSafe: json['isSafe'],
      image: json['image'],
      dataSource: json['dataSource'],
      analysisMethod: json['analysisMethod'],
      confidenceScore: json['confidenceScore']?.toDouble() ?? 0.0,
      riskLevel: json['riskLevel'],
      processingTimeMs: json['processingTimeMs'] ?? 0,
      allergenAnalysis: Map<String, dynamic>.from(json['allergenAnalysis']),
      crossContaminationRisk: Map<String, dynamic>.from(json['crossContaminationRisk']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'barcode': barcode,
      'productName': productName,
      'brand': brand,
      'ingredients': ingredients,
      'mayContainItems': mayContainItems,
      'detectedAllergens': detectedAllergens,
      'crossContaminationWarnings': crossContaminationWarnings,
      'processingFacilityWarnings': processingFacilityWarnings,
      'safetyAssessment': safetyAssessment,
      'scanDate': scanDate.toIso8601String(),
      'isSafe': isSafe,
      'image': image,
      'dataSource': dataSource,
      'analysisMethod': analysisMethod,
      'confidenceScore': confidenceScore,
      'riskLevel': riskLevel,
      'processingTimeMs': processingTimeMs,
      'allergenAnalysis': allergenAnalysis,
      'crossContaminationRisk': crossContaminationRisk,
    };
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }

  factory EnhancedScanResult.fromJsonString(String jsonString) {
    return EnhancedScanResult.fromJson(jsonDecode(jsonString));
  }

  /// Get summary of detected allergens
  String get allergenSummary {
    if (detectedAllergens.isEmpty) {
      return 'No allergens detected';
    }
    
    final allergenNames = detectedAllergens
        .map((allergen) => allergen['name'] as String)
        .toSet()
        .toList();
    
    return 'Detected: ${allergenNames.join(', ')}';
  }

  /// Get summary of warnings
  String get warningsSummary {
    final warnings = <String>[];
    
    if (crossContaminationWarnings.isNotEmpty) {
      warnings.add('${crossContaminationWarnings.length} cross-contamination warnings');
    }
    
    if (processingFacilityWarnings.isNotEmpty) {
      warnings.add('${processingFacilityWarnings.length} processing facility warnings');
    }
    
    if (warnings.isEmpty) {
      return 'No warnings';
    }
    
    return warnings.join(', ');
  }

  /// Get safety recommendation
  String get safetyRecommendation {
    final safetyLevel = safetyAssessment['safetyLevel'] as String? ?? 'unknown';
    final recommendations = safetyAssessment['recommendations'] as List<dynamic>? ?? [];
    
    if (recommendations.isNotEmpty) {
      return recommendations.first as String;
    }
    
    switch (safetyLevel) {
      case 'safe':
        return 'Product appears safe for your allergies';
      case 'caution':
        return 'Exercise caution - consult with healthcare provider';
      case 'unsafe':
        return 'AVOID - contains allergens that may affect you';
      default:
        return 'Unable to determine safety - consult with healthcare provider';
    }
  }

  /// Get risk level color
  String get riskLevelColor {
    switch (riskLevel.toLowerCase()) {
      case 'high':
        return '#FF0000'; // Red
      case 'medium':
        return '#FFA500'; // Orange
      case 'low':
        return '#FFFF00'; // Yellow
      default:
        return '#00FF00'; // Green
    }
  }

  /// Get confidence level description
  String get confidenceDescription {
    if (confidenceScore >= 0.9) {
      return 'Very High Confidence';
    } else if (confidenceScore >= 0.7) {
      return 'High Confidence';
    } else if (confidenceScore >= 0.5) {
      return 'Medium Confidence';
    } else if (confidenceScore >= 0.3) {
      return 'Low Confidence';
    } else {
      return 'Very Low Confidence';
    }
  }

  /// Check if product has high-risk allergens
  bool get hasHighRiskAllergens {
    return detectedAllergens.any((allergen) {
      final severity = allergen['severity'] as String? ?? 'medium';
      final confidence = allergen['confidence'] as double? ?? 0.0;
      return severity == 'high' && confidence > 0.8;
    });
  }

  /// Check if product has cross-contamination risks
  bool get hasCrossContaminationRisks {
    return crossContaminationWarnings.isNotEmpty || processingFacilityWarnings.isNotEmpty;
  }

  /// Get detailed allergen information
  List<Map<String, dynamic>> get detailedAllergenInfo {
    return detectedAllergens.map((allergen) {
      return {
        'name': allergen['name'],
        'severity': allergen['severity'],
        'category': allergen['category'],
        'matchedIngredient': allergen['matchedIngredient'],
        'detectionMethod': allergen['detectionMethod'],
        'confidence': allergen['confidence'],
        'riskLevel': allergen['riskLevel'],
        'evidence': allergen['evidence'] as List<dynamic>? ?? [],
      };
    }).toList();
  }

  /// Get cross-contamination details
  List<Map<String, dynamic>> get crossContaminationDetails {
    final details = <Map<String, dynamic>>[];
    
    for (final warning in crossContaminationWarnings) {
      details.add({
        'allergen': warning['allergen'],
        'category': warning['category'],
        'riskLevel': warning['riskLevel'],
        'message': warning['message'],
        'type': warning['type'],
        'severity': warning['severity'],
      });
    }
    
    for (final warning in processingFacilityWarnings) {
      details.add({
        'allergen': warning['allergen'],
        'category': warning['category'],
        'riskLevel': warning['riskLevel'],
        'message': warning['message'],
        'type': warning['type'],
        'severity': warning['severity'],
        'facilityInfo': warning['facilityInfo'],
      });
    }
    
    return details;
  }

  /// Get processing time in readable format
  String get processingTimeDescription {
    if (processingTimeMs < 1000) {
      return '${processingTimeMs}ms';
    } else {
      return '${(processingTimeMs / 1000).toStringAsFixed(1)}s';
    }
  }

  /// Get data source description
  String get dataSourceDescription {
    switch (dataSource.toLowerCase()) {
      case 'open food facts':
        return 'Global food database';
      case 'local database':
        return 'Local product database';
      case 'offline database':
        return 'Offline cached database';
      case 'memory cache':
        return 'Recently scanned product';
      default:
        return 'Unknown source';
    }
  }

  /// Check if result is from cache
  bool get isFromCache {
    return dataSource.toLowerCase().contains('cache');
  }

  /// Get cache age if applicable
  String? get cacheAge {
    if (!isFromCache) return null;
    
    final cacheAgeHours = allergenAnalysis['cache_age'] as int?;
    if (cacheAgeHours == null) return null;
    
    if (cacheAgeHours < 1) {
      return 'Just scanned';
    } else if (cacheAgeHours < 24) {
      return '${cacheAgeHours}h ago';
    } else {
      final days = cacheAgeHours ~/ 24;
      return '${days}d ago';
    }
  }

  /// Get comprehensive safety report
  Map<String, dynamic> get safetyReport {
    return {
      'overallSafety': isSafe,
      'safetyLevel': safetyAssessment['safetyLevel'],
      'riskLevel': riskLevel,
      'riskScore': safetyAssessment['riskScore'],
      'confidenceScore': confidenceScore,
      'detectedAllergensCount': detectedAllergens.length,
      'crossContaminationWarningsCount': crossContaminationWarnings.length,
      'processingFacilityWarningsCount': processingFacilityWarnings.length,
      'recommendations': safetyAssessment['recommendations'],
      'warnings': safetyAssessment['warnings'],
      'allergenSummary': allergenSummary,
      'warningsSummary': warningsSummary,
      'safetyRecommendation': safetyRecommendation,
      'hasHighRiskAllergens': hasHighRiskAllergens,
      'hasCrossContaminationRisks': hasCrossContaminationRisks,
      'analysisMethod': analysisMethod,
      'dataSource': dataSource,
      'processingTime': processingTimeDescription,
      'scanDate': scanDate.toIso8601String(),
    };
  }

  /// Create a simplified version for basic display
  Map<String, dynamic> get simplifiedResult {
    return {
      'barcode': barcode,
      'productName': productName,
      'brand': brand,
      'isSafe': isSafe,
      'riskLevel': riskLevel,
      'allergenSummary': allergenSummary,
      'safetyRecommendation': safetyRecommendation,
      'scanDate': scanDate.toIso8601String(),
    };
  }

  /// Compare with another scan result
  Map<String, dynamic> compareWith(EnhancedScanResult other) {
    final differences = <String, dynamic>{};
    
    // Compare basic information
    if (productName != other.productName) {
      differences['productName'] = {
        'current': productName,
        'other': other.productName,
      };
    }
    
    if (brand != other.brand) {
      differences['brand'] = {
        'current': brand,
        'other': other.brand,
      };
    }
    
    // Compare allergen detection
    final currentAllergens = detectedAllergens.map((a) => a['name']).toSet();
    final otherAllergens = other.detectedAllergens.map((a) => a['name']).toSet();
    
    final newAllergens = otherAllergens.difference(currentAllergens);
    final removedAllergens = currentAllergens.difference(otherAllergens);
    
    if (newAllergens.isNotEmpty) {
      differences['newAllergens'] = newAllergens.toList();
    }
    
    if (removedAllergens.isNotEmpty) {
      differences['removedAllergens'] = removedAllergens.toList();
    }
    
    // Compare safety assessment
    if (isSafe != other.isSafe) {
      differences['safetyChanged'] = {
        'from': isSafe,
        'to': other.isSafe,
      };
    }
    
    if (riskLevel != other.riskLevel) {
      differences['riskLevelChanged'] = {
        'from': riskLevel,
        'to': other.riskLevel,
      };
    }
    
    differences['hasChanges'] = differences.isNotEmpty;
    differences['comparisonDate'] = DateTime.now().toIso8601String();
    
    return differences;
  }
} 