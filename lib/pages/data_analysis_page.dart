// data_analysis_page.dart
import 'package:flutter/material.dart';
import '../services/journal_database.dart';

class DataAnalysisPage extends StatefulWidget {
  const DataAnalysisPage({super.key});

  @override
  State<DataAnalysisPage> createState() => _DataAnalysisPageState();
}

class _DataAnalysisPageState extends State<DataAnalysisPage> {
  final DatabaseService _databaseService = DatabaseService();
  Map<String, int> _emotionCounts = {};
  bool _isLoading = true;

  // Define the emotion grid (copy this from your JournalEntryPage for consistency)
  final List<Map<String, dynamic>> _emotions = [
    {'name': 'Happy', 'iconPath': 'assets/icons/happy.png', 'color': Colors.yellow},
    {'name': 'Sad', 'iconPath': 'assets/icons/sad.png', 'color': Colors.blue},
    {'name': 'Angry', 'iconPath': 'assets/icons/angry.png', 'color': Colors.red},
    {'name': 'Stressed', 'iconPath': 'assets/icons/stressed.png', 'color': Colors.purple},
    {'name': 'Calm', 'iconPath': 'assets/icons/calm.png', 'color': Colors.green},
    {'name': 'Excited', 'iconPath': 'assets/icons/excited.png', 'color': Colors.orange},
    {'name': 'Frustrated', 'iconPath': 'assets/icons/frustrated.png', 'color': Colors.brown},
    {'name': 'Anxious', 'iconPath': 'assets/icons/anxious.png', 'color': Colors.teal},
  ];

  @override
  void initState() {
    super.initState();
    _fetchEmotionCounts();
  }

  Future<void> _fetchEmotionCounts() async {
    try {
      Map<String, int> counts = await _databaseService.getEmotionCounts();
      setState(() {
        _emotionCounts = counts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Data Analysis',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _emotionCounts.isEmpty
              ? const Center(child: Text('No data available.'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GridView.builder(
                    itemCount: _emotions.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.85,
                    ),
                    itemBuilder: (context, index) {
                      final emotion = _emotions[index];
                      final count = _emotionCounts[emotion['name']] ?? 0;
                      return Container(
                        decoration: BoxDecoration(
                          color: emotion['color'].withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 45,
                              height: 45,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Image.asset(
                                  emotion['iconPath'],
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              emotion['name'],
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              count.toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}