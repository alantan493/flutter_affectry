import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // For Firebase initialization
import 'services/firebase_options.dart'; // Firebase configuration

// Import screens
import 'pages/login.dart'; // Login screen
import 'pages/create_account.dart'; // Create Account screen
import 'pages/forget_password.dart'; // Forgot Password screen
import 'pages/home.dart'; // Home screen

// Import logger for better debugging
import 'package:logger/logger.dart';

void main() async {
  // Initialize Logger
  final logger = Logger();

  // Ensure Flutter bindings are initialized before running the app
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with error handling
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    logger.i('Firebase initialized successfully.'); // Use logger instead of print
  } catch (e) {
    logger.e('Error initializing Firebase: $e'); // Use logger instead of print
  }

  // Run the app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Journal App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginPage(),
        '/create_account': (context) => const CreateAccountPage(),
        '/forget_password': (context) => const ForgetPasswordPage(),
        '/home': (context) => const HomePage(),
        '/login': (context) => const LoginPage(), // Define the /login route
      },
      debugShowCheckedModeBanner: false, // Remove the debug banner
    );
  }
}