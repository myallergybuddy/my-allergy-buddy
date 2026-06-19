import 'package:flutter/material.dart';
import 'dart:async';
// adjust if your home screen is named differently
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _loadingController;
  
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoFadeAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<double> _textSlideAnimation;
  late Animation<double> _loadingFadeAnimation;
  
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    debugPrint('SplashScreen: initState called');
    _initializeAnimations();
    _initializeSplash();
  }

  void _initializeAnimations() {
    // Logo animations
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _logoScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));
    
    _logoFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
    ));

    // Text animations
    _textController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _textFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeInOut,
    ));
    
    _textSlideAnimation = Tween<double>(
      begin: 30.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOutCubic,
    ));

    // Loading animation
    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _loadingFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _loadingController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _initializeSplash() async {
    try {
      // Start logo animation
      _logoController.forward();
      
      // Start text animation after logo starts
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) {
        _textController.forward();
      }
      
      // Start loading animation after text
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) {
        _loadingController.forward();
      }
      
      // Add subtle pulse animation to logo
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        _logoController.repeat(reverse: true);
        _logoController.duration = const Duration(milliseconds: 2000);
      }
      
      // Wait for total animation time plus display time to make it 4 seconds total
      await Future.delayed(const Duration(milliseconds: 2200));
      
      if (mounted) {
        await _checkFirstLaunch();
      }
    } catch (e, stackTrace) {
      debugPrint('SplashScreen: Error in initState: $e');
      debugPrint('SplashScreen: Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _errorMessage = 'Error initializing splash screen';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _checkFirstLaunch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasSeenWelcome = prefs.getBool('has_seen_welcome') ?? false;
      final hasAcceptedTerms = prefs.getBool('terms_accepted') ?? false;
      final hasAcceptedPrivacy = prefs.getBool('privacy_accepted') ?? false;
      
      if (mounted) {
        if (!hasSeenWelcome) {
          // First time user - show welcome screen
          debugPrint('SplashScreen: First time user, navigating to welcome');
          Navigator.pushReplacementNamed(context, '/welcome');
        } else if (hasAcceptedTerms && hasAcceptedPrivacy) {
          // User has completed onboarding - go to home
          debugPrint('SplashScreen: User completed onboarding, navigating to home');
          Navigator.pushReplacementNamed(context, '/home');
        } else if (hasAcceptedTerms) {
          // User accepted terms but not privacy - go to privacy
          debugPrint('SplashScreen: User accepted terms, navigating to privacy');
          Navigator.pushReplacementNamed(context, '/privacy');
        } else {
          // User needs to accept terms
          debugPrint('SplashScreen: User needs to accept terms');
          Navigator.pushReplacementNamed(context, '/terms');
        }
      }
    } catch (e) {
      debugPrint('SplashScreen: Error checking first launch: $e');
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/welcome');
      }
    }
  }

  @override
  void dispose() {
    debugPrint('SplashScreen: dispose called');
    _logoController.dispose();
    _textController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('SplashScreen: build called');
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE3F2FD),
              Color(0xFFF5F5F5),
            ],
          ),
        ),
        child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: size.height - MediaQuery.of(context).padding.vertical - 48),
              child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
                // Logo/Image Section with animations
                AnimatedBuilder(
                  animation: _logoController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _logoScaleAnimation.value,
                      child: Opacity(
                        opacity: _logoFadeAnimation.value,
                        child: Container(
                          width: size.width * 0.5,
                          height: size.width * 0.5,
                          margin: const EdgeInsets.only(bottom: 50),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                                spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipRRect(
                            borderRadius: BorderRadius.circular(size.width * 0.25),
                  child: Image.asset(
                              'assets/images/icon2.png',
                              fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint('SplashScreen: Error loading image: $error');
                      return _buildFallbackImage();
                    },
                  ),
                ),
              ),
                      ),
                    );
                  },
                ),
                
                // Text Section with animations
                AnimatedBuilder(
                  animation: _textController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _textSlideAnimation.value),
                      child: Opacity(
                        opacity: _textFadeAnimation.value,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  children: [
                              SizedBox(
                                width: size.width - 64,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'My Allergy Buddy',
                                    maxLines: 1,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF4A9E9C),
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                    Text(
                      'Your Personal Allergy Assistant',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                                  fontSize: 18,
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                                  letterSpacing: 0.2,
                      ),
                    ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 60),
                
                // Loading indicator with animation
                AnimatedBuilder(
                  animation: _loadingController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _loadingFadeAnimation.value,
                      child: Column(
                        children: [
                          if (_isLoading)
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    const Color(0xFF4A9E9C).withValues(alpha: 0.3),
                                    const Color(0xFF4A9E9C).withValues(alpha: 0.8),
                                    const Color(0xFF4A9E9C).withValues(alpha: 0.3),
                                  ],
                                ),
                              ),
                              child: const Padding(
                                padding: EdgeInsets.all(2.0),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                            ),
                          if (_errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
            ),
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildFallbackImage() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF4A9E9C),
            const Color(0xFF3A8A87),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Icon(
        Icons.medical_services,
        color: Colors.white,
        size: 80,
      ),
    );
  }
}

class TestScreen extends StatelessWidget {
  const TestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Test Screen',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  debugPrint('TestScreen: Button pressed');
                },
                child: const Text('Test Button'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
