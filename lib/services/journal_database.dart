import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:logger/logger.dart'; // Import logger for debugging
import '../models/journal_entry_model.dart'; // Import the updated JournalEntry model

/// Logger instance for debugging and error logging
final logger = Logger();

/// Class to handle all database operations for journal entries
class DatabaseService {
  final CollectionReference _journalCollection = FirebaseFirestore.instance.collection('journal_entries');

  /// Fetch userEmail from Firestore (if needed)
  Future<String?> fetchUserEmail(String userUid) async {
    try {
      final CollectionReference accountCollection = FirebaseFirestore.instance.collection('account_details');
      final DocumentSnapshot userDoc = await accountCollection.doc(userUid).get();

      if (userDoc.exists) {
        final Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;
        final String? userEmail = userData?['email']; // Replace 'email' with the actual field name in your Firestore document
        logger.i('Fetched userEmail from Firestore: $userEmail');
        return userEmail;
      } else {
        logger.e('User document does not exist in Firestore.');
        return null;
      }
    } catch (e) {
      logger.e('Error fetching userEmail from Firestore: $e');
      return null;
    }
  }

  /// Save a journal entry to Firestore
  /// If id is provided, it will update the existing entry
  /// If id is null, it will create a new entry
  /// Returns the document ID of the saved entry
  Future<String> saveJournalEntry(JournalEntry entry, {String? id}) async {
    try {
      final String? userEmail = FirebaseAuth.instance.currentUser?.email;
      if (userEmail == null || userEmail.isEmpty) {
        throw Exception('User is not logged in or email is unavailable.');
      }

      // Ensure the entry includes the user's email
      final journalEntryWithEmail = JournalEntry(
        emotion: entry.emotion,
        journal: entry.journal,
        pictureDescription: entry.pictureDescription,
        imageURL: entry.imageURL,
        timestamp: entry.timestamp,
        userEmail: userEmail, // Include the user's email
      );

      if (id != null) {
        // Update existing entry
        await _journalCollection.doc(id).set(journalEntryWithEmail.toJson());
        logger.i('Journal entry successfully updated with ID: $id');
        return id;
      } else {
        // Create new entry
        DocumentReference docRef = await _journalCollection.add(journalEntryWithEmail.toJson());
        logger.i('New journal entry successfully created with ID: ${docRef.id}');
        return docRef.id;
      }
    } on FirebaseException catch (e) {
      logger.e('FirebaseException while saving journal entry: ${e.message}');
      rethrow;
    } catch (e) {
      logger.e('Unexpected error while saving journal entry: $e');
      rethrow;
    }
  }

  /// Get a journal entry by its ID
  Future<JournalEntry?> getJournalEntry(String id) async {
    try {
      DocumentSnapshot doc = await _journalCollection.doc(id).get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return JournalEntry.fromJson(data);
      }
      return null;
    } catch (e) {
      logger.e('Error fetching journal entry: $e');
      rethrow;
    }
  }

  /// Delete a journal entry by its ID
  Future<void> deleteJournalEntry(String id) async {
    try {
      await _journalCollection.doc(id).delete();
      logger.i('Journal entry successfully deleted with ID: $id');
    } catch (e) {
      logger.e('Error deleting journal entry: $e');
      rethrow;
    }
  }

  /// Get all journal entries for the current user
  Future<List<Map<String, dynamic>>> getAllJournalEntriesForUser() async {
    try {
      final String? userEmail = FirebaseAuth.instance.currentUser?.email;
      if (userEmail == null || userEmail.isEmpty) {
        throw Exception('User is not logged in or email is unavailable.');
      }

      QuerySnapshot snapshot = await _journalCollection
          .where('userEmail', isEqualTo: userEmail) // Filter by userEmail
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'data': data,
        };
      }).toList();
    } catch (e) {
      logger.e('Error fetching all journal entries for user: $e');
      rethrow;
    }
  }
}

// Keep the original function for backward compatibility
Future<void> sendToFirestore(JournalEntry entry) async {
  try {
    final String? userEmail = FirebaseAuth.instance.currentUser?.email;
    if (userEmail == null || userEmail.isEmpty) {
      throw Exception('User is not logged in or email is unavailable.');
    }

    // Add the user's email to the journal entry
    final journalEntryWithEmail = JournalEntry(
      emotion: entry.emotion,
      journal: entry.journal,
      pictureDescription: entry.pictureDescription,
      imageURL: entry.imageURL,
      timestamp: entry.timestamp,
      userEmail: userEmail, // Include the user's email
    );

    DatabaseService db = DatabaseService();
    await db.saveJournalEntry(journalEntryWithEmail);
    logger.i('Journal entry successfully written to Firestore!');
  } on FirebaseException catch (e) {
    logger.e('FirebaseException while writing journal entry: ${e.message}');
  } catch (e) {
    logger.e('Unexpected error while writing journal entry: $e');
  }
}