import 'package:flutter/material.dart';
import 'services/australian_food_database_service.dart';

class TestAustralianDatabase extends StatefulWidget {
  const TestAustralianDatabase({super.key});

  @override
  State<TestAustralianDatabase> createState() => _TestAustralianDatabaseState();
}

class _TestAustralianDatabaseState extends State<TestAustralianDatabase> {
  bool _isLoading = false;
  String _testResult = '';
  List<Map<String, dynamic>> _testProducts = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Australian Database'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _isLoading ? null : _testOpenFoodFacts,
              child: Text(_isLoading ? 'Testing...' : 'Test Open Food Facts'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _testBarcodeLookup,
              child: Text(_isLoading ? 'Testing...' : 'Test Barcode Lookup'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _testAustralianProductDetection,
              child: Text(_isLoading ? 'Testing...' : 'Test Australian Product Detection'),
            ),
            const SizedBox(height: 32),
            if (_testResult.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Test Results:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(_testResult),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            if (_testProducts.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _testProducts.length,
                  itemBuilder: (context, index) {
                    final product = _testProducts[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(product['name'] ?? 'Unknown'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Brand: ${product['brand'] ?? 'Unknown'}'),
                            Text('Barcode: ${product['barcode'] ?? 'Unknown'}'),
                            Text('Data Source: ${product['dataSource'] ?? 'Unknown'}'),
                            if (product['allergens'] != null)
                              Text('Allergens: ${(product['allergens'] as List).join(', ')}'),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _testOpenFoodFacts() async {
    setState(() {
      _isLoading = true;
      _testResult = 'Testing Open Food Facts...';
      _testProducts = [];
    });

    try {
      // Test searching for Australian products with common allergens
      final result = await AustralianFoodDatabaseService.searchAndDownloadProductsWithAllergens(
        allergens: ['peanuts', 'milk', 'wheat'],
        maxProducts: 10,
      );

      setState(() {
        _isLoading = false;
        _testResult = '''
Open Food Facts Test Results:
- Success: ${result['success']}
- Total Products: ${result['products'].length}
- Data Sources: ${result['statistics']['dataSources']}
- Products with Allergens: ${result['statistics']['productsWithAllergens']}
- Message: ${result['message']}
        ''';
        _testProducts = List<Map<String, dynamic>>.from(result['products']);
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _testResult = 'Error testing Open Food Facts: $e';
      });
    }
  }

  Future<void> _testBarcodeLookup() async {
    setState(() {
      _isLoading = true;
      _testResult = 'Testing barcode lookup...';
      _testProducts = [];
    });

    try {
      // Test with a known Australian product barcode (Arnott's Tim Tam)
      const testBarcode = '9300605000000';
      
      final product = await AustralianFoodDatabaseService.getProductByBarcodeWithAutoDownload(testBarcode);
      
      if (product != null) {
        setState(() {
          _isLoading = false;
          _testResult = '''
Barcode Lookup Test Results:
- Product Found: Yes
- Name: ${product['name']}
- Brand: ${product['brand']}
- Data Source: ${product['dataSource']}
- Is Australian: ${product['isAustralianProduct']}
        ''';
          _testProducts = [product];
        });
      } else {
        setState(() {
          _isLoading = false;
          _testResult = 'Product not found for barcode: $testBarcode';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _testResult = 'Error testing barcode lookup: $e';
      });
    }
  }

  Future<void> _testAustralianProductDetection() async {
    setState(() {
      _isLoading = true;
      _testResult = 'Testing Australian product detection...';
      _testProducts = [];
    });

    try {
      // Test checking if a product exists in Open Food Facts
      const testBarcode = '9300605000000'; // Arnott's Tim Tam
      
      final checkResult = await AustralianFoodDatabaseService.checkProductExistsInOpenFoodFacts(testBarcode);
      
      setState(() {
        _isLoading = false;
        _testResult = '''
Australian Product Detection Test Results:
- Product Exists: ${checkResult['exists']}
- Is Australian: ${checkResult['isAustralian']}
- Product Name: ${checkResult['productName']}
- Brand: ${checkResult['brand']}
- Status: ${checkResult['status']}
- Message: ${checkResult['message']}
        ''';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _testResult = 'Error testing Australian product detection: $e';
      });
    }
  }
}
