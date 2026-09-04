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
              Text('Last updated: July 2026', style: GoogleFonts.nunito(fontSize: 15, color: Colors.grey[700], fontWeight: FontWeight.w600)),
              const SizedBox(height: 20),
              _sectionTitle('1. Introduction'),
              _sectionBody('My Allergy Buddy ("we", "our", "us") is operated by My Allergy Buddy, an Australian sole trader based in Australia.\n\nWe are committed to protecting your privacy and handling your personal information in accordance with the Privacy Act 1988 (Cth) and the Australian Privacy Principles (APPs), where applicable.\n\nThis Privacy Policy explains:'),
              _bulletList([
                'What information we collect',
                'How and why we use it',
                'Who we share it with',
                'How we store and protect it',
                'Your rights and choices',
              ]),
              _sectionBody('By using My Allergy Buddy, you agree to this Privacy Policy and our Terms of Use.\n\nMy Allergy Buddy is designed to operate primarily using data stored locally on your device.\n\nWe only collect information necessary to provide App functionality, improve reliability, deliver notifications, manage subscriptions, and comply with legal obligations.\n\nWhere possible, allergy information and personal settings remain under your control on your device.'),
              _sectionTitle('2. Important Notice (Medical & Safety Disclaimer)'),
              _sectionBody('My Allergy Buddy is an informational tool only designed to assist users in managing allergy-related information.\n\nIt does not provide:'),
              _bulletList([
                'Medical advice',
                'Diagnosis',
                'Treatment',
                'Emergency medical services',
                'Guaranteed allergen detection or product safety verification',
              ]),
              _sectionBody('Users must always:'),
              _bulletList([
                'Read product packaging and ingredient labels directly',
                'Consult qualified healthcare professionals regarding allergies or medical conditions',
                'Use their own judgement when consuming or using any product',
              ]),
              _sectionTitle('3. Nature of Information We Collect'),
              _sectionBody('We only collect personal information that is reasonably necessary to provide and improve the functionality of the app.\n\nSome information collected may be considered sensitive information under Australian law, including health-related information.'),
              _sectionTitle('4. Information You Provide Directly'),
              _sectionBody('You may choose to provide the following information:'),
              _subSection('a. Profile and Allergy Information'),
              _bulletList([
                'Name (optional)',
                'Allergy types',
                'Allergy severity',
                'Reaction history',
                'Personal notes about allergies or health conditions',
              ]),
              _subSection('⚠ Sensitive Health Information Notice'),
              _sectionBody('Allergy and health-related information is considered sensitive information under the Privacy Act 1988 (Cth). We only collect this information with your consent when you choose to enter it into the app.'),
              _subSection('b. Emergency Contact Information'),
              _bulletList([
                'Names of emergency contacts',
                'Phone numbers of emergency contacts',
              ]),
              _sectionBody('This information is stored to enable emergency features you choose to use.'),
              _subSection('c. Security Information'),
              _bulletList([
                'Optional app passcode settings',
                'App lock preferences',
              ]),
              _sectionBody('These are stored locally on your device using available secure storage mechanisms.'),
              _subSection('d. User-Generated Content'),
              _bulletList([
                'Feature requests (e.g. via Google Forms)',
                'Feedback you choose to send',
              ]),
              _sectionBody('External forms are governed by their own privacy policies.'),
              _subSection('e. Consent Statement'),
              _sectionBody('By entering information into My Allergy Buddy or enabling optional features, you consent to the collection and use of that information in accordance with this Privacy Policy.'),
              _sectionTitle('5. Information We Collect Automatically'),
              _sectionBody('When you use the app, we may automatically collect technical and usage information, including:'),
              _subSection('a. Analytics and App Usage'),
              _sectionBody('Collected via Firebase Analytics:'),
              _bulletList([
                'Feature usage patterns',
                'App interactions',
                'Session duration',
                'Scan outcomes (high-level only)',
                'Number of allergens detected (aggregated data)',
              ]),
              _sectionBody('We do not collect full ingredient lists or full scanned images.'),
              _subSection('b. Crash and Diagnostic Data'),
              _sectionBody('Collected via Firebase Crashlytics:'),
              _bulletList([
                'Device model',
                'Operating system version',
                'App version',
                'Crash logs and error reports',
              ]),
              _sectionBody('This helps us improve stability and fix bugs.'),
              _subSection('c. Device and Technical Information'),
              _bulletList([
                'Device type',
                'Operating system version',
                'App version',
                'Language settings',
                'Time zone',
              ]),
              _subSection('d. Push Notification Data'),
              _sectionBody('Collected via Firebase Cloud Messaging:'),
              _bulletList([
                'Device push notification token',
                'Delivery metadata required for notifications',
              ]),
              _subSection('e. Location Information'),
              _sectionBody('Location is only accessed while you are using the app, and only when you explicitly enable features that require it, such as:'),
              _bulletList([
                'Sending your location to emergency contacts',
                'Generating a map link',
              ]),
              _sectionBody('We request “While using the app” location only. We do not request Always / background location, and we do not continuously track your location.'),
              _sectionTitle('6. How We Use Your Information'),
              _sectionBody('We use collected information only where it is reasonably necessary to operate, maintain, and improve My Allergy Buddy.\n\nWe may use your information to:'),
              _bulletList([
                'Provide allergy tracking and management features',
                'Store and display your allergy profile',
                'Enable ingredient scanning and allergen detection features',
                'Maintain scan history on your device',
                'Support emergency contact and SMS features you choose to use',
                'Deliver push notifications you enable',
                'Improve app performance and user experience',
                'Diagnose crashes and fix technical issues',
                'Analyse feature usage at a general, aggregated level',
                'Manage subscriptions and entitlements via Google Play, Apple App Store, and RevenueCat',
                'Store your security settings locally on your device',
              ]),
              _sectionBody('We do not:'),
              _bulletList([
                'Sell your personal information',
                'Rent your personal information',
                'Trade your personal information',
                'Use your personal information for unrelated advertising',
              ]),
              _sectionTitle('7. Permissions Used by the App'),
              _sectionBody('My Allergy Buddy may request access to the following device permissions:'),
              _subSection('a. Camera'),
              _sectionBody('Used for:'),
              _bulletList([
                'Scanning ingredient labels',
                'Capturing images for text recognition',
              ]),
              _subSection('b. Location'),
              _sectionBody('Used only when you choose to:'),
              _bulletList([
                'Share your location with emergency contacts',
                'Generate a map link for emergency situations',
              ]),
              _sectionBody('Location permission is limited to “While using the app”. We do not track your location in the background.'),
              _subSection('c. Notifications'),
              _sectionBody('Used for:'),
              _bulletList([
                'Optional reminders',
                'App alerts',
                'Safety-related messages (if enabled)',
              ]),
              _sectionBody('Notifications can be disabled at any time in device or app settings.'),
              _subSection('d. Internet Access'),
              _sectionBody('Used for:'),
              _bulletList([
                'Firebase services (analytics, crash reporting, messaging)',
                'Subscription verification',
                'Optional external links or services you open',
              ]),
              _sectionTitle('8. Emergency Features and SMS Use'),
              _sectionBody('My Allergy Buddy includes optional emergency features that you may choose to use.'),
              _subSection('a. Emergency SMS'),
              _sectionBody('If you activate emergency messaging:'),
              _bulletList([
                'SMS messages may be sent to your selected emergency contacts',
                'Messages may include your location link (if permission is granted)',
                'Messages are only sent when you explicitly initiate the action',
              ]),
              _subSection('b. Emergency Calls'),
              _bulletList([
                'The app may provide shortcuts to emergency numbers (e.g. 000 in Australia)',
                'Calls are only placed after your confirmation',
                'The app does not automatically contact emergency services',
              ]),
              _subSection('c. Important Limitations'),
              _sectionBody('You acknowledge and agree that:'),
              _bulletList([
                'SMS delivery depends on mobile network availability',
                'GPS accuracy depends on device and environmental conditions',
                'Messages may be delayed or not delivered',
                'We cannot guarantee successful delivery of emergency communications',
              ]),
              _sectionTitle('9. Data Storage Model'),
              _sectionBody('My Allergy Buddy primarily stores data locally on your device, including:'),
              _bulletList([
                'Allergy profiles',
                'Emergency contacts',
                'Scan history',
                'App settings',
                'Security preferences',
              ]),
              _subSection('a. Local Storage'),
              _sectionBody('Data stored locally remains on your device until:'),
              _bulletList([
                'You delete it manually',
                'You uninstall the app',
                'Your device storage is cleared or reset',
              ]),
              _subSection('b. Device Backups'),
              _sectionBody('Your data may be included in:'),
              _bulletList([
                'Google device backups (Android)',
                'Apple iCloud backups (if applicable)',
              ]),
              _sectionBody('These backups are controlled by your device settings and provider policies.'),
              _subSection('c. Cloud Services (Third Parties)'),
              _sectionBody('We use third-party services for specific functions:'),
              _bulletList([
                'Google Firebase (Analytics, Crashlytics, Cloud Messaging)',
                'RevenueCat (subscription management)',
                'Google Play / Apple App Store (billing and purchases)',
              ]),
              _sectionBody('These providers may process data outside Australia.'),
              _sectionTitle('10. Data Security'),
              _sectionBody('We take reasonable administrative, technical, and organisational steps to protect your personal information.\n\nThese include:'),
              _bulletList([
                'Use of reputable third-party providers (e.g. Google Firebase)',
                'Local device storage for sensitive user data',
                'Limited data collection principles',
                'Access controls within the app',
              ]),
              _sectionBody('However, no electronic system is completely secure.'),
              _subSection('Important Notice'),
              _sectionBody('You acknowledge that:'),
              _bulletList([
                'We cannot guarantee absolute security of data transmitted over the internet',
                'You are responsible for securing your device (passcodes, biometrics, updates)',
              ]),
              _sectionTitle('11. Accuracy of Information'),
              _sectionBody('You are responsible for ensuring that information you provide is accurate and up to date, including:'),
              _bulletList([
                'Allergy profiles',
                'Emergency contact details',
                'Any personal notes stored in the app',
              ]),
              _sectionBody('We are not responsible for consequences arising from inaccurate or outdated information entered by users.'),
              _sectionTitle('12. Third-Party Services'),
              _sectionBody('My Allergy Buddy uses trusted third-party service providers to operate core features of the app.\n\nThese providers may process information on servers located outside Australia.\n\nWe use the following services:'),
              _bulletList([
                'Google Firebase (Analytics, Crashlytics, Cloud Messaging)',
                'Google ML Kit (on-device text recognition)',
                'Google Maps (location links where used)',
                'Google Play Billing and Apple In-App Purchases',
                'RevenueCat (subscription and entitlement management)',
                'Google Forms or external links you choose to open within the app',
              ]),
              _sectionBody('Each third party operates under its own privacy policy, which governs how they collect, use, and store data.\n\nWe are not responsible for:'),
              _bulletList([
                'The privacy practices of third-party services',
                'The availability or functionality of third-party systems',
                'Any loss or misuse of data by third-party providers',
              ]),
              _sectionTitle('13. Scan Accuracy and Ingredient Limitations'),
              _sectionBody('My Allergy Buddy provides ingredient scanning and allergen detection tools for informational purposes only.\n\nYou acknowledge and agree that:'),
              _bulletList([
                'Ingredient recognition may not detect all ingredients accurately',
                'Barcode data may be incomplete, outdated, or incorrect',
                'Manufacturers may change product formulations at any time without notice',
                'Packaging may vary by region or batch',
                'Some allergens may not be explicitly listed or may be hidden under alternative names',
              ]),
              _subSection('Important Safety Notice'),
              _sectionBody('You must always verify product packaging and ingredient labels directly before consuming or using any product.\n\nWe are not responsible for:'),
              _bulletList([
                'Missed allergens',
                'Incorrect ingredient identification',
                'Incomplete product data',
                'Adverse reactions resulting from reliance on scan results',
              ]),
              _sectionTitle('14. Medical and Health Disclaimer (Expanded)'),
              _sectionBody('My Allergy Buddy is not a medical device.\n\nThe app does not:'),
              _bulletList([
                'Provide medical advice',
                'Diagnose medical conditions',
                'Replace healthcare professionals',
                'Guarantee allergen safety',
              ]),
              _sectionBody('All information provided is for general informational purposes only.\n\nYou should always consult a qualified medical professional regarding allergies, reactions, or health concerns.'),
              _sectionTitle('15. No Warranty'),
              _sectionBody('My Allergy Buddy is provided on an "as is" and "as available" basis.\n\nTo the maximum extent permitted by law, we do not guarantee:'),
              _bulletList([
                'Continuous or uninterrupted operation of the app',
                'Accuracy or completeness of any information provided',
                'That the app will be free from errors, bugs, or defects',
                'That all allergens will be correctly identified',
              ]),
              _sectionTitle('16. Limitation of Liability'),
              _sectionBody('To the maximum extent permitted under Australian law, My Allergy Buddy and its operator will not be liable for any:'),
              _bulletList([
                'Direct or indirect loss',
                'Injury or harm',
                'Allergic reaction or medical outcome',
                'Loss of data',
                'Device failure',
                'Financial loss',
                'Consequential damages',
              ]),
              _sectionBody('arising from your use of the app or reliance on its features.\n\nYou use the app at your own risk.'),
              _sectionTitle('17. Data Loss and Storage Disclaimer'),
              _sectionBody('While we take reasonable steps to maintain app functionality, we are not responsible for:'),
              _bulletList([
                'Loss of locally stored data',
                'Data corruption',
                'Device failure',
                'Operating system resets or updates',
                'Accidental deletion by the user',
                'Loss of data stored in device or cloud backups',
              ]),
              _sectionTitle('18. Notification Delivery Disclaimer'),
              _sectionBody('Push notifications and alerts depend on:'),
              _bulletList([
                'Third-party services (e.g. Firebase Cloud Messaging)',
                'Device settings',
                'Network availability',
                'Operating system behaviour',
              ]),
              _sectionBody('We cannot guarantee that notifications will always be delivered, timely, or received.'),
              _sectionTitle('19. Location Accuracy Disclaimer'),
              _sectionBody('Where location services are used:'),
              _bulletList([
                'GPS accuracy may vary based on device hardware',
                'Environmental conditions may affect accuracy',
                'Indoor or low-signal environments may reduce accuracy',
              ]),
              _sectionBody('We are not responsible for inaccuracies in location data.'),
              _sectionTitle('20. Machine Learning Disclaimer (Google ML Kit)'),
              _sectionBody('My Allergy Buddy uses Google ML Kit for on-device text recognition.\n\nYou acknowledge that:'),
              _bulletList([
                'ML-based text recognition may produce incorrect results',
                'The system is not medically or safety certified',
                'Results should be verified manually by the user',
              ]),
              _sectionTitle('21. Future Features and Changes'),
              _sectionBody('We may introduce new features in future versions of the app, including but not limited to:'),
              _bulletList([
                'Optional cloud synchronisation',
                'Additional analytics or diagnostics tools',
                'Enhanced scanning capabilities',
                'New safety or allergy tracking features',
              ]),
              _sectionBody('Where such features involve additional personal information, this Privacy Policy will be updated before those features are activated.'),
              _sectionTitle('22. Business Transfers'),
              _sectionBody('If My Allergy Buddy is involved in a business transaction such as:'),
              _bulletList([
                'Sale',
                'Merger',
                'Acquisition',
                'Restructure',
              ]),
              _sectionBody('user information may be transferred as part of that process, subject to applicable privacy laws.'),
              _sectionTitle('23. Privacy Complaints'),
              _sectionBody('If you believe that we have breached the Australian Privacy Principles (APPs) or mishandled your personal information, you may contact us using the details provided below.\n\nWe will:'),
              _bulletList([
                'Acknowledge your complaint',
                'Investigate the issue',
                'Aim to respond within 30 days',
              ]),
              _sectionBody('If you are not satisfied with our response, you may lodge a complaint with the:\n\nOffice of the Australian Information Commissioner (OAIC)\nhttps://www.oaic.gov.au/'),
              _sectionTitle('24. Governing Law'),
              _sectionBody('This Privacy Policy is governed by the laws of South Australia, Australia, and the applicable laws of the Commonwealth of Australia, including the Privacy Act 1988 (Cth).'),
              _sectionTitle('25. Consent Withdrawal'),
              _sectionBody('You may withdraw your consent to the collection or use of your personal information at any time by:'),
              _bulletList([
                'Adjusting or disabling permissions in your device settings',
                'Disabling notifications in the app or system settings',
                'Deleting your data within the app (where available)',
                'Uninstalling the app from your device',
              ]),
              _sectionBody('Please note that some data may remain in third-party systems in accordance with their own retention policies.'),
              _sectionTitle('26. Access, Correction, and Deletion'),
              _sectionBody('You have the right to:'),
              _bulletList([
                'Access personal information stored within the app',
                'Request correction of inaccurate information',
                'Delete your allergy profile, scan history, or emergency contacts (where supported in-app)',
              ]),
              _sectionBody('If you require assistance, you may contact us using the details below.'),
              _sectionTitle('27. International Data Transfers'),
              _sectionBody('Some of our service providers operate globally.\n\nThis means your information may be processed in countries outside Australia, including but not limited to:'),
              _bulletList([
                'United States of America',
                'Other regions where Google, Apple, Firebase, or RevenueCat operate',
              ]),
              _sectionBody('While we take reasonable steps to use reputable providers, you acknowledge that overseas processing may be subject to different privacy laws.'),
              _sectionTitle('28. Security Incident Response (Notifiable Data Breaches)'),
              _sectionBody('In the event of a data breach involving personal information that we control, we will take reasonable steps to:'),
              _bulletList([
                'Identify and contain the incident',
                'Assess the scope and impact',
                'Mitigate any potential harm',
                'Comply with obligations under the Notifiable Data Breaches Scheme (Privacy Act 1988 Cth)',
              ]),
              _sectionBody('Where required, we will notify:'),
              _bulletList([
                'Affected individuals',
                'The Office of the Australian Information Commissioner (OAIC)',
              ]),
              _sectionTitle("29. Children's Privacy"),
              _sectionBody('My Allergy Buddy is not intended for use by children under the age of 13 (or the minimum age required in your jurisdiction).\n\nWe do not knowingly collect personal information from children in violation of applicable law.'),
              _sectionTitle('30. Changes to This Privacy Policy'),
              _sectionBody('We may update this Privacy Policy from time to time.\n\nWhen changes are made:'),
              _bulletList([
                'The "Last Updated" date will be updated',
                'Significant changes may be notified within the app where appropriate',
              ]),
              _sectionBody('Your continued use of the app after changes means you accept the updated policy.'),
              _sectionTitle('31. Contact Us'),
              _sectionBody('If you have any questions, concerns, or privacy requests, you can contact us at:\n\nMy Allergy Buddy\n\nWe aim to respond to privacy-related enquiries within 30 days.'),
              const SizedBox(height: 8),
              Text('📧 myallergybuddy@gmail.com', style: GoogleFonts.nunito(fontSize: 16, color: Colors.black87)),
              _sectionTitle('32. Final Notice (Important Legal Summary)'),
              _sectionBody('By using My Allergy Buddy, you acknowledge and agree that:'),
              _bulletList([
                'The app is provided for informational purposes only',
                'You are responsible for verifying all ingredient and allergy information independently',
                'Emergency features depend on third-party systems and may not always function as expected',
                'We are not liable for medical outcomes, allergic reactions, or decisions made based on app data',
                'You use the app at your own risk',
              ]),
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