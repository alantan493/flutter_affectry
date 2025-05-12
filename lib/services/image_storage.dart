import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:logger/logger.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ImageStorageService {
  // Firebase Storage instance
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Logger _logger = Logger();

  // Upload an image to Firebase Storage
  Future<String?> uploadImage(File file, {String? customFileName}) async {
    try {
      // Generate a unique filename based on timestamp if not provided
      final String fileName = customFileName ?? 
          DateTime.now().millisecondsSinceEpoch.toString();
      
      // Create reference to storage location
      final Reference storageRef = _storage.ref().child('images/$fileName');

      // Upload the file
      await storageRef.putFile(file);
      
      // Get and return the download URL
      final String downloadURL = await storageRef.getDownloadURL();
      
      _logger.i('Image uploaded successfully: $downloadURL');
      return downloadURL;
    } catch (e) {
      _logger.e('Error uploading image: $e');
      return null;
    }
  }

  // Delete an image from Firebase Storage
  Future<bool> deleteImage(String imageURL) async {
    try {
      // Get reference from the URL
      final Reference ref = _storage.refFromURL(imageURL);
      await ref.delete();
      
      _logger.i('Image deleted successfully');
      return true;
    } catch (e) {
      _logger.e('Error deleting image: $e');
      return false;
    }
  }
  
  // Get download URL for an image by its path
  Future<String?> getImageURL(String path) async {
    try {
      final Reference ref = _storage.ref().child(path);
      return await ref.getDownloadURL();
    } catch (e) {
      _logger.e('Error getting image URL: $e');
      return null;
    }
  }
  
  // Download an image from URL and return as File
  Future<File?> downloadImageFromUrl(String imageUrl) async {
    try {
      // Create a temporary directory to store the downloaded file
      final Directory tempDir = await getTemporaryDirectory();
      
      // Generate a file name based on the URL's path or a timestamp
      String fileName = path.basename(Uri.parse(imageUrl).path);
      if (fileName.isEmpty || !fileName.contains('.')) {
        fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      }
      
      // Create the file path
      final String filePath = path.join(tempDir.path, fileName);
      
      // Download the file
      final http.Response response = await http.get(Uri.parse(imageUrl));
      
      if (response.statusCode == 200) {
        // Write to file
        final File file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        _logger.i('Image downloaded to file: $filePath');
        return file;
      } else {
        _logger.e('Failed to download image. Status code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      _logger.e('Error downloading image: $e');
      return null;
    }
  }
}