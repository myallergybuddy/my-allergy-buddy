import 'package:flutter/material.dart';
import 'scan_label_screen.dart';
import 'scan_history_screen.dart';
import 'profile_screen.dart';
import 'my_allergies_screen.dart';
import 'settings_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'emergency_contacts_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'widgets/premium_upgrade_widget.dart';
import 'services/revenue_cat_service.dart';
import 'widgets/user_guide_prompt.dart';



class HomeScreen extends StatefulWidget {
  final Function(int)? onTabChanged;

  const HomeScreen({super.key, this.onTabChanged});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = '';
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    debugPrint('HomeScreen: initState called');
    _loadUserName();
    _loadPremiumStatus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UserGuidePrompt.showIfNeeded(context);
    });
  }

  Future<void> _loadUserName() async {
    try {
      debugPrint('HomeScreen: Loading user name...');
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString('profile_name') ?? '';
      debugPrint('HomeScreen: User name loaded: $name');
      if (mounted) {
        setState(() {
          _userName = name;
        });
      }
    } catch (e) {
      debugPrint('HomeScreen: Error loading user name: $e');
      if (mounted) {
        setState(() {
          _userName = '';
        });
      }
    }
  }

  Future<void> _loadPremiumStatus() async {
    try {
      debugPrint('HomeScreen: Loading premium status...');
      final isPremium = await RevenueCatService.hasPremiumAccess();
      debugPrint('HomeScreen: Premium status loaded: $isPremium');
      if (mounted) {
        setState(() {
          _isPremium = isPremium;
        });
      }
    } catch (e) {
      debugPrint('HomeScreen: Error loading premium status: $e');
      if (mounted) {
        setState(() {
          _isPremium = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('HomeScreen: build method called');

    // Simple fallback if there are any issues
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'My Allergy Buddy',
              maxLines: 1,
              style: GoogleFonts.nunito(
                color: Colors.teal,
                fontWeight: FontWeight.bold,
                fontSize: 34,
              ),
            ),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 72,
        titleSpacing: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: Text(
                  _userName.isNotEmpty ? 'Welcome Back, $_userName!' : 'Welcome Back!',
                  style: GoogleFonts.nunito(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                  softWrap: true,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'What would you like to do today?',
                style: GoogleFonts.nunito(
                  fontSize: 17,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    const crossAxisCount = 2;
                    const rowCount = 3;
                    const mainAxisSpacing = 6.0;
                    const crossAxisSpacing = 6.0;
                    final gridWidth = constraints.maxWidth * 0.81;
                    final gridHeight = constraints.maxHeight * 0.83;
                    final cellWidth =
                        (gridWidth - crossAxisSpacing) / crossAxisCount;
                    final cellHeight =
                        (gridHeight - mainAxisSpacing * (rowCount - 1)) / rowCount;
                    final aspectRatio = cellWidth / cellHeight;

                    return Align(
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: gridWidth,
                        height: gridHeight,
                        child: GridView.count(
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: crossAxisCount,
                          mainAxisSpacing: mainAxisSpacing,
                          crossAxisSpacing: crossAxisSpacing,
                          childAspectRatio: aspectRatio,
                          children: [
                    _buildMenuCard(
                      context,
                      'Scan a Label',
                      Icons.label_important,
                      Colors.blue,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ScanLabelScreen()),
                      ),
                      isPro: false,
                    ),

                    _buildMenuCard(
                      context,
                      'Profile',
                      Icons.person,
                      Colors.teal,
                      () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ProfileScreen()),
                        );
                        // Refresh the user name when returning from profile
                        _loadUserName();
                      },
                      isPro: false,
                    ),
                    _buildMenuCard(
                      context,
                      'My Allergies',
                      Icons.health_and_safety,
                      Colors.green,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const MyAllergiesScreen()),
                      ),
                      isPro: false,
                    ),
                    _buildMenuCard(
                      context,
                      'Emergency Contacts',
                      Icons.emergency,
                      Colors.red,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EmergencyContactsScreen(),
                        ),
                      ),
                      isPro: false,
                    ),
                    _buildMenuCard(
                      context,
                      'Settings',
                      Icons.settings,
                      Colors.purple,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SettingsScreen()),
                      ),
                      isPro: false,
                    ),
                    _buildMenuCard(
                      context,
                      'Scan History',
                      Icons.history,
                      Colors.orange,
                      () {
                        if (_isPremium) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ScanHistoryScreen()),
                          );
                        } else {
                          showDialog(
                            context: context,
                            builder: (context) => Dialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Container(
                                constraints: BoxConstraints(
                                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Header
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF4A9E9C).withValues(alpha: 0.1),
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(16),
                                          topRight: Radius.circular(16),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.history,
                                            color: const Color(0xFF4A9E9C),
                                            size: 24,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              'Upgrade to Premium',
                                              style: GoogleFonts.nunito(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                                fontSize: 18,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: () => Navigator.pop(context),
                                            icon: const Icon(Icons.close),
                                            color: Colors.grey[600],
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Scrollable content
                                    Flexible(
                                      child: SingleChildScrollView(
                                        padding: const EdgeInsets.all(20),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Scan History is a Premium feature. Upgrade to view your complete scan history and advanced analytics.',
                                              style: GoogleFonts.nunito(
                                                fontSize: 16,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 20),
                                            const PremiumUpgradeWidget(),
                                          ],
                                        ),
                                      ),
                                    ),
                                    // Footer with action button
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: const BorderRadius.only(
                                          bottomLeft: Radius.circular(16),
                                          bottomRight: Radius.circular(16),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: Text(
                                              'Maybe Later',
                                              style: GoogleFonts.nunito(
                                                color: Colors.grey[600],
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
                      },
                      isPro: true,
                    ),
                      ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => Dialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Container(
                          constraints: const BoxConstraints(
                            maxWidth: 450,
                            maxHeight: 700,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Text(
                                  'Upgrade to Premium',
                                  style: GoogleFonts.nunito(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: const PremiumUpgradeWidget(),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text(
                                        'Maybe Later',
                                        style: GoogleFonts.nunito(
                                          color: Colors.grey[600],
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
                  },
                icon: const Icon(Icons.star, color: Colors.amber, size: 22),
                label: Text(
                  'Upgrade to Premium',
                  style: GoogleFonts.nunito(
                    color: Colors.amber,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    shadows: const [
                      Shadow(
                        color: Colors.black,
                        offset: Offset(0, 0),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    required bool isPro,
  }) {
    // Helper function to get display title
    String getDisplayTitle(String originalTitle) {
      switch (originalTitle) {
        case 'Emergency Contacts':
          return 'Emergency\nContacts';
        case 'Scan History':
          return 'Scan\nHistory';
        default:
          return originalTitle;
      }
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.7),
                color,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(6.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: Colors.white,
                ),
                const SizedBox(height: 4),
                Text(
                  getDisplayTitle(title),
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                if (isPro) ...[
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.white, size: 9),
                        const SizedBox(width: 2),
                        Text(
                          'Premium',
                          style: GoogleFonts.nunito(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}