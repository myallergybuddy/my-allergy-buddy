import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'allergy_selection_screen.dart';
import 'widgets/premium_upgrade_widget.dart';
import 'scan_label_screen.dart';
import 'services/revenue_cat_service.dart';


class MyAllergiesScreen extends StatefulWidget {
  const MyAllergiesScreen({super.key});

  @override
  State<MyAllergiesScreen> createState() => _MyAllergiesScreenState();
}

class _MyAllergiesScreenState extends State<MyAllergiesScreen> {
  List<Map<String, dynamic>> _allergies = [];
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _loadAllergies();
    _loadPremiumStatus();
  }

  Future<void> _loadAllergies() async {
    final prefs = await SharedPreferences.getInstance();
    final allergiesJson = prefs.getStringList('saved_allergies') ?? [];
    
    setState(() {
      _allergies = allergiesJson
          .map((json) => Map<String, dynamic>.from(jsonDecode(json)))
          .toList();
    });
  }

  Future<void> _loadPremiumStatus() async {
    final isPremium = await RevenueCatService.hasPremiumAccess();
    setState(() {
      _isPremium = isPremium;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'My Allergies',
          style: GoogleFonts.nunito(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 32,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Allergies List Header with Add Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Allergies',
                        style: GoogleFonts.nunito(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      if (_isPremium)
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'Premium - Full allergen access',
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                color: Colors.amber[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  _buildEditButton(
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AllergySelectionScreen(isPro: _isPremium),
                        ),
                      );

                      if (result != null) {
                        _loadAllergies();
                        _loadPremiumStatus();
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Allergies List
              Expanded(
                child: ListView.builder(
                  itemCount: _allergies.length,
                  itemBuilder: (context, index) {
                    final allergy = _allergies[index];
                    Color severityColor;
                    switch (allergy['severity']) {
                      case 'High':
                        severityColor = Colors.red;
                        break;
                      case 'Medium':
                        severityColor = Colors.orange;
                        break;
                      case 'Low':
                        severityColor = Colors.yellow[700]!;
                        break;
                      default:
                        severityColor = Colors.grey;
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2F1),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            title: Text(
                              allergy['name'],
                              style: GoogleFonts.nunito(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 3),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 3,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: severityColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        allergy['severity'],
                                        style: GoogleFonts.nunito(
                                          color: severityColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF4A9E9C).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        allergy['category'],
                                        style: GoogleFonts.nunito(
                                          color: const Color(0xFF4A9E9C),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                if (allergy['notes'] != null && allergy['notes'].isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    allergy['notes'],
                                    style: GoogleFonts.nunito(
                                      color: Colors.black87,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              
              // Premium Upgrade Section
              if (!_isPremium) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                                                  Colors.amber.withValues(alpha: 0.1),
                                                  Colors.orange.withValues(alpha: 0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                                              color: Colors.amber.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            'Unlock Premium Allergens',
                            style: GoogleFonts.nunito(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Access 100+ additional allergens including rare food items.',
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 48,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text(
                                        'Upgrade to Premium',
                                        style: GoogleFonts.nunito(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Upgrade to Premium to access 100+ additional allergens and advanced features.',
                                            style: GoogleFonts.nunito(
                                              fontSize: 16,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          const PremiumUpgradeWidget(),
                                        ],
                                      ),
                                      actions: [
                                        SizedBox(
                                          height: 48,
                                          child: TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            style: TextButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                            ),
                                            child: Text(
                                              'Maybe Later',
                                              style: GoogleFonts.nunito(
                                                color: Colors.grey[600],
                                                fontWeight: FontWeight.w600,
                                                fontSize: 18,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                );
                              },
                              icon: const Icon(Icons.star, color: Colors.white, size: 16),
                              label: Text(
                                'Upgrade to Premium',
                                style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                    fontSize: 18,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber,
                                foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF4A9E9C),
        unselectedItemColor: Colors.grey[600],
        selectedLabelStyle: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: GoogleFonts.nunito(fontSize: 12),
        currentIndex: 0, // Profile is index 0 (first available option since we're on Allergies)
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
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ScanLabelScreen()),
              );
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
            icon: Icon(Icons.person, color: Colors.teal),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner, color: Colors.blue),
            label: 'Scan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home, color: Color(0xFF4A9E9C)),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emergency, color: Colors.red),
            label: 'Emergency',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings, color: Colors.purple),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildEditButton({
    required VoidCallback onTap,
    String label = 'Edit',
    IconData icon = Icons.edit,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF4A9E9C),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A9E9C).withValues(alpha: 0.25),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 12),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


