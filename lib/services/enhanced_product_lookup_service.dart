import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'open_food_facts_service.dart';
import 'product_database_service.dart';
import 'enhanced_allergen_service.dart';

class EnhancedProductLookupService {
  static const bool _enableOnlineLookup = true;
  static const bool _enableLocalFallback = true;
  static const bool _enableCaching = true;
  static const bool _enableOfflineMode = true;

  
  // Cache configuration
  static const int _maxCacheSize = 500;
  static const Duration _cacheExpiry = Duration(days: 30);

  
  // Cache storage
  static final Map<String, Map<String, dynamic>> _memoryCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  
  // Offline database
  static Map<String, Map<String, dynamic>>? _offlineDatabase;
  static DateTime? _lastOfflineUpdate;

  /// Initialize the enhanced lookup service
  static Future<void> initialize() async {
    if (_enableCaching) {
      await _loadCacheFromStorage();
    }
    
    if (_enableOfflineMode) {
      await _loadOfflineDatabase();
    }
    
    if (kDebugMode) {
      print('EnhancedProductLookup: Service initialized');
      print('EnhancedProductLookup: Cache size: ${_memoryCache.length}');
      print('EnhancedProductLookup: Offline database size: ${_offlineDatabase?.length ?? 0}');
    }
  }

  /// Get product information with enhanced fallback system
  static Future<Map<String, dynamic>?> getProduct(String barcode) async {
    Map<String, dynamic>? product;
    String source = '';
    List<String> lookupSteps = [];

    // Step 1: Check memory cache
    if (_enableCaching && _memoryCache.containsKey(barcode)) {
      final cachedProduct = _memoryCache[barcode]!;
      final timestamp = _cacheTimestamps[barcode]!;
      
      if (DateTime.now().difference(timestamp) < _cacheExpiry) {
        if (kDebugMode) {
          print('EnhancedProductLookup: Found product in memory cache: $barcode');
        }
        return {
          ...cachedProduct,
          'data_source': 'Memory Cache',
          'lookup_timestamp': DateTime.now().toIso8601String(),
          'cache_age': DateTime.now().difference(timestamp).inHours,
        };
      } else {
        // Remove expired cache entry
        _memoryCache.remove(barcode);
        _cacheTimestamps.remove(barcode);
      }
    }

    // Step 2: Try Open Food Facts API (online)
    if (_enableOnlineLookup) {
      try {
        lookupSteps.add('Open Food Facts API');
        if (kDebugMode) {
          print('EnhancedProductLookup: Trying Open Food Facts API for barcode $barcode');
        }
        
        product = await OpenFoodFactsService.getProduct(barcode);
        if (product != null) {
          source = 'Open Food Facts';
          lookupSteps.add('Success');
          if (kDebugMode) {
            print('EnhancedProductLookup: Found product in Open Food Facts: ${product['name']}');
          }
        } else {
          lookupSteps.add('Not found');
        }
      } catch (e) {
        lookupSteps.add('Error: $e');
        if (kDebugMode) {
          print('EnhancedProductLookup: Open Food Facts API error: $e');
        }
      }
    }

    // Step 3: Fallback to local database
    if (product == null && _enableLocalFallback) {
      try {
        lookupSteps.add('Local Database');
        if (kDebugMode) {
          print('EnhancedProductLookup: Trying local database for barcode $barcode');
        }
        
        product = await ProductDatabaseService.getProductByBarcode(barcode);
        if (product != null) {
          source = 'Local Database';
          lookupSteps.add('Success');
          if (kDebugMode) {
            print('EnhancedProductLookup: Found product in local database: ${product['name']}');
          }
        } else {
          lookupSteps.add('Not found');
        }
      } catch (e) {
        lookupSteps.add('Error: $e');
        if (kDebugMode) {
          print('EnhancedProductLookup: Local database error: $e');
        }
      }
    }

    // Step 4: Fallback to offline database
    if (product == null && _enableOfflineMode && _offlineDatabase != null) {
      try {
        lookupSteps.add('Offline Database');
        if (kDebugMode) {
          print('EnhancedProductLookup: Trying offline database for barcode $barcode');
        }
        
        product = _offlineDatabase![barcode];
        if (product != null) {
          source = 'Offline Database';
          lookupSteps.add('Success');
          if (kDebugMode) {
            print('EnhancedProductLookup: Found product in offline database: ${product['name']}');
          }
        } else {
          lookupSteps.add('Not found');
        }
      } catch (e) {
        lookupSteps.add('Error: $e');
        if (kDebugMode) {
          print('EnhancedProductLookup: Offline database error: $e');
        }
      }
    }

    // Add metadata to product
    if (product != null) {
      product['data_source'] = source;
      product['lookup_timestamp'] = DateTime.now().toIso8601String();
      product['lookup_steps'] = lookupSteps;
      product['cache_recommended'] = _shouldCacheProduct(product);
      
      // Cache the result
      if (_enableCaching && _shouldCacheProduct(product)) {
        await _addToCache(barcode, product);
      }
    } else {
      if (kDebugMode) {
        print('EnhancedProductLookup: Product not found in any database for barcode $barcode');
        print('EnhancedProductLookup: Lookup steps: $lookupSteps');
      }
    }

    return product;
  }

  /// Get enhanced scan result with ML-based allergen analysis
  static Future<Map<String, dynamic>> getEnhancedScanResult(
    String barcode,
    List<Map<String, dynamic>> userAllergies,
  ) async {
    final startTime = DateTime.now();
    final product = await getProduct(barcode);
    
    if (product == null) {
      return {
        'success': false,
        'message': 'Product not found in any database',
        'barcode': barcode,
        'data_source': 'None',
        'lookup_timestamp': DateTime.now().toIso8601String(),
        'processing_time_ms': DateTime.now().difference(startTime).inMilliseconds,
      };
    }

    // Enhanced allergen analysis with ML
    final allergenAnalysis = EnhancedAllergenService.detectAllergensWithML(
      List<String>.from(product['ingredients'] ?? []),
      userAllergies,
      product,
    );

    // Cross-contamination risk assessment
    final crossContaminationRisk = ProductDatabaseService.getCrossContaminationRisk(barcode);

    // Product safety assessment
    final safetyAssessment = _assessProductSafety(
      allergenAnalysis,
      crossContaminationRisk,
      userAllergies,
    );

    final result = {
      'success': true,
      'product': product,
      'allergenAnalysis': allergenAnalysis,
      'crossContaminationRisk': crossContaminationRisk,
      'safetyAssessment': safetyAssessment,
      'barcode': barcode,
      'scanDate': DateTime.now().toIso8601String(),
      'isSafe': safetyAssessment['overallSafety'],
      'data_source': product['data_source'],
      'lookup_timestamp': product['lookup_timestamp'],
      'processing_time_ms': DateTime.now().difference(startTime).inMilliseconds,
      'analysis_method': 'Enhanced ML-based allergen detection',
      'confidence_score': allergenAnalysis['confidence'],
      'risk_level': allergenAnalysis['riskLevel'],
    };

    // Log analytics
    await _logScanAnalytics(result);

    return result;
  }

  /// Assess overall product safety
  static Map<String, dynamic> _assessProductSafety(
    Map<String, dynamic> allergenAnalysis,
    Map<String, dynamic> crossContaminationRisk,
    List<Map<String, dynamic>> userAllergies,
  ) {
    final detectedAllergens = allergenAnalysis['detectedAllergens'] as List<dynamic>;
    final crossContaminationWarnings = allergenAnalysis['crossContaminationWarnings'] as List<dynamic>;
    final processingFacilityWarnings = allergenAnalysis['processingFacilityWarnings'] as List<dynamic>;
    
    bool overallSafety = detectedAllergens.isEmpty;
    String safetyLevel = 'safe';
    List<String> warnings = [];
    List<String> recommendations = [];

    // Direct allergen detection
    if (detectedAllergens.isNotEmpty) {
      overallSafety = false;
      safetyLevel = 'unsafe';
      warnings.add('Direct allergen detection: ${detectedAllergens.length} allergens found');
      
      for (final allergen in detectedAllergens) {
        final name = allergen['name'] as String;
        final severity = allergen['severity'] as String;
        final confidence = allergen['confidence'] as double;
        
        if (severity == 'high' && confidence > 0.8) {
          recommendations.add('AVOID: High confidence detection of $name');
        } else if (severity == 'medium' && confidence > 0.6) {
          recommendations.add('CAUTION: Medium confidence detection of $name');
        } else {
          recommendations.add('CONSULT: Low confidence detection of $name');
        }
      }
    }

    // Cross-contamination warnings
    if (crossContaminationWarnings.isNotEmpty) {
      if (overallSafety) {
        safetyLevel = 'caution';
      }
      warnings.add('Cross-contamination warnings: ${crossContaminationWarnings.length} warnings');
      
      for (final warning in crossContaminationWarnings) {
        final riskLevel = warning['riskLevel'] as String;
        final allergen = warning['allergen'] as String;
        
        if (riskLevel == 'high') {
          recommendations.add('AVOID: High cross-contamination risk for $allergen');
        } else if (riskLevel == 'medium') {
          recommendations.add('CAUTION: Medium cross-contamination risk for $allergen');
        } else {
          recommendations.add('CONSULT: Low cross-contamination risk for $allergen');
        }
      }
    }

    // Processing facility warnings
    if (processingFacilityWarnings.isNotEmpty) {
      if (overallSafety) {
        safetyLevel = 'caution';
      }
      warnings.add('Processing facility warnings: ${processingFacilityWarnings.length} warnings');
      
      for (final warning in processingFacilityWarnings) {
        final allergen = warning['allergen'] as String;
        recommendations.add('CONSULT: Processing facility handles $allergen');
      }
    }

    // Risk level assessment
    final riskScore = allergenAnalysis['riskScore'] as double? ?? 0.0;
    String riskLevel = 'low';
    
    if (riskScore >= 0.8) {
      riskLevel = 'high';
    } else if (riskScore >= 0.5) {
      riskLevel = 'medium';
    }

    return {
      'overallSafety': overallSafety,
      'safetyLevel': safetyLevel,
      'riskLevel': riskLevel,
      'riskScore': riskScore,
      'warnings': warnings,
      'recommendations': recommendations,
      'detectedAllergensCount': detectedAllergens.length,
      'crossContaminationWarningsCount': crossContaminationWarnings.length,
      'processingFacilityWarningsCount': processingFacilityWarnings.length,
      'assessmentTimestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Search for products with enhanced capabilities
  static Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    final results = <Map<String, dynamic>>[];
    
    // Search in local database
    final localResults = ProductDatabaseService.searchProducts(query);
    results.addAll(localResults);
    
    // Search in offline database
    if (_offlineDatabase != null) {
      final offlineResults = _searchOfflineDatabase(query);
      results.addAll(offlineResults);
    }
    
    // Search online if enabled
    if (_enableOnlineLookup) {
      try {
        final onlineResults = await OpenFoodFactsService.searchProducts(query);
        results.addAll(onlineResults);
      } catch (e) {
        if (kDebugMode) {
          print('EnhancedProductLookup: Online search error: $e');
        }
      }
    }
    
    // Remove duplicates and sort by relevance
    final uniqueResults = _removeDuplicates(results);
    final sortedResults = _sortByRelevance(uniqueResults, query);
    
    return sortedResults.take(20).toList(); // Limit to top 20 results
  }

  /// Add product to cache
  static Future<void> _addToCache(String barcode, Map<String, dynamic> product) async {
    if (_memoryCache.length >= _maxCacheSize) {
      // Remove oldest entry
      final oldestKey = _cacheTimestamps.entries
          .reduce((a, b) => a.value.isBefore(b.value) ? a : b)
          .key;
      _memoryCache.remove(oldestKey);
      _cacheTimestamps.remove(oldestKey);
    }
    
    _memoryCache[barcode] = product;
    _cacheTimestamps[barcode] = DateTime.now();
    
    // Save to persistent storage
    await _saveCacheToStorage();
  }

  /// Load cache from persistent storage
  static Future<void> _loadCacheFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = prefs.getString('enhanced_product_cache');
      final timestampData = prefs.getString('enhanced_product_cache_timestamps');
      
      if (cacheData != null && timestampData != null) {
        final cacheMap = Map<String, Map<String, dynamic>>.from(
          jsonDecode(cacheData).map((key, value) => MapEntry(key, Map<String, dynamic>.from(value)))
        );
        final timestampMap = Map<String, DateTime>.from(
          jsonDecode(timestampData).map((key, value) => MapEntry(key, DateTime.parse(value)))
        );
        
        // Filter out expired entries
        final now = DateTime.now();
        cacheMap.forEach((key, value) {
          final timestamp = timestampMap[key];
          if (timestamp != null && now.difference(timestamp) < _cacheExpiry) {
            _memoryCache[key] = value;
            _cacheTimestamps[key] = timestamp;
          }
        });
        
        if (kDebugMode) {
          print('EnhancedProductLookup: Loaded ${_memoryCache.length} cached products');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('EnhancedProductLookup: Error loading cache: $e');
      }
    }
  }

  /// Save cache to persistent storage
  static Future<void> _saveCacheToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = jsonEncode(_memoryCache);
      final timestampData = jsonEncode(
        _cacheTimestamps.map((key, value) => MapEntry(key, value.toIso8601String()))
      );
      
      await prefs.setString('enhanced_product_cache', cacheData);
      await prefs.setString('enhanced_product_cache_timestamps', timestampData);
      
      if (kDebugMode) {
        print('EnhancedProductLookup: Saved ${_memoryCache.length} products to cache');
      }
    } catch (e) {
      if (kDebugMode) {
        print('EnhancedProductLookup: Error saving cache: $e');
      }
    }
  }

  /// Load offline database
  static Future<void> _loadOfflineDatabase() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/offline_product_database.json');
      
      if (await file.exists()) {
        final data = await file.readAsString();
        final database = Map<String, Map<String, dynamic>>.from(
          jsonDecode(data).map((key, value) => MapEntry(key, Map<String, dynamic>.from(value)))
        );
        
        _offlineDatabase = database;
        _lastOfflineUpdate = DateTime.now();
        
        if (kDebugMode) {
          print('EnhancedProductLookup: Loaded ${database.length} products to offline database');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('EnhancedProductLookup: Error loading offline database: $e');
      }
    }
  }

  /// Search offline database
  static List<Map<String, dynamic>> _searchOfflineDatabase(String query) {
    if (_offlineDatabase == null) return [];
    
    final results = <Map<String, dynamic>>[];
    final lowerQuery = query.toLowerCase();
    
    for (String barcode in _offlineDatabase!.keys) {
      final product = _offlineDatabase![barcode]!;
      final name = product['name'].toString().toLowerCase();
      final brand = product['brand'].toString().toLowerCase();
      
      if (name.contains(lowerQuery) || brand.contains(lowerQuery)) {
        results.add({
          'barcode': barcode,
          ...product,
          'data_source': 'Offline Database',
        });
      }
    }
    
    return results;
  }

  /// Remove duplicate products from search results
  static List<Map<String, dynamic>> _removeDuplicates(List<Map<String, dynamic>> results) {
    final seen = <String>{};
    final unique = <Map<String, dynamic>>[];
    
    for (final result in results) {
      final barcode = result['barcode'] as String? ?? '';
      if (!seen.contains(barcode)) {
        seen.add(barcode);
        unique.add(result);
      }
    }
    
    return unique;
  }

  /// Sort search results by relevance
  static List<Map<String, dynamic>> _sortByRelevance(
    List<Map<String, dynamic>> results,
    String query,
  ) {
    final lowerQuery = query.toLowerCase();
    
    results.sort((a, b) {
      final aName = a['name'].toString().toLowerCase();
      final bName = b['name'].toString().toLowerCase();
      final aBrand = a['brand'].toString().toLowerCase();
      final bBrand = b['brand'].toString().toLowerCase();
      
      // Exact name match gets highest priority
      if (aName == lowerQuery && bName != lowerQuery) return -1;
      if (bName == lowerQuery && aName != lowerQuery) return 1;
      
      // Name starts with query gets second priority
      if (aName.startsWith(lowerQuery) && !bName.startsWith(lowerQuery)) return -1;
      if (bName.startsWith(lowerQuery) && !aName.startsWith(lowerQuery)) return 1;
      
      // Name contains query gets third priority
      if (aName.contains(lowerQuery) && !bName.contains(lowerQuery)) return -1;
      if (bName.contains(lowerQuery) && !aName.contains(lowerQuery)) return 1;
      
      // Brand match gets fourth priority
      if (aBrand.contains(lowerQuery) && !bBrand.contains(lowerQuery)) return -1;
      if (bBrand.contains(lowerQuery) && !aBrand.contains(lowerQuery)) return 1;
      
      // Alphabetical order for tie-breaking
      return aName.compareTo(bName);
    });
    
    return results;
  }

  /// Determine if product should be cached
  static bool _shouldCacheProduct(Map<String, dynamic> product) {
    // Cache products with complete information
    final hasIngredients = (product['ingredients'] as List<dynamic>?)?.isNotEmpty ?? false;
    final hasName = (product['name'] as String?)?.isNotEmpty ?? false;
    final hasBrand = (product['brand'] as String?)?.isNotEmpty ?? false;
    
    return hasIngredients && hasName && hasBrand;
  }

  /// Log scan analytics
  static Future<void> _logScanAnalytics(Map<String, dynamic> result) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final analytics = prefs.getStringList('scan_analytics') ?? [];
      
      final analyticsEntry = {
        'timestamp': DateTime.now().toIso8601String(),
        'barcode': result['barcode'],
        'product_name': result['product']['name'],
        'data_source': result['data_source'],
        'processing_time_ms': result['processing_time_ms'],
        'is_safe': result['isSafe'],
        'risk_level': result['risk_level'],
        'confidence_score': result['confidence_score'],
        'detected_allergens_count': (result['allergenAnalysis']['detectedAllergens'] as List<dynamic>).length,
      };
      
      analytics.add(jsonEncode(analyticsEntry));
      
      // Keep only last 1000 entries
      if (analytics.length > 1000) {
        analytics.removeRange(0, analytics.length - 1000);
      }
      
      await prefs.setStringList('scan_analytics', analytics);
    } catch (e) {
      if (kDebugMode) {
        print('EnhancedProductLookup: Error logging analytics: $e');
      }
    }
  }

  /// Get cache statistics
  static Map<String, dynamic> getCacheStats() {
    final now = DateTime.now();
    int expiredCount = 0;
    
    for (final timestamp in _cacheTimestamps.values) {
      if (now.difference(timestamp) >= _cacheExpiry) {
        expiredCount++;
      }
    }
    
    return {
      'memory_cache_size': _memoryCache.length,
      'expired_entries': expiredCount,
      'max_cache_size': _maxCacheSize,
      'cache_utilization': _memoryCache.length / _maxCacheSize,
      'offline_database_size': _offlineDatabase?.length ?? 0,
      'last_offline_update': _lastOfflineUpdate?.toIso8601String(),
      'cache_enabled': _enableCaching,
      'offline_mode_enabled': _enableOfflineMode,
      'online_lookup_enabled': _enableOnlineLookup,
    };
  }

  /// Clear cache
  static Future<void> clearCache() async {
    _memoryCache.clear();
    _cacheTimestamps.clear();
    await _saveCacheToStorage();
    
    if (kDebugMode) {
      print('EnhancedProductLookup: Cache cleared');
    }
  }

  /// Update offline database
  static Future<void> updateOfflineDatabase() async {
    try {
      // This would typically download from a server
      // For now, we'll use the local database as the offline source
      final localProducts = ProductDatabaseService.getAllProducts();
      
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/offline_product_database.json');
      
      await file.writeAsString(jsonEncode(localProducts));
      
      _offlineDatabase = localProducts;
      _lastOfflineUpdate = DateTime.now();
      
      if (kDebugMode) {
        print('EnhancedProductLookup: Offline database updated with ${localProducts.length} products');
      }
    } catch (e) {
      if (kDebugMode) {
        print('EnhancedProductLookup: Error updating offline database: $e');
      }
    }
  }
} 