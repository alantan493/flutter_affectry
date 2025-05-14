import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

class RagService {
  final Logger _logger = Logger();
  List<Map<String, dynamic>> _mockData = [];
  bool _isInitialized = false;

  /// Singleton pattern
  static final RagService _instance = RagService._internal();
  factory RagService() => _instance;
  RagService._internal();

  /// Initialize the service by loading mock data
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Load mock_data.json from assets
      final String jsonString = await rootBundle.loadString('pinecone/mock_data.json');
      final List<dynamic> jsonData = json.decode(jsonString);
      
      // Convert to strongly typed list
      _mockData = jsonData.map((item) => Map<String, dynamic>.from(item)).toList();
      _isInitialized = true;
      _logger.i('RAG Service initialized with ${_mockData.length} entries');
    } catch (e) {
      _logger.e('Error initializing RAG Service: $e');
      // If there's an error loading from assets, try loading from the file system
      try {
        final file = await rootBundle.loadString('assets/pinecone/mock_data.json');
        final List<dynamic> jsonData = json.decode(file);
        _mockData = jsonData.map((item) => Map<String, dynamic>.from(item)).toList();
        _isInitialized = true;
        _logger.i('RAG Service initialized with ${_mockData.length} entries (fallback)');
      } catch (e) {
        _logger.e('Fallback loading failed: $e');
        // Initialize with empty list if loading fails
        _mockData = [];
      }
    }
  }

  /// Calculate simple similarity score between journal entry and mock data item
  /// This uses a combination of emotion matching and keyword matching
  double _calculateSimilarity(
    String emotion,
    String journalContent,
    String pictureDescription,
    Map<String, dynamic> mockDataItem,
  ) {
    double score = 0.0;
    
    // Extract data from the mock data item
    final String mockText = mockDataItem['text'] as String;
    final List<String> mockTags = List<String>.from(mockDataItem['tags']);
    final String mockId = mockDataItem['id'] as String;
    
    // 1. Check if emotion matches the id prefix (e.g., "happy-1" matches emotion "happy")
    if (mockId.startsWith(emotion.toLowerCase())) {
      score += 10.0; // Give high weight to emotion match
    }
    
    // 2. Check if emotion is in the tags
    if (mockTags.contains(emotion.toLowerCase())) {
      score += 5.0;
    }
    
    // 3. Count keyword matches in text
    final List<String> journalWords = _extractKeywords(journalContent);
    final List<String> mockWords = _extractKeywords(mockText);
    
    // Count matching words
    for (final word in journalWords) {
      if (mockWords.contains(word)) {
        score += 1.0;
      }
    }
    
    // 4. Consider picture description if available
    if (pictureDescription.isNotEmpty) {
      final List<String> pictureWords = _extractKeywords(pictureDescription);
      for (final word in pictureWords) {
        if (mockWords.contains(word)) {
          score += 0.5;
        }
      }
    }
    
    return score;
  }
  
  /// Extract meaningful keywords from text
  List<String> _extractKeywords(String text) {
    final List<String> stopWords = [
      'a', 'an', 'the', 'and', 'or', 'but', 'is', 'are', 'in', 'on', 'at', 'to',
      'for', 'with', 'by', 'about', 'as', 'of', 'that', 'it', 'this', 'i', 'you', 'he',
      'she', 'we', 'they', 'be', 'have', 'do', 'can', 'will', 'your', 'my',
    ];
    
    // Convert to lowercase, remove punctuation, and split
    text = text.toLowerCase();
    text = text.replaceAll(RegExp(r'[^\w\s]'), '');
    List<String> words = text.split(' ');
    
    // Remove stop words and filter out empty strings
    return words
        .where((word) => !stopWords.contains(word) && word.isNotEmpty)
        .toList();
  }
  
  /// Get the top N most relevant entries for a journal entry
  Future<List<Map<String, dynamic>>> getTopRelevantEntries({
    required String emotion,
    required String journalContent,
    required String pictureDescription,
    int limit = 3,
    bool debug = true,
  }) async {
    // Ensure the service is initialized
    if (!_isInitialized) {
      await initialize();
    }
    
    // Handle edge case of empty mock data
    if (_mockData.isEmpty) {
      _logger.w('Mock data is empty, returning empty list');
      return [];
    }
    
    // Calculate similarity scores for each item
    final List<Map<String, dynamic>> scoredEntries = _mockData.map((item) {
      final double score = _calculateSimilarity(
        emotion,
        journalContent,
        pictureDescription,
        item,
      );
      
      return {
        'entry': item,
        'score': score,
      };
    }).toList();
    
    // Sort by score in descending order
    scoredEntries.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));
    
    // Take the top N entries
    final topEntries = scoredEntries.take(limit).map((item) => item['entry'] as Map<String, dynamic>).toList();
    
    _logger.i('Retrieved top $limit entries for emotion: $emotion');
    for (int i = 0; i < topEntries.length; i++) {
      final entry = topEntries[i];
      final score = scoredEntries[i]['score'];
      _logger.i('Top ${i+1}: ID: ${entry['id']} - Score: $score - Text: ${entry['text'].substring(0, min(50, entry['text'].length))}...');
    }
    return topEntries;
  }
}