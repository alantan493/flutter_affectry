import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/firebase_options.dart';

// Import screens
import 'pages/login.dart';
import 'pages/create_account.dart';
import 'pages/forget_password.dart';
import 'bottom_navigation_bar.dart';
import 'pages/user_profile/profile_page.dart';
import 'pages/user_profile/edit_profile.dart';

// Import utilities
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Onboarding screen
import 'onboarding/onboarding_flow.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final logger = Logger();

  // Check if user has already onboarded
  final prefs = await SharedPreferences.getInstance();
  final onboarded = prefs.getBool('hasOnboarded') ?? false;

  // Initialize Firebase
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    logger.i('Firebase initialized successfully.');
  } catch (e) {
    logger.e('Error initializing Firebase: $e');
  }

  runApp(MyApp(onboarded: onboarded));
}

class MyApp extends StatelessWidget {
  final bool onboarded;

  const MyApp({super.key, required this.onboarded});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Journal App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: onboarded ? '/login' : '/',
      routes: {
        '/': (context) => const OnboardingFlow(),
        '/login': (context) => const LoginPage(),
        '/create_account': (context) => const CreateAccountPage(),
        '/forget_password': (context) => const ForgetPasswordPage(),
        '/home': (context) => const BottomNavigationBarScreen(),
        '/profile': (context) => const ProfilePage(),
        '/edit_profile': (context) => const EditProfilePage(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}