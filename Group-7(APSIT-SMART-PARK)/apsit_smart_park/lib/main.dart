import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'services/admin_service.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/notification_service.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/reservation_screen.dart';
import 'screens/bookings_screen.dart';
import 'screens/history_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/alerts_screen.dart';
import 'screens/map_screen.dart';
import 'screens/parking_map_screen.dart';

final themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.dark);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Seed default parking slots to Firestore (only runs if collection is empty)
  try {
    await FirestoreService.seedParkingSlotsIfEmpty();
  } catch (e) {
    debugPrint('Seed error (non-fatal): $e');
  }

  // Initialize Firebase Cloud Messaging (push notifications)
  // Skipped on web — handled via service worker instead
  if (!kIsWeb) {
    try {
      await NotificationService.initialize();
    } catch (e) {
      debugPrint('Notification init error (non-fatal): $e');
    }
  }

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const APSITSmartParkApp());
}

class APSITSmartParkApp extends StatelessWidget {
  const APSITSmartParkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, __) {
        return MaterialApp(
          title: 'APSIT Smart Park',
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF3F4F6),
            primaryColor: const Color(0xFF2563EB),
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2563EB),
              secondary: Color(0xFF3B82F6),
              surface: Colors.white,
            ),
            textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF0A0E1A),
            primaryColor: const Color(0xFF2563EB),
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF2563EB),
              secondary: Color(0xFF3B82F6),
              surface: Color(0xFF111827),
            ),
            textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
            useMaterial3: true,
          ),
          // Auth-aware initial screen
          home: const _AuthGate(),
          routes: {
            '/splash': (context) => const SplashScreen(),
            '/login': (context) => const LoginScreen(),
            '/signup': (context) => const SignupScreen(),
            '/home': (context) => const HomeScreen(),
            '/reservation': (context) => const ReservationScreen(),
            '/bookings': (context) => const BookingsScreen(),
            '/history': (context) => const HistoryScreen(),
            '/settings': (context) => const SettingsScreen(),
            '/profile': (context) => const ProfileScreen(),
            '/alerts': (context) => const AlertsScreen(),
            '/map': (context) => const MapScreen(),
            '/parking-map': (context) => const ParkingMapScreen(),
          },
        );
      },
    );
  }
}

/// Listens to Firebase auth state. Shows login when signed out,
/// home when signed in. Also bootstraps user Firestore doc on first login.
/// Globally listens for new admin alerts and fires local push notifications.
class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  StreamSubscription<List<Map<String, dynamic>>>? _alertSub;
  final Set<String> _notifiedAlertIds = {};

  @override
  void initState() {
    super.initState();
    _startAlertListener();
  }

  void _startAlertListener() {
    if (kIsWeb) return;
    _alertSub = AdminService.alertsStream().listen((alerts) {
      final currentEmail = FirebaseAuth.instance.currentUser?.email ?? '';
      // Non-admin users get push notifications for new alerts
      if (!AdminService.isAdmin(currentEmail) && currentEmail.isNotEmpty) {
        for (final alert in alerts) {
          final id = alert['id'] as String?;
          if (id != null && !_notifiedAlertIds.contains(id)) {
            _notifiedAlertIds.add(id);
            NotificationService.showLocalNotification(
              title: '📢 ${alert['title'] ?? 'APSIT Smart Park'}',
              body: alert['body'] ?? '',
              id: id.hashCode,
            );
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _alertSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.authStateChanges,
      builder: (context, snapshot) {
        // Still loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        // Signed in
        if (snapshot.hasData && snapshot.data != null) {
          // Ensure Firestore profile exists
          AuthService.ensureProfile(snapshot.data!);
          return const HomeScreen();
        }
        // Not signed in
        return const LoginScreen();
      },
    );
  }
}
