import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() => _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState extends State<NotificationsSettingsScreen> {
  late SharedPreferences _prefs;
  bool _isLoading = true;

  // Notification settings
  bool _emergencyAlerts = true;
  bool _medicationExpiry = true;
  bool _appUpdates = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'emergency':
        return Icons.warning;
      case 'medication':
        return Icons.medication;
      case 'scan':
        return Icons.qr_code_scanner;
      case 'reminder':
        return Icons.alarm;
      case 'update':
        return Icons.system_update;
      default:
        return Icons.notifications;
    }
  }

  Future<void> _loadNotificationSettings() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      
      setState(() {
        _emergencyAlerts = _prefs.getBool('emergency_alerts') ?? true;
        _medicationExpiry = _prefs.getBool('medication_expiry') ?? true;
        _appUpdates = _prefs.getBool('app_updates') ?? true;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading notification settings: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveNotificationSetting(String key, bool value) async {
    try {
      await _prefs.setBool(key, value);
      debugPrint('Saved notification setting: $key = $value');
    } catch (e) {
      debugPrint('Error saving notification setting: $e');
    }
  }

  Future<void> _updateNotificationSetting(String key, bool value) async {
    await _saveNotificationSetting(key, value);
    
    // Show feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value ? 'Notifications enabled' : 'Notifications disabled'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildNotificationTile({
    required String title,
    required String description,
    required String icon,
    required bool value,
    required String settingKey,
    required Color iconColor,
    bool isEmergency = false,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isEmergency 
            ? BorderSide(color: Colors.red.withValues(alpha: 0.3), width: 1)
            : BorderSide.none,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getIconData(icon),
            color: iconColor,
            size: 24,
          ),
        ),
        title: Text(
          title,
           style: GoogleFonts.nunito(
             fontWeight: FontWeight.bold,
             fontSize: 18,
             color: isEmergency ? Colors.red : Colors.black87,
          ),
        ),
        subtitle: Text(
          description,
           style: GoogleFonts.nunito(
             fontSize: 16,
             color: Colors.black54,
          ),
        ),
        trailing: Switch(
           value: value,
           onChanged: (newValue) {
                  setState(() {
                    switch (settingKey) {
                      case 'emergency_alerts':
                        _emergencyAlerts = newValue;
                        break;
                      case 'medication_expiry':
                        _medicationExpiry = newValue;
                        break;
                      case 'app_updates':
                        _appUpdates = newValue;
                        break;
                    }
                  });
                  _updateNotificationSetting(settingKey, newValue);
           },
           activeThumbColor: isEmergency ? Colors.red : const Color(0xFF4A9E9C),
          inactiveThumbColor: Colors.grey[300],
          inactiveTrackColor: Colors.grey[200],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
             style: GoogleFonts.nunito(
              fontWeight: FontWeight.bold,
               fontSize: 20,
               color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
             style: GoogleFonts.nunito(
               fontSize: 14,
               color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FAF9),
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: GoogleFonts.nunito(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 32,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF4A9E9C)),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              _showNotificationsHelp();
            },
            tooltip: 'Help',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Notification categories
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 20),
                    children: [
                      // Emergency & Safety
                      _buildSectionHeader(
                        'Emergency & Safety',
                        'Critical alerts for your safety and health',
                      ),
                      _buildNotificationTile(
                        title: 'Emergency Alerts',
                        description: 'Critical alerts for anaphylactic reactions and emergencies',
                        icon: 'emergency',
                        value: _emergencyAlerts,
                        settingKey: 'emergency_alerts',
                        iconColor: Colors.red,
                        isEmergency: true,
                      ),
                      _buildNotificationTile(
                        title: 'Medication Expiry',
                        description: 'Warnings when your medication is about to expire',
                        icon: 'medication',
                        value: _medicationExpiry,
                        settingKey: 'medication_expiry',
                        iconColor: Colors.orange,
                        isEmergency: true,
                      ),

                      // Updates
                      _buildSectionHeader(
                        'Updates',
                        'Important app updates and information',
                      ),
                      _buildNotificationTile(
                        title: 'App Updates',
                        description: 'New features and important app updates',
                        icon: 'update',
                        value: _appUpdates,
                        settingKey: 'app_updates',
                        iconColor: Colors.indigo,
                      ),

                      // Reset button
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: ElevatedButton.icon(
                          onPressed: _resetToDefaults,
                          icon: const Icon(Icons.restore),
                          label: Text(
                            'Reset to Defaults',
                             style: GoogleFonts.nunito(
                               fontWeight: FontWeight.bold,
                               fontSize: 16,
                             ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[200],
                            foregroundColor: Colors.grey[700],
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF4A9E9C),
        unselectedItemColor: Colors.grey[600],
        selectedLabelStyle: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: GoogleFonts.nunito(fontSize: 12),
        currentIndex: 4, // Settings is index 4 (last option)
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
              Navigator.pushReplacementNamed(context, '/my_allergies');
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
            icon: Icon(Icons.health_and_safety, color: Colors.green),
            label: 'Allergies',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home, color: Color(0xFF4A9E9C)),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emergency, color: Color(0xFFE53935)),
            label: 'Emergency',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings, color: Color(0xFF8E24AA)),
            label: 'Settings',
                ),
              ],
            ),
    );
  }

  void _resetToDefaults() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Reset Notifications',
             style: GoogleFonts.nunito(
               fontWeight: FontWeight.bold,
               fontSize: 20,
               color: Colors.black87,
             ),
          ),
          content: Text(
            'This will reset all notification settings to their default values. Are you sure?',
             style: GoogleFonts.nunito(
               fontSize: 16,
               color: Colors.black54,
             ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                 style: GoogleFonts.nunito(
                   fontWeight: FontWeight.bold,
                   fontSize: 16,
                   color: Colors.grey[600],
                 ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _performReset();
              },
              style: ElevatedButton.styleFrom(
                 backgroundColor: const Color(0xFF4A9E9C),
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Reset',
                 style: GoogleFonts.nunito(
                   fontWeight: FontWeight.bold,
                   fontSize: 16,
                 ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _performReset() async {
    setState(() {
      _emergencyAlerts = true;
      _medicationExpiry = true;
      _appUpdates = true;
    });

    // Save all default values
    await _saveNotificationSetting('emergency_alerts', true);
    await _saveNotificationSetting('medication_expiry', true);
    await _saveNotificationSetting('app_updates', true);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Notification settings reset to defaults',
             style: GoogleFonts.nunito(
               fontWeight: FontWeight.bold,
               fontSize: 16,
             ),
          ),
           backgroundColor: const Color(0xFF4A9E9C),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showNotificationsHelp() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Notifications Help',
             style: GoogleFonts.nunito(
               fontWeight: FontWeight.bold,
               fontSize: 20,
               color: Colors.black87,
             ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Emergency & Safety:',
                   style: GoogleFonts.nunito(
                     fontWeight: FontWeight.bold,
                     fontSize: 18,
                     color: Colors.red,
                   ),
                ),
                const SizedBox(height: 4),
                Text(
                  '• Emergency Alerts: Critical notifications for anaphylactic reactions\n'
                  '• Medication Expiry: Warnings when medication expires',
                   style: GoogleFonts.nunito(
                     fontSize: 16,
                     color: Colors.black54,
                   ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Updates:',
                   style: GoogleFonts.nunito(
                     fontWeight: FontWeight.bold,
                     fontSize: 18,
                     color: Colors.indigo,
                   ),
                ),
                const SizedBox(height: 4),
                Text(
                  '• App Updates: New features and updates',
                   style: GoogleFonts.nunito(
                     fontSize: 16,
                     color: Colors.black54,
                   ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Got it',
                 style: GoogleFonts.nunito(
                   fontWeight: FontWeight.bold,
                   fontSize: 16,
                   color: const Color(0xFF4A9E9C),
                 ),
              ),
            ),
          ],
        );
      },
    );
  }
}
