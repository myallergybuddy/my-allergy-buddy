import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'services/product_lookup_service.dart';
import 'services/product_database_service.dart';
import 'services/firebase_service.dart';
import 'services/revenue_cat_service.dart';
import 'services/australian_food_database_service.dart';
import 'services/spoonacular_service.dart';
import 'services/ocr_service.dart';
import 'models/enhanced_scan_result.dart';
import 'widgets/premium_upgrade_widget.dart';
import 'package:permission_handler/permission_handler.dart';

class ScanLabelScreen extends StatefulWidget {
  const ScanLabelScreen({super.key});

  @override
  State<ScanLabelScreen> createState() => _ScanLabelScreenState();
}

class _ScanLabelScreenState extends State<ScanLabelScreen> with SingleTickerProviderStateMixin {
  String barcodeText = 'No barcode scanned yet';
  bool _isPremium = false;
  bool isScanning = true;
  bool showResults = false;
  bool isFlashOn = false;
  bool isLoading = false;
  bool hasCameraPermission = false;
  bool isCameraInitialized = false;
  String scannerStatus = 'Checking camera permissions...';
  String? cameraError;
  late AnimationController _animationController;
  late Animation<double> _scanAnimation;
  final TextEditingController _manualBarcodeController = TextEditingController();
  
  // Enhanced scan result data
  EnhancedScanResult? scanResult;
  List<Map<String, dynamic>> userAllergies = [];
  
  // Photo scan integration
  bool _showPhotoScanOptions = false;
  File? _selectedImage;

  late final MobileScannerController _scannerController;

  String _extractedText = '';
  List<String> _extractedIngredients = [];
  List<Map<String, dynamic>> _photoDetectedAllergens = [];

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      formats: const [
        BarcodeFormat.ean13,
        BarcodeFormat.ean8,
        BarcodeFormat.upcA,
        BarcodeFormat.upcE,
        BarcodeFormat.code128,
        BarcodeFormat.code39,
        BarcodeFormat.qrCode,
      ],
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _scanAnimation = Tween<double>(begin: 0, end: 1).animate(_animationController);
    _loadUserAllergies();
    _loadPremiumStatus();
    _initializeEnhancedServices();
    _checkCameraPermissions();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _manualBarcodeController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _initializeEnhancedServices() async {
    // Initialize Spoonacular service
    await SpoonacularService.initializeApiKey();
    
    // Using ProductLookupService instead of EnhancedProductLookupService
    if (kDebugMode) {
      print('ScanLabelScreen: Product lookup services initialized');
      print('ScanLabelScreen: Spoonacular API configured: ${SpoonacularService.isApiKeyConfigured()}');
    }
  }

  Future<void> _loadUserAllergies() async {
    final prefs = await SharedPreferences.getInstance();
    final allergiesJson = prefs.getStringList('saved_allergies') ?? [];
    setState(() {
      userAllergies = allergiesJson
          .map((json) => Map<String, dynamic>.from(jsonDecode(json)))
          .toList();
    });
    
    if (kDebugMode) {
      print('ScanLabelScreen: Loaded ${userAllergies.length} user allergies');
      for (var allergy in userAllergies) {
        print('ScanLabelScreen: Allergy - ${allergy['name']} (${allergy['severity']})');
      }
      
      // If no allergies are set up, show a warning
      if (userAllergies.isEmpty) {
        print('ScanLabelScreen: WARNING - No user allergies found! Allergen detection will not work.');
        print('ScanLabelScreen: User needs to set up allergies in the app settings.');
      }
    }
  }

  Future<void> _loadPremiumStatus() async {
    final isPremium = await RevenueCatService.hasPremiumAccess();
    setState(() {
      _isPremium = isPremium;
    });
  }

  Future<void> _checkCameraPermissions() async {
    if (kDebugMode) {
      print('ScanLabelScreen: Checking camera permissions...');
    }
    
    try {
      final status = await Permission.camera.status;
      if (kDebugMode) {
        print('ScanLabelScreen: Camera permission status: $status');
      }
      
      if (status.isGranted) {
        setState(() {
          hasCameraPermission = true;
          scannerStatus = 'Camera ready';
          isCameraInitialized = true;
        });
        if (kDebugMode) {
          print('ScanLabelScreen: Camera permission granted');
        }
      } else if (status.isDenied) {
        final result = await Permission.camera.request();
        if (result.isGranted) {
          setState(() {
            hasCameraPermission = true;
            scannerStatus = 'Camera ready';
            isCameraInitialized = true;
          });
          if (kDebugMode) {
            print('ScanLabelScreen: Camera permission granted after request');
          }
        } else {
          setState(() {
            hasCameraPermission = false;
            scannerStatus = 'Camera permission denied';
            cameraError = 'Camera access is required for scanning';
          });
          if (kDebugMode) {
            print('ScanLabelScreen: Camera permission denied');
          }
        }
      } else {
        setState(() {
          hasCameraPermission = false;
          scannerStatus = 'Camera permission permanently denied';
          cameraError = 'Please enable camera access in app settings';
        });
        if (kDebugMode) {
          print('ScanLabelScreen: Camera permission permanently denied');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('ScanLabelScreen: Error checking camera permissions: $e');
      }
      setState(() {
        hasCameraPermission = false;
        scannerStatus = 'Camera error';
        cameraError = 'Failed to access camera: $e';
      });
    }
  }

  void _onDetect(BarcodeCapture capture) async {
    if (!isScanning || isLoading) return;

    if (kDebugMode) {
      print('Scanner: _onDetect called');
      print('Scanner: Capture barcodes count: ${capture.barcodes.length}');
      print('Scanner: Current scanning state: $isScanning');
      print('Scanner: Current loading state: $isLoading');
    }
    
    if (capture.barcodes.isEmpty) {
      if (kDebugMode) {
        print('Scanner: No barcodes detected in capture');
      }
      return;
    }

    final barcode = capture.barcodes.first;
    final code = barcode.rawValue;
    
    if (kDebugMode) {
      print('Scanner: Detected barcode: $code');
      print('Scanner: Barcode format: ${barcode.format}');
      print('Scanner: Barcode type: ${barcode.type}');
    }
    
    if (code != null && code.isNotEmpty) {
      if (kDebugMode) {
        print('Scanner: Processing barcode: $code');
      }
      await _processBarcode(code);
    } else {
      if (kDebugMode) {
        print('Scanner: Barcode code is null or empty');
      }
    }
  }

  Future<void> _processBarcode(String barcode) async {
    if (kDebugMode) {
      print('ScanLabelScreen: _processBarcode called with barcode: $barcode');
      print('ScanLabelScreen: User allergies count: ${userAllergies.length}');
      print('ScanLabelScreen: Current state - isLoading: $isLoading, isScanning: $isScanning, showResults: $showResults');
    }
    
    setState(() {
      isLoading = true;
      isScanning = false;
      showResults = false;
    });

    if (kDebugMode) {
      print('ScanLabelScreen: State updated - isLoading: $isLoading, isScanning: $isScanning, showResults: $showResults');
    }

    try {
      if (kDebugMode) {
        print('ScanLabelScreen: About to call ProductLookupService.getScanResult');
        print('ScanLabelScreen: Barcode: $barcode');
        print('ScanLabelScreen: User allergies: $userAllergies');
      }
      // Get scan result with allergen analysis
      final result = await ProductLookupService.analyzeProduct(barcode, userAllergies);
      
      // Also check Australian Food Database for additional information
      Map<String, dynamic>? australianData;
      Map<String, dynamic>? spoonacularData;
      
      try {
        australianData = await AustralianFoodDatabaseService.getProductByBarcodeWithAutoDownload(barcode);
        if (australianData != null) {
          if (kDebugMode) {
            print('ScanLabelScreen: Found product in Australian database');
          }
        } else {
          if (kDebugMode) {
            print('ScanLabelScreen: Product not found in Australian database');
          }
          
          // Check if product exists in Open Food Facts but isn't Australian
          try {
            final openFoodFactsCheck = await AustralianFoodDatabaseService.checkProductExistsInOpenFoodFacts(barcode);
            if (openFoodFactsCheck['exists'] == true) {
              if (kDebugMode) {
                print('ScanLabelScreen: Product exists in Open Food Facts: ${openFoodFactsCheck['message']}');
              }
              // Store this information for potential user feedback
              if (openFoodFactsCheck['isAustralian'] == false) {
                if (kDebugMode) {
                  print('ScanLabelScreen: Product found but not identified as Australian: ${openFoodFactsCheck['productName']}');
                }
              }
            } else {
              if (kDebugMode) {
                print('ScanLabelScreen: Product not found in Open Food Facts: ${openFoodFactsCheck['message']}');
              }
            }
          } catch (e) {
            if (kDebugMode) {
              print('ScanLabelScreen: Error checking Open Food Facts: $e');
            }
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('ScanLabelScreen: Error checking Australian database: $e');
        }
      }
      
      // Check Spoonacular API for additional product information
      if (SpoonacularService.isApiKeyConfigured()) {
        try {
          spoonacularData = await SpoonacularService.getProductByUPC(barcode);
          if (spoonacularData != null) {
            if (kDebugMode) {
              print('ScanLabelScreen: Found product in Spoonacular database: ${spoonacularData['name']}');
            }
          } else {
            if (kDebugMode) {
              print('ScanLabelScreen: Product not found in Spoonacular database');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('ScanLabelScreen: Error checking Spoonacular database: $e');
          }
        }
      } else {
        if (kDebugMode) {
          print('ScanLabelScreen: Spoonacular API key not configured');
        }
      }
      
      if (kDebugMode) {
        print('ScanLabelScreen: ProductLookupService result received');
        print('ScanLabelScreen: Result success: ${result['success']}');
        print('ScanLabelScreen: Result message: ${result['message']}');
        print('ScanLabelScreen: Result data source: ${result['data_source']}');
        if (result['success']) {
          print('ScanLabelScreen: Product name: ${result['product']['name']}');
          print('ScanLabelScreen: Product brand: ${result['product']['brand']}');
          print('ScanLabelScreen: Ingredients count: ${result['product']['ingredients']?.length ?? 0}');
          print('ScanLabelScreen: Detected allergens count: ${result['detectedAllergens']?.length ?? 0}');
        }
      }
      
      if (result['success']) {
        // Enhance with Australian database and Spoonacular data if available
        List<Map<String, dynamic>> enhancedAllergens = List<Map<String, dynamic>>.from(result['detectedAllergens']);
        List<Map<String, dynamic>> crossContaminationWarnings = [];
        List<Map<String, dynamic>> processingFacilityWarnings = [];
        var dataSource = result['data_source']?.toString() ?? 'Unknown';
        List<String> additionalIngredients = [];
        
        // Only show allergens that match the user's allergy profile.
        final userAllergyNames = userAllergies
            .map((a) => a['name']?.toString().toLowerCase() ?? '')
            .where((name) => name.isNotEmpty)
            .toSet();
        enhancedAllergens = enhancedAllergens
            .where((allergen) =>
                userAllergyNames.contains(allergen['name']?.toString().toLowerCase()))
            .toList();
        
        // Add cross-contamination warnings from ProductLookupService result
        final productLookupCrossContamination = result['crossContaminationWarnings'] as List<dynamic>? ?? [];
        if (kDebugMode) {
          print('ScanLabelScreen: ProductLookupService cross-contamination warnings count: ${productLookupCrossContamination.length}');
          print('ScanLabelScreen: ProductLookupService cross-contamination warnings raw data: $productLookupCrossContamination');
          for (var warning in productLookupCrossContamination) {
            print('ScanLabelScreen: ProductLookupService warning: ${warning['allergen']} - ${warning['message']}');
          }
        }
        crossContaminationWarnings.addAll(productLookupCrossContamination.map((w) => Map<String, dynamic>.from(w)));
        
        if (kDebugMode) {
          print('ScanLabelScreen: After adding ProductLookupService warnings, total cross-contamination warnings: ${crossContaminationWarnings.length}');
        }
        
        // Add processing facility warnings from ProductLookupService result
        final productLookupProcessingFacility = result['processingFacilityWarnings'] as List<dynamic>? ?? [];
        processingFacilityWarnings.addAll(productLookupProcessingFacility.map((w) => Map<String, dynamic>.from(w)));
        
        if (spoonacularData != null) {
          // Add Spoonacular allergens
          final spoonacularAllergens = spoonacularData['allergens'] as List<dynamic>? ?? [];
          for (var allergen in spoonacularAllergens) {
            if (!enhancedAllergens.any((a) => a['name'] == allergen)) {
              enhancedAllergens.add({
                'name': allergen,
                'severity': 'medium',
                'confidence': 0.85,
                'matchedIngredient': allergen,
                'source': 'Spoonacular'
              });
            }
          }
          
          // Add Spoonacular ingredients if not already present
          final spoonacularIngredients = spoonacularData['ingredients'] as List<dynamic>? ?? [];
          additionalIngredients.addAll(spoonacularIngredients.map((i) => i.toString()));
          
          // Update data source to include Spoonacular
          if (dataSource.contains('Spoonacular')) {
            dataSource = dataSource;
          } else {
            dataSource = '$dataSource, Spoonacular';
          }
        }
        
        // Check if ingredients are available
        final baseIngredients = List<String>.from(result['product']['ingredients'] ?? []);
        final allIngredients = [...baseIngredients, ...additionalIngredients];
        final ingredients = allIngredients.toSet().toList(); // Remove duplicates
        final hasIngredients = ingredients.isNotEmpty;
        

        
        // Integrate cross-contamination warnings into detected allergens
        if (kDebugMode) {
          print('ScanLabelScreen: Cross-contamination warnings count: ${crossContaminationWarnings.length}');
          print('ScanLabelScreen: Cross-contamination warnings raw data: $crossContaminationWarnings');
          for (var warning in crossContaminationWarnings) {
            print('ScanLabelScreen: Cross-contamination warning: ${warning['allergen']} - ${warning['message']}');
          }
        }
        
        for (var warning in crossContaminationWarnings) {
          final allergenName = warning['allergen'] as String?;
          if (allergenName != null) {
            // Check if this allergen is already in detected allergens
            final existingIndex = enhancedAllergens.indexWhere((a) => a['name'] == allergenName);
            if (existingIndex >= 0) {
              // Check if the existing allergen is from actual ingredients (not already cross-contamination)
              final existingAllergen = enhancedAllergens[existingIndex];
              bool isFromActualIngredients = existingAllergen['detectionMethod'] == 'Direct ingredient match' || 
                                           existingAllergen['detectionMethod'] == 'Actual ingredient match';
              
              if (isFromActualIngredients) {
                // Don't overwrite definite allergens - keep them as definite
                if (kDebugMode) {
                  print('ScanLabelScreen: Keeping existing definite allergen $allergenName as definite (not overwriting with cross-contamination)');
                }
              } else {
                // Update existing allergen to mark as cross-contamination only if it's not from actual ingredients
                enhancedAllergens[existingIndex]['isCrossContamination'] = true;
                enhancedAllergens[existingIndex]['crossContaminationWarning'] = warning['message'];
                if (kDebugMode) {
                  print('ScanLabelScreen: Updated existing allergen $allergenName as cross-contamination');
                }
              }
            } else {
              // Add new allergen as cross-contamination
              enhancedAllergens.add({
                'name': allergenName,
                'severity': 'medium',
                'confidence': warning['confidence'] ?? 0.7,
                'matchedIngredient': 'Cross-contamination warning',
                'detectionMethod': 'Cross-contamination analysis',
                'isCrossContamination': true,
                'crossContaminationWarning': warning['message'],
                'riskLevel': warning['riskLevel'] ?? 'Medium',
                'source': 'Australian Food Database'
              });
              if (kDebugMode) {
                print('ScanLabelScreen: ✅ Added new cross-contamination allergen: $allergenName');
                print('ScanLabelScreen: Cross-contamination allergen details: ${enhancedAllergens.last}');
              }
            }
          }
        }
        
        // Adjust confidence and recommendation based on ingredient availability
        String recommendation;
        String confidence;
        double confidenceScore;
        
        if (enhancedAllergens.isNotEmpty) {
          recommendation = 'Avoid this product';
          confidence = 'High';
          confidenceScore = _calculateConfidenceScore(australianData != null, spoonacularData != null, hasIngredients);
        } else if (!hasIngredients) {
          recommendation = 'Ingredients not available - check product label manually';
          confidence = 'Low';
          confidenceScore = 0.3;
        } else {
          recommendation = 'Safe to consume';
          confidence = 'High';
          confidenceScore = _calculateConfidenceScore(australianData != null, spoonacularData != null, hasIngredients);
        }
        
        final productForMayContain = Map<String, dynamic>.from(result['product'] ?? {});
        productForMayContain['crossContaminationWarnings'] = crossContaminationWarnings;
        final mayContainItems = ProductDatabaseService.collectMayContainItems(
          ingredients: ingredients,
          product: productForMayContain,
        );

        final scanResultData = EnhancedScanResult(
          barcode: barcode,
          productName: result['product']['name'],
          brand: result['product']['brand'],
          ingredients: ingredients,
          mayContainItems: mayContainItems,
          detectedAllergens: enhancedAllergens,
          crossContaminationWarnings: crossContaminationWarnings,
          processingFacilityWarnings: processingFacilityWarnings,
          safetyAssessment: {
            'risk_level': enhancedAllergens.isNotEmpty ? 'High' : 'Low',
            'recommendation': recommendation,
            'confidence': confidence,
            'has_ingredients': hasIngredients,
            'ingredient_warning': !hasIngredients ? 'No ingredient information available in database' : null,
          },
          scanDate: DateTime.now(),
          isSafe: result['isSafe'],
          image: result['product']['image'],
          dataSource: dataSource,
          analysisMethod: _getAnalysisMethod(australianData != null, spoonacularData != null),
          confidenceScore: confidenceScore,
          riskLevel: enhancedAllergens.isNotEmpty ? 'High' : 'Low',
          processingTimeMs: 0,
          allergenAnalysis: {
            'detectedAllergens': enhancedAllergens,
            'crossContaminationWarnings': crossContaminationWarnings,
            'processingFacilityWarnings': processingFacilityWarnings,
            'totalIngredients': ingredients.length,
            'analyzedIngredients': ingredients.length,
            'detectionMethod': _getDetectionMethod(australianData != null, spoonacularData != null),
            'lastUpdated': DateTime.now().toIso8601String(),
            'australianDatabaseIncluded': australianData != null,
            'spoonacularIncluded': spoonacularData != null,
          },
          crossContaminationRisk: {
            'risk': crossContaminationWarnings.isNotEmpty ? 'medium' : 'unknown',
            'message': crossContaminationWarnings.isNotEmpty ? 'Cross-contamination warnings detected' : 'No cross-contamination information available',
            'crossContamination': crossContaminationWarnings,
            'processingFacility': processingFacilityWarnings.isNotEmpty ? 'Processing facility information available' : 'No information available'
          },
        );
        
        // Save to scan history
        await _saveToScanHistory(scanResultData);
        
        // Log scan completion analytics
        await FirebaseService.logProductScan(
          productName: scanResultData.productName,
          hasAllergens: scanResultData.detectedAllergens.isNotEmpty,
          detectedAllergens: scanResultData.detectedAllergens
              .map((allergen) => allergen['name'] as String)
              .toList(),
        );
        
        // Log debug information for enhanced results
        if (kDebugMode) {
          print('Enhanced Scan Result Debug Info:');
          print('Product: ${scanResultData.productName}');
          print('Brand: ${scanResultData.brand}');
          print('Ingredients: ${scanResultData.ingredients}');
          print('User Allergies: ${userAllergies.length}');
          print('Detected Allergens: ${scanResultData.detectedAllergens.length}');
          for (var allergen in scanResultData.detectedAllergens) {
            print('  - ${allergen['name']} (${allergen['severity']}) - isCrossContamination: ${allergen['isCrossContamination']}');
          }
          print('Cross-contamination Warnings: ${scanResultData.crossContaminationWarnings.length}');
          print('Processing Facility Warnings: ${scanResultData.processingFacilityWarnings.length}');
          print('Risk Level: ${scanResultData.riskLevel}');
          print('Confidence Score: ${scanResultData.confidenceScore}');
          print('Data Source: ${scanResultData.dataSource}');
          print('Processing Time: ${scanResultData.processingTimeDescription}');
          
          // Debug: Check for cross-contamination allergens in detected allergens
          final crossContaminationAllergens = scanResultData.detectedAllergens.where((a) => a['isCrossContamination'] == true).toList();
          print('Cross-contamination allergens in detected allergens: ${crossContaminationAllergens.length}');
          for (var allergen in crossContaminationAllergens) {
            print('  - ${allergen['name']} (${allergen['detectionMethod']})');
          }
        }
        
        if (kDebugMode) {
          print('ScanLabelScreen: About to update UI with scan result');
          print('ScanLabelScreen: Setting scanResult, barcodeText: $barcode, showResults: true, isLoading: false');
        }
        
        setState(() {
          scanResult = scanResultData;
          barcodeText = barcode;
          showResults = true;
          isLoading = false;
        });
        
        if (kDebugMode) {
          print('ScanLabelScreen: UI updated successfully');
          print('ScanLabelScreen: Final state - showResults: $showResults, isLoading: $isLoading');
        }
        
        // Show warning if no allergies are set up
        if (userAllergies.isEmpty && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'No allergies set up. Go to Settings to configure your allergies for allergen detection.',
                style: GoogleFonts.nunito(),
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Settings',
                textColor: Colors.white,
                onPressed: () => Navigator.pushNamed(context, '/settings'),
              ),
                ),
              );
            }

        // Enhanced custom alerts for premium users (only show for high-risk allergens)
        if (_isPremium && scanResultData.hasHighRiskAllergens) {
            if (mounted) {
            _showHighRiskAlert(scanResultData);
            }
        }
      } else {
        // Log failed scan
        await FirebaseService.logProductScan(
          productName: 'Unknown Product',
          hasAllergens: false,
          detectedAllergens: [],
        );
        
        if (kDebugMode) {
          print('ScanLabelScreen: Product lookup failed - ${result['message']}');
        }
        
        setState(() {
          barcodeText = barcode;
          scanResult = null;
          showResults = true;
          isLoading = false;
        });
        
        // Show error message to user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Product not found. Please check the barcode or try again.',
                style: GoogleFonts.nunito(),
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('ScanLabelScreen: Error processing barcode: $e');
      }
      setState(() {
        barcodeText = barcode;
        scanResult = null;
        showResults = true;
        isLoading = false;
      });
    }
  }

  void _showHighRiskAlert(EnhancedScanResult result) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            const SizedBox(width: 8),
            Text(
              'High Risk Allergen Detected',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
            Text(
              'This product contains allergens that may pose a high risk to your health.',
              style: GoogleFonts.nunito(),
            ),
            const SizedBox(height: 16),
            Text(
              'Detected Allergens:',
              style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
            ),
            ...result.detectedAllergens.map((allergen) => Padding(
              padding: const EdgeInsets.only(left: 16, top: 4),
              child: Text(
                '• ${allergen['name']} (${allergen['severity']} severity)',
                style: GoogleFonts.nunito(color: Colors.red),
              ),
            )),
            const SizedBox(height: 16),
            Text(
              'Recommendation: AVOID this product',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Dismiss'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showDetailedAllergenInfo(result);
            },
            child: const Text('View Details'),
          ),
        ],
      ),
    );
  }



  Widget _buildAllergenResults(EnhancedScanResult result) {
    if (kDebugMode) {
      print('_buildAllergenResults: Starting allergen analysis');
      print('_buildAllergenResults: Total detected allergens: ${result.detectedAllergens.length}');
      print('_buildAllergenResults: User allergies count: ${userAllergies.length}');
      print('_buildAllergenResults: Cross-contamination warnings count: ${result.crossContaminationWarnings.length}');
      print('_buildAllergenResults: Ingredients count: ${result.ingredients.length}');
      
      // Debug: Print all cross-contamination warnings
      print('_buildAllergenResults: All cross-contamination warnings:');
      for (int i = 0; i < result.crossContaminationWarnings.length; i++) {
        var warning = result.crossContaminationWarnings[i];
        print('  Warning $i: $warning');
      }
      
      // Debug: Print all detected allergens with their properties
      print('_buildAllergenResults: All detected allergens:');
      for (int i = 0; i < result.detectedAllergens.length; i++) {
        var allergen = result.detectedAllergens[i];
        print('  Allergen $i: ${allergen['name']} - isCrossContamination: ${allergen['isCrossContamination']} - detectionMethod: ${allergen['detectionMethod']}');
      }
    }

    // Separate all detected allergens into definite and may contain based on isCrossContamination flag
    List<Map<String, dynamic>> definiteAllergens = [];
    List<Map<String, dynamic>> mayContainAllergens = [];
    
    // Process detected allergens
    if (kDebugMode) {
      print('_buildAllergenResults: Processing ${result.detectedAllergens.length} detected allergens');
      print('_buildAllergenResults: User allergies count: ${userAllergies.length}');
      for (var allergy in userAllergies) {
        print('_buildAllergenResults: User allergy: ${allergy['name']}');
      }
      for (var allergen in result.detectedAllergens) {
        print('_buildAllergenResults: Allergen: ${allergen['name']}, isCrossContamination: ${allergen['isCrossContamination']}, detectionMethod: ${allergen['detectionMethod']}');
      }
    }
    
    for (var allergen in result.detectedAllergens) {
      // Handle different data types for isCrossContamination
      bool isCrossContamination = false;
      if (allergen['isCrossContamination'] is bool) {
        isCrossContamination = allergen['isCrossContamination'] as bool;
      } else if (allergen['isCrossContamination'] is String) {
        isCrossContamination = allergen['isCrossContamination'].toString().toLowerCase() == 'true';
      } else if (allergen['isCrossContamination'] != null) {
        isCrossContamination = allergen['isCrossContamination'] == true;
      }
      
      if (kDebugMode) {
        print('_buildAllergenResults: Processing allergen ${allergen['name']} - isCrossContamination: $isCrossContamination (raw value: ${allergen['isCrossContamination']})');
      }
      
      if (isCrossContamination) {
        mayContainAllergens.add(Map<String, dynamic>.from(allergen));
        if (kDebugMode) {
          print('_buildAllergenResults: Added to may contain: ${allergen['name']}');
        }
      } else {
        definiteAllergens.add(Map<String, dynamic>.from(allergen));
        if (kDebugMode) {
          print('_buildAllergenResults: Added to definite: ${allergen['name']}');
        }
      }
    }
    
    // Also process separate cross-contamination warnings
    if (kDebugMode) {
      print('_buildAllergenResults: Processing ${result.crossContaminationWarnings.length} separate cross-contamination warnings');
    }
    
    for (var warning in result.crossContaminationWarnings) {
      String? allergenName = warning['allergen']?.toString();
      if (allergenName != null && allergenName.isNotEmpty) {
        // Check if this allergen is already in the may contain list
        bool alreadyExists = mayContainAllergens.any((a) => a['name'] == allergenName);
        
        if (!alreadyExists) {
          mayContainAllergens.add({
            'name': allergenName,
            'severity': 'medium',
            'confidence': warning['confidence']?.toDouble() ?? 0.7,
            'detectionMethod': 'Cross-contamination warning',
            'matchedIngredient': 'Cross-contamination warning',
            'isCrossContamination': true,
            'crossContaminationWarning': warning['message']?.toString() ?? 'May contain traces',
            'source': 'Cross-contamination analysis'
          });
          
          if (kDebugMode) {
            print('_buildAllergenResults: Added cross-contamination allergen from warnings: $allergenName');
          }
        } else {
          if (kDebugMode) {
            print('_buildAllergenResults: Skipped duplicate cross-contamination allergen: $allergenName');
          }
        }
      } else {
        if (kDebugMode) {
          print('_buildAllergenResults: Skipped cross-contamination warning with no allergen name: $warning');
        }
      }
    }
    
    // Note: Test warning removed - French cross-contamination detection is now working
    
    if (kDebugMode) {
      print('_buildAllergenResults: Final results:');
      print('  Definite allergens found: ${definiteAllergens.length}');
      print('  May contain allergens found: ${mayContainAllergens.length}');
      
      if (mayContainAllergens.isNotEmpty) {
        print('  May contain allergens:');
        for (var allergen in mayContainAllergens) {
          print('    - ${allergen['name']} (${allergen['detectionMethod']})');
        }
      }
    }

    return Column(
      children: [
        // Show definite allergens first (from actual ingredients)
        if (definiteAllergens.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.triangle_alert, color: Colors.red[700]),
                    const SizedBox(width: 8),
                    Text(
                      'Allergens Found in Ingredients',
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...definiteAllergens.map((allergen) => _buildAllergenCard(allergen, isDefinite: true)),
              ],
            ),
          ),
        
        // Show "may contain" warnings below
        if (mayContainAllergens.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.triangle_alert, color: Colors.orange[700]),
                    const SizedBox(width: 8),
                    Text(
                      'May Contain Warnings',
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...mayContainAllergens.map((allergen) => _buildAllergenCard(allergen, isDefinite: false)),
              ],
            ),
          ),
      ],
    );
  }



  /// Builds a consistent allergen card for both definite and may contain allergens
  Widget _buildAllergenCard(Map<String, dynamic> allergen, {required bool isDefinite}) {
    final allergenName = allergen['name']?.toString() ?? 'Unknown allergen';
    final severity = allergen['severity']?.toString() ?? 'Medium';
    final detectionMethod = allergen['detectionMethod']?.toString() ?? 'Unknown';
    final confidence = (allergen['confidence'] as num?)?.toDouble() ?? 0.0;

    Color severityColor;
    switch (severity) {
      case 'High':
        severityColor = isDefinite ? Colors.red : Colors.orange;
        break;
      case 'Medium':
        severityColor = isDefinite ? Colors.orange : Colors.amber;
        break;
      case 'Low':
        severityColor = isDefinite ? Colors.yellow : Colors.yellow[700]!;
        break;
      default:
        severityColor = Colors.grey;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: severityColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                allergenName,
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.bold,
                  color: severityColor,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: severityColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isDefinite ? severity : 'MAY CONTAIN',
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Detection Method: $detectionMethod',
            style: GoogleFonts.nunito(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          Text(
            'Confidence: ${(confidence * 100).toStringAsFixed(1)}%',
            style: GoogleFonts.nunito(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          if (isDefinite && allergen['matchedIngredient']?.isNotEmpty == true)
            Text(
              'Found in: ${allergen['matchedIngredient']}',
              style: GoogleFonts.nunito(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          if (!isDefinite && allergen['crossContaminationWarning']?.isNotEmpty == true)
            Text(
              'Warning: ${allergen['crossContaminationWarning']}',
              style: GoogleFonts.nunito(
                fontSize: 12,
                color: Colors.orange[700],
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  void _showDetailedAllergenInfo(EnhancedScanResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Detailed Allergen Analysis',
          style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Safety Assessment
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: result.isSafe ? Colors.green[50] : Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: result.isSafe ? Colors.green : Colors.red,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Safety Assessment',
                      style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('Overall Safety: ${result.isSafe ? "Safe" : "Unsafe"}'),
                    Text('Risk Level: ${result.riskLevel.toUpperCase()}'),
                    Text('Confidence: ${result.confidenceDescription}'),
                    Text('Analysis Method: ${result.analysisMethod}'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // All Allergens (definite and may contain) - combined layout
              ...(() {
                final definiteAllergens = result.detectedAllergens.where((allergen) => allergen['isCrossContamination'] != true).toList();
                final mayContainAllergens = result.detectedAllergens.where((allergen) => allergen['isCrossContamination'] == true).toList();
                
                if (definiteAllergens.isEmpty && mayContainAllergens.isEmpty) return <Widget>[];
                
                List<Widget> allWidgets = [];
                
                // Add definite allergens first
                if (definiteAllergens.isNotEmpty) {
                  allWidgets.addAll([
                    Text(
                      'Detected Allergens',
                      style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...definiteAllergens.map((allergen) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            allergen['name'],
                            style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
                          ),
                          Text('Severity: ${allergen['severity']}'),
                          Text('Confidence: ${(allergen['confidence'] * 100).toStringAsFixed(1)}%'),
                          Text('Detection Method: ${allergen['detectionMethod']}'),
                          if (allergen['matchedIngredient']?.isNotEmpty == true)
                            Text('Matched Ingredient: ${allergen['matchedIngredient']}'),
                        ],
                      ),
                    )),
                  ]);
                }
                
                // Add may contain allergens below
                if (mayContainAllergens.isNotEmpty) {
                  allWidgets.addAll([
                    const SizedBox(height: 16),
                    Text(
                      'May Contain',
                      style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...mayContainAllergens.map((allergen) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                allergen['name'],
                                style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'MAY CONTAIN',
                                  style: GoogleFonts.nunito(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text('Severity: ${allergen['severity']}'),
                          Text('Confidence: ${(allergen['confidence'] * 100).toStringAsFixed(1)}%'),
                          Text('Detection Method: ${allergen['detectionMethod']}'),
                          if (allergen['matchedIngredient']?.isNotEmpty == true)
                            Text('Matched Ingredient: ${allergen['matchedIngredient']}'),
                        ],
                      ),
                    )),
                  ]);
                }
                
                allWidgets.add(const SizedBox(height: 16));
                return allWidgets;
              })(),
              
              // Cross-contamination Warnings
              if (result.crossContaminationWarnings.isNotEmpty) ...[
                Text(
                  'Cross-Contamination Warnings',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...result.crossContaminationWarnings.map((warning) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        warning['allergen'],
                        style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
                      ),
                      Text('Risk Level: ${warning['riskLevel']}'),
                      Text('Message: ${warning['message']}'),
                    ],
                  ),
                )),
                const SizedBox(height: 16),
              ],
              
              // Processing Facility Warnings
              if (result.processingFacilityWarnings.isNotEmpty) ...[
                Text(
                  'Processing Facility Warnings',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...result.processingFacilityWarnings.map((warning) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.yellow[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.yellow),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        warning['allergen'],
                        style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
                      ),
                      Text('Risk Level: ${warning['riskLevel']}'),
                      Text('Message: ${warning['message']}'),
                      if (warning['facilityInfo']?.isNotEmpty == true)
                        Text('Facility Info: ${warning['facilityInfo']}'),
                    ],
                  ),
                )),
                const SizedBox(height: 16),
              ],
              
              // Recommendations
              if (result.safetyAssessment['recommendations']?.isNotEmpty == true) ...[
                Text(
                  'Recommendations',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...(result.safetyAssessment['recommendations'] as List<dynamic>).map((rec) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• $rec'),
                )),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveToScanHistory(EnhancedScanResult result) async {
    // Only save scan history for Premium users
    if (!_isPremium) return;
    
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList('enhanced_scan_history') ?? [];
    
    // Add new scan result
    historyJson.add(result.toJsonString());
    
    // Keep only last 50 scans
    if (historyJson.length > 50) {
      historyJson.removeRange(0, historyJson.length - 50);
    }
    
    await prefs.setStringList('enhanced_scan_history', historyJson);
  }



  void _toggleFlash() async {
    await _scannerController.toggleTorch();
    if (!mounted) return;
    setState(() {
      isFlashOn = _scannerController.value.torchState == TorchState.on;
    });
  }



  void _showManualBarcodeDialog() {
    _manualBarcodeController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Enter Barcode Manually',
          style: GoogleFonts.nunito(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2A4C4A),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _manualBarcodeController,
              decoration: InputDecoration(
                hintText: 'Enter product barcode (e.g., 9334169005004)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.qr_code),
                helperText: 'Enter the barcode number from the product packaging',
              ),
              keyboardType: TextInputType.number,
              maxLength: 20,
              onSubmitted: (value) => _processManualBarcode(),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter the barcode number from the product packaging',
              style: GoogleFonts.nunito(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.nunito(
                color: Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _processManualBarcode,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A9E9C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Search',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _processManualBarcode() {
    final barcode = _manualBarcodeController.text.trim();
    if (barcode.isNotEmpty && barcode.length >= 8) {
      Navigator.pop(context);
      _processBarcode(barcode);
      _manualBarcodeController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter a valid barcode (at least 8 digits)',
            style: GoogleFonts.nunito(),
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  /// Calculate confidence score based on available data sources
  double _calculateConfidenceScore(bool hasAustralianData, bool hasSpoonacularData, bool hasIngredients) {
    double baseScore = 0.7; // Base confidence for standard analysis
    
    if (hasAustralianData) {
      baseScore += 0.15; // Australian database adds 15%
    }
    
    if (hasSpoonacularData) {
      baseScore += 0.1; // Spoonacular adds 10%
    }
    
    if (hasIngredients) {
      baseScore += 0.05; // Having ingredients adds 5%
    }
    
    // Cap at 0.95 to leave room for uncertainty
    return baseScore.clamp(0.3, 0.95);
  }

  /// Get analysis method description based on available data sources
  String _getAnalysisMethod(bool hasAustralianData, bool hasSpoonacularData) {
    if (hasAustralianData && hasSpoonacularData) {
      return 'Enhanced allergen analysis with Australian database and Spoonacular API';
    } else if (hasAustralianData) {
      return 'Enhanced allergen analysis with Australian database';
    } else if (hasSpoonacularData) {
      return 'Enhanced allergen analysis with Spoonacular API';
    } else {
      return 'Standard allergen analysis';
    }
  }

  /// Get detection method description based on available data sources
  String _getDetectionMethod(bool hasAustralianData, bool hasSpoonacularData) {
    if (hasAustralianData && hasSpoonacularData) {
      return 'Enhanced database matching with Australian compliance data and Spoonacular nutritional analysis';
    } else if (hasAustralianData) {
      return 'Enhanced database matching with Australian compliance data';
    } else if (hasSpoonacularData) {
      return 'Enhanced database matching with Spoonacular nutritional analysis';
    } else {
      return 'Standard allergen database matching';
    }
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => const PremiumUpgradeWidget(),
    );
  }

  // Photo scan methods
  void _togglePhotoScanOptions() {
    setState(() {
      _showPhotoScanOptions = !_showPhotoScanOptions;
      if (!_showPhotoScanOptions) {
        _selectedImage = null;
        _extractedText = '';
        _extractedIngredients = [];
        _photoDetectedAllergens = [];
      }
    });
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final image = await OCRService.pickImageFromCamera();
      if (image != null) {
        setState(() {
          _selectedImage = image;
          _showPhotoScanOptions = false;
        });
        await _processPhotoImage();
      }
    } catch (e) {
      if (kDebugMode) {
        print('ScanLabel: Error picking image from camera: $e');
      }
      _showErrorSnackBar('Failed to capture image: $e');
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final image = await OCRService.pickImageFromGallery();
      if (image != null) {
        setState(() {
          _selectedImage = image;
          _showPhotoScanOptions = false;
        });
        await _processPhotoImage();
      }
    } catch (e) {
      if (kDebugMode) {
        print('ScanLabel: Error picking image from gallery: $e');
      }
      _showErrorSnackBar('Failed to pick image: $e');
    }
  }

  Future<void> _processPhotoImage() async {
    if (_selectedImage == null) return;
    
    setState(() {
      isLoading = true;
    });
    
    try {
      // Extract text from image
      final extractedText = await OCRService.extractTextFromImage(_selectedImage!);
      
      // Extract ingredients from text
      final ingredients = OCRService.extractIngredientsFromText(extractedText);
      
      // Analyze allergens
      final allergenAnalysis = await _analyzePhotoAllergens(ingredients);
      
      // Determine product safety
      final safetyAssessment = _assessPhotoSafety(allergenAnalysis);
      
      setState(() {
        _extractedText = extractedText;
        _extractedIngredients = ingredients;
        _photoDetectedAllergens = allergenAnalysis['detectedAllergens'];
        isLoading = false;
        showResults = true;
        isScanning = false;
      });
      
      // Create scan result for photo scan
      await _createPhotoScanResult(safetyAssessment);
      
    } catch (e) {
      if (kDebugMode) {
        print('ScanLabel: Error processing photo image: $e');
      }
      setState(() {
        isLoading = false;
      });
      _showErrorSnackBar('Failed to process image: $e');
    }
  }

  Future<Map<String, dynamic>> _analyzePhotoAllergens(List<String> ingredients) async {
    final detectedAllergens = <Map<String, dynamic>>[];
    
    for (final userAllergy in userAllergies) {
      final allergyName = userAllergy['name'] as String;
      final allergySeverity = userAllergy['severity'] as String;
      
      // Check if any ingredient contains this allergen
      for (final ingredient in ingredients) {
        final isMatch = ingredient.toLowerCase().contains(allergyName.toLowerCase());
        
        if (isMatch) {
          detectedAllergens.add({
            'name': allergyName,
            'severity': allergySeverity,
            'confidence': 0.85, // High confidence for OCR detection
            'matchedIngredient': ingredient,
            'source': 'OCR Analysis',
          });
          break; // Found this allergen, move to next
        }
      }
    }
    
    return {
      'detectedAllergens': detectedAllergens,
      'totalIngredients': ingredients.length,
      'analyzedIngredients': ingredients.length,
    };
  }

  Map<String, dynamic> _assessPhotoSafety(Map<String, dynamic> allergenAnalysis) {
    final detectedAllergens = allergenAnalysis['detectedAllergens'] as List<Map<String, dynamic>>;
    final totalIngredients = allergenAnalysis['totalIngredients'] as int;
    
    bool isSafe = detectedAllergens.isEmpty;
    String riskLevel = 'Low';
    double confidenceScore = 0.8; // Base confidence for OCR
    
    if (detectedAllergens.isNotEmpty) {
      riskLevel = 'High';
      confidenceScore = 0.9; // Higher confidence when allergens are detected
    } else if (totalIngredients == 0) {
      riskLevel = 'Unknown';
      confidenceScore = 0.3; // Low confidence when no ingredients found
    }
    
    return {
      'isSafe': isSafe,
      'riskLevel': riskLevel,
      'confidenceScore': confidenceScore,
    };
  }

  Future<void> _createPhotoScanResult(Map<String, dynamic> safetyAssessment) async {
    try {
      final scanResult = EnhancedScanResult(
        barcode: 'PHOTO_${DateTime.now().millisecondsSinceEpoch}',
        productName: 'Product from Photo',
        brand: 'Unknown Brand',
        ingredients: _extractedIngredients,
        mayContainItems: ProductDatabaseService.collectMayContainItems(
          ingredients: _extractedIngredients,
          product: {'crossContaminationWarnings': []},
        ),
        detectedAllergens: _photoDetectedAllergens,
        crossContaminationWarnings: [],
        processingFacilityWarnings: [],
        safetyAssessment: {
          'risk_level': safetyAssessment['riskLevel'],
          'recommendation': safetyAssessment['isSafe'] ? 'Safe to consume' : 'Avoid this product',
          'confidence': safetyAssessment['confidenceScore'] > 0.8 ? 'High' : 'Medium',
          'has_ingredients': _extractedIngredients.isNotEmpty,
          'ingredient_warning': _extractedIngredients.isEmpty ? 'No ingredient information available' : null,
        },
        scanDate: DateTime.now(),
        isSafe: safetyAssessment['isSafe'],
        image: _selectedImage?.path,
        dataSource: 'Photo OCR Analysis',
        analysisMethod: 'Optical Character Recognition with Allergen Analysis',
        confidenceScore: safetyAssessment['confidenceScore'],
        riskLevel: safetyAssessment['riskLevel'],
        processingTimeMs: 0,
        allergenAnalysis: {
          'detectedAllergens': _photoDetectedAllergens,
          'crossContaminationWarnings': [],
          'processingFacilityWarnings': [],
          'totalIngredients': _extractedIngredients.length,
          'analyzedIngredients': _extractedIngredients.length,
          'detectionMethod': 'OCR-based ingredient analysis',
          'lastUpdated': DateTime.now().toIso8601String(),
          'australianDatabaseIncluded': false,
          'spoonacularIncluded': false,
          'ocrIncluded': true,
        },
        crossContaminationRisk: {
          'risk': 'unknown',
          'message': 'Cross-contamination information not available from photo analysis',
          'crossContamination': [],
          'processingFacility': 'No information available'
        },
      );
      
      // Save to scan history
      final prefs = await SharedPreferences.getInstance();
      final scanHistory = prefs.getStringList('scan_history') ?? [];
      scanHistory.add(jsonEncode(scanResult.toJson()));
      await prefs.setStringList('scan_history', scanHistory);
      
      // Log analytics
      await FirebaseService.logProductScan(
        productName: scanResult.productName,
        hasAllergens: scanResult.detectedAllergens.isNotEmpty,
        detectedAllergens: scanResult.detectedAllergens
            .map((allergen) => allergen['name'] as String)
            .toList(),
      );
      
      if (kDebugMode) {
        print('ScanLabel: Photo scan result saved to history');
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('ScanLabel: Error creating photo scan result: $e');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          title: Text(
            'Scan',
            style: GoogleFonts.nunito(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.camera_alt,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                'Camera access is not available in web browsers',
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),

            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Scan',
          style: GoogleFonts.nunito(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 32,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF4A9E9C),
        foregroundColor: Colors.black,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(_showPhotoScanOptions ? Icons.close : Icons.camera_alt),
            onPressed: _togglePhotoScanOptions,
          ),
          IconButton(
            icon: Icon(isFlashOn ? LucideIcons.zap : LucideIcons.zap),
            onPressed: _toggleFlash,
          ),
          if (!_isPremium)
            IconButton(
              icon: const Icon(LucideIcons.star),
              onPressed: _showUpgradeDialog,
            ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF4A9E9C),
        unselectedItemColor: Colors.grey[600],
        selectedLabelStyle: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: GoogleFonts.nunito(fontSize: 12),
        currentIndex: 2, // Home is index 2 (scan screen is part of home flow)
        elevation: 8,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        iconSize: 21,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/profile');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/my_allergies');
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/home');
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/emergency_contacts');
              break;
            case 4:
              Navigator.pushReplacementNamed(context, '/settings');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.person, color: Color(0xFF1976D2)), // Profile blue
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.health_and_safety, color: Color(0xFF43A047)), // Allergies green
            label: 'Allergies',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home, color: Color(0xFF4A9E9C)), // Home teal
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emergency, color: Color(0xFFE53935)), // Emergency red
            label: 'Emergency',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings, color: Color(0xFF8E24AA)), // Settings purple
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (isScanning) {
      return Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                if (hasCameraPermission && isCameraInitialized)
                  MobileScanner(
                    onDetect: _onDetect,
                    controller: _scannerController,
                  ),
                
                // Photo scan options overlay
                if (_showPhotoScanOptions)
                  Container(
                    color: Colors.black.withValues(alpha: 0.8),
                    child: Center(
                      child: Container(
                        margin: const EdgeInsets.all(32),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Photo Scan',
                              style: GoogleFonts.nunito(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF2A4C4A),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Take a photo of the product label to extract ingredient information',
                              style: GoogleFonts.nunito(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _pickImageFromCamera,
                                    icon: const Icon(Icons.camera_alt),
                                    label: const Text('Camera'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF4A9E9C),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _pickImageFromGallery,
                                    icon: const Icon(Icons.photo_library),
                                    label: const Text('Gallery'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF4A9E9C),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                
                // Camera error or initialization state
                if (!hasCameraPermission || !isCameraInitialized)
                  Container(
                    color: Colors.black,
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                          Icon(
                            cameraError != null ? Icons.camera_alt : Icons.camera_alt,
                            size: 64,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            cameraError ?? 'Initializing camera...',
                            style: GoogleFonts.nunito(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (cameraError != null) ...[
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _checkCameraPermissions,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4A9E9C),
                                foregroundColor: Colors.white,
                              ),
                              child: Text(
                                'Retry',
                                style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                        ),
                      ),
                    ),
                  ),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.all(40),
                ),
                AnimatedBuilder(
                  animation: _scanAnimation,
                  builder: (context, child) {
                    return Positioned(
                      top: 40 + (_scanAnimation.value * (MediaQuery.of(context).size.height * 0.6 - 80)),
                      left: 40,
                      right: 40,
                      child: Container(
                        height: 2,
                        color: const Color(0xFF4A9E9C),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  LucideIcons.barcode,
                  size: 40,
                  color: Color(0xFF4A9E9C),
                ),
                const SizedBox(height: 16),
                Text(
                  hasCameraPermission && isCameraInitialized 
                    ? 'Position the barcode within the frame'
                    : scannerStatus,
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Hold steady for best results',
                  style: GoogleFonts.nunito(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                       onPressed: () {
                         setState(() {
                           isScanning = true;
                           showResults = false;
                           scanResult = null;
                         });
                       },
                       icon: const Icon(Icons.refresh),
                       label: Text(
                         'New Scan',
                         style: GoogleFonts.nunito(
                           fontWeight: FontWeight.bold,
                         ),
                       ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A9E9C),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _showManualBarcodeDialog,
                      icon: const Icon(Icons.keyboard),
                      label: Text(
                        'Manual Entry',
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        foregroundColor: Colors.grey[700],
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    } else if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A9E9C)),
            ),
            const SizedBox(height: 16),
            Text(
              'Analyzing product...',
              style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Using enhanced ML-based allergen detection',
              style: GoogleFonts.nunito(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    } else if (showResults) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                         // Product information
             Container(
               margin: const EdgeInsets.only(bottom: 16),
               padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(
                 color: Colors.white,
                 borderRadius: BorderRadius.circular(12),
                 boxShadow: [
                   BoxShadow(
                     color: Colors.grey.withValues(alpha: 0.1),
                     spreadRadius: 1,
                     blurRadius: 4,
                     offset: const Offset(0, 2),
                   ),
                 ],
               ),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   if (scanResult != null) ...[
                     Row(
                       children: [
                         Expanded(
                           child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               Row(
                                 children: [
                                   Expanded(
                                     child: Text(
                                       scanResult!.productName,
                                       style: GoogleFonts.nunito(
                                         fontSize: 20,
                                         fontWeight: FontWeight.bold,
                                         color: const Color(0xFF2A4C4A),
                                       ),
                                       overflow: TextOverflow.ellipsis,
                                       maxLines: 2,
                                     ),
                                   ),
                                   if (scanResult!.dataSource == 'Premium Database')
                                     Container(
                                       margin: const EdgeInsets.only(left: 8),
                                       padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                       decoration: BoxDecoration(
                                         color: Colors.amber[100],
                                         borderRadius: BorderRadius.circular(8),
                                         border: Border.all(color: Colors.amber[300]!),
                                       ),
                                       child: Row(
                                         mainAxisSize: MainAxisSize.min,
                                         children: [
                                           Icon(
                                             Icons.star,
                                             size: 12,
                                             color: Colors.amber[700],
                                           ),
                                           const SizedBox(width: 2),
                                           Text(
                                             'PREMIUM',
                                             style: GoogleFonts.nunito(
                                               fontSize: 10,
                                               fontWeight: FontWeight.bold,
                                               color: Colors.amber[700],
                                             ),
                                           ),
                                         ],
                                       ),
                                     ),
                                   if (scanResult!.dataSource == 'Photo OCR Analysis')
                                     Container(
                                       margin: const EdgeInsets.only(left: 8),
                                       padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                       decoration: BoxDecoration(
                                         color: Colors.blue[100],
                                         borderRadius: BorderRadius.circular(8),
                                         border: Border.all(color: Colors.blue[300]!),
                                       ),
                                       child: Row(
                                         mainAxisSize: MainAxisSize.min,
                                         children: [
                                           Icon(
                                             Icons.camera_alt,
                                             size: 12,
                                             color: Colors.blue[700],
                                           ),
                                           const SizedBox(width: 2),
                                           Text(
                                             'PHOTO',
                                             style: GoogleFonts.nunito(
                                               fontSize: 10,
                                               fontWeight: FontWeight.bold,
                                               color: Colors.blue[700],
                                             ),
                                           ),
                                         ],
                                       ),
                                     ),
                                 ],
                               ),
                             ],
                           ),
                         ),
                         Container(
                           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                           decoration: BoxDecoration(
                             color: scanResult!.isSafe ? Colors.green[100] : Colors.red[100],
                             borderRadius: BorderRadius.circular(12),
                           ),
                           child: Text(
                             scanResult!.isSafe ? 'SAFE' : 'UNSAFE',
                             style: GoogleFonts.nunito(
                               fontSize: 12,
                               fontWeight: FontWeight.bold,
                               color: scanResult!.isSafe ? Colors.green[700] : Colors.red[700],
                             ),
                           ),
                         ),
                       ],
                     ),
                     const SizedBox(height: 8),
                     Text(
                       'Brand: ${scanResult!.brand}',
                       style: GoogleFonts.nunito(
                         fontSize: 14,
                         color: Colors.grey[600],
                       ),
                     ),
                     if (scanResult!.dataSource == 'Photo OCR Analysis') ...[
                       const SizedBox(height: 8),
                       Text(
                         'Analysis Method: OCR Text Recognition',
                         style: GoogleFonts.nunito(
                           fontSize: 12,
                           color: Colors.blue[600],
                           fontStyle: FontStyle.italic,
                         ),
                       ),
                     ] else ...[
                       const SizedBox(height: 8),
                       Text(
                         'Data Source: ${scanResult!.dataSource}',
                         style: GoogleFonts.nunito(
                           fontSize: 12,
                           color: Colors.grey[600],
                         ),
                       ),
                     ],
                   ] else ...[
                     Text(
                       'Product Not Found',
                       style: GoogleFonts.nunito(
                         fontSize: 20,
                         fontWeight: FontWeight.bold,
                         color: const Color(0xFF2A4C4A),
                       ),
                     ),
                     const SizedBox(height: 8),
                     Text(
                       'This barcode is not in our database',
                       style: GoogleFonts.nunito(
                         color: Colors.grey[600],
                       ),
                     ),
                   ],
                 ],
               ),
             ),

             // Allergen results (only show if product found and allergens detected)
             if (scanResult != null && scanResult!.detectedAllergens.isNotEmpty) ...[
               Builder(
                 builder: (context) {
                   if (kDebugMode) {
                     print('ScanLabelScreen: Building allergen results for ${scanResult!.detectedAllergens.length} allergens');
                   }
                   return _buildAllergenResults(scanResult!);
                 },
               ),
             ],

             // Ingredients list (only show if product found)
             if (scanResult != null) ...[
               Container(
                 margin: const EdgeInsets.only(bottom: 16),
                 padding: const EdgeInsets.all(16),
                 decoration: BoxDecoration(
                   color: Colors.white,
                   borderRadius: BorderRadius.circular(12),
                   boxShadow: [
                     BoxShadow(
                       color: Colors.grey.withValues(alpha: 0.1),
                       spreadRadius: 1,
                       blurRadius: 4,
                       offset: const Offset(0, 2),
                     ),
                   ],
                 ),
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Row(
                       children: [
                         Icon(LucideIcons.list, color: const Color(0xFF4A9E9C)),
                         const SizedBox(width: 8),
                         Text(
                           'Ingredients',
                           style: GoogleFonts.nunito(
                             fontSize: 16,
                             fontWeight: FontWeight.bold,
                             color: const Color(0xFF2A4C4A),
                           ),
                         ),
                       ],
                     ),
                     const SizedBox(height: 12),
                     if (scanResult?.ingredients.isNotEmpty == true)
                       Wrap(
                         spacing: 8,
                         runSpacing: 8,
                         children: scanResult!.ingredients.map((ingredient) {
                           final isAllergen = scanResult!.detectedAllergens.any((allergen) =>
                               allergen['matchedIngredient'] == ingredient);
                           
                           return Container(
                             constraints: BoxConstraints(
                               maxWidth: MediaQuery.of(context).size.width * 0.8,
                             ),
                             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                             decoration: BoxDecoration(
                               color: isAllergen ? Colors.red[100] : Colors.grey[100],
                               borderRadius: BorderRadius.circular(12),
                               border: Border.all(
                                 color: isAllergen ? Colors.red : Colors.grey[300]!,
                               ),
                             ),
                             child: Text(
                               ingredient,
                               style: GoogleFonts.nunito(
                                 fontSize: 12,
                                 color: isAllergen ? Colors.red[700] : Colors.grey[700],
                                 fontWeight: isAllergen ? FontWeight.bold : FontWeight.normal,
                               ),
                               overflow: TextOverflow.ellipsis,
                               maxLines: 2,
                             ),
                           );
                         }).toList(),
                       )
                     else
                       Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Text(
                             'No ingredients information available',
                             style: GoogleFonts.nunito(
                               color: Colors.grey[600],
                               fontStyle: FontStyle.italic,
                             ),
                           ),
                           const SizedBox(height: 8),
                           Container(
                             padding: const EdgeInsets.all(12),
                             decoration: BoxDecoration(
                               color: Colors.orange[50],
                               borderRadius: BorderRadius.circular(8),
                               border: Border.all(color: Colors.orange[200]!),
                             ),
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 Row(
                                   children: [
                                     Icon(Icons.warning, color: Colors.orange[700], size: 16),
                                     const SizedBox(width: 4),
                                     Text(
                                       'Limited Information',
                                       style: GoogleFonts.nunito(
                                         fontSize: 12,
                                         fontWeight: FontWeight.bold,
                                         color: Colors.orange[700],
                                       ),
                                     ),
                                   ],
                                 ),
                                 const SizedBox(height: 4),
                                 Text(
                                   'This product was found in our database but ingredient information is not available. Please check the product label manually for allergen information.',
                                   style: GoogleFonts.nunito(
                                     fontSize: 11,
                                     color: Colors.orange[700],
                                   ),
                                 ),
                               ],
                             ),
                           ),
                         ],
                       ),
                     const SizedBox(height: 16),
                     Container(
                       width: double.infinity,
                       padding: const EdgeInsets.all(12),
                       decoration: BoxDecoration(
                         color: Colors.orange[50],
                         borderRadius: BorderRadius.circular(8),
                         border: Border.all(color: Colors.orange[200]!),
                       ),
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Row(
                             children: [
                               Icon(LucideIcons.triangle_alert, color: Colors.orange[700], size: 18),
                               const SizedBox(width: 8),
                               Text(
                                 'May Contain (from label)',
                                 style: GoogleFonts.nunito(
                                   fontSize: 14,
                                   fontWeight: FontWeight.bold,
                                   color: Colors.orange[800],
                                 ),
                               ),
                             ],
                           ),
                           const SizedBox(height: 8),
                           if (scanResult!.mayContainItems.isEmpty)
                             Text(
                               'No "may contain" statement found on this product\'s ingredient listing.',
                               style: GoogleFonts.nunito(
                                 fontSize: 13,
                                 color: Colors.grey[700],
                                 fontStyle: FontStyle.italic,
                               ),
                             )
                           else
                             ...scanResult!.mayContainItems.map(
                               (item) => Padding(
                                 padding: const EdgeInsets.only(top: 4),
                                 child: Text(
                                   '• $item',
                                   style: GoogleFonts.nunito(
                                     fontSize: 13,
                                     color: Colors.orange[900],
                                   ),
                                 ),
                               ),
                             ),
                         ],
                       ),
                     ),
                   ],
                 ),
               ),

               // Raw extracted text for photo scans
               if (scanResult != null && scanResult!.dataSource == 'Photo OCR Analysis' && _extractedText.isNotEmpty) ...[
                 Container(
                   margin: const EdgeInsets.only(bottom: 16),
                   padding: const EdgeInsets.all(16),
                   decoration: BoxDecoration(
                     color: Colors.white,
                     borderRadius: BorderRadius.circular(12),
                     boxShadow: [
                       BoxShadow(
                         color: Colors.grey.withValues(alpha: 0.1),
                         spreadRadius: 1,
                         blurRadius: 4,
                         offset: const Offset(0, 2),
                       ),
                     ],
                   ),
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Row(
                         children: [
                           Icon(Icons.text_fields, color: Colors.blue[600]),
                           const SizedBox(width: 8),
                           Text(
                             'Raw Extracted Text',
                             style: GoogleFonts.nunito(
                               fontSize: 16,
                               fontWeight: FontWeight.bold,
                               color: Colors.blue[600],
                             ),
                           ),
                         ],
                       ),
                       const SizedBox(height: 12),
                       Container(
                         padding: const EdgeInsets.all(12),
                         decoration: BoxDecoration(
                           color: Colors.grey[50],
                           borderRadius: BorderRadius.circular(8),
                           border: Border.all(color: Colors.grey[300]!),
                         ),
                         child: Text(
                           _extractedText,
                           style: GoogleFonts.nunito(
                             fontSize: 12,
                             color: Colors.grey[700],
                             height: 1.4,
                           ),
                         ),
                       ),
                     ],
                   ),
                 ),
               ],
             ],
            // Action buttons
            Container(
              margin: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          isScanning = true;
                          showResults = false;
                          scanResult = null;
                          _selectedImage = null;
                          _extractedText = '';
                          _extractedIngredients = [];
                          _photoDetectedAllergens = [];
                          _showPhotoScanOptions = false;
                        });
                      },
                      icon: const Icon(Icons.refresh),
                      label: Text(
                        'Scan Another Product',
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A9E9C),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _showManualBarcodeDialog,
                      icon: const Icon(Icons.keyboard),
                      label: Text(
                        'Enter Barcode Manually',
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        foregroundColor: Colors.grey[700],
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    
    return Container(); // Fallback
  }


}



