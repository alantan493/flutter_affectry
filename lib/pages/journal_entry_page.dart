import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/journal_database.dart';
import '../models/journal_entry_model.dart';
import 'package:logger/logger.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/image_storage.dart';
import 'ai_analysis_page.dart'; // Add this import

final logger = Logger();

class JournalEntryPage extends StatefulWidget {
  final String? docId;
  final String emotion;
  final String journal;
  final String pictureDescription;
  final String? imageURL;
  final DateTime? timestamp;
  final String userEmail;

  const JournalEntryPage({
    super.key,
    this.docId,
    required this.emotion,
    required this.journal,
    required this.pictureDescription,
    this.imageURL,
    this.timestamp,
    required this.userEmail,
  });

  @override
  State<JournalEntryPage> createState() => _JournalEntryPageState();
}

class _JournalEntryPageState extends State<JournalEntryPage> {
  late TextEditingController _emotionController;
  late TextEditingController _journalController;
  late TextEditingController _pictureDescriptionController;
  late DateTime _selectedDate; // Add this property
  late TimeOfDay _selectedTime; // Add this property
  bool _wantAIAnalysis = true;

  bool _isLoading = false;
  String _selectedEmotion = '';
  String? _imageURL;
  File? _pickedImage;
  String? _fetchedUserEmail;

  @override
  void initState() {
    super.initState();
    _emotionController = TextEditingController(text: widget.emotion);
    _journalController = TextEditingController(text: widget.journal);
    _pictureDescriptionController = TextEditingController(
      text: widget.pictureDescription,
    );

    _selectedEmotion = widget.emotion;
    // Only set imageURL if it's not null AND not empty
    _imageURL = widget.imageURL?.isNotEmpty == true ? widget.imageURL : null;

    // Initialize date and time
    _selectedDate = widget.timestamp ?? DateTime.now();
    _selectedTime = TimeOfDay.fromDateTime(_selectedDate);

    // Fetch user email from Firestore or fallback
    _fetchAndDisplayUserEmail();
  }

  Future<void> _fetchAndDisplayUserEmail() async {
    setState(() => _isLoading = true);

    try {
      final String userUid = FirebaseAuth.instance.currentUser!.uid;
      final DatabaseService db = DatabaseService();
      final String? userEmail = await db.fetchUserEmail(userUid);

      if (userEmail != null && userEmail.isNotEmpty) {
        setState(() => _fetchedUserEmail = userEmail);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to retrieve user email')),
        );
      }
    } catch (e) {
      logger.e("Error fetching user email: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitData() async {
    final journal = _journalController.text.trim();
    final pictureDescription = _pictureDescriptionController.text.trim();

    final String userEmail = _fetchedUserEmail ?? widget.userEmail;

    if (_selectedEmotion.isEmpty ||
        journal.isEmpty ||
        pictureDescription.isEmpty ||
        userEmail.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final entry = JournalEntry(
        // Keep the original ID if editing an existing entry
        id: widget.docId,
        emotion: _selectedEmotion,
        journal: journal,
        pictureDescription: pictureDescription,
        imageURL: _imageURL ?? '',
        timestamp: _selectedDate,
        userEmail: userEmail,
      );

      logger.i('Submitting JournalEntry: ${entry.toJson()}');

      final DatabaseService db = DatabaseService();
      // Save the entry and get back the document ID
      final String entryId = await db.saveJournalEntry(entry, id: widget.docId);

      // Update the entry ID to ensure we're using the correct one
      entry.id = entryId;

      // Only proceed if the widget is still mounted
      if (!mounted) return;

      setState(() => _isLoading = false);

      // Check if user wants AI analysis (will be implemented next)
      if (_wantAIAnalysis) {
        // Navigate to AI analysis page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    AIAnalysisPage(journalEntry: entry, imageURL: _imageURL),
          ),
        );
      } else {
        // Skip AI analysis and go back to previous screen
        Navigator.pop(context, true); // Return true to indicate successful save
      }
    } catch (e) {
      logger.e('Error submitting data: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadImage() async {
    try {
      // 1. Initialize picker
      final ImagePicker picker = ImagePicker();

      // 2. Show debugging dialog before picking
      if (!mounted) return; // Add this check
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Opening image picker...')));

      // 3. Pick image
      final XFile? pickedImage = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85, // Adding quality parameter to reduce file size
      );

      // 4. Debug if image was picked
      if (pickedImage == null) {
        logger.w('No image selected');
        if (!mounted) return; // Add this check
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No image selected')));
        return;
      }

      // 5. Debug file information
      final File imageFile = File(pickedImage.path);
      final bool fileExists = await imageFile.exists();
      final int fileSize = await imageFile.length();

      logger.i('Image picked: ${pickedImage.path}');
      logger.i('File exists: $fileExists, Size: $fileSize bytes');

      // 6. Set the picked image and update UI
      if (!mounted) return; // Add this check
      setState(() {
        _pickedImage = imageFile;
        logger.i('_pickedImage set to: ${_pickedImage?.path}');
      });

      // 7. Use the ImageStorageService to upload the image
      final ImageStorageService storageService = ImageStorageService();

      // 8. Show uploading indicator
      if (!mounted) return; // Add this check
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Uploading image...')));

      final String? downloadURL = await storageService.uploadImage(imageFile);

      if (downloadURL != null) {
        if (!mounted) return; // Add this check
        setState(() {
          _imageURL = downloadURL;
          logger.i('Image uploaded successfully, URL: $_imageURL');
        });

        if (!mounted) return; // Add this check
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image uploaded successfully!')),
        );
      } else {
        throw Exception('Failed to get download URL');
      }
    } catch (e) {
      logger.e('Image upload failed: $e');
      if (!mounted) return; // Add this check
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        _selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'New Journal Entry',
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How are you feeling today?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            if (_fetchedUserEmail != null)
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 20),
                child: Text(
                  'Account: $_fetchedUserEmail',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            _emotionSelectionSection(),
            const SizedBox(height: 20),
            TextField(
              controller: _journalController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Journal Entry',
                labelStyle: const TextStyle(color: Colors.black54),
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Image.asset(
                    'assets/icons/journal.png',
                    width: 20,
                    height: 20,
                  ),
                ),
                filled: true,
                fillColor: const Color(0xFFF7F8F8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'How are you today? Is everything going well?',
              style: TextStyle(fontSize: 10, color: Colors.black38),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _pictureDescriptionController,
                    decoration: InputDecoration(
                      labelText: 'Picture Description',
                      labelStyle: const TextStyle(color: Colors.black54),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Image.asset(
                          'assets/icons/camera.png',
                          width: 20,
                          height: 20,
                        ),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF7F8F8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _uploadImage,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF92A3FD),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Image.asset(
                      'assets/icons/upload.png',
                      width: 20,
                      height: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F8F8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 20,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
                          style: const TextStyle(fontSize: 16),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () => _selectDate(context),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F8F8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 20,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _selectedTime.format(context),
                          style: const TextStyle(fontSize: 16),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.access_time),
                          onPressed: () => _selectTime(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            if (_imageURL != null && _imageURL!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Column(
                    children: [
                      Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(10),
                          image: DecorationImage(
                            image: NetworkImage(_imageURL!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Uploaded image',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              )
            else if (_pickedImage != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Column(
                    children: [
                      Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(10),
                          image: DecorationImage(
                            image: FileImage(_pickedImage!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Selected image',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 30),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8F8),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              margin: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.psychology,
                        color: Color(0xFF92A3FD),
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "AI Analysis",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Switch(
                        value: _wantAIAnalysis,
                        onChanged: (value) {
                          setState(() {
                            _wantAIAnalysis = value;
                          });
                        },
                        activeColor: const Color(0xFF92A3FD),
                        activeTrackColor: const Color(
                          0xFF92A3FD,
                        ).withOpacity(0.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Let AI analyze your emotions and provide personalized insights based on your journal entry.",
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  if (!_wantAIAnalysis)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        "You can always generate AI analysis later from your journal history.",
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Center(
              child: ElevatedButton(
                onPressed:
                    _isLoading || _fetchedUserEmail == null
                        ? null
                        : _submitData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF92A3FD),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    vertical: 15,
                    horizontal: 30,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                  elevation: 5,
                ),
                child:
                    _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                          'Submit Entry',
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
    );
  }

  Widget _emotionSelectionSection() {
    final List<Map<String, dynamic>> emotions = [
      {
        'name': 'Happy',
        'iconPath': 'assets/icons/happy.png',
        'color': Colors.yellow,
      },
      {'name': 'Sad', 'iconPath': 'assets/icons/sad.png', 'color': Colors.blue},
      {
        'name': 'Angry',
        'iconPath': 'assets/icons/angry.png',
        'color': Colors.red,
      },
      {
        'name': 'Stressed',
        'iconPath': 'assets/icons/stressed.png',
        'color': Colors.purple,
      },
      {
        'name': 'Calm',
        'iconPath': 'assets/icons/calm.png',
        'color': Colors.green,
      },
      {
        'name': 'Excited',
        'iconPath': 'assets/icons/excited.png',
        'color': Colors.orange,
      },
      {
        'name': 'Frustrated',
        'iconPath': 'assets/icons/frustrated.png',
        'color': Colors.brown,
      },
      {
        'name': 'Anxious',
        'iconPath': 'assets/icons/anxious.png',
        'color': Colors.teal,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Your Emotion',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 15),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1,
          ),
          itemCount: emotions.length,
          itemBuilder: (context, index) {
            final emotion = emotions[index];
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedEmotion = emotion['name'];
                  _emotionController.text = _selectedEmotion;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color:
                      _selectedEmotion == emotion['name']
                          ? emotion['color'].withAlpha(77)
                          : Colors.grey.withAlpha(51),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                        child: Image.asset(emotion['iconPath']),
                      ),
                    ),
                    Text(
                      emotion['name'],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
