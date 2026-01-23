import 'package:flutter/material.dart';
import 'screens/documents_screen.dart';
import 'screens/ai_screen.dart';
import 'screens/news_screen.dart';
import 'screens/settings_screen.dart';
import 'widgets/navigation/glass_bottom_nav.dart';

import 'screens/document_scanner_screen.dart';
import 'utils/theme.dart';

/// Main App Widget with bottom navigation
class SehatLockerApp extends StatefulWidget {
  const SehatLockerApp({super.key});

  @override
  State<SehatLockerApp> createState() => _SehatLockerAppState();
}

class _SehatLockerAppState extends State<SehatLockerApp> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DocumentsScreen(),
    AIScreen(),
    NewsScreen(),
    SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DocumentScannerScreen(),
                  ),
                );
              },
              backgroundColor: AppTheme.accentTeal,
              child: const Icon(Icons.document_scanner),
            )
          : null,
      bottomNavigationBar: GlassBottomNav(
        currentIndex: _currentIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
