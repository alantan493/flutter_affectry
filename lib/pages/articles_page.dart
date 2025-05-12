import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class ArticlesPage extends StatelessWidget {
  const ArticlesPage({super.key});

  Future<List<Map<String, dynamic>>> _loadAllPapers() async {
    try {
      // Load the AssetManifest.json to find all JSON paper paths
      final String manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);
      final List<String> paperPaths = manifestMap.keys
          .where((key) =>
              key.startsWith('assets/extracted_journals_conference_papers/') &&
              key.endsWith('.json'))
          .toList();
      debugPrint("🔍 Found paper paths: $paperPaths");

      // Load each JSON file and parse its content
      final List<Map<String, dynamic>> papers = [];
      for (var path in paperPaths) {
        try {
          final String raw = await rootBundle.loadString(path);
          final data = json.decode(raw);
          if (data is Map<String, dynamic>) {
            debugPrint("📄 Loaded paper from $path");
            debugPrint("Friendly Definition: ${data['friendly_definition']}");
            papers.add(data);
          } else {
            debugPrint("❌ Invalid JSON format in $path");
          }
        } catch (e) {
          debugPrint("❌ Failed to load paper from $path: $e");
        }
      }
      return papers;
    } catch (e) {
      debugPrint("🚨 Error loading papers: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Relevant Articles and Journals',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color.fromARGB(0, 0, 0, 0),
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _loadAllPapers(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("No papers found.", style: TextStyle(fontSize: 18)),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _showDebugInstructions(context),
                      icon: const Icon(Icons.bug_report),
                      label: const Text("Show Debug Info"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
                    )
                  ],
                ),
              );
            }
            final papers = snapshot.data!;
            return ListView.builder(
              itemCount: papers.length,
              itemBuilder: (context, index) {
                final paper = papers[index];
                return _buildPaperCard(context, paper, index + 1);
              },
            );
          },
        ),
      ),
    );
  }

  void _showDebugInstructions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Debug Instructions"),
        content: const Text(
          "1. Make sure JSON files are in:\n"
          "   assets/extracted_journals_conference_papers/\n"
          "2. Ensure pubspec.yaml includes:\n"
          "   assets:\n"
          "     - assets/extracted_journals_conference_papers/\n"
          "3. Run:\n"
          "   flutter pub get\n"
          "   flutter clean\n"
          "   flutter run",
        ),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  Widget _buildPaperCard(BuildContext context, Map<String, dynamic> paper, int id) {
    // Handle citation safely
    Map<String, dynamic> citation = {};
    if (paper['citation'] is Map<String, dynamic>) {
      citation = paper['citation'];
    }

    // Extract title, authors, year, and description
    final String title = paper['title'] ?? citation['title'] ?? 'Untitled';
    final List<dynamic>? authorsRaw = citation['authors'] is List ? citation['authors'] : null;
    final List<String> authors = authorsRaw?.map((a) => a.toString()).toList() ?? [];
    final String year = citation['year'] ?? '';
    final String description = paper['friendly_definition']?.toString().trim() ??
        'No friendly definition available for this paper.';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(50),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Paper $id",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                ),
              ),
              const Icon(Icons.article_outlined, color: Color(0xff256fff)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          if (authors.isNotEmpty || year.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                "${authors.join(', ')} ${year.isNotEmpty ? '($year)' : ''}",
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ArticleDetailPage(paper: paper),
                  ),
                );
              },
              icon: const Icon(Icons.read_more, size: 16),
              label: const Text("Read Paper"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff256fff),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class ArticleDetailPage extends StatelessWidget {
  final Map<String, dynamic> paper;

  const ArticleDetailPage({super.key, required this.paper});

  @override
  Widget build(BuildContext context) {
    // Handle citation safely
    Map<String, dynamic> citation = {};
    if (paper['citation'] is Map<String, dynamic>) {
      citation = paper['citation'];
    }

    // Extract title, authors, year, and journal
    final String title = paper['title'] ?? citation['title'] ?? 'Article';
    final List<dynamic>? authorsRaw = citation['authors'] is List ? citation['authors'] : null;
    final List<String> authors = authorsRaw?.map((a) => a.toString()).toList() ?? [];
    final String year = citation['year'] ?? '';
    final String journal = citation['journal'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xff256fff),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (authors.isNotEmpty || year.isNotEmpty)
                Text(
                  "${authors.join(', ')} ${year.isNotEmpty ? '($year)' : ''}",
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              if (journal.isNotEmpty)
                Text(
                  journal,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13, fontStyle: FontStyle.italic),
                ),
              const SizedBox(height: 24),
              // Friendly Definition
              if (paper.containsKey('friendly_definition') && paper['friendly_definition'] != null)
                _buildSection(
                  context,
                  "Friendly Definition",
                  paper['friendly_definition'].toString(),
                ),
              // Real-Life Examples
              if (paper.containsKey('real_life_example') && paper['real_life_example'] != null)
                _buildSection(
                  context,
                  "Real-Life Example",
                  paper['real_life_example'].toString(),
                ),
              // Often Confused With
              if (paper.containsKey('often_confused_with') && paper['often_confused_with'] != null)
                _buildSection(
                  context,
                  "Often Confused With",
                  paper['often_confused_with'].toString(),
                ),
              // Research Insight
              if (paper.containsKey('research_insight') && paper['research_insight'] != null)
                _buildSection(
                  context,
                  "Research Insight",
                  paper['research_insight'].toString(),
                ),
              // Personal Check-In
              if (paper.containsKey('personal_check_in') && paper['personal_check_in'] != null)
                _buildSectionWithContainer(
                  context,
                  "Personal Check-In",
                  paper['personal_check_in'].toString(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xff256fff)),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(fontSize: 16),
          textAlign: TextAlign.justify,
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSectionWithContainer(BuildContext context, String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xff256fff)),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xff256fff).withOpacity(0.3)),
          ),
          child: Text(
            content,
            style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
            textAlign: TextAlign.justify,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}