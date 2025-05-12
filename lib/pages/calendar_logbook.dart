// calendar_logbook.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'journal_entry_page.dart'; // Import the JournalEntryPage
import '../services/journal_database.dart'; // Import DatabaseService
import 'package:logger/logger.dart'; // ✅ Added Logger

class CalendarLogbookPage extends StatefulWidget {
  const CalendarLogbookPage({super.key});

  @override
  State<CalendarLogbookPage> createState() => _CalendarLogbookPageState();
}

class _CalendarLogbookPageState extends State<CalendarLogbookPage> {
  String? selectedCardId; // Track which card is currently selected
  final Logger _logger = Logger(); // ✅ Logger instance

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Center(child: Text('User not logged in.'));
    }

    final String? currentUserEmail = currentUser.email;

    if (currentUserEmail == null || currentUserEmail.isEmpty) {
      return const Center(child: Text('User email not found.'));
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Calendar Logbook',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      // Add this floating action button
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => JournalEntryPage(
                    emotion: '',
                    journal: '',
                    pictureDescription: '',
                    imageURL: '',
                    userEmail: currentUserEmail,
                  ),
            ),
          ).then((value) {
            // Refresh the page when we return from creating an entry
            setState(() {});
          });
        },
        backgroundColor: const Color(0xFF92A3FD),
        elevation: 6,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'New Journal Entry',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('journal_entries')
                .where('userEmail', isEqualTo: currentUserEmail)
                .orderBy('timestamp', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text("Error fetching data: ${snapshot.error}"),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No journal entries available.'));
          }

          final List<DocumentSnapshot> journalEntries = snapshot.data!.docs;

          // ✅ Replaced print() with Logger
          for (var entry in journalEntries) {
            final data = entry.data() as Map<String, dynamic>;
            _logger.d(
              "Document ID: ${entry.id}, userEmail: ${data['userEmail']}",
            );
          }

          return ListView.builder(
            itemCount: journalEntries.length,
            itemBuilder: (context, index) {
              final entry = journalEntries[index];
              final data = entry.data() as Map<String, dynamic>;
              final docId = entry.id;
              final bool isSelected = selectedCardId == docId;

              return Stack(
                children: [
                  Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: InkWell(
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => JournalEntryPage(
                                  docId: docId,
                                  emotion: data['emotion'] ?? '',
                                  journal: data['journal'] ?? '',
                                  pictureDescription:
                                      data['pictureDescription'] ?? '',
                                  imageURL: data['imageURL'],
                                  timestamp: data['timestamp']?.toDate(),
                                  userEmail: data['userEmail'] ?? '',
                                ),
                          ),
                        );

                        if (result != null && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Journal entry updated!'),
                            ),
                          );
                        }
                      },
                      onLongPress: () {
                        setState(() {
                          selectedCardId = isSelected ? null : docId;
                        });
                      },
                      child: ListTile(
                        leading:
                            data['imageURL'] != null
                                ? Image.network(
                                  data['imageURL'],
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                )
                                : const Icon(
                                  Icons.image_not_supported,
                                  size: 50,
                                ),
                        title: Text(data['emotion'] ?? 'No Emotion'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Journal: ${data['journal'] ?? 'No Journal'}'),
                            Text(
                              'Picture Description: ${data['pictureDescription'] ?? 'No Description'}',
                            ),
                            Text(
                              'Date: ${data['timestamp']?.toDate().toString() ?? 'No Date'}',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // X button for deletion that appears when card is selected
                  if (isSelected)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            try {
                              final DatabaseService db = DatabaseService();
                              await db.deleteJournalEntry(docId);

                              setState(() {
                                selectedCardId = null; // Reset selection
                              });

                              // ✅ Use context.mounted guard
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Journal entry deleted successfully',
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              // ✅ Use context.mounted guard
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error deleting entry: $e'),
                                  ),
                                );
                              }
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
