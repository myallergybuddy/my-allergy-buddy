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
                      'My Allergy Buddy – Terms and Conditions',
                      style: GoogleFonts.nunito(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
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
              Text('Last updated: July 2026', style: GoogleFonts.nunito(fontSize: 15, color: Colors.grey[700], fontWeight: FontWeight.w600)),
              const SizedBox(height: 20),
              _sectionTitle('1. Acceptance of Terms'),
              _sectionBody('By downloading, installing, or using My Allergy Buddy ("the App"), you agree that:'),
              _bulletList([
                'You are at least 14 years old (or the minimum age required in your jurisdiction)',
                'You have read and agree to these Terms and our Privacy Policy',
                'You understand the App is provided for informational and personal use only',
                'You accept full responsibility for how you use the App and any decisions made based on it',
                'You use the App at your own risk',
              ]),
              _sectionBody('If you do not agree, you must stop using the App.'),
              _sectionTitle('2. About the App (Important Limitations)'),
              _sectionBody('My Allergy Buddy is an informational allergy support tool that helps users identify potential allergens using:'),
              _bulletList([
                'Ingredient label scanning',
                'Barcode data (where available)',
                'Product databases (where available)',
              ]),
              _subSection('Important limitations:'),
              _sectionBody('You acknowledge and agree that:'),
              _bulletList([
                'The App does not provide medical advice, diagnosis, or treatment',
                'The App is not a medical device',
                'Results may be incomplete, outdated, or inaccurate',
                'Manufacturers may change ingredients at any time without notice',
                'Database information may be missing or incorrect',
                'Cross-contamination risks cannot be reliably detected',
                'You must always check the physical product label yourself before use',
              ]),
              _subSection('User responsibility:'),
              _sectionBody('You are solely responsible for verifying product safety before consuming or using any product.'),
              _sectionTitle('3. Medical Disclaimer (Expanded Protection)'),
              _sectionBody('The App is not a substitute for professional medical advice.\n\nYou should always:'),
              _bulletList([
                'Consult qualified healthcare professionals for allergy management',
                'Seek emergency medical help when required',
                'Rely on official product labelling over App results',
              ]),
              _sectionBody('We do not guarantee allergen safety or medical outcomes.'),
              _sectionTitle('4. Cross-Contamination and "May Contain" Information'),
              _sectionBody('The App may display allergen warnings based on available label or database data.\n\nYou acknowledge that:'),
              _bulletList([
                '"May contain" warnings are not exhaustive',
                'Cross-contamination risks may not be disclosed by manufacturers',
                'Production environments may introduce undeclared allergens',
                'Information may be incomplete or outdated',
              ]),
              _sectionBody('We are not responsible for allergic reactions or harm resulting from missing or incomplete information.'),
              _sectionTitle('5. Emergency Features and Location Services'),
              _sectionBody('The App includes optional emergency features that are fully user-initiated.'),
              _subSection('5.1 Emergency Responsibility'),
              _sectionBody('You acknowledge that:'),
              _bulletList([
                'The App does not automatically contact emergency services',
                'Emergency actions are only triggered by you',
                'All emergency features depend on device and network availability',
              ]),
              _subSection('5.2 Location Services'),
              _bulletList([
                'Location is only used when you explicitly activate emergency features',
                'Location may be shared only with your chosen contacts via SMS or messaging tools',
                'Location services can be disabled at any time',
              ]),
              _sectionBody('We do not continuously track or store your location.'),
              _subSection('5.3 SMS and Messaging'),
              _bulletList([
                'SMS messages are sent only when you choose to initiate them',
                'Messages may include your location link if enabled',
                'Delivery depends on carrier, device, and network availability',
                'Standard SMS charges may apply',
              ]),
              _sectionBody('We are not responsible for failed or delayed message delivery.'),
              _subSection('5.4 Emergency Dialling'),
              _bulletList([
                'The App may provide shortcuts to emergency numbers (e.g. 000 in Australia)',
                'Calls require your confirmation before being placed',
                'We do not contact emergency services on your behalf',
              ]),
              _sectionTitle('6. Emergency Feature Responsibilities'),
              _sectionBody('You agree that you will:'),
              _bulletList([
                'Keep emergency contact information accurate',
                'Only use emergency features for genuine emergencies',
                'Ensure your device is functional and charged when needed',
                'Understand that delays or failures may occur due to external factors',
              ]),
              _sectionBody('You accept full responsibility for consequences arising from use or misuse of emergency features.'),
              _sectionTitle('7. Subscriptions and Payments'),
              _subSection('7.1 Pricing (AUD)'),
              _bulletList([
                'Weekly: \$3.99',
                'Monthly: \$8.99',
                'Yearly: \$74.99',
              ]),
              _subSection('7.2 Billing'),
              _bulletList([
                'Payments are processed by Google Play or Apple App Store',
                'Subscription management is handled by the respective platform',
                'RevenueCat may be used to verify subscription status',
              ]),
              _subSection('7.3 Renewal and Cancellation'),
              _bulletList([
                'Subscriptions renew automatically unless cancelled before renewal',
                'Cancellation must be done via your app store account settings',
              ]),
              _subSection('7.4 Refunds'),
              _sectionBody('Refunds are handled in accordance with:'),
              _bulletList([
                'Australian Consumer Law (ACL)',
                'Google Play or Apple App Store policies',
              ]),
              _sectionBody('We do not directly control refund decisions.'),
              _sectionTitle('8. User Responsibilities and Acceptable Use'),
              _sectionBody('You agree not to:'),
              _bulletList([
                'Misuse emergency features or trigger false alerts',
                'Provide false or misleading information',
                'Attempt to reverse engineer, modify, or copy the App',
                'Use the App for illegal, harmful, or abusive purposes',
                'Interfere with app functionality or security systems',
              ]),
              _sectionBody('You are responsible for all activity conducted through your account or device.'),
              _sectionTitle('9. Location Data Disclaimer'),
              _sectionBody('You acknowledge that:'),
              _bulletList([
                'Location accuracy depends on your device and environment',
                'GPS signals may be unavailable or inaccurate indoors',
                'Location is only shared when you initiate emergency features',
                'We are not responsible for inaccurate location data',
              ]),
              _sectionTitle('10. Third-Party Services'),
              _sectionBody('The App integrates with third-party services, including:'),
              _bulletList([
                'Google Firebase (Analytics, Crashlytics, Cloud Messaging)',
                'Google ML Kit (on-device text recognition)',
                'Google Maps (location links)',
                'RevenueCat (subscription verification)',
                'Google Play / Apple App Store services',
                'Device-native SMS, location, and calling APIs',
                'Food/product databases where available',
              ]),
              _sectionBody('Each third-party provider operates under its own terms and privacy policies.\n\nWe are not responsible for:'),
              _bulletList([
                'Third-party outages or errors',
                'Data handling by third-party services',
                'Changes to third-party systems or APIs',
              ]),
              _sectionTitle('11. Intellectual Property'),
              _sectionBody('All content, branding, features, designs, and software in the App are owned by or licensed to My Allergy Buddy.\n\nYou may not:'),
              _bulletList([
                'Copy or redistribute the App',
                'Reverse engineer or extract source code',
                'Use branding or content without permission',
              ]),
              _sectionTitle('12. No Warranty'),
              _sectionBody('The App is provided on an "as is" and "as available" basis.\n\nWe make no guarantees regarding:'),
              _bulletList([
                'Accuracy of allergen detection or ingredient data',
                'Continuous or error-free operation',
                'Fitness for any specific medical or dietary purpose',
                'Availability of emergency features',
              ]),
              _sectionTitle('13. Limitation of Liability'),
              _sectionBody('To the maximum extent permitted by law:\n\nMy Allergy Buddy is not liable for any loss, damage, injury, or harm arising from:'),
              _bulletList([
                'Use or misuse of the App',
                'Reliance on allergen or ingredient information',
                'Missed or incorrect allergen detection',
                'Emergency feature delays or failures',
                'SMS or location delivery issues',
                'Data loss or device malfunction',
                'Third-party service failures',
              ]),
              _sectionBody('You use the App entirely at your own risk.'),
              _sectionTitle('14. Termination'),
              _sectionBody('We may suspend or terminate access to the App if you:'),
              _bulletList([
                'Violate these Terms',
                'Misuse emergency or subscription features',
                'Engage in fraudulent, abusive, or harmful behaviour',
              ]),
              _sectionBody('We may take such action without prior notice where necessary.'),
              _sectionTitle('15. Changes to These Terms'),
              _sectionBody('We may update these Terms from time to time.\n\nWhen updates occur:'),
              _bulletList([
                'The "Last Updated" date will change',
                'Material changes may be communicated in-app or via website',
              ]),
              _sectionBody('Continued use of the App means you accept the updated Terms.'),
              _sectionTitle('16. Privacy Policy'),
              _sectionBody('Your use of the App is also governed by our Privacy Policy, which explains how we collect, use, and protect your information.'),
              _sectionTitle('17. Governing Law'),
              _sectionBody('These Terms are governed by the laws of South Australia, Australia, and applicable Commonwealth laws, including Australian Consumer Law.'),
              _sectionTitle('18. Contact Us'),
              _sectionBody('If you have questions about these Terms:'),
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