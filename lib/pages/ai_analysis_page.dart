import 'dart:io';
import 'package:flutter/material.dart';
import '../models/journal_entry_model.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/ai_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/image_storage.dart';

class AIAnalysisPage extends StatefulWidget {
  final JournalEntry journalEntry;
  final String? imageURL;

  const AIAnalysisPage({
    super.key,
    required this.journalEntry,
    this.imageURL,
  });

  @override
  State<AIAnalysisPage> createState() => _AIAnalysisPageState();
}

class _AIAnalysisPageState extends State<AIAnalysisPage> {
  bool _isAnalyzing = true;
  String _acknowledgement = '';
  String _advice = '';
  String _errorMessage = '';
  
  // Change to nullable for async initialization
  AIService? _aiService;
  final ImageStorageService _imageStorageService = ImageStorageService();

  @override
  void initState() {
    super.initState();
    _performAnalysis();
  }

  Future<void> _performAnalysis() async {
    try {
      // First properly initialize the AIService
      _aiService = await AIService.create();
      
      // Check if service initialized properly
      if (!(_aiService?.isInitialized ?? false)) {
        setState(() {
          _isAnalyzing = false;
          _errorMessage = "Unable to initialize AI service. Please check your configuration.";
        });
        return;
      }
      
      // Download image if URL is provided
      File? imageFile;
      if (widget.imageURL != null && widget.imageURL!.isNotEmpty) {
        imageFile = await _imageStorageService.downloadImageFromUrl(widget.imageURL!);
      }
      
      // Only proceed if widget is still mounted
      if (!mounted) return;
      
      // Get separate analyses from the AI service
      final acknowledgement = await _aiService!.acknowledgeFeeling(
        emotion: widget.journalEntry.emotion,
        journalContent: widget.journalEntry.journal,
        pictureDescription: widget.journalEntry.pictureDescription,
        imageFile: imageFile,
      );
      
      if (!mounted) return;
      
      final advice = await _aiService!.provideAdvice(
        emotion: widget.journalEntry.emotion,
        journalContent: widget.journalEntry.journal,
        pictureDescription: widget.journalEntry.pictureDescription,
        imageFile: imageFile,
      );
      
      if (!mounted) return;
      
      setState(() {
        _isAnalyzing = false;
        _acknowledgement = acknowledgement;
        _advice = advice;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _acknowledgement = "Sorry, I couldn't analyze your entry at this time.";
          _advice = "Please try again later.";
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        // Existing appBar configuration
        title: const Text(
          'AI Analysis',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8F8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: SvgPicture.asset('assets/icons/Arrow - Left 2.svg'),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildJournalDetails(),
            const SizedBox(height: 25),
            if (_isAnalyzing)
              _buildLoadingIndicator()
            else if (_errorMessage.isNotEmpty)
              _buildErrorMessage()
            else
              Column(
                children: [
                  _buildAcknowledgementSection(),
                  const SizedBox(height: 16),
                  _buildAdviceSection(),
                ],
              ),
            const SizedBox(height: 30),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Card(
      elevation: 4,
      color: Colors.red[100],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 40),
            const SizedBox(height: 16),
            const Text(
              'Unable to analyze your journal entry',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage.isEmpty ? 
                'Please try again later.' : 
                'Error: $_errorMessage',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isAnalyzing = true;
                  _errorMessage = '';
                });
                _performAnalysis();
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Card(
      elevation: 4,
      color: const Color(0xFFEBF5FF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Analyzing your journal entry...'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAcknowledgementSection() {
    return Card(
      elevation: 4,
      color: const Color(0xFFEBF5FF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.psychology_alt,
                  color: Colors.blue[800],
                ),
                const SizedBox(width: 10),
                Text(
                  'Understanding Your Feelings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _acknowledgement,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdviceSection() {
    return Card(
      elevation: 4,
      color: const Color(0xFFF0F9EB),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.tips_and_updates,
                  color: Colors.green[700],
                ),
                const SizedBox(width: 10),
                Text(
                  'Suggestions & Next Steps',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _advice,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJournalDetails() {
    final DateFormat dateFormat = DateFormat('MMM d, yyyy');
    final DateFormat timeFormat = DateFormat('h:mm a');
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Journal Entry',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
            const SizedBox(height: 15),
            
            // Emotion
            _buildDetailItem('Emotion', widget.journalEntry.emotion),
            const Divider(),
            
            // Journal text
            _buildDetailItem('Journal Content', widget.journalEntry.journal),
            const Divider(),
            
            // Picture description
            _buildDetailItem('Picture Description', widget.journalEntry.pictureDescription),
            
            // Display image if available
            if (widget.imageURL != null && widget.imageURL!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Attached Image:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        widget.imageURL!,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(
                              height: 180,
                              color: Colors.grey[200],
                              child: const Center(
                                child: Text('Unable to load image'),
                              ),
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 12),
            
            // Date and time
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  dateFormat.format(widget.journalEntry.timestamp),
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(width: 16),
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  timeFormat.format(widget.journalEntry.timestamp),
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[300],
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
              ),
            ),
            child: const Text('Edit Entry'),
          ),
          const SizedBox(width: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/home');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF92A3FD),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
              ),
              elevation: 5,
            ),
            child: const Text('Save & Finish'),
          ),
        ],
      ),
    );
  }
}