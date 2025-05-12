import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/account_database.dart'; // Import the updated database service

class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key});

  @override
  _CreateAccountPageState createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseService _databaseService = DatabaseService();

  Future<void> _createAccount() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Input validation
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    try {
      // Step 1: Create the user in Firebase Authentication
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Step 2: Store additional user data in Firestore
      if (mounted) {
        final additionalInfo = await _collectAdditionalInfo(context);

        // Step 3: Store user data with additional info in Firestore
        await _databaseService.createUserProfile(
          email,
          additionalInfo['displayName'],
          additionalInfo['age'],
          additionalInfo['bio'],
        );

        // Show success message and navigate back to login page
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account created successfully!')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      String errorMessage = 'An error occurred. Please try again.';
      if (e.toString().contains('invalid-email')) {
        errorMessage = 'Invalid email format.';
      } else if (e.toString().contains('weak-password')) {
        errorMessage = 'Password should be at least 6 characters long.';
      } else if (e.toString().contains('email-already-in-use')) {
        errorMessage = 'This email is already registered.';
      }

      if (!mounted) return; // Guard against async gaps
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    }
  }

  Future<Map<String, dynamic>> _collectAdditionalInfo(
    BuildContext context,
  ) async {
    String? displayName;
    int? age;
    String? bio;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final displayNameController = TextEditingController();
        final ageController = TextEditingController();
        final bioController = TextEditingController();

        return AlertDialog(
          title: const Text('Complete Your Profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: displayNameController,
                  decoration: const InputDecoration(labelText: 'Display Name'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: ageController,
                  decoration: const InputDecoration(labelText: 'Age'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: bioController,
                  decoration: const InputDecoration(
                    labelText: 'Bio (optional)',
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                displayName = displayNameController.text.trim();
                age =
                    ageController.text.isNotEmpty
                        ? int.tryParse(ageController.text.trim())
                        : null;
                bio = bioController.text.trim();
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    return {'displayName': displayName, 'age': age, 'bio': bio};
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 216, 216, 216),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Title
            Text(
              'Create Account',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 40),

            // Email Input Field
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(color: Colors.black),
                filled: true,
                fillColor:
                    Colors.white, // Distinct background color for input fields
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Password Input Field
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle: TextStyle(color: Colors.black),
                filled: true,
                fillColor:
                    Colors.white, // Distinct background color for input fields
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Create Account Button
            ElevatedButton(
              onPressed: _createAccount,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 15,
                  horizontal: 50,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                backgroundColor: Colors.blue, // Distinct button color
                foregroundColor: Colors.white, // Text color
                elevation: 5,
              ),
              child: const Text(
                'Create Account',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 15),

            // Back to Login Button
            OutlinedButton(
              onPressed: () {
                Navigator.pop(context); // Navigate back to the login screen
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 20,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                side: BorderSide(
                  color: Colors.blue, // Distinct outline color
                  width: 2.0,
                ),
                foregroundColor: Colors.blue, // Text color
              ),
              child: const Text(
                'Back to Login',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
