import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FeatureRequestScreen extends StatefulWidget {
  const FeatureRequestScreen({super.key});

  @override
  State<FeatureRequestScreen> createState() => _FeatureRequestScreenState();
}

class _FeatureRequestScreenState extends State<FeatureRequestScreen> {
  static const Color _primaryColor = Color(0xFF4A9E9C);

  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _isSubmitting = false;
  bool _isLoadingDraft = true;

  static const String _draftDescriptionKey = 'feature_request_draft_description';
  static const String _draftEmailKey = 'feature_request_draft_email';

  @override
  void initState() {
    super.initState();
    _loadDraft();
    _descriptionController.addListener(_autoSaveDraft);
    _emailController.addListener(_autoSaveDraft);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draftDescription = prefs.getString(_draftDescriptionKey) ?? '';
      final draftEmail = prefs.getString(_draftEmailKey) ?? '';
      setState(() {
        _descriptionController.text = draftDescription;
        _emailController.text = draftEmail;
        _isLoadingDraft = false;
      });
    } catch (_) {
      setState(() {
        _isLoadingDraft = false;
      });
    }
  }

  Future<void> _autoSaveDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_draftDescriptionKey, _descriptionController.text);
      await prefs.setString(_draftEmailKey, _emailController.text);
    } catch (_) {}
  }

  Future<void> _clearDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_draftDescriptionKey);
      await prefs.remove(_draftEmailKey);
    } catch (_) {}
  }

  Future<void> _submit() async {
    debugPrint('Feature Request: Submit button tapped');
    setState(() => _isSubmitting = true);

    try {
      const String formUrl = 'https://docs.google.com/forms/d/e/1FAIpQLSdOE4Pw-kNWQegkruyr3U5OJpXgQRwYAjU0VFuE3A6ihSiCjA/viewform';
      final Uri formUri = Uri.parse(formUrl);
      
      debugPrint('Feature Request: Attempting to launch URL: $formUrl');
      final result = await launchUrl(formUri, mode: LaunchMode.externalApplication);
      debugPrint('Feature Request: Launch result: $result');
      
      await _clearDraft();
      
      if (mounted) {
        Navigator.pop(context);
      }
      
    } catch (e) {
      debugPrint('Feature Request: Error launching URL: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open form: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Feature Request',
          style: GoogleFonts.nunito(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 24,
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
      body: _isLoadingDraft
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _primaryColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _primaryColor.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb, color: _primaryColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Describe the feature you\'d like to see. Include as much detail as possible.',
                        style: GoogleFonts.nunito(fontSize: 14, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'Feature Description',
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 8,
                decoration: InputDecoration(
                  hintText: 'What feature would you like? Why would it help you?',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please describe your feature request';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              Text(
                'Email (optional)',
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Enter email if you want a reply (optional)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) return null; // optional
                  final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                  if (!emailRegex.hasMatch(text)) return 'Please enter a valid email address';
                  return null;
                },
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  icon: const Icon(Icons.send, color: Colors.white),
                  label: Text(
                    _isSubmitting ? 'Sending…' : 'Submit Feature Request',
                    style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }
}


