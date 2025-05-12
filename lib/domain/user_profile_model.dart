import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String email;
  final String? displayName;
  final int? age;
  final String? bio;
  final String? profileImageUrl;
  final DateTime createdAt;

  UserProfile({
    required this.uid,
    required this.email,
    this.displayName,
    this.age,
    this.bio,
    this.profileImageUrl,
    required this.createdAt,
  });

  // Factory constructor to create UserProfile from Firestore document
  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      age: data['age'],
      bio: data['bio'],
      profileImageUrl: data['profileImageUrl'],
      createdAt:
          data['createdAt'] != null
              ? (data['createdAt'] is Timestamp
                  ? (data['createdAt'] as Timestamp).toDate()
                  : DateTime.parse(data['createdAt']))
              : DateTime.now(),
    );
  }

  // Convert UserProfile to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'age': age,
      'bio': bio,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
