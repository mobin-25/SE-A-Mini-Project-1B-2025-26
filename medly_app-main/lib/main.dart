import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/search_screen.dart';
import 'screens/symptom_screen.dart';
import 'screens/reminder_screen.dart';
import 'screens/interaction_screen.dart';
import 'screens/pharmacy_screen.dart';
import 'screens/profile_screen.dart';
import 'services/notification_service.dart';
import 'services/supabase_service.dart';
import 'db/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://duqdtdkezpvsvltrdmjb.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR1cWR0ZGtlenB2c3ZsdHJkbWpiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ4NzU5MjYsImV4cCI6MjA5MDQ1MTkyNn0.2cPPh_dpC-N4lBJM3bOhHEve7YexPieksZrgazIxAUE',
  );

  // sqflite does not support web — only init on native platforms
  if (!kIsWeb) {
    await DatabaseHelper.instance.database;
  }

  // Initialize notifications
  await NotificationService.instance.initialize();

  runApp(const MedlyApp());
}

class MedlyApp extends StatelessWidget {
  const MedlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Medly',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A6B5A),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        cardTheme: const CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A6B5A),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const SearchScreen(),
    const SymptomScreen(),
    const ReminderScreen(),
    const InteractionScreen(),
    const PharmacyScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _checkAlerts();
  }

  Future<void> _checkAlerts() async {
    // Check low stock and expiry alerts on startup
    final lowStock = await SupabaseService.instance.getLowStockAlerts();
    final expiring = await SupabaseService.instance.getExpiringMedicines();

    for (final s in lowStock) {
      await NotificationService.instance.showLowStockAlert(
        medicineName: s['medicine_name'] as String,
        remaining: s['current_count'] as int,
      );
    }
    for (final s in expiring) {
      await NotificationService.instance.showExpiryAlert(
        medicineName: s['medicine_name'] as String,
        expiryDate: s['expiry_date'] as String,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(icon: Icon(Icons.healing), label: 'Symptoms'),
          NavigationDestination(icon: Icon(Icons.alarm), label: 'Remind'),
          NavigationDestination(icon: Icon(Icons.warning_amber), label: 'Interact'),
          NavigationDestination(icon: Icon(Icons.local_pharmacy), label: 'Pharmacy'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
