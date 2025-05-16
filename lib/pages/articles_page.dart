import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart'; // Add this package to pubspec.yaml

class ArticlesPage extends StatefulWidget {
  const ArticlesPage({super.key});

  @override
  State<ArticlesPage> createState() => _ArticlesPageState();
}

class _ArticlesPageState extends State<ArticlesPage> {
  late Future<List<Map<String, dynamic>>> _papersFuture;
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _papersFuture = _loadAllPapers();
  }

  Future<List<Map<String, dynamic>>> _loadAllPapers() async {
    try {
      final String manifestContent = await rootBundle.loadString('AssetManifest.json');
      final manifestMap = json.decode(manifestContent) as Map<String, dynamic>;
      
      final paperPaths = manifestMap.keys
          .where((key) => key.startsWith('assets/extracted_journals_conference_papers/') && 
                          key.endsWith('.json'))
          .toList();
      
      // Load papers concurrently
      final futures = paperPaths.map((path) async {
        try {
          final raw = await rootBundle.loadString(path);
          return json.decode(raw) as Map<String, dynamic>?;
        } catch (e) {
          debugPrint("❌ Failed to load paper from $path: $e");
          return null;
        }
      }).toList();

      final results = await Future.wait(futures);
      return results.whereType<Map<String, dynamic>>().toList();
    } catch (e) {
      debugPrint("🚨 Error loading papers: $e");
      return [];
    }
  }

  List<Map<String, dynamic>> _filterPapers(List<Map<String, dynamic>> papers) {
    if (_searchQuery.isEmpty) return papers;
    
    final query = _searchQuery.toLowerCase();
    return papers.where((paper) {
      final title = (paper['title'] ?? paper['citation']?['title'] ?? '').toString().toLowerCase();
      final definition = (paper['friendly_definition'] ?? '').toString().toLowerCase();
      final authors = ((paper['citation']?['authors'] as List?) ?? [])
          .map((a) => a.toString().toLowerCase())
          .join(' ');
      
      return title.contains(query) || definition.contains(query) || authors.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Research Papers',
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xff256fff),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() => _papersFuture = _loadAllPapers()),
            tooltip: 'Refresh papers',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _papersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return _buildErrorView(snapshot.error.toString());
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyView();
                }
                
                final filteredPapers = _filterPapers(snapshot.data!);
                return filteredPapers.isEmpty 
                    ? _buildNoResultsView() 
                    : _buildPapersList(filteredPapers);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search papers...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey.shade200,
        ),
        style: GoogleFonts.openSans(),
        onChanged: (value) => setState(() => _searchQuery = value),
      ),
    );
  }

  Widget _buildNoResultsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'No results found for "$_searchQuery"',
            style: GoogleFonts.openSans(fontSize: 16, color: Colors.grey),
          ),
          TextButton(
            onPressed: () => setState(() => _searchQuery = ''),
            child: const Text('Clear search'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Failed to load papers',
            style: GoogleFonts.openSans(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: GoogleFonts.openSans(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => setState(() => _papersFuture = _loadAllPapers()),
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff256fff),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => _showDebugInstructions(context),
            child: const Text('Debug Information'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.article_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'No papers found',
            style: GoogleFonts.openSans(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Make sure you have papers in the assets folder',
            style: GoogleFonts.openSans(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _showDebugInstructions(context),
            icon: const Icon(Icons.bug_report),
            label: const Text('Debug Information'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueGrey,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPapersList(List<Map<String, dynamic>> papers) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: papers.length,
      itemBuilder: (context, index) => _buildPaperCard(context, papers[index], index + 1),
    );
  }

  Widget _buildPaperCard(BuildContext context, Map<String, dynamic> paper, int id) {
    final citation = paper['citation'] is Map ? paper['citation'] as Map<String, dynamic> : {};
    final String title = paper['title'] ?? citation['title'] ?? 'Untitled';
    final List<String> authors = (citation['authors'] as List?)?.map((a) => a.toString()).toList() ?? [];
    final String year = citation['year']?.toString() ?? '';
    final String journal = citation['journal']?.toString() ?? '';
    final String description = paper['friendly_definition']?.toString().trim() ?? 
        'No friendly definition available for this paper.';

    final String heroTag = 'paper-$id-${Object.hash(title, id)}';

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ArticleDetailPage(paper: paper, heroTag: heroTag),
          ),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeroAvatar(id, heroTag),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (authors.isNotEmpty || year.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              "${authors.join(', ')} ${year.isNotEmpty ? '($year)' : ''}",
                              style: GoogleFonts.openSans(fontSize: 13, color: Colors.grey),
                            ),
                          ),
                        if (journal.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              journal,
                              style: GoogleFonts.openSans(
                                fontSize: 12, 
                                color: Colors.grey,
                                fontStyle: FontStyle.italic
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Text(
                description,
                style: GoogleFonts.openSans(fontSize: 14, color: Colors.black54),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ArticleDetailPage(paper: paper, heroTag: heroTag),
                    ),
                  ),
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('View Details'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xff256fff),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroAvatar(int id, String heroTag) {
    return Material(
      elevation: 0,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      color: const Color(0xff256fff).withOpacity(0.1),
      child: Hero(
        tag: heroTag,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Center(
            child: Text(
              id.toString(),
              style: GoogleFonts.montserrat(
                color: const Color(0xff256fff),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDebugInstructions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Debug Instructions", style: GoogleFonts.montserrat()),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("1. Ensure JSON files are in the correct location:", 
                  style: GoogleFonts.openSans()),
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text("assets/extracted_journals_conference_papers/*.json",
                    style: GoogleFonts.openSans()),
              ),
              const SizedBox(height: 12),
              Text("2. Check your pubspec.yaml includes:", 
                  style: GoogleFonts.openSans()),
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text(
                  "assets:\n  - assets/extracted_journals_conference_papers/",
                  style: GoogleFonts.sourceCodePro(),
                ),
              ),
              const SizedBox(height: 12),
              Text("3. Run these commands:", 
                  style: GoogleFonts.openSans()),
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text(
                  "flutter pub get\nflutter clean\nflutter run",
                  style: GoogleFonts.sourceCodePro(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text("Close"),
          )
        ],
      ),
    );
  }
}

class ArticleDetailPage extends StatelessWidget {
  final Map<String, dynamic> paper;
  final String heroTag;

  const ArticleDetailPage({super.key, required this.paper, required this.heroTag});

  @override
  Widget build(BuildContext context) {
    final citation = paper['citation'] is Map ? paper['citation'] as Map<String, dynamic> : {};
    final String title = paper['title'] ?? citation['title'] ?? 'Article';
    final List<String> authors = (citation['authors'] as List?)?.map((a) => a.toString()).toList() ?? [];
    final String year = citation['year']?.toString() ?? '';
    final String journal = citation['journal']?.toString() ?? '';
    final String doi = citation['doi']?.toString() ?? '';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                title,
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              titlePadding: const EdgeInsets.symmetric(horizontal: 48, vertical: 8),
              background: Container(color: const Color(0xff256fff)),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {
                  final shareText = 'Check out this paper: $title by ${authors.join(', ')}';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(shareText)),
                  );
                },
                tooltip: 'Share',
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeroAvatar(context, heroTag),
                  _buildMetadataCard(authors, year, journal, doi),
                  const SizedBox(height: 24),
                  
                  if (_hasContent(paper, 'friendly_definition'))
                    _buildSection(
                      context,
                      "Friendly Definition",
                      paper['friendly_definition'].toString(),
                      Icons.lightbulb_outline,
                    ),
                  
                  if (_hasContent(paper, 'real_life_example'))
                    _buildSection(
                      context,
                      "Real-Life Example",
                      paper['real_life_example'].toString(),
                      Icons.public,
                    ),
                  
                  if (_hasContent(paper, 'often_confused_with'))
                    _buildSection(
                      context,
                      "Often Confused With",
                      paper['often_confused_with'].toString(),
                      Icons.help_outline,
                    ),
                  
                  if (_hasContent(paper, 'research_insight'))
                    _buildSection(
                      context,
                      "Research Insight",
                      paper['research_insight'].toString(),
                      Icons.psychology,
                    ),
                  
                  if (_hasContent(paper, 'personal_check_in'))
                    _buildHighlightedSection(
                      context,
                      "Personal Check-In",
                      paper['personal_check_in'].toString(),
                      Icons.favorite_border,
                    ),
                    
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pop(context),
        backgroundColor: const Color(0xff256fff),
        child: const Icon(Icons.arrow_back),
      ),
    );
  }

  bool _hasContent(Map<String, dynamic> paper, String key) {
    return paper.containsKey(key) && paper[key] != null;
  }

  Widget _buildHeroAvatar(BuildContext context, String heroTag) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Material(
          elevation: 2,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          color: const Color(0xff256fff).withOpacity(0.1),
          child: Hero(
            tag: heroTag,
            child: const SizedBox(
              width: 60,
              height: 60,
              child: Icon(
                Icons.article,
                color: Color(0xff256fff),
                size: 30,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetadataCard(List<String> authors, String year, String journal, String doi) {
    return Card(
      elevation: 1,
      color: Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (authors.isNotEmpty)
              _buildMetadataRow(Icons.people, authors.join(', ')),
              
            if (year.isNotEmpty)
              _buildMetadataRow(Icons.calendar_today, year),
              
            if (journal.isNotEmpty)
              _buildMetadataRow(Icons.library_books, journal, italic: true),
              
            if (doi.isNotEmpty)
              _buildMetadataRow(Icons.link, 'DOI: $doi', isLink: true),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataRow(IconData icon, String text, {bool italic = false, bool isLink = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.openSans(
                fontSize: 14,
                fontStyle: italic ? FontStyle.italic : null,
                color: isLink ? Colors.blue.shade700 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xff256fff), size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.montserrat(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold,
                  color: const Color(0xff256fff),
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          Text(
            content,
            style: GoogleFonts.openSans(fontSize: 16, height: 1.5),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightedSection(BuildContext context, String title, String content, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xff256fff), size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.montserrat(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold,
                  color: const Color(0xff256fff),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xff256fff).withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xff256fff).withOpacity(0.3)),
            ),
            child: Text(
              content,
              style: GoogleFonts.openSans(
                fontSize: 16, 
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
              textAlign: TextAlign.justify,
            ),
          ),
        ],
      ),
    );
  }
}