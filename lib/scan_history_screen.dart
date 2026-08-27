import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'models/enhanced_scan_result.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/premium_upgrade_widget.dart';
import 'widgets/product_comparison_widget.dart';
import 'services/firebase_service.dart';
import 'services/revenue_cat_service.dart';

class ScanHistoryScreen extends StatefulWidget {
  const ScanHistoryScreen({super.key});

  @override
  State<ScanHistoryScreen> createState() => _ScanHistoryScreenState();
}

class _ScanHistoryScreenState extends State<ScanHistoryScreen> {
  List<EnhancedScanResult> scanHistory = [];
  bool _isPremium = false;
  bool _isLoading = true;
  String _searchQuery = '';
  String _filterRiskLevel = 'all';
  String _filterSafety = 'all';

  @override
  void initState() {
    super.initState();
    _loadPremiumStatus();
    _loadScanHistory();
  }

  Future<void> _loadPremiumStatus() async {
    final isPremium = await RevenueCatService.hasPremiumAccess();
    setState(() {
      _isPremium = isPremium;
    });
  }

  Future<void> _loadScanHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
    final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList('enhanced_scan_history') ?? [];
    
    final history = historyJson
          .map((json) {
            try {
              return EnhancedScanResult.fromJsonString(json);
            } catch (e) {
              // Skip invalid entries
              return null;
            }
          })
          .where((result) => result != null)
          .cast<EnhancedScanResult>()
        .toList();
    
    // Sort by date, most recent first
    history.sort((a, b) => b.scanDate.compareTo(a.scanDate));

    setState(() {
      scanHistory = history;
        _isLoading = false;
    });
    
    // Log scan history view
    await FirebaseService.logScanHistoryView(
      totalScans: history.length,
      hasAllergens: history.any((scan) => scan.detectedAllergens.isNotEmpty),
    );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteHistoryItem(EnhancedScanResult item) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList('enhanced_scan_history') ?? [];
    
    // Remove the item
    final updatedHistory = historyJson.where((json) {
      try {
        final result = EnhancedScanResult.fromJsonString(json);
        return result.barcode != item.barcode || result.scanDate != item.scanDate;
      } catch (e) {
        return true; // Keep valid entries
      }
    }).toList();
    
    await prefs.setStringList('enhanced_scan_history', updatedHistory);
    
    setState(() {
      scanHistory.remove(item);
    });
  }

  Future<void> _clearAllHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Clear Scan History',
          style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete all scan history? This action cannot be undone.',
          style: GoogleFonts.nunito(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.nunito(),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Clear All',
              style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('enhanced_scan_history');
      
      setState(() {
        scanHistory.clear();
      });
    }
  }

  List<EnhancedScanResult> get _filteredHistory {
    return scanHistory.where((scan) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesSearch = scan.productName.toLowerCase().contains(query) ||
            scan.brand.toLowerCase().contains(query) ||
            scan.barcode.contains(query);
        if (!matchesSearch) return false;
      }

      // Risk level filter
      if (_filterRiskLevel != 'all') {
        if (scan.riskLevel.toLowerCase() != _filterRiskLevel) return false;
      }

      // Safety filter
      if (_filterSafety != 'all') {
        if (_filterSafety == 'safe' && !scan.isSafe) return false;
        if (_filterSafety == 'unsafe' && scan.isSafe) return false;
      }

      return true;
    }).toList();
  }

  void _showProductComparison() {
    if (scanHistory.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Need at least 2 products to compare',
            style: GoogleFonts.nunito(),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductComparisonWidget(
          products: scanHistory,
        ),
      ),
    );
  }

  void _showProductDetails(EnhancedScanResult scan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Product Details',
          style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
              _buildDetailRow('Product', scan.productName),
              _buildDetailRow('Brand', scan.brand),
              _buildDetailRow('Barcode', scan.barcode),
              _buildDetailRow('Scan Date', _formatDate(scan.scanDate)),
              _buildDetailRow('Data Source', scan.dataSourceDescription),
              _buildDetailRow('Analysis Method', scan.analysisMethod),
              _buildDetailRow('Processing Time', scan.processingTimeDescription),
              _buildDetailRow('Confidence Score', '${(scan.confidenceScore * 100).toStringAsFixed(1)}%'),
              _buildDetailRow('Risk Level', scan.riskLevel.toUpperCase()),
              _buildDetailRow('Safety', scan.isSafe ? 'Safe' : 'Unsafe'),
              _buildDetailRow('Allergen Summary', scan.allergenSummary),
              _buildDetailRow('Warnings Summary', scan.warningsSummary),
              _buildDetailRow('Safety Recommendation', scan.safetyRecommendation),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.nunito(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
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

  @override
  Widget build(BuildContext context) {
    if (!_isPremium) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          title: Text(
            'Scan History',
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          centerTitle: true,
          backgroundColor: const Color(0xFF4A9E9C),
          foregroundColor: Colors.black,
        ),
        body: const Center(
          child: PremiumUpgradeWidget(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Scan History',
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF4A9E9C),
        foregroundColor: Colors.black,
        actions: [
          if (scanHistory.length >= 2)
            IconButton(
              icon: const Icon(Icons.compare),
              onPressed: _showProductComparison,
              tooltip: 'Compare Products',
            ),
          if (scanHistory.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _clearAllHistory,
              tooltip: 'Clear All History',
            ),
        ],
      ),
      body: Column(
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
                  blurRadius: 5,
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
                  },
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    prefixIcon: const Icon(LucideIcons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
                const SizedBox(height: 12),
                
                // Filters
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _filterRiskLevel,
                        decoration: InputDecoration(
                          labelText: 'Risk Level',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        items: [
                          DropdownMenuItem(value: 'all', child: Text('All Risk Levels')),
                          DropdownMenuItem(value: 'high', child: Text('High Risk')),
                          DropdownMenuItem(value: 'medium', child: Text('Medium Risk')),
                          DropdownMenuItem(value: 'low', child: Text('Low Risk')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _filterRiskLevel = value!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _filterSafety,
                        decoration: InputDecoration(
                          labelText: 'Safety',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        items: [
                          DropdownMenuItem(value: 'all', child: Text('All Products')),
                          DropdownMenuItem(value: 'safe', child: Text('Safe Only')),
                          DropdownMenuItem(value: 'unsafe', child: Text('Unsafe Only')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _filterSafety = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Statistics
          if (_filteredHistory.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Scans',
                      _filteredHistory.length.toString(),
                      LucideIcons.scan,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                                         child: _buildStatCard(
                       'Safe Products',
                       _filteredHistory.where((s) => s.isSafe).length.toString(),
                       Icons.check_circle,
                       Colors.green,
                     ),
                   ),
                   const SizedBox(width: 12),
                   Expanded(
                     child: _buildStatCard(
                       'High Risk',
                       _filteredHistory.where((s) => s.riskLevel == 'high').length.toString(),
                       Icons.warning,
                       Colors.red,
                     ),
                  ),
                ],
              ),
            ),

          // Scan history list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A9E9C)),
                    ),
                  )
                : _filteredHistory.isEmpty
                    ? Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.clock,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
                              _searchQuery.isNotEmpty || _filterRiskLevel != 'all' || _filterSafety != 'all'
                                  ? 'No products match your filters'
                                  : 'No scan history yet',
            style: GoogleFonts.nunito(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
                              'Start scanning products to build your history',
            style: GoogleFonts.nunito(
              color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredHistory.length,
                        itemBuilder: (context, index) {
                          final scan = _filteredHistory[index];
                          return _buildScanHistoryItem(scan);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
              padding: const EdgeInsets.all(16),
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
                children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
                  Text(
            value,
                    style: GoogleFonts.nunito(
              fontSize: 20,
                      fontWeight: FontWeight.bold,
              color: color,
                    ),
                  ),
                  Text(
            title,
                    style: GoogleFonts.nunito(
              fontSize: 12,
              color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
        ],
      ),
    );
  }

  Widget _buildScanHistoryItem(EnhancedScanResult scan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: scan.isSafe ? Colors.green[100] : Colors.red[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            scan.isSafe ? Icons.check_circle : Icons.warning,
            color: scan.isSafe ? Colors.green : Colors.red,
          ),
        ),
        title: Text(
          scan.productName,
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              scan.brand,
              style: GoogleFonts.nunito(
                color: Colors.grey[600],
              ),
            ),
              const SizedBox(height: 4),
            Row(
              children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: _getRiskLevelColor(scan.riskLevel),
                    borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                    scan.riskLevel.toUpperCase(),
                  style: GoogleFonts.nunito(
                      color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
                const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${(scan.confidenceScore * 100).toStringAsFixed(0)}%',
                    style: GoogleFonts.nunito(
                      color: Colors.blue[700],
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              scan.allergenSummary,
              style: GoogleFonts.nunito(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            if (scan.hasCrossContaminationRisks) ...[
              const SizedBox(height: 4),
              Text(
                scan.warningsSummary,
                style: GoogleFonts.nunito(
                  color: Colors.orange[600],
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              _formatDate(scan.scanDate),
              style: GoogleFonts.nunito(
                color: Colors.grey[500],
                fontSize: 11,
            ),
          ),
        ],
      ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'details':
                _showProductDetails(scan);
              break;
              case 'delete':
                _deleteHistoryItem(scan);
              break;
          }
        },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'details',
              child: Row(
                children: [
                  Icon(LucideIcons.info, size: 16),
                  const SizedBox(width: 8),
                  Text('View Details', style: GoogleFonts.nunito()),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                                 children: [
                   Icon(Icons.delete, size: 16, color: Colors.red),
                   const SizedBox(width: 8),
                   Text('Delete', style: GoogleFonts.nunito(color: Colors.red)),
                 ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 