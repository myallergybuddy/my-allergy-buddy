import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/australian_food_database_service.dart';

class AustralianDatabaseScreen extends StatefulWidget {
  const AustralianDatabaseScreen({super.key});

  @override
  State<AustralianDatabaseScreen> createState() => _AustralianDatabaseScreenState();
}

class _AustralianDatabaseScreenState extends State<AustralianDatabaseScreen> {
  bool _isLoading = false;
  bool _isDownloading = false;
  List<Map<String, dynamic>> _downloadedProducts = [];
  Map<String, dynamic>? _databaseStats;
  
  // Selected allergens for search
  final Set<String> _selectedAllergens = {};
  
  // Available allergens
  final List<String> _availableAllergens = [
    'peanuts',
    'tree nuts',
    'milk',
    'eggs',
    'soy',
    'wheat',
    'fish',
    'shellfish',
    'sesame',
    'sulfites',
    'mustard',
    'celery',
    'lupin',
    'molluscs',
    'gluten',
    'lactose',
    'casein',
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingDatabase();
  }

  Future<void> _loadExistingDatabase() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final products = await AustralianFoodDatabaseService.loadProductsFromLocalStorage();
      final stats = AustralianFoodDatabaseService.getDatabaseStatistics();
      
      setState(() {
        _downloadedProducts = products;
        _databaseStats = stats;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error loading database: $e');
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadProductsWithAllergens() async {
    if (_selectedAllergens.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one allergen to search for'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isDownloading = true;
    });

    try {
      final result = await AustralianFoodDatabaseService.searchAndDownloadProductsWithAllergens(
        allergens: _selectedAllergens.toList(),
        maxProducts: 500, // Limit to 500 products for performance
        includeCrossContamination: true,
        includeProcessingFacility: true,
      );

      if (result['success']) {
        final products = List<Map<String, dynamic>>.from(result['products']);
        final stats = result['statistics'] as Map<String, dynamic>;
        
        setState(() {
          _downloadedProducts = products;
          _databaseStats = stats;
          _isDownloading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully downloaded ${products.length} products with ${_selectedAllergens.length} allergens'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() {
          _isDownloading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${result['message']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isDownloading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading products: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _clearDatabase() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Database'),
        content: const Text('Are you sure you want to clear all downloaded products? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AustralianFoodDatabaseService.clearDatabase();
      setState(() {
        _downloadedProducts.clear();
        _databaseStats = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Database cleared successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Australian Food Database'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (_downloadedProducts.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _clearDatabase,
              tooltip: 'Clear Database',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Allergen Selection Section
                _buildAllergenSelectionSection(),
                
                // Download Button
                _buildDownloadSection(),
                
                // Statistics Section
                if (_databaseStats != null) _buildStatisticsSection(),
                
                // Products List
                Expanded(child: _buildProductsList()),
              ],
            ),
    );
  }

  Widget _buildAllergenSelectionSection() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Allergens to Search For:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableAllergens.map((allergen) {
                final isSelected = _selectedAllergens.contains(allergen);
                return FilterChip(
                  label: Text(allergen),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedAllergens.add(allergen);
                      } else {
                        _selectedAllergens.remove(allergen);
                      }
                    });
                  },
                  selectedColor: Colors.blue.withValues(alpha: 0.3),
                  checkmarkColor: Colors.blue,
                );
              }).toList(),
            ),
            if (_selectedAllergens.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Selected: ${_selectedAllergens.join(', ')}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isDownloading ? null : _downloadProductsWithAllergens,
              icon: _isDownloading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download),
              label: Text(_isDownloading ? 'Downloading...' : 'Download Products'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'This will search Open Food Facts for Australian products containing the selected allergens',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection() {
    if (_databaseStats == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Database Statistics:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Products',
                    _databaseStats!['totalProducts'].toString(),
                    Icons.inventory,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Allergens Found',
                    _databaseStats!['allergenCounts']?.length.toString() ?? '0',
                    Icons.warning,
                  ),
                ),
              ],
            ),
            if (_databaseStats!['downloadDate'] != null) ...[
              const SizedBox(height: 8),
              Text(
                'Last Updated: ${_databaseStats!['downloadDate']}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildProductsList() {
    if (_downloadedProducts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No products downloaded yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Select allergens and download products to get started',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _downloadedProducts.length,
      itemBuilder: (context, index) {
        final product = _downloadedProducts[index];
        return _buildProductCard(product);
      },
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final detectedAllergens = List<Map<String, dynamic>>.from(product['detectedAllergens'] ?? []);
    final riskAssessment = product['riskAssessment'] as Map<String, dynamic>?;
    final riskLevel = riskAssessment?['riskLevel'] ?? 'Unknown';

    Color riskColor;
    switch (riskLevel.toLowerCase()) {
      case 'high':
        riskColor = Colors.red;
        break;
      case 'medium':
        riskColor = Colors.orange;
        break;
      case 'low':
        riskColor = Colors.green;
        break;
      default:
        riskColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['name'] ?? 'Unknown Product',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product['brand'] ?? 'Unknown Brand',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: riskColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: riskColor),
                  ),
                  child: Text(
                    riskLevel.toUpperCase(),
                    style: GoogleFonts.ptSans(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: riskColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (product['barcode'] != null) ...[
              Text(
                'Barcode: ${product['barcode']}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (detectedAllergens.isNotEmpty) ...[
              const Text(
                'Detected Allergens:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: detectedAllergens.map((allergen) {
                  return Chip(
                    label: Text(
                      allergen['name'],
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: Colors.red.withValues(alpha: 0.2),
                    labelStyle: const TextStyle(color: Colors.red),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
            ],
            if (riskAssessment != null) ...[
              Text(
                'Recommendation: ${riskAssessment['recommendation']}',
                style: TextStyle(
                  fontSize: 14,
                  color: riskColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
} 