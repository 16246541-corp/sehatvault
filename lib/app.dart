import 'package:flutter/material.dart';
import 'screens/documents_screen.dart';
import 'screens/ai_screen.dart';
import 'screens/news_screen.dart';
import 'screens/settings_screen.dart';
import 'widgets/navigation/glass_bottom_nav.dart';
import 'widgets/design/liquid_glass_background.dart';

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
      bottomNavigationBar: GlassBottomNav(
        currentIndex: _currentIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
