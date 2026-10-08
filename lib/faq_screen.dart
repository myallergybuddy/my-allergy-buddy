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
  final Set<String> _expandedItems = {};

  // FAQ data
  final List<Map<String, dynamic>> _faqItems = [
    // Scanning and Barcode Features
    {
      'category': 'Scanning and Barcode',
      'questions': [
        {
          'question': 'How do I scan a product barcode?',
          'answer': 'On the home screen, tap Scan a Label. Point the camera at the barcode and hold the phone steady in good light until the product is found.',
        },
        {
          'question': 'What if the barcode does not scan?',
          'answer': 'Wipe the barcode, improve the light, and hold the phone steady. If it still does not scan, tap Report this product after the attempt, or go to Settings, then Support, then Report a missing product.',
        },
        {
          'question': 'Can I scan products without barcodes?',
          'answer': 'Yes. On the scan screen, tap Photo Scan and take a photo of the ingredient label, or choose one from your gallery. The text is read on your phone.',
        },
        {
          'question': 'Why can I not find my product?',
          'answer': 'Not every product is in the lookup yet. Go to Settings, then Support, then Report a missing product, or tap Report this product after a scan. You can email photos of the front, the ingredients, and the barcode so it can be added.',
        },
      ],
    },
    // Allergies and Safety
    {
      'category': 'Allergies and Safety',
      'questions': [
        {
          'question': 'How do I add my allergies?',
          'answer': 'On the home screen, tap My Allergies and select the allergens you need to avoid.',
        },
        {
          'question': 'What should I do in a severe allergic reaction?',
          'answer': 'Use your prescribed adrenaline injector if you have one, and call 000. In the app, open Emergency Contacts to call emergency services. Texting a contact opens your SMS app so you can send the message yourself. The app does not call 000 or send texts on its own.',
        },
        {
          'question': 'How accurate is allergen detection?',
          'answer': 'Results come from product databases and from text read on the label. Always read the packet yourself and follow your doctor\'s advice. The app is a guide, not a medical device.',
        },
      ],
    },
    // App Features
    {
      'category': 'App Features',
      'questions': [
        {
          'question': 'How do I upgrade to Premium?',
          'answer': 'Tap Upgrade to Premium on the home screen, or open Settings and tap Upgrade, then choose a plan.',
        },
        {
          'question': 'What is included in Premium?',
          'answer': 'Premium is ad free and includes up to 10 emergency contacts, the advanced allergen database, scan history, and priority support. The free plan includes 2 emergency contacts.',
        },
        {
          'question': 'Can I use the app offline?',
          'answer': 'Your saved allergies stay on the phone and can be viewed offline. Looking up a new barcode needs an internet connection. Photo Scan reads label text on the phone.',
        },
      ],
    },
    // Emergency Contacts
    {
      'category': 'Emergency Contacts',
      'questions': [
        {
          'question': 'How do I add emergency contacts?',
          'answer': 'On the home screen, tap Emergency Contacts, then tap + and enter a name, phone number, and relationship.',
        },
        {
          'question': 'How many emergency contacts can I have?',
          'answer': 'The free plan includes 2 emergency contacts. Premium includes up to 10. Calling 000 and opening an SMS are available on every plan. You still confirm each text in your SMS app.',
        },
      ],
    },
    // Premium and Billing
    {
      'category': 'Premium and Billing',
      'questions': [
        {
          'question': 'How do I cancel Premium?',
          'answer': 'Open the Google Play Store, then Payments and subscriptions, then Subscriptions, and cancel My Allergy Buddy. The plan renews until you cancel it there.',
        },
        {
          'question': 'How do I restore a purchase?',
          'answer': 'Open Upgrade to Premium and tap Restore Purchases. Use the same Google account you used to subscribe.',
        },
        {
          'question': 'How do I pay?',
          'answer': 'Payment is handled by Google Play. The methods available are the ones already set up on that Google account.',
        },
      ],
    },
  ];

  void _toggleExpansion(String id) {
    setState(() {
      if (_expandedItems.contains(id)) {
        _expandedItems.remove(id);
      } else {
        _expandedItems.add(id);
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
            '${category['category']}-$questionIndex',
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildFAQItem(Map<String, dynamic> item, String id) {
    final isExpanded = _expandedItems.contains(id);
    
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
            onTap: () => _toggleExpansion(id),
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
                    'Answers for scanning, allergies, emergency contacts, and Premium. If you still need help, contact support.',
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
