import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'privacy_policy_screen.dart';
import 'terms_screen.dart';
import 'about_developer_screen.dart';

import 'support_screen.dart';


import 'services/location_service.dart';
import 'services/premium_service.dart';
import 'widgets/premium_upgrade_widget.dart';


import 'scan_label_screen.dart';



class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Constants
  static const Color _primaryColor = Color(0xFF4A9E9C);
  static const Duration _animationDuration = Duration(milliseconds: 300);

  // State variables
  bool _isProUser = false;
  bool _notificationsEnabled = true;
  bool _locationEnabled = true;
  String _appVersion = '';
  String _buildNumber = '';
  bool _isLoading = true;
  bool _isSaving = false;

  // Colors (light mode only)
  Color get _textColor => Colors.black;
  Color get _subtitleColor => Colors.black87;

  @override
  void initState() {
    super.initState();
    _initializeSettings();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  Future<void> _initializeSettings() async {
    try {
      await Future.wait([
        _loadSettings(),
        _loadAppVersion(),
      ]);
    } catch (e) {
      _showErrorSnackBar('Failed to load settings');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _appVersion = packageInfo.version;
        _buildNumber = packageInfo.buildNumber;
      });
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final isPremium = await PremiumService.isPremiumUser();

    await prefs.remove('passcode');
    await prefs.remove('passcode_encrypted');
    await prefs.remove('passcode_lock_enabled');
    await prefs.remove('is_passcode_set');
    await prefs.remove('passcode_fail_count');
    await prefs.remove('passcode_lockout_until');
    await prefs.remove('biometric_enabled');

    if (mounted) {
      setState(() {
        _isProUser = isPremium;
        _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
        _locationEnabled = prefs.getBool('location_enabled') ?? true;
      });
    }
  }

  Future<void> _saveSettings() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      await Future.wait([
        prefs.setBool('notifications_enabled', _notificationsEnabled),
        prefs.setBool('location_enabled', _locationEnabled),
      ]);

      if (mounted) {
        _showSuccessSnackBar('Settings saved successfully!');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to save settings');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: _primaryColor,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _showUpgradeDialog() async {
    await PremiumUpgradeWidget.show(context);
  }

  Future<void> _showLocationStatus() async {
    final locationStatus = await LocationService.getLocationStatus();
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Location Services Status',
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.bold,
            color: _textColor,
            fontSize: 20,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusRow(
              'App Setting',
              locationStatus['locationEnabled'] ? 'Enabled' : 'Disabled',
              locationStatus['locationEnabled'] ? Colors.green : Colors.red,
            ),
            _buildStatusRow(
              'Device Services',
              locationStatus['serviceEnabled'] ? 'Enabled' : 'Disabled',
              locationStatus['serviceEnabled'] ? Colors.green : Colors.red,
            ),
            _buildStatusRow(
              'Permission',
              locationStatus['permissionGranted'] ? 'Granted' : 'Denied',
              locationStatus['permissionGranted'] ? Colors.green : Colors.red,
            ),
            _buildStatusRow(
              'Cached Location',
              locationStatus['hasLastLocation'] ? 'Available' : 'Not Available',
              locationStatus['hasLastLocation'] ? Colors.green : Colors.orange,
            ),
            const SizedBox(height: 16),
            Text(
              'Location is requested as “While using the app” only. It is never accessed in the background. Your location is shared with emergency contacts only when you activate emergency features.',
              style: GoogleFonts.nunito(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.nunito(
                color: _primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
    EdgeInsetsGeometry? margin,
  }) {
    return AnimatedContainer(
      duration: _animationDuration,
      margin: margin ?? const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F2F1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              title,
              style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _textColor,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    IconData? icon,
    Widget? trailing,
  }) {
    return ListTile(
      leading: icon != null ? Icon(icon, color: _primaryColor) : null,
      title: Text(
        title,
        style: GoogleFonts.nunito(
          fontSize: 16,
          color: _textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.nunito(
          fontSize: 16,
          color: _subtitleColor,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null) trailing,
          Switch(
            value: value,
            onChanged: onChanged,
            thumbColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return _primaryColor;
              }
              return null;
            }),
          ),
        ],
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    );
  }

  Widget _buildListTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback? onTap,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(icon, color: _primaryColor),
      title: Text(
        title,
        style: GoogleFonts.nunito(
          fontSize: 16,
          color: _textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.nunito(
          fontSize: 16,
          color: _subtitleColor,
        ),
      ),
      trailing: trailing ?? (onTap != null 
        ? const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF4A9E9C)) 
        : null),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
      ),
    );
  }

  Widget _buildStatusRow(String label, String status, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 14,
              color: _textColor,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color),
            ),
            child: Text(
              status,
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.nunito(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 32,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? _buildLoadingIndicator()
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // Account
                  _buildSection(
                    title: 'Account',
                    children: [
                      _buildSwitchTile(
                        title: 'Location',
                        subtitle: 'Share location only while using the app, for emergency calls',
                        value: _locationEnabled,
                        icon: Icons.location_on,
                        onChanged: (value) {
                          setState(() {
                            _locationEnabled = value;
                          });
                          _saveSettings();
                        },
                        trailing: IconButton(
                          icon: const Icon(Icons.info_outline, color: Color(0xFF4A9E9C)),
                          onPressed: _showLocationStatus,
                        ),
                      ),
                      _buildListTile(
                        title: 'Subscription',
                        subtitle: _isProUser ? 'Active Premium Subscription' : 'Basic',
                        icon: Icons.star,
                        onTap: _isProUser ? _showUpgradeDialog : _showUpgradeDialog,
                        trailing: _isProUser 
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.amber,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'PREMIUM',
                                style: GoogleFonts.nunito(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _textColor,
                                ),
                              ),
                            )
                          : Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'FREE',
                                style: GoogleFonts.nunito(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _subtitleColor,
                                ),
                              ),
                            ),
                      ),
                      _buildListTile(
                        title: 'Upgrade',
                        subtitle: 'Upgrade to Premium',
                        icon: Icons.star,
                        onTap: _showUpgradeDialog,
                      ),
                      if (_isProUser)
                        FutureBuilder<int>(
                          future: PremiumService.getDaysRemaining(),
                          builder: (context, snapshot) {
                            final daysRemaining = snapshot.data ?? 0;
                            return _buildListTile(
                              title: 'Subscription Status',
                              subtitle: daysRemaining > 0 
                                ? '$daysRemaining days remaining'
                                : 'Subscription expired',
                              icon: Icons.schedule,
                              onTap: null,
                              trailing: daysRemaining > 0
                                ? Icon(Icons.check_circle, color: Colors.green, size: 20)
                                : Icon(Icons.warning, color: Colors.orange, size: 20),
                            );
                          },
                        ),
                      
                      // Emergency SMS is unlimited for all users
                      _buildListTile(
                        title: 'SMS Usage',
                        subtitle: 'Unlimited SMS available',
                        icon: Icons.sms,
                        onTap: null,
                        trailing: Icon(Icons.check_circle, color: Colors.green, size: 20),
                      ),
                    ],
                  ),

                  // About
                  _buildSection(
                    title: 'About',
                    children: [
                      _buildListTile(
                        title: 'Version',
                        subtitle: '$_appVersion ($_buildNumber)',
                        icon: Icons.info,
                        onTap: null,
                      ),
                      _buildListTile(
                        title: 'About the Developer',
                        subtitle: 'Meet the creator',
                        icon: Icons.person,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AboutDeveloperScreen(),
                          ),
                        ),
                      ),
                      _buildListTile(
                        title: 'Privacy Policy',
                        subtitle: 'Read our privacy policy',
                        icon: Icons.privacy_tip,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PrivacyPolicyScreen(isReadOnly: true),
                          ),
                        ),
                      ),
                      _buildListTile(
                        title: 'Terms and Conditions',
                        subtitle: 'Read our terms and conditions',
                        icon: Icons.description,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TermsScreen(isReadOnly: true),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Support
                  _buildSection(
                    title: 'Support',
                    children: [
                      _buildListTile(
                        title: 'Get help and contact us',
                        subtitle: 'FAQ, user guide, missing products, and email',
                        icon: Icons.support_agent,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SupportScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Save indicator
                  if (_isSaving)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Saving...',
                            style: GoogleFonts.nunito(
                              color: _subtitleColor,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF4A9E9C),
        unselectedItemColor: Colors.grey[600],
        selectedLabelStyle: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: GoogleFonts.nunito(fontSize: 12),
        currentIndex: 0, // Profile is index 0 (first available option since we're on Settings)
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
              Navigator.pushReplacementNamed(context, '/my_allergies');
              break;
            case 4:
              Navigator.pushReplacementNamed(context, '/emergency_contacts');
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
            icon: Icon(Icons.health_and_safety, color: Colors.green),
            label: 'Allergies',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emergency, color: Colors.red),
            label: 'Emergency',
          ),
        ],
      ),
    );
  }
} 
