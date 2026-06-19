import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'services/premium_product_service.dart';
import 'services/premium_service.dart';
import 'widgets/premium_upgrade_widget.dart';

class PremiumProductsScreen extends StatefulWidget {
  const PremiumProductsScreen({super.key});

  @override
  State<PremiumProductsScreen> createState() => _PremiumProductsScreenState();
}

class _PremiumProductsScreenState extends State<PremiumProductsScreen> {
  bool _isLoading = true;
  bool _hasPremium = false;
  String _selectedCategory = 'all';
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final isPremium = await PremiumService.isPremiumUser();
      setState(() {
        _hasPremium = isPremium;
      });

      if (isPremium) {
        final products = await PremiumProductService.getAllPremiumProducts();
        setState(() {
          _products = products;
          _filteredProducts = products;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading premium products: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterProducts() {
    setState(() {
      _filteredProducts = _products.where((product) {
        // Filter by category
        if (_selectedCategory != 'all' && product['category'] != _selectedCategory) {
          return false;
        }

        // Filter by search query
        if (_searchQuery.isNotEmpty) {
          final name = product['name'].toString().toLowerCase();
          final brand = product['brand'].toString().toLowerCase();
          final query = _searchQuery.toLowerCase();
          if (!name.contains(query) && !brand.contains(query)) {
            return false;
          }
        }

        return true;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Premium Products',
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF4A9E9C),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _hasPremium ? _buildPremiumContent() : _buildUpgradePrompt(),
    );
  }

  Widget _buildUpgradePrompt() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4A9E9C), Color(0xFF2E7D7B)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    Icon(
                      LucideIcons.crown,
                      size: 80,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Premium Products',
                      style: GoogleFonts.nunito(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Access our exclusive database of products containing all major allergens. Perfect for testing and training purposes.',
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      child: Column(
                        children: [
                          Text(
                            'Premium Features:',
                            style: GoogleFonts.nunito(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildFeatureItem('🧴 Body Care Products'),
                          _buildFeatureItem('🧴 Skin Care Products'),
                          _buildFeatureItem('🧴 Shampoo & Conditioner'),
                          _buildFeatureItem('🧴 Lotions & Creams'),
                          _buildFeatureItem('☀️ Sunscreen Products'),
                          _buildFeatureItem('🔍 All Major Allergens'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              child: const PremiumUpgradeWidget(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.nunito(
              fontSize: 14,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF4A9E9C),
        ),
      );
    }

    return Column(
      children: [
        // Search and filter section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                                    color: Colors.grey.withValues(alpha: 0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Search bar
              TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                  _filterProducts();
                },
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Category filter
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildCategoryChip('all', 'All Products', '📦'),
                    ...PremiumProductService.getPremiumProductCategories().map(
                      (category) => _buildCategoryChip(
                        category,
                        PremiumProductService.getCategoryDisplayName(category),
                        PremiumProductService.getCategoryIcon(category),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Products list
        Expanded(
          child: _filteredProducts.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = _filteredProducts[index];
                    return _buildProductCard(product);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String category, String displayName, String icon) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon),
            const SizedBox(width: 4),
            Text(displayName),
          ],
        ),
        onSelected: (selected) {
          setState(() {
            _selectedCategory = category;
          });
          _filterProducts();
        },
        selectedColor: const Color(0xFF4A9E9C),
        checkmarkColor: Colors.white,
        backgroundColor: Colors.grey[100],
        side: BorderSide(
          color: isSelected ? const Color(0xFF4A9E9C) : Colors.grey[300]!,
        ),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final allergens = List<String>.from(product['allergens'] ?? []);
    final category = product['category'] as String? ?? 'unknown';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with category icon and name
            Row(
              children: [
                Text(
                  PremiumProductService.getCategoryIcon(category),
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['name'] ?? 'Unknown Product',
                        style: GoogleFonts.nunito(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        product['brand'] ?? 'Unknown Brand',
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A9E9C),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    PremiumProductService.getCategoryDisplayName(category),
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Allergens section
            Text(
              'Contains Allergens:',
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: allergens.map((allergen) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    border: Border.all(color: Colors.red[200]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    allergen,
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: Colors.red[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            // Ingredients preview
            Text(
              'Ingredients (${(product['ingredients'] as List<dynamic>?)?.length ?? 0}):',
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              (product['ingredients'] as List<dynamic>?)?.take(5).join(', ') ?? 'No ingredients listed',
              style: GoogleFonts.nunito(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
                         if (((product['ingredients'] as List<dynamic>?)?.length ?? 0) > 5)
               Text(
                 '... and ${((product['ingredients'] as List<dynamic>?)?.length ?? 0) - 5} more',
                 style: GoogleFonts.nunito(
                   fontSize: 12,
                   color: Colors.grey[500],
                   fontStyle: FontStyle.italic,
                 ),
               ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.search,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No products found',
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filter criteria',
            style: GoogleFonts.nunito(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
} 