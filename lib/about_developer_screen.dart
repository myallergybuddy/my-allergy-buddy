import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AboutDeveloperScreen extends StatelessWidget {
  const AboutDeveloperScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'About the Developer',
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
              // Top about developer box
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
                      Icons.person,
                      color: Colors.white,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'About the Developer',
                      style: GoogleFonts.nunito(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Meet the creator of My Allergy Buddy',
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              // Card with main content
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Allergy Buddy was created by a solo indie developer.',
                        style: GoogleFonts.nunito(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'A mother whose child has multiple serious allergies.',
                        style: GoogleFonts.nunito(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "This app was born out of personal experience — countless moments standing in supermarket aisles, trying to decode vague, complex, or incomplete ingredient labels. For parents, carers, and anyone living with life-threatening allergies, every decision about food can feel high stakes. Without a tech background or corporate backing, she created this tool to make those moments easier — empowering others to make safer, faster, and more confident choices, every day.",
                        style: GoogleFonts.nunito(fontSize: 16, color: Colors.black87, height: 1.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Every subscription directly supports the app's ongoing updates and development — helping keep this tool reliable, relevant, and accessible for everyone who needs it.",
                        style: GoogleFonts.nunito(fontSize: 16, color: Colors.black87, height: 1.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "My Allergy Buddy is not affiliated with any medical provider, brand, or institution. It's powered by lived experience, genuine care, and a strong desire to improve allergy safety for others.",
                        style: GoogleFonts.nunito(fontSize: 16, color: Colors.black87, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My goal is to empower you with reliable, easy-to-use tools for managing allergies, emergencies, and everyday choices. I believe technology can make a real difference in health and peace of mind. Thank you',
                        style: GoogleFonts.nunito(fontSize: 16, color: Colors.black87, height: 1.5),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Contact: myallergybuddy@gmail.com',
                        style: GoogleFonts.nunito(fontSize: 15, color: Colors.teal[700]),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Move the purpose card to the bottom
              Card(
                color: Color(0xFF4A9E9C).withValues(alpha: 0.12),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite, color: Color(0xFF4A9E9C), size: 22),
                      SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          'Built by a parent. Powered by purpose.',
                          style: GoogleFonts.nunito(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4A9E9C),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 