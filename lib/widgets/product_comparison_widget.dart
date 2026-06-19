import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../models/enhanced_scan_result.dart';

class ProductComparisonWidget extends StatefulWidget {
  final List<EnhancedScanResult> products;

  const ProductComparisonWidget({
    super.key,
    required this.products,
  });

  @override
  State<ProductComparisonWidget> createState() => _ProductComparisonWidgetState();
}

class _ProductComparisonWidgetState extends State<ProductComparisonWidget> {
  int selectedProductIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.products.isEmpty) {
      return const Center(
        child: Text('No products to compare'),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Product Comparison',
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: const Color(0xFF4A9E9C),
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.download),
            onPressed: _exportComparison,
            tooltip: 'Export Comparison',
          ),
        ],
      ),
      body: Column(
        children: [
          // Product selector
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Product to View Details',
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: widget.products.asMap().entries.map((entry) {
                      final index = entry.key;
                      final product = entry.value;
                      
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedProductIndex = index;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: selectedProductIndex == index
                                ? const Color(0xFF4A9E9C)
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selectedProductIndex == index
                                  ? const Color(0xFF4A9E9C)
                                  : Colors.grey[300]!,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                product.productName.length > 20
                                    ? '${product.productName.substring(0, 20)}...'
                                    : product.productName,
                                style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.bold,
                                  color: selectedProductIndex == index
                                      ? Colors.white
                                      : Colors.black,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: selectedProductIndex == index
                                      ? Colors.white
                                      : _getRiskLevelColor(product.riskLevel),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  product.riskLevel.toUpperCase(),
                                  style: GoogleFonts.nunito(
                                    color: selectedProductIndex == index
                                        ? const Color(0xFF4A9E9C)
                                        : Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Comparison table
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Basic information comparison
                  _buildComparisonSection(
                    'Basic Information',
                    [
                      'Product Name',
                      'Brand',
                      'Barcode',
                      'Scan Date',
                      'Data Source',
                    ],
                    widget.products.map((product) => [
                      product.productName,
                      product.brand,
                      product.barcode,
                      _formatDate(product.scanDate),
                      product.dataSourceDescription,
                    ]).toList(),
                  ),

                  // Safety comparison
                  _buildComparisonSection(
                    'Safety Assessment',
                    [
                      'Overall Safety',
                      'Risk Level',
                      'Confidence Score',
                      'Safety Recommendation',
                    ],
                    widget.products.map((product) => [
                      product.isSafe ? 'Safe' : 'Unsafe',
                      product.riskLevel.toUpperCase(),
                      '${(product.confidenceScore * 100).toStringAsFixed(1)}%',
                      product.safetyRecommendation,
                    ]).toList(),
                  ),

                  // Allergen comparison
                  _buildAllergenComparison(),

                  // Cross-contamination comparison
                  _buildCrossContaminationComparison(),

                  // Processing facility comparison
                  _buildProcessingFacilityComparison(),

                  // Detailed product information
                  _buildDetailedProductInfo(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonSection(
    String title,
    List<String> fields,
    List<List<String>> values,
  ) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF4A9E9C),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.compare, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: [
                DataColumn(
                  label: Text(
                    'Field',
                    style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
                  ),
                ),
                ...widget.products.asMap().entries.map((entry) {
                  final product = entry.value;
                  return DataColumn(
                    label: Container(
                      constraints: const BoxConstraints(maxWidth: 120),
                      child: Column(
                        children: [
                          Text(
                            product.productName.length > 15
                                ? '${product.productName.substring(0, 15)}...'
                                : product.productName,
                            style: GoogleFonts.nunito(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getRiskLevelColor(product.riskLevel),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              product.riskLevel.toUpperCase(),
                              style: GoogleFonts.nunito(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
              rows: fields.asMap().entries.map((entry) {
                final fieldIndex = entry.key;
                final field = entry.value;
                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        field,
                        style: GoogleFonts.nunito(fontWeight: FontWeight.w500),
                      ),
                    ),
                    ...values.map((productValues) => DataCell(
                      Container(
                        constraints: const BoxConstraints(maxWidth: 120),
                        child: Text(
                          productValues[fieldIndex],
                          style: GoogleFonts.nunito(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllergenComparison() {
    // Get all unique allergens across all products
    final allAllergens = <String>{};
    for (final product in widget.products) {
      for (final allergen in product.detectedAllergens) {
        allAllergens.add(allergen['name'] as String);
      }
    }

    if (allAllergens.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            Text(
              'No allergens detected in any of the compared products',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Allergen Comparison',
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: [
                DataColumn(
                  label: Text(
                    'Allergen',
                    style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
                  ),
                ),
                ...widget.products.map((product) => DataColumn(
                  label: Container(
                    constraints: const BoxConstraints(maxWidth: 100),
                    child: Text(
                      product.productName.length > 12
                          ? '${product.productName.substring(0, 12)}...'
                          : product.productName,
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )),
              ],
              rows: allAllergens.map((allergen) {
                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        allergen,
                        style: GoogleFonts.nunito(fontWeight: FontWeight.w500),
                      ),
                    ),
                    ...widget.products.map((product) {
                      final detectedAllergen = product.detectedAllergens
                          .where((a) => a['name'] == allergen)
                          .firstOrNull;
                      
                      if (detectedAllergen != null) {
                        return DataCell(
                          Container(
                            constraints: const BoxConstraints(maxWidth: 100),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _getSeverityColor(detectedAllergen['severity']),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    detectedAllergen['severity'],
                                    style: GoogleFonts.nunito(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${(detectedAllergen['confidence'] * 100).toStringAsFixed(0)}%',
                                  style: GoogleFonts.nunito(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      } else {
                        return const DataCell(
                          Icon(Icons.check, color: Colors.green, size: 16),
                        );
                      }
                    }),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCrossContaminationComparison() {
    final allWarnings = <String>{};
    for (final product in widget.products) {
      for (final warning in product.crossContaminationWarnings) {
        allWarnings.add(warning['allergen'] as String);
      }
    }

    if (allWarnings.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            Text(
              'No cross-contamination warnings in any of the compared products',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Cross-Contamination Comparison',
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: [
                DataColumn(
                  label: Text(
                    'Allergen',
                    style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
                  ),
                ),
                ...widget.products.map((product) => DataColumn(
                  label: Container(
                    constraints: const BoxConstraints(maxWidth: 100),
                    child: Text(
                      product.productName.length > 12
                          ? '${product.productName.substring(0, 12)}...'
                          : product.productName,
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )),
              ],
              rows: allWarnings.map((allergen) {
                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        allergen,
                        style: GoogleFonts.nunito(fontWeight: FontWeight.w500),
                      ),
                    ),
                    ...widget.products.map((product) {
                      final warning = product.crossContaminationWarnings
                          .where((w) => w['allergen'] == allergen)
                          .firstOrNull;
                      
                      if (warning != null) {
                        return DataCell(
                          Container(
                            constraints: const BoxConstraints(maxWidth: 100),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _getRiskLevelColor(warning['riskLevel']),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    warning['riskLevel'],
                                    style: GoogleFonts.nunito(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Text(
                                  warning['message'],
                                  style: GoogleFonts.nunito(
                                    fontSize: 8,
                                    color: Colors.grey[600],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      } else {
                        return const DataCell(
                          Icon(Icons.check, color: Colors.green, size: 16),
                        );
                      }
                    }),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingFacilityComparison() {
    final allWarnings = <String>{};
    for (final product in widget.products) {
      for (final warning in product.processingFacilityWarnings) {
        allWarnings.add(warning['allergen'] as String);
      }
    }

    if (allWarnings.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            Text(
              'No processing facility warnings in any of the compared products',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.yellow,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.business, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Processing Facility Comparison',
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: [
                DataColumn(
                  label: Text(
                    'Allergen',
                    style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
                  ),
                ),
                ...widget.products.map((product) => DataColumn(
                  label: Container(
                    constraints: const BoxConstraints(maxWidth: 100),
                    child: Text(
                      product.productName.length > 12
                          ? '${product.productName.substring(0, 12)}...'
                          : product.productName,
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )),
              ],
              rows: allWarnings.map((allergen) {
                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        allergen,
                        style: GoogleFonts.nunito(fontWeight: FontWeight.w500),
                      ),
                    ),
                    ...widget.products.map((product) {
                      final warning = product.processingFacilityWarnings
                          .where((w) => w['allergen'] == allergen)
                          .firstOrNull;
                      
                      if (warning != null) {
                        return DataCell(
                          Container(
                            constraints: const BoxConstraints(maxWidth: 100),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _getRiskLevelColor(warning['riskLevel']),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    warning['riskLevel'],
                                    style: GoogleFonts.nunito(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Text(
                                  warning['message'],
                                  style: GoogleFonts.nunito(
                                    fontSize: 8,
                                    color: Colors.grey[600],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      } else {
                        return const DataCell(
                          Icon(Icons.check, color: Colors.green, size: 16),
                        );
                      }
                    }),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedProductInfo() {
    final selectedProduct = widget.products[selectedProductIndex];
    
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF4A9E9C),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.info, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Detailed Information: ${selectedProduct.productName}',
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Analysis Method', selectedProduct.analysisMethod),
                _buildInfoRow('Confidence Score', '${(selectedProduct.confidenceScore * 100).toStringAsFixed(1)}%'),
                _buildInfoRow('Processing Time', selectedProduct.processingTimeDescription),
                _buildInfoRow('Data Source', selectedProduct.dataSourceDescription),
                if (selectedProduct.isFromCache && selectedProduct.cacheAge != null)
                  _buildInfoRow('Cache Age', selectedProduct.cacheAge!),
                _buildInfoRow('Scan Date', _formatDate(selectedProduct.scanDate)),
                _buildInfoRow('Barcode', selectedProduct.barcode),
                const SizedBox(height: 16),
                Text(
                  'Ingredients (${selectedProduct.ingredients.length})',
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: selectedProduct.ingredients.map((ingredient) {
                    final isAllergen = selectedProduct.detectedAllergens.any((allergen) =>
                        allergen['matchedIngredient'] == ingredient);
                    
                    return Container(
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
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.nunito(),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRiskLevelColor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.yellow;
      default:
        return Colors.green;
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _exportComparison() {
    // TODO: Implement export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Export functionality coming soon!',
          style: GoogleFonts.nunito(),
        ),
        backgroundColor: const Color(0xFF4A9E9C),
      ),
    );
  }
} 