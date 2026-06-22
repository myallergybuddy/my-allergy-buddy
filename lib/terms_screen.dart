import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TermsScreen extends StatefulWidget {
  final bool isReadOnly;
  
  const TermsScreen({
    super.key,
    this.isReadOnly = false,
  });

  @override
  TermsScreenState createState() => TermsScreenState();
}

class TermsScreenState extends State<TermsScreen> {
  // final bool _accepted = false; // Removed unused field
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.isReadOnly) {
      // If read-only mode (from settings), don't check acceptance
      setState(() {
        _isLoading = false;
      });
    } else {
      _checkTermsAcceptance();
    }
  }

  Future<void> _checkTermsAcceptance() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasAcceptedTerms = prefs.getBool('terms_accepted') ?? false;
      final hasAcceptedPrivacy = prefs.getBool('privacy_accepted') ?? false;
      
      if (hasAcceptedTerms && hasAcceptedPrivacy) {
        // User has already accepted both terms and privacy, go directly to home
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else if (hasAcceptedTerms) {
        // User has accepted terms but not privacy, go to privacy screen
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/privacy');
        }
      } else {
        // User needs to accept terms
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _acceptTerms() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('terms_accepted', true);
      
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/privacy');
      }
    } catch (e) {
      // Handle error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save terms acceptance'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A9E9C)),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Terms & Conditions',
          style: TextStyle(
            color: Color(0xFF4A9E9C),
            fontWeight: FontWeight.bold,
            fontSize: 26,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF4A9E9C)),
      ),
      backgroundColor: const Color(0xFFF5FAF9),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top terms box header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A9E9C),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.gavel,
                      color: Colors.white,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Terms & Conditions',
                      style: GoogleFonts.nunito(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please read these terms carefully',
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              Text('Last updated: May 2026', style: GoogleFonts.nunito(fontSize: 15, color: Colors.grey[700], fontWeight: FontWeight.w600)),
              const SizedBox(height: 20),
              _sectionTitle('1. Acceptance of Terms'),
              _bulletList([
                'By downloading, installing, or using My Allergy Buddy, you confirm that:',
                'You are at least 14 years old',
                'You have read, understood, and accepted these Terms and our Privacy Policy',
                'You are using the app for personal, non-commercial purposes',
                'You accept full responsibility for how you use the app and any outcomes resulting from that use',
              ]),
              _sectionTitle('2. About the App'),
              _sectionBody('My Allergy Buddy helps users identify potential allergens in food products by scanning product labels and barcodes, and by looking up product information from databases where available.'),
              _subSection('Limitations:'),
              _bulletList([
                'This app does not provide medical advice, diagnosis, or treatment',
                'Results are based on label text, barcode data, and product databases—they may be incomplete, outdated, or inaccurate',
                'Always read the physical product label and packaging yourself before consuming',
                'Use is entirely at your own risk',
              ]),
              _sectionTitle('3. Cross-Contamination and "May Contain" Disclaimer'),
              _sectionBody('The app may flag possible cross-contamination or "may contain" risks when that information appears in scanned label text or in product database records. These warnings are informational only.'),
              _bulletList([
                'We do not guarantee that all trace allergens, "may contain" statements, or cross-contamination risks will be detected',
                'Manufacturers may not list every possible allergen exposure on packaging',
                'Database entries may be missing, incomplete, or out of date',
                'Unlisted production-environment cross-contamination cannot be reliably detected',
                'You must use your own judgment and consult a healthcare professional when in doubt',
              ]),
              _sectionTitle('4. Medical Disclaimer'),
              _sectionBody('Always consult a qualified healthcare professional for diagnosis or treatment. This app is not a substitute for professional medical advice.'),
              _sectionTitle('5. Emergency Features and Location Services'),
              _sectionBody('Emergency features are user-initiated tools to help you reach people and services during a crisis. The app does not automatically dispatch emergency services or connect to any emergency-services API on your behalf.'),
              _subSection('a. Location Services'),
              _bulletList([
                'Used only when you manually activate emergency features',
                'May be included in SMS messages you send to your saved emergency contacts (e.g. as a Google Maps link)',
                'Can be disabled via your device or in-app settings',
              ]),
              _subSection('b. SMS Functionality'),
              _bulletList([
                'When you choose to use it, sends alerts or location links to your saved emergency contacts',
                'You control when messages are sent; delivery depends on your device, carrier, and network',
                'Standard carrier charges may apply',
              ]),
              _subSection('c. Emergency Dialling'),
              _bulletList([
                'Provides a shortcut to dial 000 (Australia) or other local emergency numbers—you must confirm and place the call',
                'Does not automatically notify, dispatch, or transmit data to emergency services',
                'When enabled, may also send location information to your emergency contacts via SMS at your direction',
              ]),
              _subSection('d. Required Permissions'),
              _bulletList([
                'Location, SMS, and call permissions are required for emergency features',
                'Permissions are only active during use and can be revoked',
              ]),
              _sectionTitle('6. Emergency Feature Responsibilities'),
              _bulletList([
                'You agree to:',
                'Maintain up-to-date emergency contact details',
                'Only use emergency features in genuine emergencies',
                'Avoid misuse or triggering false alerts',
                'Ensure your device has sufficient battery and network connectivity',
                'You are responsible for any consequences arising from emergency feature usage.',
              ]),
              _sectionTitle('7. Subscriptions and Payments'),
              _subSection('Subscription Tiers:'),
              _bulletList([
                'Free Tier: Basic allergen detection and scanning',
                'Premium Tier: Unlocks advanced allergen categories and enhanced features via subscription',
              ]),
              _subSection('Premium Pricing (AUD):'),
              _bulletList([
                'Weekly: \$3.99',
                'Monthly: \$8.99',
                'Yearly: \$74.99',
              ]),
              _subSection('Billing Details:'),
              _bulletList([
                'Purchases are processed through the Google Play Store (Android) or Apple App Store (iOS)',
                'The app uses the RevenueCat SDK to verify subscription status when configured with valid store and RevenueCat API keys',
                'Subscriptions auto-renew unless cancelled before the renewal date in your store account settings',
                "Refunds follow Australian Consumer Law and the applicable store's policies",
              ]),
              _sectionTitle('8. User Responsibilities'),
              _bulletList([
                'You agree not to:',
                'Misuse emergency or subscription features',
                'Provide false or misleading personal information',
                'Copy, modify, or redistribute app content',
                'Use the app to harm, threaten, or harass others',
                'You are solely responsible for managing your data and settings.',
              ]),
              _sectionTitle('9. Location Data and Privacy'),
              _bulletList([
                'Location is used temporarily when you use emergency features (e.g. to include a maps link in SMS to your contacts)',
                'Not collected in the background without your action and permission',
                'Location access can be turned off in device or in-app settings',
                'Location is not automatically transmitted to emergency services; it is shared only as part of features you initiate',
              ]),
              _sectionTitle('10. Third-Party Services'),
              _sectionBody('This app integrates with the following trusted providers:'),
              _bulletList([
                'Google Maps (for sending location links)',
                'Firebase Crashlytics (for error logging and crash diagnostics)',
                'Firebase Analytics (for anonymous usage tracking and feature improvement)',
                'RevenueCat (for verifying in-app subscription status when configured)',
                'Australian Food Database (for enhanced allergen detection)',
                'Native Android/iOS APIs (SMS, location, phone)',
                'Each service operates under its own privacy and security terms.',
              ]),
              _sectionTitle('11. Intellectual Property'),
              _sectionBody('All trademarks, icons, content, and features belong to or are licensed to My Allergy Buddy. You may not reuse, reverse engineer, or redistribute any part of the app without permission.'),
              _sectionTitle('12. Limitation of Liability'),
              _bulletList([
                'To the fullest extent permitted by law, My Allergy Buddy is not liable for:',
                'Any harm from using the app or interpreting results',
                'Label inaccuracies, missed allergens, or translation errors',
                'Delays or failures in emergency features',
                'SMS delivery or GPS location errors',
                'Any indirect or incidental damages',
              ]),
              _sectionTitle('13. Termination'),
              _bulletList([
                'Your access to the app may be suspended or terminated for:',
                'Violating these Terms',
                'Misusing emergency or premium features',
                'Abusive or fraudulent behaviour',
              ]),
              _sectionTitle('14. Changes to These Terms'),
              _bulletList([
                'We may update these Terms and Conditions at any time',
                'Changes will be communicated via the app or website',
                'Your continued use after updates means you accept the new terms',
              ]),
              _sectionTitle('15. Acknowledgement and Acceptance'),
              _bulletList([
                'By using the app, you acknowledge that:',
                'You accept all terms, limitations, and disclaimers',
                'You are responsible for how you use the app',
                'Emergency features require you to initiate calls and messages; allergy guidance requires your own judgment',
              ]),
              _sectionTitle('16. Contact'),
              _sectionBody('For help, questions, or billing issues, contact:'),
              const SizedBox(height: 8),
              Text('📧 myallergybuddy@gmail.com', style: GoogleFonts.nunito(fontSize: 16, color: Colors.black87)),
              const SizedBox(height: 32),
              // Acceptance button
              if (!widget.isReadOnly) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: ElevatedButton(
                    onPressed: _acceptTerms,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A9E9C),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                    ),
                    child: Text(
                      'I Accept Terms & Conditions',
                      style: GoogleFonts.nunito(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 6),
        child: Text(
          title,
          style: GoogleFonts.nunito(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Colors.teal[700],
          ),
        ),
      );

  Widget _subSection(String title) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 2),
        child: Text(
          title,
          style: GoogleFonts.nunito(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.teal[400],
          ),
        ),
      );

  Widget _sectionBody(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Text(
          text,
          style: GoogleFonts.nunito(fontSize: 16, color: Colors.black87, height: 1.5),
        ),
      );

  Widget _bulletList(List<String> items) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items
            .map((item) => Padding(
                  padding: const EdgeInsets.only(left: 12, bottom: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(fontSize: 16)),
                      Expanded(
                        child: Text(item, style: GoogleFonts.nunito(fontSize: 16, color: Colors.black87)),
                      ),
                    ],
                  ),
                ))
            .toList(),
      );
} 