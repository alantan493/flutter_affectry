// calendar_logbook.dart
import 'package:emotion_journal/pages/ai_analysis_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import 'journal_entry_page.dart';
import '../services/journal_database.dart';
import 'package:logger/logger.dart';

class CalendarLogbookPage extends StatefulWidget {
  const CalendarLogbookPage({super.key});

  @override
  State<CalendarLogbookPage> createState() => _CalendarLogbookPageState();
}

class _CalendarLogbookPageState extends State<CalendarLogbookPage> {
  String? selectedCardId; // Track which card is currently selected
  final Logger _logger = Logger(); // Logger instance

  // Calendar related variables
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<dynamic>> _events = {};

  // Add this state variable
  bool _showCalendar = false; // Controls calendar visibility

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
        // Add calendar toggle button
        actions: [
          IconButton(
            icon: Icon(
              _showCalendar ? Icons.list : Icons.calendar_month,
              color: const Color(0xFF92A3FD),
            ),
            onPressed: () {
              setState(() {
                _showCalendar = !_showCalendar;
              });
            },
            tooltip: _showCalendar ? 'Show List View' : 'Show Calendar View',
          ),
        ],
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

          // Process journal entries for the calendar
          _processJournalEntries(snapshot.data!.docs);

          return Column(
            children: [
              // Show calendar only when _showCalendar is true
              if (_showCalendar) ...[
                _buildCalendar(),
                const Divider(height: 20, thickness: 1),
              ],

              // Date header - show different text based on calendar visibility
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Icon(
                      _showCalendar ? Icons.calendar_today : Icons.list_alt,
                      color: Colors.blue.shade700,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _showCalendar && _selectedDay != null
                          ? 'Entries for ${DateFormat.yMMMd().format(_selectedDay!)}'
                          : 'All Journal Entries',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (_showCalendar && _selectedDay != null)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedDay = null;
                          });
                        },
                        child: const Text('Show All'),
                      ),
                  ],
                ),
              ),

              // Journal entries list
              Expanded(child: _buildJournalEntriesList(snapshot.data!.docs)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
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
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
    );
  }

  // Rest of your existing methods remain the same

  // Process journal entries to create events for the calendar
  void _processJournalEntries(List<DocumentSnapshot> entries) {
    _events = {};

    for (var entry in entries) {
      final data = entry.data() as Map<String, dynamic>;
      if (data['timestamp'] != null) {
        final DateTime entryDate = (data['timestamp'] as Timestamp).toDate();
        // Convert to date only (no time) for comparison
        final DateTime dateOnly = DateTime(
          entryDate.year,
          entryDate.month,
          entryDate.day,
        );

        if (_events[dateOnly] != null) {
          _events[dateOnly]!.add(entry);
        } else {
          _events[dateOnly] = [entry];
        }
      }
    }
  }

  // Build the calendar widget
  Widget _buildCalendar() {
    return TableCalendar(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      calendarFormat: _calendarFormat,
      eventLoader: (day) {
        final dateOnly = DateTime(day.year, day.month, day.day);
        return _events[dateOnly] ?? [];
      },
      selectedDayPredicate: (day) {
        if (_selectedDay == null) return false;
        return isSameDay(_selectedDay!, day);
      },
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
      },
      onFormatChanged: (format) {
        setState(() {
          _calendarFormat = format;
        });
      },
      availableCalendarFormats: const {
        CalendarFormat.month: 'Month',
        CalendarFormat.twoWeeks: '2 Weeks',
        CalendarFormat.week: 'Week',
      },
      onPageChanged: (focusedDay) {
        _focusedDay = focusedDay;
      },
      calendarStyle: CalendarStyle(
        markerDecoration: const BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
        ),
        todayDecoration: BoxDecoration(
          color: Colors.blue.shade200,
          shape: BoxShape.circle,
        ),
        selectedDecoration: const BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
        ),
      ),
      headerStyle: const HeaderStyle(
        formatButtonVisible: true,
        titleCentered: true,
      ),
    );
  }

  // Build the journal entries list filtered by selected date if applicable
  Widget _buildJournalEntriesList(List<DocumentSnapshot> allEntries) {
    List<DocumentSnapshot> filteredEntries;

    if (_selectedDay != null) {
      // Filter entries for selected date
      filteredEntries =
          allEntries.where((entry) {
            final data = entry.data() as Map<String, dynamic>;
            if (data['timestamp'] != null) {
              final DateTime entryDate =
                  (data['timestamp'] as Timestamp).toDate();
              return entryDate.year == _selectedDay!.year &&
                  entryDate.month == _selectedDay!.month &&
                  entryDate.day == _selectedDay!.day;
            }
            return false;
          }).toList();
    } else {
      filteredEntries = allEntries;
    }

    if (filteredEntries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 50, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _selectedDay != null
                  ? 'No entries for ${DateFormat.yMMMd().format(_selectedDay!)}'
                  : 'No journal entries available',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            if (_selectedDay != null)
              ElevatedButton(
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
                            timestamp: _selectedDay,
                            userEmail:
                                FirebaseAuth.instance.currentUser!.email!,
                          ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF92A3FD),
                ),
                child: const Text('Add Entry for This Date'),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredEntries.length,
      itemBuilder: (context, index) {
        final entry = filteredEntries[index];
        final data = entry.data() as Map<String, dynamic>;
        final docId = entry.id;
        final bool isSelected = selectedCardId == docId;

        return Stack(
          children: [
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: InkWell(
                // Update the onTap handler in the _buildJournalEntriesList method
                onTap: () async {
                  // Show options to the user
                  showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    builder: (context) {
                      return Container(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Choose an option',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),
                            ListTile(
                              leading: const Icon(
                                Icons.edit,
                                color: Colors.blue,
                              ),
                              title: const Text('Edit Journal Entry'),
                              onTap: () async {
                                Navigator.pop(
                                  context,
                                ); // Close the bottom sheet

                                // Open the journal entry for editing (existing functionality)
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
                                          timestamp:
                                              data['timestamp']?.toDate(),
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
                            ),
                            ListTile(
                              leading: const Icon(
                                Icons.psychology,
                                color: Colors.green,
                              ),
                              title: const Text('View AI Analysis'),
                              onTap: () async {
                                Navigator.pop(
                                  context,
                                ); // Close the bottom sheet

                                try {
                                  // Check if entry has existing analysis
                                  final DatabaseService db = DatabaseService();
                                  final journalEntry = await db
                                      .getJournalEntryById(docId);

                                  if (journalEntry == null) {
                                    throw Exception('Journal entry not found');
                                  }

                                  if (!context.mounted) return;

                                  if (journalEntry.aiAcknowledgement != null &&
                                      journalEntry.aiAdvice != null) {
                                    // Show existing analysis
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => AIAnalysisPage(
                                              journalEntry: journalEntry,
                                              imageURL: journalEntry.imageURL,
                                              existingAnalysis: true,
                                            ),
                                      ),
                                    );
                                  } else {
                                    // Ask user if they want to generate analysis
                                    final shouldGenerate = await showDialog<
                                      bool
                                    >(
                                      context: context,
                                      builder:
                                          (context) => AlertDialog(
                                            title: const Text(
                                              'No Analysis Found',
                                            ),
                                            content: const Text(
                                              'This entry doesn\'t have an AI analysis yet. Would you like to generate one?',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed:
                                                    () => Navigator.pop(
                                                      context,
                                                      false,
                                                    ),
                                                child: const Text('Cancel'),
                                              ),
                                              ElevatedButton(
                                                onPressed: () {
                                                  print(
                                                    "Generate Analysis button clicked",
                                                  ); // Debug print
                                                  Navigator.pop(context, true);
                                                },
                                                child: const Text(
                                                  'Generate Analysis',
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(
                                                    0xFF92A3FD,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                    );

if (shouldGenerate == true) {
                                      if (context.mounted) {
                                        try {
                                          // Generate new analysis with proper error handling
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => AIAnalysisPage(
                                                journalEntry: journalEntry,
                                                imageURL: journalEntry.imageURL,
                                              ),
                                            ),
                                          ).then((value) {
                                            // Optional: Handle return from AI analysis page
                                            print("Returned from AI Analysis page");
                                          }).catchError((error) {
                                            print("Navigation error: $error");
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Error: $error')),
                                            );
                                          });
                                        } catch (e) {
                                          print("Exception during navigation: $e");
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Error: $e')),
                                          );
                                        }
                                      } else {
                                        print("Context not mounted after dialog");
                                      }
                                    } else {
                                      print("User cancelled analysis generation");
                                    }
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error: $e')),
                                    );
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                onLongPress: () {
                  setState(() {
                    selectedCardId = isSelected ? null : docId;
                  });
                },
                child: ListTile(
                  leading: Icon(
                    Icons.book,
                    size: 50,
                    color: Colors.blue.shade700,
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
                        'Date: ${DateFormat('MMM d, yyyy - h:mm a').format(data['timestamp']?.toDate() ?? DateTime.now())}',
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // X button for deletion
            if (isSelected)
              Positioned(top: 0, right: 0, child: _buildDeleteButton(docId)),
          ],
        );
      },
    );
  }

  // Delete button widget
  Widget _buildDeleteButton(String docId) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          try {
            final DatabaseService db = DatabaseService();
            await db.deleteJournalEntry(docId);

            setState(() {
              selectedCardId = null;
            });

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Journal entry deleted successfully'),
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error deleting entry: $e')),
              );
            }
          }
        },
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.close, color: Colors.white, size: 16),
        ),
      ),
    );
  }
}
