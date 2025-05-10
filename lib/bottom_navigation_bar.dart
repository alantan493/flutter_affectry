import 'package:flutter/material.dart';

// Import with prefixes to avoid ambiguity
import 'pages/home.dart' as home;
import 'pages/calendar_logbook.dart' as calendar;
import 'pages/journal_entry_page.dart' as journal;
import 'pages/data_analysis_page.dart' as data;
import 'pages/articles_page.dart' as articles;

class BottomNavigationBarScreen extends StatefulWidget {
  const BottomNavigationBarScreen({super.key});

  @override
  State<BottomNavigationBarScreen> createState() => _BottomNavigationBarScreenState();
}

class _BottomNavigationBarScreenState extends State<BottomNavigationBarScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    home.HomePage(),
    calendar.CalendarLogbookPage(),
    journal.JournalEntryPage(
      emotion: '',
      journal: '',
      pictureDescription: '',
      imageURL: '',
      userEmail: '',
    ),
    data.DataAnalysisPage(),
    articles.ArticlesPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: "Logbook"),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: "New Entry"),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Data Analysis"),
          BottomNavigationBarItem(icon: Icon(Icons.article), label: "Articles"),
        ],
      ),
    );
  }
}