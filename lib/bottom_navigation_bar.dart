import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

// Import page files (assumed to exist)
import 'pages/home.dart' as home;
import 'pages/calendar_logbook.dart' as calendar;
import 'pages/journal_entry_page.dart' as journal;
import 'pages/data_analysis_page.dart' as data;
import 'pages/articles_page.dart' as articles;

// Define global colors
const Color navyBlue = Color(0xFF0A1172); // Navy blue for FAB
const Color primaryBlue = Color(0xFF4285F4); // Primary blue for selected items

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Journal App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: primaryBlue,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryBlue,
          secondary: const Color(0xFF34A853), // Google Green
        ),
        fontFamily: 'Google Sans',
      ),
      home: const BottomNavigationBarScreen(),
    );
  }
}

class BottomNavigationBarScreen extends StatefulWidget {
  const BottomNavigationBarScreen({super.key});

  @override
  State<BottomNavigationBarScreen> createState() => _BottomNavigationBarScreenState();
}

class _BottomNavigationBarScreenState extends State<BottomNavigationBarScreen> {
  int _selectedIndex = 0;

  // Handle missing assets by providing fallback images
  final Map<String, AssetImage> _assetImages = {};

  @override
  void initState() {
    super.initState();
    
    // Add error handling for asset loading
    ErrorWidget.builder = (FlutterErrorDetails details) {
      // Return a placeholder for asset loading errors
      if (details.exception is Exception && 
          details.exception.toString().contains('Unable to load asset')) {
        return Container(
          alignment: Alignment.center,
          child: const Icon(Icons.image_not_supported, color: Colors.grey),
        );
      }
      return ErrorWidget(details.exception);
    };
  }

  // Pages list
  final List<Widget> _pages = const [
    home.HomePage(),
    calendar.CalendarLogbookPage(),
    SizedBox(), // Placeholder for FAB
    data.DataAnalysisPage(),
    articles.ArticlesPage(), 
  ];

  void _onItemTapped(int index) {
    // If selecting the middle tab, show journal entry page
    if (index == 2) {
      _showJournalEntryPage();
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  void _showJournalEntryPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => journal.JournalEntryPage(
          emotion: '',
          journal: '',
          pictureDescription: '',
          imageURL: '',
          userEmail: '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex == 2 ? 0 : _selectedIndex], // Fallback to home if middle tab
      
      // Navy blue circular floating action button
      floatingActionButton: SizedBox(
        height: 60.0,
        width: 60.0,
        child: FloatingActionButton(
          onPressed: _showJournalEntryPage,
          backgroundColor: const Color(0xFF0A1172), // Navy blue
          foregroundColor: Colors.white,
          elevation: 4.0,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, size: 28.0),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      
      // Simplified bottom navigation bar
      bottomNavigationBar: BottomAppBar(
        notchMargin: 8.0,
        shape: const CircularNotchedRectangle(),
        height: 60,
        padding: EdgeInsets.zero,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            // Left side
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(0, Icons.home_rounded, 'Home'),
                  _buildNavItem(1, Icons.book_rounded, 'Logbook'),
                ],
              ),
            ),
            
            // Center spacer for FAB
            const SizedBox(width: 80),
            
            // Right side
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(3, Icons.analytics_rounded, 'Analytics'),
                  _buildNavItem(4, Icons.article_rounded, 'Discover'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isSelected = _selectedIndex == index;
    
    return InkWell(
      onTap: () => _onItemTapped(index),
      customBorder: const CircleBorder(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? primaryBlue : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                color: isSelected ? primaryBlue : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}