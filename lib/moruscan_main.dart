import 'package:flutter/material.dart';
import 'moruscan_home.dart';
import 'history_page.dart';
import 'info_page.dart';
import 'settings_page.dart';

class MoruScanMain extends StatefulWidget {
  const MoruScanMain({super.key});

  @override
  State<MoruScanMain> createState() => _MoruScanMainState();
}

class _MoruScanMainState extends State<MoruScanMain> {
  int _selectedIndex = 0;

  final _pages = const [
    MoruScanHomePage(), 
    HistoryPage(),
    InfoPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.info), label: 'Info'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
