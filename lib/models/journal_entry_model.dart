import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore for Timestamp

/// Represents a journal entry in Firestore.
class JournalEntry {
  /// The emotion associated with the journal entry.
  final String emotion;

  /// The main content of the journal entry.
  final String journal;

  /// A description of the picture associated with the journal entry.
  final String pictureDescription;

  /// An optional URL for an image associated with the journal entry.
  final String? imageURL;

  /// The timestamp when the journal entry was created.
  final DateTime timestamp;

  /// The unique ID of the user who created the journal entry.
  final String userEmail;

  /// Default values for optional fields.
  static const String defaultEmotion = '';
  static const String defaultJournal = '';
  static const String defaultPictureDescription = '';

  /// Constructor for creating a new JournalEntry object.
  JournalEntry({
    required this.emotion,
    required this.journal,
    required this.pictureDescription,
    this.imageURL,
    required this.timestamp,
    required this.userEmail, // Required field for user ID
  });

  /// Converts the object into a JSON map for Firestore.
  Map<String, dynamic> toJson() {
    return {
      'emotion': emotion,
      'journal': journal,
      'pictureDescription': pictureDescription,
      'imageURL': imageURL,
      'timestamp': timestamp, // Store as DateTime
      'userEmail': userEmail, // Include userId in Firestore
    };
  }

  /// Factory method to create a JournalEntry from a Firestore document.
  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    final userId = json['userId'];
    if (userId == null || userId.isEmpty) {
      throw ArgumentError('userId cannot be null or empty');
    }

    return JournalEntry(
      emotion: json['emotion'] ?? defaultEmotion,
      journal: json['journal'] ?? defaultJournal,
      pictureDescription: json['pictureDescription'] ?? defaultPictureDescription,
      imageURL: json['imageURL'],
      timestamp: (json['timestamp'] as Timestamp).toDate(), // Convert Firestore Timestamp to DateTime
      userEmail: json['userEmail'], 
    );
  }
}