import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

class AIService {
  final Logger logger = Logger();
  String? _apiKey;
  bool _isInitialized = false;
  
  /// Factory constructor that ensures proper async initialization
  static Future<AIService> create() async {
    final service = AIService._();
    await service._initialize();
    return service;
  }
  
  // Private constructor
  AIService._();
  
  // For backward compatibility - but prefer using the factory method
  AIService() {
    _loadApiKey();
    logger.i('AIService created with synchronous initialization. Consider using AIService.create() instead.');
  }
  
  Future<void> _initialize() async {
    await _loadApiKeyAsync();
    _isInitialized = true;
  }
  
  void _loadApiKey() {
    try {
      // Use a safer approach that doesn't throw if dotenv isn't initialized
      _apiKey = dotenv.maybeGet('OPENAI_API_KEY');
      if (_apiKey == null || _apiKey!.isEmpty) {
        logger.e('OpenAI API key not found. Please check your .env file');
      }
    } catch (e) {
      logger.e('Error loading OpenAI API key: $e');
      // Don't rethrow - handle gracefully
    }
  }
  
  Future<void> _loadApiKeyAsync() async {
    try {
      // Make sure dotenv is loaded if not already
      await _ensureDotEnvLoaded();
      
      _apiKey = dotenv.maybeGet('OPENAI_API_KEY');
      if (_apiKey == null || _apiKey!.isEmpty) {
        logger.e('OpenAI API key not found. Please check your .env file');
      } else {
        logger.i('Successfully loaded OpenAI API key');
      }
    } catch (e) {
      logger.e('Error loading OpenAI API key: $e');
      // Don't rethrow - handle gracefully
    }
  }

  // Helper method to ensure dotenv is loaded
  Future<void> _ensureDotEnvLoaded() async {
    try {
      // First check if dotenv is already loaded by trying to access a value
      try {
        dotenv.get('DUMMY_KEY', fallback: 'dummy');
        logger.i('dotenv is already loaded');
        return;
      } catch (e) {
        // If we get here, dotenv needs to be loaded
        logger.i('dotenv not initialized, attempting to load...');
      }
      
      // Try to load from different possible locations
      final List<String> possiblePaths = [
        '.env',
        'assets/.env',
        '../.env',
        '../../.env',
      ];
      
      bool loaded = false;
      for (final path in possiblePaths) {
        try {
          await dotenv.load(fileName: path);
          logger.i('Successfully loaded dotenv from: $path');
          loaded = true;
          break;
        } catch (e) {
          logger.w('Failed to load dotenv from $path: $e');
          // Continue to next path
        }
      }
      
      if (!loaded) {
        logger.e('Failed to load dotenv from any path');
        
        // As a last resort, try to set the API key directly
        // You could hardcode this for development, but remove for production
        _apiKey = null; // Don't set a default API key in code
      }
    } catch (e) {
      logger.e('Error ensuring dotenv is loaded: $e');
    }
  }

  // Check if service is properly initialized
  bool get isInitialized => _apiKey != null && _apiKey!.isNotEmpty;

  /// Acknowledges and validates how the user is feeling based on their journal entry
  Future<String> acknowledgeFeeling({
    required String emotion,
    required String journalContent, 
    required String pictureDescription,
    File? imageFile,
  }) async {
    final prompt = '''
I'm feeling $emotion. Here's my journal entry:
"$journalContent"

I also described a picture as: "$pictureDescription"
${imageFile != null ? "There's an image attached to this entry." : ""}

Please acknowledge how I'm feeling in a thoughtful, empathetic way. Validate my emotions 
and show understanding. Keep the response to about 3-4 sentences.
''';

    return await _callOpenAI(prompt, imageFile: imageFile);
  }
  
  /// Provides practical advice on how to improve the user's emotional state
  Future<String> provideAdvice({
    required String emotion,
    required String journalContent, 
    required String pictureDescription,
    File? imageFile,
  }) async {
    final prompt = '''
I'm feeling $emotion. Here's my journal entry:
"$journalContent"

I also described a picture as: "$pictureDescription"
${imageFile != null ? "There's an image attached to this entry." : ""}

Based on this information, please provide 2-3 practical, specific suggestions on 
how I might improve my emotional state. Include concrete activities, mindfulness techniques,
or perspective shifts that could help. Keep the response concise and actionable.
''';

    return await _callOpenAI(prompt, imageFile: imageFile);
  }
  
  /// Makes an API call to OpenAI to get a generated response
  Future<String> _callOpenAI(String prompt, {File? imageFile}) async {
    if (!isInitialized) {
      logger.e('AIService not properly initialized. API key is missing.');
      return 'Sorry, I was unable to analyze your entry. Service configuration error.';
    }
    
    final url = Uri.parse('https://api.openai.com/v1/chat/completions');
    
    try {
      Map<String, dynamic> requestBody;
      
      if (imageFile != null) {
        // For image analysis, use GPT-4o-mini which supports vision at lower cost
        final List<int> imageBytes = await imageFile.readAsBytes();
        final String base64Image = base64Encode(imageBytes);
        
        requestBody = {
          'model': 'gpt-4o-mini',  // Updated to more cost-effective model
          'messages': [
            {
              'role': 'system', 
              'content': 'You are a helpful, empathetic assistant specializing in mental health and well-being.'
            },
            {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text': prompt
                },
                {
                  'type': 'image_url',
                  'image_url': {
                    'url': 'data:image/jpeg;base64,$base64Image'
                  }
                }
              ]
            }
          ],
          'temperature': 0.7,
          'max_tokens': 300,
        };
      } else {
        // Text-only request - can use cheaper model here too
        requestBody = {
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system', 
              'content': 'You are a helpful, empathetic assistant specializing in mental health and well-being.'
            },
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.7,
          'max_tokens': 300,
        };
      }
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode(requestBody),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'].trim();
      } else {
        logger.e('Error from OpenAI API: ${response.statusCode} - ${response.body}');
        return 'Sorry, I was unable to analyze your entry. Please try again later.';
      }
    } catch (e) {
      logger.e('Exception when calling OpenAI API: $e');
      return 'Sorry, I was unable to analyze your entry. Please try again later.';
    }
  }
  
  /// Combines both acknowledgment and advice into a single response
  Future<String> getCompleteAnalysis({
    required String emotion,
    required String journalContent, 
    required String pictureDescription,
    String? imageURL,
    File? imageFile,
  }) async {
    try {
      File? fileToUse = imageFile;
      
      // If we have a URL but no file, try to download the file
      if (fileToUse == null && imageURL != null && imageURL.isNotEmpty) {
        // Note: You'll need to pass the ImageStorageService instance to this class
        // or make the method static
        // This is pseudocode - you'll need to implement a way to access the service
        // fileToUse = await imageStorageService.downloadImageFromUrl(imageURL);
        
        // For now, let's not implement this part as we need the ImageStorageService
      }
      
      final acknowledgment = await acknowledgeFeeling(
        emotion: emotion,
        journalContent: journalContent,
        pictureDescription: pictureDescription,
        imageFile: fileToUse,
      );
      
      final advice = await provideAdvice(
        emotion: emotion,
        journalContent: journalContent,
        pictureDescription: pictureDescription,
        imageFile: fileToUse,
      );
      
      return '$acknowledgment\n\n$advice';
    } catch (e) {
      logger.e('Error generating complete analysis: $e');
      return 'Sorry, I was unable to analyze your entry. Please try again later.';
    }
  }
}