import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/follow_up_item.dart';
import 'services/local_storage_service.dart';
import 'screens/documents_screen.dart';
import 'screens/follow_up_list_screen.dart';
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

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      DocumentsScreen(onTasksTap: () => _onItemTapped(1)),
      const FollowUpListScreen(),
      const AIScreen(),
      const NewsScreen(),
      const SettingsScreen(),
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkOverdueItems();
    });
  }

  void _checkOverdueItems() {
    final overdueItems = LocalStorageService().getOverdueItems();
    if (overdueItems.isNotEmpty) {
      ScaffoldMessenger.of(context).showMaterialBanner(
        MaterialBanner(
          content:
              Text('You have ${overdueItems.length} overdue follow-up items.'),
          leading: const Icon(Icons.warning_amber, color: Colors.orange),
          backgroundColor:
              Theme.of(context).colorScheme.surfaceContainerHighest,
          actions: [
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
                setState(() {
                  _currentIndex = 1;
                });
              },
              child: const Text('VIEW'),
            ),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
              },
              child: const Text('DISMISS'),
            ),
          ],
        ),
      );
    }
  }

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
      bottomNavigationBar: ValueListenableBuilder<Box<FollowUpItem>>(
        valueListenable: LocalStorageService().followUpItemsListenable,
        builder: (context, box, _) {
          final now = DateTime.now();
          final overdueCount = box.values
              .where((item) =>
                  !item.isCompleted &&
                  item.dueDate != null &&
                  item.dueDate!.isBefore(now))
              .length;

          return GlassBottomNav(
            currentIndex: _currentIndex,
            onItemTapped: _onItemTapped,
            badgeCounts: overdueCount > 0 ? {1: overdueCount} : null,
          );
        },
      ),
    );
  }
}
