import 'package:flutter/material.dart';
import 'search_screen.dart';
import 'reminder_screen.dart';
import 'interaction_screen.dart';
import 'symptom_screen.dart';
import 'pharmacy_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final _screens = const [
    SearchScreen(),
    SymptomScreen(),
    ReminderScreen(),
    InteractionScreen(),
    PharmacyScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(icon: Icon(Icons.sick), label: 'Symptoms'),
          NavigationDestination(icon: Icon(Icons.alarm), label: 'Reminders'),
          NavigationDestination(icon: Icon(Icons.warning_amber), label: 'Interactions'),
          NavigationDestination(icon: Icon(Icons.local_pharmacy), label: 'Pharmacy'),
        ],
      ),
    );
  }
}