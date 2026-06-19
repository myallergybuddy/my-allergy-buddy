import 'package:flutter/material.dart';
import 'services/product_database_service.dart';

class TestCrossContamination extends StatefulWidget {
  const TestCrossContamination({super.key});

  @override
  State<TestCrossContamination> createState() => _TestCrossContaminationState();
}

class _TestCrossContaminationState extends State<TestCrossContamination> {
  String testResult = '';

  void _testCrossContaminationParsing() {
    setState(() {
      testResult = '';
    });

    // Test ingredients with cross-contamination warnings (VitaWeat 9 Grains format)
    List<String> testIngredients = [
      'CRISPBREAD WHOLEGRAINS (86%) (WHEAT, BARLEY, RYE, CORN)',
      'SEEDS (5%) (CANOLA, LINSEED, POPPY, SUNFLOWER KERNELS)',
      'VEGETABLE OIL',
      'SALT',
      'SUGAR',
      'SOY',
      'CONTAINS WHEAT, GLUTEN, SOY',
      'MAY CONTAIN EGG, MILK, TREE NUTS, PEANUT, SESAME',
    ];

    // Test user allergies
    List<Map<String, dynamic>> userAllergies = [
      {'name': 'Peanuts', 'severity': 'Medium', 'category': 'Nuts'},
      {'name': 'Milk', 'severity': 'Medium', 'category': 'Dairy'},
      {'name': 'Wheat', 'severity': 'Medium', 'category': 'Gluten'},
      {'name': 'Soy', 'severity': 'Medium', 'category': 'Legumes'},
    ];

    // Parse ingredients
    Map<String, dynamic> parsed = ProductDatabaseService.parseIngredientsWithWarnings(testIngredients);
    List<String> actualIngredients = parsed['actualIngredients'];
    List<String> crossContaminationWarnings = parsed['crossContaminationWarnings'];
    List<String> processingFacilityWarnings = parsed['processingFacilityWarnings'];

    // Analyze allergens
    List<Map<String, dynamic>> detectedAllergens = ProductDatabaseService.analyzeAllergens(testIngredients, userAllergies);

    // Build result string
    StringBuffer result = StringBuffer();
    result.writeln('=== CROSS-CONTAMINATION PARSING TEST ===\n');
    
    result.writeln('ORIGINAL INGREDIENTS:');
    for (String ingredient in testIngredients) {
      result.writeln('  - $ingredient');
    }
    
    result.writeln('\nPARSED ACTUAL INGREDIENTS:');
    for (String ingredient in actualIngredients) {
      result.writeln('  - $ingredient');
    }
    
    result.writeln('\nCROSS-CONTAMINATION WARNINGS:');
    for (String warning in crossContaminationWarnings) {
      result.writeln('  - $warning');
    }
    
    result.writeln('\nPROCESSING FACILITY WARNINGS:');
    for (String warning in processingFacilityWarnings) {
      result.writeln('  - $warning');
    }
    
    result.writeln('\nDETECTED ALLERGENS:');
    for (Map<String, dynamic> allergen in detectedAllergens) {
      result.writeln('  - ${allergen['name']} (${allergen['isCrossContamination'] == true ? 'MAY CONTAIN' : 'DEFINITE'})');
      result.writeln('    Method: ${allergen['detectionMethod']}');
      result.writeln('    Confidence: ${(allergen['confidence'] * 100).toStringAsFixed(1)}%');
      result.writeln('    Matched: ${allergen['matchedIngredient']}');
    }

    setState(() {
      testResult = result.toString();
    });
  }

  void _testVitaWeatSpecific() {
    setState(() {
      testResult = '';
    });

    // Test the exact VitaWeat ingredients from the terminal output
    List<String> vitaWeatIngredients = [
      'CRISPBREAD WHOLEGRAINS  (WHEAT, BARLEY, RYE, CORN)',
      'SEEDS  (CANOLA, LINSEED, POPPY, SUNFLOWER KERNELS)',
      'VEGETABLE OIL',
      'SALT',
      'SUGAR',
      'GLUTEN',
      'MILK',
      'TREE NUTS',
      'PEANUT',
      'SESAME',
    ];

    // Test user allergies
    List<Map<String, dynamic>> userAllergies = [
      {'name': 'Peanuts', 'severity': 'Medium', 'category': 'Nuts'},
      {'name': 'Milk', 'severity': 'Medium', 'category': 'Dairy'},
      {'name': 'Wheat', 'severity': 'Medium', 'category': 'Gluten'},
      {'name': 'Soy', 'severity': 'Medium', 'category': 'Legumes'},
    ];

    // Parse ingredients
    Map<String, dynamic> parsed = ProductDatabaseService.parseIngredientsWithWarnings(vitaWeatIngredients);
    List<String> actualIngredients = parsed['actualIngredients'];
    List<String> crossContaminationWarnings = parsed['crossContaminationWarnings'];
    List<String> processingFacilityWarnings = parsed['processingFacilityWarnings'];

    // Analyze allergens
    List<Map<String, dynamic>> detectedAllergens = ProductDatabaseService.analyzeAllergens(vitaWeatIngredients, userAllergies);

    // Build result string
    StringBuffer result = StringBuffer();
    result.writeln('=== VITAWEAT SPECIFIC TEST ===\n');
    
    result.writeln('VITAWEAT INGREDIENTS (from terminal):');
    for (String ingredient in vitaWeatIngredients) {
      result.writeln('  - $ingredient');
    }
    
    result.writeln('\nPARSED ACTUAL INGREDIENTS:');
    for (String ingredient in actualIngredients) {
      result.writeln('  - $ingredient');
    }
    
    result.writeln('\nCROSS-CONTAMINATION WARNINGS:');
    for (String warning in crossContaminationWarnings) {
      result.writeln('  - $warning');
    }
    
    result.writeln('\nPROCESSING FACILITY WARNINGS:');
    for (String warning in processingFacilityWarnings) {
      result.writeln('  - $warning');
    }
    
    result.writeln('\nDETECTED ALLERGENS:');
    for (Map<String, dynamic> allergen in detectedAllergens) {
      result.writeln('  - ${allergen['name']} (${allergen['isCrossContamination'] == true ? 'MAY CONTAIN' : 'DEFINITE'})');
      result.writeln('    Method: ${allergen['detectionMethod']}');
      result.writeln('    Confidence: ${(allergen['confidence'] * 100).toStringAsFixed(1)}%');
      result.writeln('    Matched: ${allergen['matchedIngredient']}');
    }

    setState(() {
      testResult = result.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cross-Contamination Test'),
        backgroundColor: const Color(0xFF2A4C4A),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _testCrossContaminationParsing,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A9E9C),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Test Standard Parsing'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _testVitaWeatSpecific,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A9E9C),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Test VitaWeat'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Text(
                    testResult.isEmpty ? 'Click a button above to test cross-contamination parsing' : testResult,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
