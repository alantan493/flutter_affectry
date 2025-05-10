// lib/services/account_database.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart'; // ✅ Added Logger import

class DatabaseService {
  // Reference to the 'account_details' collection
  final CollectionReference _accountCollection =
      FirebaseFirestore.instance.collection('account_details');

  final Logger _logger = Logger(); // ✅ Logger instance

  // Method to write user data to Firestore
  Future<void> writeUserData(String email) async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _accountCollection.doc(user.uid).set({
          'email': email,
          'createdAt': DateTime.now().toIso8601String(),
        });
        _logger.d('User data written to Firestore successfully.'); // ✅ Replaced print
      }
    } catch (e) {
      _logger.e('Error writing data to Firestore: $e'); // ✅ Replaced print
    }
  }

  // Method to read user data from Firestore
  Future<Map<String, dynamic>?> readUserData() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final DocumentSnapshot snapshot = await _accountCollection.doc(user.uid).get();
        if (snapshot.exists) {
          return snapshot.data() as Map<String, dynamic>;
        }
      }
      return null; // Return null if no data exists
    } catch (e) {
      _logger.e('Error reading data from Firestore: $e'); // ✅ Replaced print
      return null;
    }
  }

  // Method to update user data in Firestore
  Future<void> updateUserData(Map<String, dynamic> updates) async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _accountCollection.doc(user.uid).update(updates);
        _logger.d('User data updated in Firestore successfully.'); // ✅ Replaced print
      }
    } catch (e) {
      _logger.e('Error updating data in Firestore: $e'); // ✅ Replaced print
    }
  }

  // Method to delete user data from Firestore
  Future<void> deleteUserData() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _accountCollection.doc(user.uid).delete();
        _logger.d('User data deleted from Firestore successfully.'); // ✅ Replaced print
      }
    } catch (e) {
      _logger.e('Error deleting data from Firestore: $e'); // ✅ Replaced print
    }
  }
}