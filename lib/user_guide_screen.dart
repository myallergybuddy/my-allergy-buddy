import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class UserGuideScreen extends StatelessWidget {
  const UserGuideScreen({super.key});

  static const Color _primaryColor = Color(0xFF4A9E9C);

  static const List<_GuideStep> _steps = [
    _GuideStep(
      number: 1,
      title: 'Set up your profile',
      description:
          'From the home screen, tap Profile to add your name and personal details. This helps personalise your experience.',
      icon: Icons.person,
    ),
    _GuideStep(
      number: 2,
      title: 'Add your allergies',
      description:
          'Tap My Allergies on the home screen and select the allergens you need to avoid. Set the severity for each one so scan results match your needs.',
      icon: Icons.health_and_safety,
    ),
    _GuideStep(
      number: 3,
      title: 'Scan a product',
      description:
          'Tap Scan a Label, allow camera access, and point your phone at the product barcode. You can also enter a barcode manually or use Photo Scan to capture the ingredients label.',
      icon: Icons.qr_code_scanner,
    ),
    _GuideStep(
      number: 4,
      title: 'Review the results',
      description:
          'After scanning, check the product name, ingredients, and any detected allergens. Look for definite allergens and any “may contain” warnings before deciding whether the product is safe for you.',
      icon: Icons.fact_check,
    ),
    _GuideStep(
      number: 5,
      title: 'Add emergency contacts',
      description:
          'Tap Emergency Contacts on the home screen to save people who should be notified in an emergency. Keep this list up to date.',
      icon: Icons.emergency,
    ),
    _GuideStep(
      number: 6,
      title: 'Find help and settings',
      description:
          'Use Settings for notifications, privacy, and premium options. For FAQs, this guide, or to contact support, go to Settings > Support.',
      icon: Icons.settings,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'How to Use the App',
          style: GoogleFonts.nunito(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2F1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.book, color: _primaryColor, size: 32),
                  const SizedBox(height: 12),
                  Text(
                    'Getting Started',
                    style: GoogleFonts.nunito(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Follow these steps to set up My Allergy Buddy and check products for your allergens.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ..._steps.map(_buildStepCard),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Colors.amber[800], size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Always read product labels yourself and follow your doctor\'s advice. This app is a helpful guide, not medical advice.',
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCard(_GuideStep step) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: _primaryColor,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '${step.number}',
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(step.icon, color: _primaryColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        step.title,
                        style: GoogleFonts.nunito(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  step.description,
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideStep {
  final int number;
  final String title;
  final String description;
  final IconData icon;

  const _GuideStep({
    required this.number,
    required this.title,
    required this.description,
    required this.icon,
  });
}
