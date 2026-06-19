import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class FAQScreen extends StatefulWidget {
  const FAQScreen({super.key});

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  static const Color _primaryColor = Color(0xFF4A9E9C);
  
  // Track which FAQ items are expanded
  final Set<int> _expandedItems = {};

  // FAQ data
  final List<Map<String, dynamic>> _faqItems = [
    // Scanning and Barcode Features
    {
      'category': 'Scanning and Barcode',
      'questions': [
        {
          'question': 'How do I scan a product barcode?',
          'answer': 'Tap the camera icon on the home screen, point your camera at the product barcode, and wait for the app to automatically detect and scan it. Make sure the barcode is well-lit and clearly visible.',
        },
        {
          'question': 'What if the barcode doesn\'t scan?',
          'answer': 'Try cleaning the barcode, ensuring good lighting, and holding your device steady. If it still doesn\'t work, you can manually search for the product or add it to our database.',
        },
        {
          'question': 'Can I scan products without barcodes?',
          'answer': 'Yes! You can use the camera to take a photo of the product label and our AI will analyze the ingredients text to identify potential allergens.',
        },
        {
          'question': 'Why can\'t I find my product in the database?',
          'answer': 'Our database is constantly growing. If you can\'t find a product, you can add it manually or contact us to include it in our database.',
        },
      ],
    },
    // Allergies and Safety
    {
      'category': 'Allergies and Safety',
      'questions': [
        {
          'question': 'How do I add my allergies to the app?',
          'answer': 'Go to Settings > My Allergies, then select all the allergens you need to avoid.',
        },
        {
          'question': 'What should I do if I have a severe allergic reaction?',
          'answer': 'If you are having a severe allergic reaction you must use your epipen and call emergency services (000) Australia by hitting the emergency button in this app. All emergency contacts will be notified of your emergency and location (if location settings has been implemented).',
        },
        {
          'question': 'How accurate is the allergen detection?',
          'answer': 'We use multiple databases and AI technology to provide the most accurate information possible. However, always double-check product labels and consult with healthcare professionals for serious allergies.',
        },
        {
          'question': 'Can I trust the app\'s allergy warnings?',
          'answer': 'While we strive for accuracy, always verify with product labels and consult healthcare professionals. The app is a helpful tool but not a replacement for careful label reading.',
        },
      ],
    },
    // App Features
    {
      'category': 'App Features',
      'questions': [
        {
          'question': 'How do I upgrade to Premium?',
          'answer': 'Tap the "Upgrade to Premium" button on the home screen or go to Settings > Premium. Choose from our available subscription plans.',
        },
        {
          'question': 'What features are included in Premium?',
          'answer': 'Premium includes: 10 emergency contacts, advanced allergen database, priority customer support, scan history, and advanced analytics.',
        },
        {
          'question': 'How do I backup my allergy information?',
          'answer': 'Your allergy information is automatically synced to your account. You can also export your data from Settings > Data & Privacy.',
        },
        {
          'question': 'Can I use the app offline?',
          'answer': 'Basic scanning and your saved allergy information work offline. However, product database updates and new product lookups require an internet connection.',
        },
      ],
    },
    // Emergency Contacts
    {
      'category': 'Emergency Contacts',
      'questions': [
        {
          'question': 'How do I add emergency contacts?',
          'answer': 'Go to the Emergency Contacts section from the home screen. Tap the "+" button to add contacts with their name, phone number, and relationship to you.',
        },
        {
          'question': 'How many emergency contacts can I have?',
          'answer': 'Free users can have 2 emergency contacts. Premium users can have up to 10 emergency contacts.',
        },
        {
          'question': 'Do emergency contacts need the app installed?',
          'answer': 'No, emergency contacts will receive regular SMS messages. However, if they have the app, they\'ll get more detailed information about your situation.',
        },
      ],
    },
    // Privacy and Security
    {
      'category': 'Privacy and Security',
      'questions': [
        {
          'question': 'Is my allergy information secure?',
          'answer': 'Yes, we use industry-standard encryption to protect your data. Your allergy information is stored securely and only accessible to you.',
        },
        {
          'question': 'Where is my data stored?',
          'answer': 'Your data is stored locally on your device. We use on-device secure storage and preferences for things like your allergies, emergency contacts, and history. We do not upload your personal data to remote servers.',
        },
        {
          'question': 'Can I delete my account and data?',
          'answer': 'Yes, you can delete your account and all associated data from Settings > Data & Privacy > Delete Account.',
        },
      ],
    },
    // Premium and Billing
    {
      'category': 'Premium and Billing',
      'questions': [
        {
          'question': 'How do I cancel my Premium subscription?',
          'answer': 'You can cancel through your device\'s app store settings (Google Play Store or Apple App Store) or contact our support team.',
        },
        {
          'question': 'How do I restore my Premium purchase?',
          'answer': 'Go to Settings > Premium and tap "Restore Purchases". Make sure you\'re signed in with the same account used for the original purchase.',
        },
        {
          'question': 'What payment methods are accepted?',
          'answer': 'We accept all major credit cards, PayPal, and payment methods supported by Google Play Store and Apple App Store.',
        },
      ],
    },
  ];

  void _toggleExpansion(int index) {
    setState(() {
      if (_expandedItems.contains(index)) {
        _expandedItems.remove(index);
      } else {
        _expandedItems.add(index);
      }
    });
  }

  Widget _buildCategorySection(Map<String, dynamic> category) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: _primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _primaryColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Text(
            category['category'],
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _primaryColor,
            ),
          ),
        ),
        // Questions in this category
        ...List.generate(
          category['questions'].length,
          (questionIndex) => _buildFAQItem(
            category['questions'][questionIndex],
            questionIndex,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildFAQItem(Map<String, dynamic> item, int index) {
    final isExpanded = _expandedItems.contains(index);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Question header
          InkWell(
            onTap: () => _toggleExpansion(index),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item['question'],
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: _primaryColor,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
          // Answer content
          if (isExpanded)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                item['answer'],
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.5,
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
      backgroundColor: const Color(0xFFF5FAF9),
      appBar: AppBar(
        title: Text(
          'Frequently Asked Questions',
          style: GoogleFonts.nunito(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Introduction
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: _primaryColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _primaryColor.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.help_outline,
                    color: _primaryColor,
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Need Help?',
                    style: GoogleFonts.nunito(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Find answers to common questions about MyAllergyBuddy. If you can\'t find what you\'re looking for, contact our support team.',
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            // FAQ Categories
            ..._faqItems.map((category) => _buildCategorySection(category)),
            // Contact support section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(top: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _primaryColor.withValues(alpha: 0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.support_agent,
                    color: _primaryColor,
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Still Need Help?',
                    style: GoogleFonts.nunito(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Can\'t find the answer you\'re looking for? Our support team is here to help!',
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context); // Go back to support screen
                      },
                      icon: const Icon(Icons.email, color: Colors.white),
                      label: Text(
                        'Contact Support',
                        style: GoogleFonts.nunito(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
