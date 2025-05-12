// home.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/account_database.dart';
import '../domain/user_profile_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DatabaseService _databaseService = DatabaseService();
  UserProfile? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final profile = await _databaseService.getUserProfile();
      setState(() {
        _userProfile = profile;
      });
    } catch (e) {
      // Handle error if needed
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Journal App',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/profile').then((_) {
                  // Refresh user profile data when returning
                  if (mounted) _loadUserProfile();
                });
              },
              child: CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                radius: 20,
                child:
                    _userProfile?.profileImageUrl != null
                        ? ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.network(
                            _userProfile!.profileImageUrl!,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                          ),
                        )
                        : const Icon(Icons.person, color: Colors.blue),
              ),
            ),
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: <Widget>[
                  // 📣 Header + Welcome Message
                  SliverToBoxAdapter(child: _buildHeaderSection(context, user)),

                  // 📊 Mood Summary Card
                  SliverToBoxAdapter(child: _buildMoodSummaryCard(context)),

                  // 💡 Recommendation / Insight Area
                  SliverToBoxAdapter(child: _buildRecommendationCard(context)),

                  // 🔽 Original Content Below
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 40,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),

                          const Text(
                            'Welcome to Your Journal',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Use the bottom navigation bar to create journal entries, view your history, and more.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),

                          const Spacer(), // Pushes logout button to bottom
                          // Logout Button
                          ElevatedButton(
                            onPressed: () async {
                              try {
                                await FirebaseAuth.instance.signOut();
                                Navigator.pushReplacementNamed(
                                  context,
                                  '/login',
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Failed to log out. Please try again.',
                                    ),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              backgroundColor: const Color(0xFF92A3FD),
                              foregroundColor: Colors.black,
                              elevation: 5,
                            ),
                            child: const SizedBox(
                              width: double.infinity,
                              child: Text(
                                'Log Out',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildHeaderSection(BuildContext context, User? user) {
    // Use display name from profile if available, otherwise fall back to email
    final String displayText =
        _userProfile?.displayName ?? user?.email ?? "User";

    return Padding(
      padding: const EdgeInsets.only(left: 28, right: 28, top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Welcome Back!",
            style: TextStyle(color: Colors.grey[600], fontSize: 20),
          ),
          SizedBox(height: 8),
          Text(
            displayText, // Now shows display name if available
            style: const TextStyle(
              color: Colors.black,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text("How are you feeling today?", style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  // --- MOOD SUMMARY CARD ---
  Widget _buildMoodSummaryCard(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 28, vertical: 12),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            // ✅ Add Expanded to allow wrapping
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "This Week",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "3 Journals · 😊 Happy (Awaiting Data Analytics to be set up)", // Long text
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  maxLines: 2,
                  softWrap: true,
                  overflow: TextOverflow.fade,
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xff256fff),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.show_chart, color: Colors.white),
          ),
        ],
      ),
    );
  }

  // --- RECOMMENDATION CARD ---
  Widget _buildRecommendationCard(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 28, vertical: 12),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: const Color(0xff256fff)),
              SizedBox(width: 8),
              Text(
                "Your Tip Today",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            "It looks like you've been stressed lately. Try taking a few deep breaths or writing about what's on your mind. (Awaiting LLM to be set up)",
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
