import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'faq_screen.dart';
import 'report_missing_product_screen.dart';
import 'user_guide_screen.dart';


class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  // Constants
  static const Color _primaryColor = Color(0xFF4A9E9C);
  static const Duration _animationDuration = Duration(milliseconds: 300);

  // State variables
  final bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _sendEmail() async {
    try {
      const String formUrl = 'https://docs.google.com/forms/d/e/1FAIpQLSfpkeF_EXbiVA2vKA65w9JDSuAv9O78Kz0GO7a4swOG6HkjCg/viewform';
      final Uri formUri = Uri.parse(formUrl);
      
      await launchUrl(formUri, mode: LaunchMode.externalApplication);
      _showSuccessSnackBar('Opening support form...');
      
    } catch (e) {
      _showErrorSnackBar('Failed to open support form: $e');
    }
  }

  Future<void> _openFeatureRequestForm() async {
    try {
      const String formUrl = 'https://docs.google.com/forms/d/e/1FAIpQLSdOE4Pw-kNWQegkruyr3U5OJpXgQRwYAjU0VFuE3A6ihSiCjA/viewform';
      final Uri formUri = Uri.parse(formUrl);
      
      await launchUrl(formUri, mode: LaunchMode.externalApplication);
      _showSuccessSnackBar('Opening feature request form...');
      
    } catch (e) {
      _showErrorSnackBar('Failed to open feature request form: $e');
    }
  }

  Future<void> _copyEmailAddress() async {
    await Clipboard.setData(const ClipboardData(text: 'myallergybuddy@gmail.com'));
    _showSuccessSnackBar('Email address copied to clipboard');
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
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                color: Colors.black,
              ),
            ),
          ),
          ...children,
        ],
      ),
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
          color: Colors.black,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.nunito(
          fontSize: 16,
          color: Colors.black87,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Support',
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? _buildLoadingIndicator()
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // Help and Resources
                  _buildSection(
                    title: 'Help and Resources',
                    children: [
                      _buildListTile(
                        title: 'FAQ',
                        subtitle: 'Frequently asked questions',
                        icon: Icons.help,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FAQScreen(),
                          ),
                        ),
                      ),
                      _buildListTile(
                        title: 'How to Use the App',
                        subtitle: 'Basic steps to get started',
                        icon: Icons.book,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const UserGuideScreen(),
                          ),
                        ),
                      ),
                      _buildListTile(
                        title: 'Feature Request',
                        subtitle: 'Submit a feature request via form',
                        icon: Icons.lightbulb,
                        onTap: _openFeatureRequestForm,
                      ),
                    ],
                  ),

                  // Contact Support
                  _buildSection(
                    title: 'Contact Support',
                    children: [
                      _buildListTile(
                        title: 'Report a missing product',
                        subtitle: 'Product not found? Email photos so we can add it',
                        icon: Icons.add_photo_alternate_outlined,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ReportMissingProductScreen(),
                          ),
                        ),
                      ),
                      _buildListTile(
                        title: 'Contact Support',
                        subtitle: 'Submit a support request via form',
                        icon: Icons.support_agent,
                        onTap: _sendEmail,
                      ),
                      _buildListTile(
                        title: 'Email Address',
                        subtitle: 'myallergybuddy@gmail.com',
                        icon: Icons.copy,
                        onTap: _copyEmailAddress,
                        trailing: const Icon(Icons.copy, color: Color(0xFF4A9E9C)),
                      ),
                    ],
                  ),

                  // Emergency Information
                  _buildSection(
                    title: 'Emergency Information',
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.warning, color: Colors.red, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Emergency Notice',
                                  style: GoogleFonts.nunito(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'If you are experiencing a severe allergic reaction, please call emergency services immediately. This app is not a substitute for professional medical care.',
                              style: GoogleFonts.nunito(
                                fontSize: 14,
                                color: Colors.red[800],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}
