import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'widgets/user_guide_prompt.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  final bool isReadOnly;
  
  const PrivacyPolicyScreen({
    super.key,
    this.isReadOnly = false,
  });

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  // final bool _understood = false; // Removed unused field
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
      _checkPrivacyAcceptance();
    }
  }

  Future<void> _checkPrivacyAcceptance() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasAcceptedPrivacy = prefs.getBool('privacy_accepted') ?? false;
      
      if (hasAcceptedPrivacy) {
        // User has already accepted privacy policy, go directly to home
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        // User needs to accept privacy policy
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

  Future<void> _acceptPrivacyPolicy() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('privacy_accepted', true);
      await UserGuidePrompt.scheduleAfterOnboarding();
      
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      // Handle error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save privacy policy acceptance'),
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
          'Privacy Policy',
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
              // Top privacy policy box
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
                            Icons.privacy_tip,
                            color: Colors.white,
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Privacy Policy',
                            style: GoogleFonts.nunito(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'How we protect your data',
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
              _sectionTitle('1. Introduction'),
              _sectionBody('My Allergy Buddy (“we”, “us”) respects your privacy. This Privacy Policy describes what information the app may collect, how it is used, and your choices. By using the app, you agree to this policy together with our Terms of Use.'),
              _sectionTitle('2. What We Collect'),
              _subSection('a. Information you provide'),
              _bulletList([
                'Profile details you enter (e.g. name, phone number)',
                'Allergy selections, severity, notes, and related health information you choose to save',
                'Emergency contact names and phone numbers',
                'Optional passcode or recovery-related information you configure',
                'Content you submit through external forms (e.g. feature request Google Forms), which are governed by those services',
              ]),
              _subSection('b. Information collected automatically'),
              _bulletList([
                'Crash logs and diagnostics via Firebase Crashlytics (Google)',
                'App analytics and custom events via Firebase Analytics (Google), which may include parameters such as product names from scans, whether allergens were detected, counts, feature usage, and session activity',
                'Firebase Cloud Messaging (FCM) device tokens and related data needed to deliver push notifications',
                'Device and app technical data as collected by the above Firebase services',
                'Approximate or precise GPS location only when you use features that request it (e.g. emergency messaging with a maps link)',
              ]),
              _subSection('c. Camera, images, and on-device processing'),
              _bulletList([
                'If you use label or photo scanning, the camera captures images you point at labels; text recognition uses Google ML Kit on your device where supported',
                'Processing is designed to run on-device for recognition; analytics events may still log high-level scan outcomes as described above',
              ]),
              _subSection('d. Security-related data'),
              _bulletList([
                'Passcodes and sensitive values may be encrypted (e.g. AES-256) and stored using the device secure storage / keychain where applicable',
                'If you enable biometric unlock, biometric templates are handled only by your device’s operating system—not sent to us',
              ]),
              _sectionTitle('3. How We Use Your Data'),
              _bulletList([
                'Provide allergy tracking, scanning, history, notifications, emergency contacts, and related features',
                'Improve stability and diagnose issues (Crashlytics)',
                'Understand how features are used and improve the product (Analytics)',
                'Deliver and manage push notifications (FCM)',
                'Manage premium or subscription state via the platform or, when enabled, third-party subscription tools',
                'Protect the app with passcodes, biometrics, or similar controls you turn on',
              ]),
              _sectionTitle('4. Data Security'),
              _bulletList([
                'We use encryption and secure storage for sensitive local data where implemented',
                'Internet transmission is not perfectly secure; we rely on reputable providers (e.g. Google Firebase) for hosted services',
                'You are responsible for device security (lock screen, OS updates)',
              ]),
              _sectionTitle('5. Location Services'),
              _bulletList([
                'Location is used when you activate features that include it (e.g. sharing a Google Maps link with emergency contacts)',
                'Shared with recipients you choose (e.g. via SMS); not sold by us',
                'You can revoke location permission in your device settings',
              ]),
              _sectionTitle('6. SMS and Emergency Features'),
              _bulletList([
                'SMS may be used to reach your emergency contacts when you use those features',
                'Messages may include your location link if you grant permission',
                'Emergency dialling features may use local emergency numbers (e.g. 000 in Australia) where applicable',
                'Keep emergency contact details accurate; carrier SMS charges may apply',
              ]),
              _sectionTitle('7. Local Storage and Cloud Services'),
              _bulletList([
                'Core allergy, profile, scan history, and similar app data are stored primarily on your device (e.g. SharedPreferences / local storage)',
                'Firebase (Google) processes analytics, crash reporting, and push notification infrastructure as described above; that processing occurs under Google’s terms and privacy policy',
                'If you use iCloud, Google backup, or similar OS backup, copies of app data may be stored by your platform provider according to their settings',
                'We do not operate our own separate “My Allergy Buddy” cloud database for your full health profile in the current app version',
              ]),
              _sectionTitle('8. Your Rights'),
              _bulletList([
                'Access, correct, or delete information stored in the app through in-app settings where available',
                'Control permissions (camera, location, notifications) in system settings',
                'Request information or assistance by contacting us (see below); regional laws (e.g. GDPR, CCPA) may grant additional rights where they apply',
              ]),
              _sectionTitle('9. Data Retention'),
              _bulletList([
                'On-device data generally remains until you delete it or uninstall the app',
                'Firebase/Google may retain analytics and crash data for periods defined in their policies, which may persist after you uninstall the app',
                'Backups on your device or cloud account are controlled by you and your platform provider',
              ]),
              _sectionTitle('10. Third-Party Services'),
              _bulletList([
                'Google Firebase (Analytics, Crashlytics, Cloud Messaging, core SDKs)—see policies at https://firebase.google.com/support/privacy',
                'Google ML Kit (on-device text recognition)',
                'Google Maps (links generated for location sharing)',
                'Google Play / Apple App Store and their billing systems for purchases',
                'Subscription management providers (e.g. RevenueCat) when integrated—subject to their privacy terms',
                'External websites or forms opened from the app (e.g. Google Forms) are governed by those sites',
              ]),
              _sectionTitle("11. Children's Privacy"),
              _sectionBody('The app is not directed at children under 13 (or the minimum age required in your region). We do not knowingly collect personal information from children in violation of applicable law.'),
              _sectionTitle('12. Changes to This Policy'),
              _sectionBody('We may update this policy from time to time. The “Last updated” date will change, and we may show an in-app notice for material changes where appropriate.'),
              _sectionTitle('13. International Processing'),
              _bulletList([
                'We are based in Australia and aim to comply with the Australian Privacy Principles (APPs) where they apply',
                'Providers such as Google may process data in the United States and other countries where they operate',
                'Depending on your location, laws such as the GDPR or CCPA may also apply; contact us to exercise applicable rights',
              ]),
              _sectionTitle('14. Emergency Data Use'),
              _bulletList([
                'When you use emergency features, information you choose to send (e.g. location link, message content) is shared with the recipients or services you select',
                'We do not use that content for marketing',
              ]),
              _sectionTitle('15. Security Incidents'),
              _bulletList([
                'If we become aware of a breach affecting personal data we control, we will take reasonable steps to mitigate harm and notify users or regulators where required by law',
              ]),
              _sectionTitle('16. No Automated Decision-Making'),
              _sectionBody('The app does not make legally significant automated decisions about you. Features are initiated by you; on-device ML assists with text recognition only as part of scanning you choose to run.'),
              _sectionTitle('17. Consent Withdrawal'),
              _bulletList([
                'Adjust or revoke permissions in device settings',
                'Disable notifications or biometric unlock in the app or system settings',
                'Uninstall the app to remove locally stored app data from the device (subject to backups and third-party retention as above)',
              ]),
              _sectionTitle('18. Contact Us'),
              _sectionBody('For questions or privacy requests:'),
              const SizedBox(height: 8),
              Text('📧 myallergybuddy@gmail.com', style: GoogleFonts.nunito(fontSize: 16, color: Colors.black87)),
              Text('📍 My Allergy Buddy, Australia', style: GoogleFonts.nunito(fontSize: 16, color: Colors.black87)),
              const SizedBox(height: 32),
              // Acceptance button
              if (!widget.isReadOnly) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: ElevatedButton(
                    onPressed: _acceptPrivacyPolicy,
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
                      'I Accept Privacy Policy',
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