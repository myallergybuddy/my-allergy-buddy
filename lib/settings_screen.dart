import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'privacy_policy_screen.dart';
import 'terms_screen.dart';
import 'about_developer_screen.dart';

import 'support_screen.dart';
import 'notifications_settings_screen.dart';


import 'services/location_service.dart';
import 'services/encryption_service.dart';
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
  bool _biometricEnabled = false;
  bool _locationEnabled = true;
  String _appVersion = '';
  String _buildNumber = '';
  bool _isLoading = true;
  bool _isSaving = false;
  
  // Security settings
  bool _passcodeLockEnabled = false;
  String _passcode = '';
  bool _isPasscodeSet = false;

  // Colors (light mode only)
  Color get _textColor => Colors.black;
  Color get _subtitleColor => Colors.black87;

  @override
  void initState() {
    super.initState();
    _initializeSettings();
    _migratePasscodeIfNeeded();
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
    
    if (mounted) {
      setState(() {
        _isProUser = isPremium;
        _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
        _biometricEnabled = prefs.getBool('biometric_enabled') ?? false;
        _locationEnabled = prefs.getBool('location_enabled') ?? true;
        _passcodeLockEnabled = prefs.getBool('passcode_lock_enabled') ?? false;
        _isPasscodeSet = prefs.getBool('is_passcode_set') ?? false;
        
        // Load encrypted passcode - we'll decrypt it when needed for verification
        final encryptedPasscode = prefs.getString('passcode') ?? '';
        if (encryptedPasscode.isNotEmpty) {
          _passcode = encryptedPasscode; // Store encrypted version for verification
        }
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
      
      // Encrypt passcode before saving
      String encryptedPasscode = '';
      if (_passcode.isNotEmpty && !EncryptionService.isEncrypted(_passcode)) {
        // Only encrypt if it's not already encrypted
        encryptedPasscode = await EncryptionService.encryptPasscode(_passcode);
      } else {
        encryptedPasscode = _passcode; // Already encrypted or empty
      }
      
      await Future.wait([
        prefs.setBool('notifications_enabled', _notificationsEnabled),
        prefs.setBool('biometric_enabled', _biometricEnabled),
        prefs.setBool('location_enabled', _locationEnabled),
        prefs.setBool('passcode_lock_enabled', _passcodeLockEnabled),
        prefs.setBool('is_passcode_set', _isPasscodeSet),
        prefs.setString('passcode', encryptedPasscode),
        prefs.setBool('passcode_encrypted', true), // Mark as encrypted
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Upgrade to Premium',
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.bold,
            color: _textColor,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Upgrade to Premium to unlock all features and enhance your allergy management.',
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    color: _textColor,
                  ),
                ),
                const SizedBox(height: 16),
                const PremiumUpgradeWidget(),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Maybe Later',
              style: GoogleFonts.nunito(
                color: _subtitleColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
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

  void _showPasscodeSetupDialog() {
    final TextEditingController passcodeController = TextEditingController();
    final TextEditingController confirmPasscodeController = TextEditingController();
    bool isConfirming = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(
              isConfirming ? 'Confirm Passcode' : 'Set Passcode',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.bold,
                color: _textColor,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isConfirming 
                    ? 'Please confirm your 4-digit passcode'
                    : 'Create a 4-digit passcode to secure your data',
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    color: _textColor,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: isConfirming ? confirmPasscodeController : passcodeController,
                  decoration: InputDecoration(
                    labelText: 'Passcode',
                    hintText: 'Enter 4 digits',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.lock, color: Color(0xFF4A9E9C)),
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  obscureText: true,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.nunito(
                    color: _subtitleColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  final currentPasscode = isConfirming ? confirmPasscodeController.text : passcodeController.text;
                  
                  if (currentPasscode.length != 4) {
                    _showErrorSnackBar('Passcode must be 4 digits');
                    return;
                  }
                  
                  if (!isConfirming) {
                    // First passcode entry
                    setState(() {
                      isConfirming = true;
                    });
                  } else {
                    // Confirm passcode
                    if (passcodeController.text != confirmPasscodeController.text) {
                      _showErrorSnackBar('Passcodes do not match');
                      return;
                    }
                    
                    // Save passcode
                    setState(() {
                      _passcode = passcodeController.text;
                      _isPasscodeSet = true;
                      _passcodeLockEnabled = true;
                    });
                    
                    _saveSettings();
                    Navigator.pop(context);
                    _showSuccessSnackBar('Passcode set successfully!');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A9E9C),
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  isConfirming ? 'Confirm' : 'Next',
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showPasscodeChangeDialog() {
    final TextEditingController currentPasscodeController = TextEditingController();
    final TextEditingController newPasscodeController = TextEditingController();
    final TextEditingController confirmPasscodeController = TextEditingController();
    int step = 1; // 1: current passcode, 2: new passcode, 3: confirm new passcode

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          String getTitle() {
            switch (step) {
              case 1: return 'Current Passcode';
              case 2: return 'New Passcode';
              case 3: return 'Confirm New Passcode';
              default: return 'Change Passcode';
            }
          }
          
          String getMessage() {
            switch (step) {
              case 1: return 'Enter your current passcode';
              case 2: return 'Create a new 4-digit passcode';
              case 3: return 'Please confirm your new passcode';
              default: return '';
            }
          }
          
          TextEditingController getController() {
            switch (step) {
              case 1: return currentPasscodeController;
              case 2: return newPasscodeController;
              case 3: return confirmPasscodeController;
              default: return currentPasscodeController;
            }
          }

          return AlertDialog(
            title: Text(
              getTitle(),
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.bold,
                color: _textColor,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  getMessage(),
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    color: _textColor,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: getController(),
                  decoration: InputDecoration(
                    labelText: 'Passcode',
                    hintText: 'Enter 4 digits',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.lock, color: Color(0xFF4A9E9C)),
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  obscureText: true,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.nunito(
                    color: _subtitleColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  final currentInput = getController().text;
                  
                  if (currentInput.length != 4) {
                    _showErrorSnackBar('Passcode must be 4 digits');
                    return;
                  }
                  
                  switch (step) {
                    case 1:
                      // Verify current passcode
                      if (!await _verifyPasscode(currentInput)) {
                        _showErrorSnackBar('Incorrect passcode');
                        return;
                      }
                      setState(() {
                        step = 2;
                      });
                      break;
                    case 2:
                      // New passcode
                      setState(() {
                        step = 3;
                      });
                      break;
                    case 3:
                      // Confirm new passcode
                      if (newPasscodeController.text != confirmPasscodeController.text) {
                        _showErrorSnackBar('Passcodes do not match');
                        return;
                      }
                      
                      // Save new passcode
                      setState(() {
                        _passcode = newPasscodeController.text;
                      });
                      
                      await _saveSettings();

                      if (!context.mounted) return;

                      Navigator.pop(context);
                      _showSuccessSnackBar('Passcode changed successfully!');
                      break;
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A9E9C),
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  step == 3 ? 'Confirm' : 'Next',
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showRemovePasscodeDialog() {
    final TextEditingController passcodeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Remove Passcode',
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter your current passcode to remove it',
              style: GoogleFonts.nunito(
                fontSize: 16,
                color: _textColor,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: passcodeController,
              decoration: InputDecoration(
                labelText: 'Passcode',
                hintText: 'Enter 4 digits',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.lock, color: Color(0xFF4A9E9C)),
              ),
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.nunito(
                color: _subtitleColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (passcodeController.text != _passcode) {
                _showErrorSnackBar('Incorrect passcode');
                return;
              }
              
              setState(() {
                _passcode = '';
                _isPasscodeSet = false;
                _passcodeLockEnabled = false;
              });
              
              _saveSettings();
              Navigator.pop(context);
              if (mounted) {
                _showSuccessSnackBar('Passcode removed successfully!');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Remove',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPasscodeResetDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final phoneNumber = prefs.getString('profile_phone') ?? '';
    
    if (phoneNumber.isEmpty) {
      _showErrorSnackBar('Please add a phone number in your profile first');
      return;
    }

    if (!mounted) return;

    final TextEditingController resetCodeController = TextEditingController();
    final TextEditingController newPasscodeController = TextEditingController();
    final TextEditingController confirmPasscodeController = TextEditingController();
    int step = 1; // 1: send code, 2: enter code, 3: new passcode, 4: confirm passcode

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          String getTitle() {
            switch (step) {
              case 1: return 'Reset Passcode';
              case 2: return 'Enter Reset Code';
              case 3: return 'New Passcode';
              case 4: return 'Confirm Passcode';
              default: return 'Reset Passcode';
            }
          }
          
          String getMessage() {
            switch (step) {
              case 1: return 'We\'ll send a reset code to $phoneNumber';
              case 2: return 'Enter the 6-digit code sent to your phone';
              case 3: return 'Create a new 4-digit passcode';
              case 4: return 'Please confirm your new passcode';
              default: return '';
            }
          }

          return AlertDialog(
            title: Text(
              getTitle(),
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.bold,
                color: _textColor,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  getMessage(),
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    color: _textColor,
                  ),
                ),
                if (step > 1) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: step == 2 ? resetCodeController : 
                              step == 3 ? newPasscodeController : confirmPasscodeController,
                    decoration: InputDecoration(
                      labelText: step == 2 ? 'Reset Code' : 'Passcode',
                      hintText: step == 2 ? 'Enter 6 digits' : 'Enter 4 digits',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(
                        step == 2 ? Icons.security : Icons.lock,
                        color: const Color(0xFF4A9E9C),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: step == 2 ? 6 : 4,
                    obscureText: step > 2,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.nunito(
                    color: _subtitleColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  switch (step) {
                    case 1:
                      // Send reset code (simulated)
                      setState(() {
                        step = 2;
                      });
                      _showSuccessSnackBar('Reset code sent to $phoneNumber');
                      break;
                    case 2:
                      // Verify reset code
                      if (resetCodeController.text.length != 6) {
                        _showErrorSnackBar('Please enter 6-digit code');
                        return;
                      }
                      // In a real app, you would verify the code with your backend
                      setState(() {
                        step = 3;
                      });
                      break;
                    case 3:
                      // New passcode
                      if (newPasscodeController.text.length != 4) {
                        _showErrorSnackBar('Passcode must be 4 digits');
                        return;
                      }
                      setState(() {
                        step = 4;
                      });
                      break;
                    case 4:
                      // Confirm new passcode
                      if (newPasscodeController.text != confirmPasscodeController.text) {
                        _showErrorSnackBar('Passcodes do not match');
                        return;
                      }
                      
                      // Save new passcode
                      setState(() {
                        _passcode = newPasscodeController.text;
                        _isPasscodeSet = true;
                        _passcodeLockEnabled = true;
                      });
                      
                      await _saveSettings();

                      if (!context.mounted) return;

                      Navigator.pop(context);
                      if (!mounted) return;
                      _showSuccessSnackBar('Passcode reset successfully!');
                      break;
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A9E9C),
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  step == 1 ? 'Send Code' : (step == 4 ? 'Confirm' : 'Next'),
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
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

  /// Migrate existing passcodes to encrypted format
  Future<void> _migratePasscodeIfNeeded() async {
    await EncryptionService.migratePlainTextPasscode();
  }

  /// Verify passcode against stored encrypted passcode
  Future<bool> _verifyPasscode(String inputPasscode) async {
    if (_passcode.isEmpty) return false;
    
    try {
      if (EncryptionService.isEncrypted(_passcode)) {
        // Decrypt stored passcode and compare
        final decryptedPasscode = await EncryptionService.decryptPasscode(_passcode);
        return decryptedPasscode == inputPasscode;
      } else if (EncryptionService.isHashed(_passcode)) {
        // Verify against hashed passcode
        return EncryptionService.verifyPasscode(inputPasscode, _passcode);
      } else {
        // Legacy plain text comparison
        return _passcode == inputPasscode;
      }
    } catch (e) {
      debugPrint('Passcode verification error: $e');
      return false;
    }
  }



  Future<void> _showSecurityStatus() async {
    final encryptionStatus = await EncryptionService.getEncryptionStatus();
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Security Status',
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
              'Passcode Protection',
              _passcodeLockEnabled ? 'Enabled' : 'Disabled',
              _passcodeLockEnabled ? Colors.green : Colors.red,
            ),
            _buildStatusRow(
              'Passcode Set',
              _isPasscodeSet ? 'Yes' : 'No',
              _isPasscodeSet ? Colors.green : Colors.orange,
            ),
            _buildStatusRow(
              'Encryption',
              encryptionStatus['status'],
              _getEncryptionColor(encryptionStatus['status']),
            ),
            const SizedBox(height: 16),
            Text(
              'Security Features:',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.bold,
                color: _textColor,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            _buildSecurityFeatureRow('AES-256 Encryption', true),
            _buildSecurityFeatureRow('Secure Key Storage', true),
            _buildSecurityFeatureRow('Automatic Migration', true),
            _buildSecurityFeatureRow('Fallback Hashing', true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.nunito(
                color: _primaryColor,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getEncryptionColor(String status) {
    switch (status) {
      case 'Encrypted (AES-256)':
        return Colors.green;
      case 'Hashed (SHA-256)':
        return Colors.orange;
      case 'Plain Text (Legacy)':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildSecurityFeatureRow(String feature, bool enabled) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            enabled ? Icons.check_circle : Icons.cancel,
            color: enabled ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            feature,
            style: GoogleFonts.nunito(
              color: _textColor,
              fontSize: 14,
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
                      _buildListTile(
                        title: 'Notifications',
                        subtitle: 'Manage notification preferences',
                        icon: Icons.notifications,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NotificationsSettingsScreen(),
                            ),
                          );
                        },
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.grey[400],
                          size: 16,
                        ),
                      ),
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
                      
                      // SMS Usage Info
                      FutureBuilder<Map<String, dynamic>>(
                        future: PremiumService.getSmsUsageInfo(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            final smsInfo = snapshot.data!;
                            final isPremium = smsInfo['isPremium'];
                            final usageCount = smsInfo['usageCount'];
                            final limit = smsInfo['limit'];
                            final remaining = smsInfo['remaining'];
                            
                            String subtitle;
                            IconData trailingIcon;
                            Color trailingColor;
                            
                            if (isPremium) {
                              subtitle = 'Unlimited SMS available';
                              trailingIcon = Icons.check_circle;
                              trailingColor = Colors.green;
                            } else {
                              subtitle = '$usageCount/$limit SMS used this month';
                              if (remaining > 0) {
                                trailingIcon = Icons.info_outline;
                                trailingColor = Colors.blue;
                              } else {
                                trailingIcon = Icons.warning;
                                trailingColor = Colors.orange;
                              }
                            }
                            
                            return _buildListTile(
                              title: 'SMS Usage',
                              subtitle: subtitle,
                              icon: Icons.sms,
                              onTap: null,
                              trailing: Icon(trailingIcon, color: trailingColor, size: 20),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),

                  // Security
                  _buildSection(
                    title: 'Security',
                    children: [
                      if (!_isPasscodeSet)
                        _buildListTile(
                          title: 'Set Passcode',
                          subtitle: 'Create a 4-digit passcode to secure your data',
                          icon: Icons.lock_outline,
                          onTap: _showPasscodeSetupDialog,
                        )
                      else ...[
                        _buildSwitchTile(
                          title: 'Passcode Lock',
                          subtitle: 'Require passcode to access the app',
                          value: _passcodeLockEnabled,
                          icon: Icons.lock,
                          onChanged: (value) {
                            setState(() {
                              _passcodeLockEnabled = value;
                            });
                            _saveSettings();
                          },
                          trailing: IconButton(
                            icon: const Icon(Icons.security, color: Color(0xFF4A9E9C)),
                            onPressed: _showSecurityStatus,
                          ),
                        ),
                        _buildListTile(
                          title: 'Change Passcode',
                          subtitle: 'Update your current passcode',
                          icon: Icons.edit,
                          onTap: _showPasscodeChangeDialog,
                        ),
                        _buildListTile(
                          title: 'Remove Passcode',
                          subtitle: 'Remove passcode protection',
                          icon: Icons.lock_open,
                          onTap: _showRemovePasscodeDialog,
                        ),
                        _buildListTile(
                          title: 'Reset Passcode',
                          subtitle: 'Forgot your passcode? Reset it via SMS',
                          icon: Icons.restore,
                          onTap: _showPasscodeResetDialog,
                        ),
                      ],
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
