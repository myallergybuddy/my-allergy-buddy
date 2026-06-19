import 'package:flutter/material.dart';

class TestParsing extends StatefulWidget {
  const TestParsing({super.key});

  @override
  State<TestParsing> createState() => _TestParsingState();
}

class _TestParsingState extends State<TestParsing> {
  String testResult = '';

  void _testParsing() {
    setState(() {
      testResult = '';
    });

    // Test the VitaWeat ingredients format
    String testIngredients = 'CRISPBREAD WHOLEGRAINS (86%) (WHEAT, BARLEY, RYE, CORN), SEEDS (5%) (CANOLA, LINSEED, POPPY, SUNFLOWER KERNELS), VEGETABLE OIL, SALT, SUGAR, SOY. CONTAINS WHEAT, GLUTEN, SOY. MAY CONTAIN EGG, MILK, TREE NUTS, PEANUT, SESAME.';

    // Test the parsing logic directly
    String lowerText = testIngredients.toLowerCase();
    int mayContainIndex = lowerText.indexOf('may contain');
    int containsIndex = lowerText.indexOf('contains');
    
    String actualIngredientsText = '';
    String warningsText = '';
    
    if (mayContainIndex != -1) {
      actualIngredientsText = testIngredients.substring(0, mayContainIndex).trim();
      warningsText = testIngredients.substring(mayContainIndex).trim();
    } else if (containsIndex != -1) {
      String beforeContains = testIngredients.substring(0, containsIndex).trim();
      if (beforeContains.endsWith('.') || beforeContains.endsWith(',')) {
        actualIngredientsText = testIngredients.substring(0, containsIndex).trim();
        warningsText = testIngredients.substring(containsIndex).trim();
      }
    }
    
    List<String> actual = actualIngredientsText.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    List<String> cross = warningsText.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    setState(() {
      testResult = 'Original: $testIngredients\n\n'
                   'Actual Ingredients: ${actual.join(', ')}\n\n'
                   'Cross-Contamination Warnings: ${cross.join(', ')}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Parsing'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: _testParsing,
              child: const Text('Test Parsing'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Text(testResult),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
