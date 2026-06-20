import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../services/revenue_cat_service.dart';

class PremiumUpgradeWidget extends StatefulWidget {
  final VoidCallback? onUpgradeComplete;

  const PremiumUpgradeWidget({super.key, this.onUpgradeComplete});

  @override
  State<PremiumUpgradeWidget> createState() => _PremiumUpgradeWidgetState();
}

class _PremiumUpgradeWidgetState extends State<PremiumUpgradeWidget> {
  bool _isLoading = false;
  bool _hasPremium = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _products = [];
  bool _showSubscriptionOptions = false;

  @override
  void initState() {
    super.initState();
    debugPrint('PremiumUpgradeWidget initState called');
    _checkPremiumStatus();
    _loadProducts();
  }

  Future<void> _checkPremiumStatus() async {
    final hasPremium = await RevenueCatService.hasPremiumAccess();
    setState(() {
      _hasPremium = hasPremium;
    });
  }

  Future<void> _loadProducts() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final products = await RevenueCatService.getProducts();
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load products: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _purchaseProduct(Map<String, dynamic> product) async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final success = await RevenueCatService.purchaseProduct(product);
      
      if (success != null && success['hasPremium'] == true) {
        await _checkPremiumStatus();
        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Premium upgrade successful!'),
              backgroundColor: const Color(0xFF4A9E9C),
            ),
          );
        }

        widget.onUpgradeComplete?.call();
      } else {
        setState(() {
          _errorMessage = 'Purchase failed. Please try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Purchase error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _restorePurchases() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final customerInfo = await RevenueCatService.restorePurchases();
      
      if (customerInfo != null && customerInfo['hasPremium'] == true) {
        await _checkPremiumStatus();
        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Purchases restored successfully!'),
              backgroundColor: const Color(0xFF4A9E9C),
            ),
          );
        }

        widget.onUpgradeComplete?.call();
      } else {
        setState(() {
          _errorMessage = customerInfo != null
              ? 'No active premium subscription found.'
              : 'No purchases found to restore.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Restore error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('PremiumUpgradeWidget build: _hasPremium=$_hasPremium, _showSubscriptionOptions=$_showSubscriptionOptions');
    
    if (_hasPremium) {
      return _buildPremiumActiveCard();
    }

    if (_showSubscriptionOptions) {
      return _buildSubscriptionScreen();
    }

    return _buildFeaturesScreen();
  }

  Widget _buildFeaturesScreen() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A9E9C).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      LucideIcons.crown,
                      color: const Color(0xFF4A9E9C),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Upgrade to Premium',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF4A9E9C),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A9E9C).withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF4A9E9C).withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Premium Features:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF4A9E9C),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildFeatureItem('10 Emergency Contacts'),
                    _buildFeatureItem('Advanced Allergen Database'),
                    _buildFeatureItem('Priority Customer Support'),
                    _buildFeatureItem('Scan History'),
                  ],
                ),
                              ),
                const SizedBox(height: 12),
                SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _showSubscriptionOptions = true;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A9E9C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                  child: Text(
                    'Choose Plan',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                              ),
                const SizedBox(height: 8),
                SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _restorePurchases,
                  icon: Icon(Icons.refresh, color: const Color(0xFF4A9E9C)),
                  label: Text(
                    'Restore Purchases',
                    style: TextStyle(color: const Color(0xFF4A9E9C)),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    side: BorderSide(color: const Color(0xFF4A9E9C)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionScreen() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 500),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _showSubscriptionOptions = false;
                      });
                    },
                    icon: Icon(
                      Icons.arrow_back,
                      color: const Color(0xFF4A9E9C),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A9E9C).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      LucideIcons.crown,
                      color: const Color(0xFF4A9E9C),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Choose Your Plan',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF4A9E9C),
                      ),
                    ),
                  ),
                ],
                              ),
                const SizedBox(height: 12),
                if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_products.isNotEmpty) ...[
                ..._products.map((product) => _buildSubscriptionCard(product)),
              ] else if (_isLoading) ...[
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A9E9C)),
                    ),
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text('No subscription plans available'),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _restorePurchases,
                  icon: Icon(Icons.refresh, color: const Color(0xFF4A9E9C)),
                  label: Text(
                    'Restore Purchases',
                    style: TextStyle(color: const Color(0xFF4A9E9C)),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    side: BorderSide(color: const Color(0xFF4A9E9C)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
  
  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF4A9E9C).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              LucideIcons.check,
              color: const Color(0xFF4A9E9C),
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard(Map<String, dynamic> product) {
    final id = product['identifier']?.toString() ?? '';
    final isPopular = id.contains('yearly');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: isPopular ? const Color(0xFF4A9E9C) : Colors.grey.shade300,
          width: isPopular ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
        color: isPopular ? const Color(0xFF4A9E9C).withValues(alpha: 0.05) : null,
      ),
      child: InkWell(
        onTap: _isLoading ? null : () => _purchaseProduct(product),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product['title'] ?? 'Premium Plan',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isPopular) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4A9E9C),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'POPULAR',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product['description'] ?? '',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    product['priceString'] ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF4A9E9C),
                    ),
                  ),
                  if (product['priceString']?.toString().contains('week') == true)
                    Text(
                      'per week',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    )
                  else if (product['priceString']?.toString().contains('month') == true)
                    Text(
                      'per month',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    )
                  else if (product['priceString']?.toString().contains('year') == true)
                    Text(
                      'per year',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumActiveCard() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A9E9C).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      LucideIcons.crown,
                      color: const Color(0xFF4A9E9C),
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Premium Active',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF4A9E9C),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A9E9C).withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF4A9E9C).withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A9E9C).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.check_circle,
                        color: const Color(0xFF4A9E9C),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You have access to all premium features!',
                        style: TextStyle(
                          color: const Color(0xFF4A9E9C),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 
