// lib/services/account_database.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  // Reference to Firestore
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Reference to the 'account_details' collection
  final CollectionReference _accountCollection =
      FirebaseFirestore.instance.collection('account_details');

  // Method to write user data to Firestore
  Future<void> writeUserData(String email) async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _accountCollection.doc(user.uid).set({
          'email': email,
          'createdAt': DateTime.now().toIso8601String(),
        });
        print('User data written to Firestore successfully.');
      }
    } catch (e) {
      print('Error writing data to Firestore: $e');
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
      print('Error reading data from Firestore: $e');
      return null;
    }
  }

  // Method to update user data in Firestore
  Future<void> updateUserData(Map<String, dynamic> updates) async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _accountCollection.doc(user.uid).update(updates);
        print('User data updated in Firestore successfully.');
      }
    } catch (e) {
      print('Error updating data in Firestore: $e');
    }
  }

  // Method to delete user data from Firestore
  Future<void> deleteUserData() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _accountCollection.doc(user.uid).delete();
        print('User data deleted from Firestore successfully.');
      }
    } catch (e) {
      print('Error deleting data from Firestore: $e');
    }
  }
}