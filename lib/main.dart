import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'services/firebase_service.dart';
import 'services/api_credentials_service.dart';
import 'services/product_database_service.dart';
import 'services/user_learned_product_store.dart';
import 'splash_screen.dart';
import 'welcome_screen.dart';
import 'terms_screen.dart';
import 'privacy_policy_screen.dart';
import 'about_developer_screen.dart';
import 'home_screen.dart';
import 'my_allergies_screen.dart';
import 'services/revenue_cat_service.dart';
import 'emergency_contacts_screen.dart';
import 'settings_screen.dart';
import 'australian_database_screen.dart';
import 'profile_screen.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    try {
      // Initialize Firebase services (skip on web if not configured)
      if (!kIsWeb) {
        await FirebaseService.initialize();
        await FirebaseService.logAppSessionStart();
        await RevenueCatService.initialize();
        await ApiCredentialsService.initialize();
        await ProductDatabaseService.initialize();
        await UserLearnedProductStore.initialize();
      }
    } catch (e) {
      debugPrint('Firebase initialization failed: $e');
      // Continue without Firebase for web
    }
    
    // Set system UI overlay style immediately to prevent white flash
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    
    // Set preferred orientations (skip on web)
    if (!kIsWeb) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }

    // Force immediate app start
    debugPrint('MyApp: Starting app...');
    runApp(const MyApp());
  }, (error, stack) {
    debugPrint('Error in main: $error');
    debugPrint('Stack trace: $stack');
    // Only use Firebase crashlytics if not on web
    if (!kIsWeb) {
      try {
        FirebaseCrashlytics.instance.recordError(error, stack);
      } catch (e) {
        debugPrint('Firebase crashlytics failed: $e');
      }
    }
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('MyApp: Building MaterialApp...');
    return MaterialApp(
      title: 'My Allergy Buddy',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4A9E9C),
          primary: const Color(0xFF4A9E9C),
          secondary: const Color(0xFFB8D8D7),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          iconTheme: IconThemeData(color: Colors.black),
          foregroundColor: Colors.black,
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/terms': (context) => const TermsScreen(),
        '/privacy': (context) => const PrivacyPolicyScreen(),
        '/about_developer': (context) => const AboutDeveloperScreen(),
        '/home': (context) => const HomeScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/my_allergies': (context) => const MyAllergiesScreen(),
        '/emergency_contacts': (context) => const EmergencyContactsScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/australian_database': (context) => const AustralianDatabaseScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
