import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'services/location_service.dart';
import 'services/premium_service.dart';
import 'widgets/premium_upgrade_widget.dart';
import 'scan_label_screen.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  final List<Map<String, String>> _contacts = [];
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _relationshipController = TextEditingController();

  // Emergency services numbers for different countries
  final Map<String, String> _emergencyNumbers = {
    'Australia': '000',
    'US': '911',
    'UK': '999',
    'EU': '112',
    'Canada': '911',
    'India': '112',
    'Japan': '119',
    'South Korea': '119',
    'Brazil': '190',
    'Mexico': '911',
  };

  // Premium status and contact limits
  bool _isPremium = false;
  int get maxContacts => _isPremium ? 10 : 1; // Free: 1, Premium: 10

  @override
  void initState() {
    super.initState();
    _loadPremiumStatus();
    _loadContacts();
  }

  Future<void> _loadPremiumStatus() async {
    final isPremium = await PremiumService.isPremiumUser();
    setState(() {
      _isPremium = isPremium;
    });
  }

  Future<void> _loadContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final contactsJson = prefs.getStringList('emergency_contacts') ?? [];
    setState(() {
      _contacts.clear();
      _contacts.addAll(contactsJson.map((json) => Map<String, String>.from(jsonDecode(json))));
    });
  }

  Future<void> _saveContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final contactsJson = _contacts.map((c) => jsonEncode(c)).toList();
    await prefs.setStringList('emergency_contacts', contactsJson);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _relationshipController.dispose();
    super.dispose();
  }

  void _addContact() {
    if (_contacts.length >= maxContacts) {
      Navigator.pop(context);
      if (_isPremium) {
        _showErrorSnackBar('You can add up to 10 emergency contacts.');
      } else {
        _showPremiumUpgradeDialog();
      }
      return;
    }
    if (_formKey.currentState!.validate()) {
      setState(() {
        _contacts.add({
          'name': _nameController.text,
          'phone': _phoneController.text,
          'relationship': _relationshipController.text,
        });
        _nameController.clear();
        _phoneController.clear();
        _relationshipController.clear();
      });
      _saveContacts();
      Navigator.pop(context);
      _showSuccessSnackBar('Contact added successfully!');
    }
  }

  static const InputDecoration _contactFieldDecoration = InputDecoration(
    floatingLabelBehavior: FloatingLabelBehavior.always,
    errorMaxLines: 1,
    errorStyle: TextStyle(fontSize: 11, height: 1.1),
    isDense: true,
    contentPadding: EdgeInsets.symmetric(vertical: 12),
  );

  Widget _buildRelationshipField() {
    return TextFormField(
      controller: _relationshipController,
      decoration: _contactFieldDecoration.copyWith(
        labelText: 'Relationship',
        hintText: 'e.g. Partner',
        prefixIcon: const Icon(Icons.group_outlined),
        prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      ),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
        TextInputFormatter.withFunction((oldValue, newValue) {
          return TextEditingValue(
            text: newValue.text.split(' ').map((word) {
              if (word.isNotEmpty) {
                return word[0].toUpperCase() + word.substring(1).toLowerCase();
              }
              return word;
            }).join(' '),
            selection: newValue.selection,
          );
        }),
      ],
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Enter relationship';
        }
        return null;
      },
    );
  }

  Widget _buildContactFormFields() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextFormField(
          controller: _nameController,
          decoration: _contactFieldDecoration.copyWith(
            labelText: 'Name',
            prefixIcon: const Icon(Icons.person_outline),
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
            TextInputFormatter.withFunction((oldValue, newValue) {
              return TextEditingValue(
                text: newValue.text.split(' ').map((word) {
                  if (word.isNotEmpty) {
                    return word[0].toUpperCase() + word.substring(1).toLowerCase();
                  }
                  return word;
                }).join(' '),
                selection: newValue.selection,
              );
            }),
          ],
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Enter name';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _phoneController,
          decoration: _contactFieldDecoration.copyWith(
            labelText: 'Phone Number',
            prefixIcon: const Icon(Icons.phone_outlined),
          ),
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Enter phone number';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        _buildRelationshipField(),
      ],
    );
  }

  Widget _buildContactDialogContent(BuildContext context) {
    return SizedBox(
      width: double.maxFinite,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.5,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: _buildContactFormFields(),
          ),
        ),
      ),
    );
  }

  void _editContact(int index) {
    final contact = _contacts[index];
    _nameController.text = contact['name']!;
    _phoneController.text = contact['phone']!;
    _relationshipController.text = contact['relationship']!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        title: Text(
          'Edit Contact',
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        content: _buildContactDialogContent(context),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.nunito(
                color: Colors.grey,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                setState(() {
                  _contacts[index] = {
                    'name': _nameController.text,
                    'phone': _phoneController.text,
                    'relationship': _relationshipController.text,
                  };
                });
                _saveContacts();
                _nameController.clear();
                _phoneController.clear();
                _relationshipController.clear();
                Navigator.pop(context);
                _showSuccessSnackBar('Contact updated successfully!');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A9E9C),
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Save',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddContactDialog() {
    if (_contacts.length >= maxContacts) {
      if (_isPremium) {
        _showErrorSnackBar('You can add up to 10 emergency contacts.');
      } else {
        _showPremiumUpgradeDialog();
      }
      return;
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        title: Text(
          'Add Emergency Contact',
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        content: _buildContactDialogContent(context),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.nunito(
                color: Colors.grey,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _addContact,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A9E9C),
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Add',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _callContact(String phoneNumber, String contactName) async {
    try {
      final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
      if (await launchUrl(phoneUri)) {
        _showSuccessSnackBar('Calling $contactName...');
        // Share location if enabled
        await _shareLocationWithContact(contactName);
      } else {
        _showErrorSnackBar('Could not make call');
      }
    } catch (e) {
      _showErrorSnackBar('Error making call');
    }
  }

  Future<void> _shareLocationWithContact(String contactName) async {
    // Check if location sharing is enabled
    final prefs = await SharedPreferences.getInstance();
    final locationEnabled = prefs.getBool('location_enabled') ?? false;
    
    if (locationEnabled) {
      // Get location status first
      final locationStatus = await LocationService.getLocationStatus();
      
      if (!locationStatus['locationEnabled']) {
        _showErrorSnackBar('Location sharing is disabled in settings');
        return;
      }
      
      if (!locationStatus['serviceEnabled']) {
        _showErrorSnackBar('Location services are disabled on your device');
        return;
      }
      
      if (!locationStatus['permissionGranted']) {
        _showErrorSnackBar('Location permission is required to share location');
        return;
      }
      
      // Get current location and share via SMS
      final position = await LocationService.getCurrentLocation();
      if (position != null) {
        _showSuccessSnackBar('Location shared with $contactName');
      } else {
        _showErrorSnackBar('Could not get current location');
      }
    }
  }

  void _showEmergencyServicesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Emergency Services',
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to call emergency services?',
              style: GoogleFonts.nunito(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'This will dial your country\'s emergency number.',
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Emergency Numbers:',
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            ...(_emergencyNumbers.entries.take(5).map((entry) => 
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  '${entry.key}: ${entry.value}',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.nunito(
                color: Colors.grey,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showLocationSharingApproval();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Call Emergency',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLocationSharingApproval() async {
    // Check if location sharing is enabled
    final prefs = await SharedPreferences.getInstance();
    final locationEnabled = prefs.getBool('location_enabled') ?? false;
    
    if (!mounted) return;
    
    if (locationEnabled) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text(
            'Location Sharing',
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Emergency services will be able to access your location to provide faster assistance.',
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.location_on, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your current location will be shared',
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.security, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Location is only shared during emergency calls',
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
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
                  color: Colors.grey,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _callEmergencyServicesWithLocation();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Call & Share Location',
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // Location not enabled, just call emergency services
      _callEmergencyServices();
    }
  }

  Future<void> _callEmergencyServicesWithLocation() async {
    // Default to Australia emergency number (000)
    const String emergencyNumber = '000';
    
    try {
      // Get location status first
      final locationStatus = await LocationService.getLocationStatus();
      
      if (!locationStatus['locationEnabled']) {
        _showErrorSnackBar('Location sharing is disabled in settings');
        return;
      }
      
      if (!locationStatus['serviceEnabled']) {
        _showErrorSnackBar('Location services are disabled on your device');
        return;
      }
      
      if (!locationStatus['permissionGranted']) {
        _showErrorSnackBar('Location permission is required to share location');
        return;
      }
      
      final Uri phoneUri = Uri(scheme: 'tel', path: emergencyNumber);
      if (await launchUrl(phoneUri)) {
        _showSuccessSnackBar('Calling emergency services with location...');
        // Share location with emergency services
        await _shareLocationWithEmergencyServices();
      } else {
        _showErrorSnackBar('Could not call emergency services');
      }
    } catch (e) {
      _showErrorSnackBar('Error calling emergency services');
    }
  }

  Future<void> _callEmergencyServices() async {
    // Default to Australia emergency number (000)
    const String emergencyNumber = '000';
    
    try {
      final Uri phoneUri = Uri(scheme: 'tel', path: emergencyNumber);
      if (await launchUrl(phoneUri)) {
        _showSuccessSnackBar('Calling emergency services...');
      } else {
        _showErrorSnackBar('Could not call emergency services');
      }
    } catch (e) {
      _showErrorSnackBar('Error calling emergency services');
    }
  }

  Future<void> _shareLocationWithEmergencyServices() async {
    try {
      // Share location with emergency services
      bool success = await LocationService.shareLocationWithEmergencyServices();
      
      if (success) {
        _showSuccessSnackBar('Location shared with emergency services');
        // Also notify emergency contacts
        await _notifyEmergencyContacts();
      } else {
        _showErrorSnackBar('Failed to share location with emergency services');
      }
    } catch (e) {
      _showErrorSnackBar('Error sharing location with emergency services');
    }
  }

  Future<void> _notifyEmergencyContacts() async {
    if (_contacts.isNotEmpty) {
      try {
        // Check SMS usage info
        final smsInfo = await PremiumService.getSmsUsageInfo();
        
        if (!smsInfo['canSend']) {
          if (smsInfo['isPremium']) {
            _showErrorSnackBar('Unable to send SMS at this time. Please try again.');
          } else {
            _showSmsLimitDialog();
          }
          return;
        }
        
        bool success = await LocationService.notifyEmergencyContacts();
        if (success) {
          _showSuccessSnackBar('Emergency contacts notified with your location');
        } else {
          _showErrorSnackBar('Failed to notify some emergency contacts');
        }
      } catch (e) {
        _showErrorSnackBar('Error notifying emergency contacts');
      }
    }
  }

  void _showSmsLimitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.sms, color: Colors.orange, size: 24),
            const SizedBox(width: 8),
            Text(
              'SMS Limit Reached',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You\'ve used your monthly SMS allowance (1 SMS per month on basic plan).',
              style: GoogleFonts.nunito(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Upgrade to Premium for unlimited emergency SMS alerts.',
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.nunito(
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
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
                        'Upgrade to Premium for unlimited emergency SMS alerts and more features.',
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
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A9E9C),
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Upgrade to Premium',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
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
        backgroundColor: const Color(0xFF4A9E9C),
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

  Color _getContactColor(int index) {
    final colors = [
      const Color(0xFF4A9E9C), // Teal
      const Color(0xFFE53935), // Red
      const Color(0xFF8E24AA), // Purple
      const Color(0xFF43A047), // Green
      const Color(0xFFFF9800), // Orange
      const Color(0xFF2196F3), // Blue
      const Color(0xFF9C27B0), // Deep Purple
      const Color(0xFF00BCD4), // Cyan
      const Color(0xFF795548), // Brown
      const Color(0xFF607D8B), // Blue Grey
    ];
    return colors[index % colors.length];
  }

  void _showPremiumUpgradeDialog() {
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
              'You\'ve reached the free plan limit of 1 emergency contact. Upgrade to Premium to add up to 10 emergency contacts.',
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
    );
  }

  Widget _buildRelationshipChip(String relationship, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _getContactColor(index).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        relationship,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.nunito(
          color: _getContactColor(index),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FAF9),
      appBar: AppBar(
        title: Text(
          'Emergency Contacts',
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
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton.icon(
                onPressed: _showEmergencyServicesDialog,
                icon: const Icon(Icons.emergency, color: Colors.white, size: 36),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Emergency Services',
                    style: GoogleFonts.nunito(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 6,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Add box for adding contacts if none exist
            if (_contacts.isEmpty) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.group_outlined,
                      size: 40,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No emergency contacts added yet',
                      style: GoogleFonts.nunito(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Add your emergency contacts for quick access',
                      style: GoogleFonts.nunito(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _contacts.length >= maxContacts
                        ? null
                        : _showAddContactDialog,
                      icon: const Icon(Icons.add, size: 16),
                      label: Text(
                        'Add Contact',
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A9E9C),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    if (_contacts.length >= maxContacts) ...[
                      const SizedBox(height: 8),
                      Text(
                        _isPremium
                          ? 'You can add up to 10 emergency contacts.'
                          : 'Upgrade to Premium to add more than 1 emergency contact.',
                        style: GoogleFonts.nunito(
                          color: Colors.red,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            Expanded(
              child: _contacts.isEmpty
                  ? const SizedBox.shrink()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _contacts.length,
                      itemBuilder: (context, index) {
                        final contact = _contacts[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  backgroundColor: _getContactColor(index),
                                  child: Text(
                                    contact['name']![0].toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        contact['name']!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.nunito(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        contact['phone']!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.nunito(
                                          fontSize: 16,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      _buildRelationshipChip(
                                        contact['relationship']!,
                                        index,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                        minWidth: 40,
                                        minHeight: 40,
                                      ),
                                      icon: const Icon(
                                        Icons.phone,
                                        color: Colors.green,
                                      ),
                                      onPressed: () => _callContact(
                                        contact['phone']!,
                                        contact['name']!,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => _editContact(index),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF4A9E9C),
                                          borderRadius: BorderRadius.circular(8),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.1),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.edit, color: Colors.white, size: 14),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Edit',
                                              style: GoogleFonts.nunito(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF4A9E9C),
        unselectedItemColor: Colors.grey[600],
        selectedLabelStyle: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: GoogleFonts.nunito(fontSize: 11),
        currentIndex: 0, // Profile is index 0 (first available option since we're on Emergency)
        elevation: 8,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        iconSize: 20,
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
            icon: Icon(Icons.health_and_safety, color: Colors.green),
            label: 'Allergies',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings, color: Colors.purple),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
} 