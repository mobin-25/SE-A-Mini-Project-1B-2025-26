// ✅ Add these imports at the top
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notifications
  await NotificationService.initialize();

  const supabaseUrlRaw = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKeyRaw = String.fromEnvironment('SUPABASE_ANON_KEY');
  final supabaseUrl = _normalizeSupabaseUrl(supabaseUrlRaw);
  final supabaseAnonKey = supabaseAnonKeyRaw.trim();

  if (supabaseUrlRaw.isEmpty || supabaseAnonKeyRaw.isEmpty) {
    throw Exception(
      'Missing SUPABASE_URL or SUPABASE_ANON_KEY. Pass them with --dart-define.',
    );
  }

  if (supabaseAnonKey != supabaseAnonKeyRaw.trim()) {
    throw Exception(
      'Supabase anon key contains extra whitespace. Remove any leading/trailing spaces from SUPABASE_ANON_KEY.',
    );
  }

  final isInvalidProjectUrl = !supabaseUrl.contains('.supabase.co');
  final isInvalidAnonKey = !supabaseAnonKey.startsWith('eyJ') || supabaseAnonKey.length < 80;

  if (isInvalidProjectUrl || isInvalidAnonKey) {
    throw Exception(
      'Invalid Supabase credentials. SUPABASE_URL must be your project URL (for example https://your-project.supabase.co). '
      'SUPABASE_ANON_KEY must be the anon public key from Supabase Settings -> API.',
    );
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const MyApp());
}

String _normalizeSupabaseUrl(String rawUrl) {
  final trimmedUrl = rawUrl.trim();
  if (trimmedUrl.isEmpty) return trimmedUrl;

  final dashboardPatterns = [
    RegExp(r'https?://supabase\.com/dashboard/project/([^/?#]+)', caseSensitive: false),
    RegExp(r'https?://app\.supabase\.com/project/([^/?#]+)', caseSensitive: false),
    RegExp(r'https?://app\.supabase\.com/[^/]+/project/([^/?#]+)', caseSensitive: false),
  ];

  for (final pattern in dashboardPatterns) {
    final match = pattern.firstMatch(trimmedUrl);
    if (match != null) {
      final projectRef = match.group(1);
      if (projectRef != null && projectRef.isNotEmpty) {
        return 'https://$projectRef.supabase.co';
      }
    }
  }

  final projectRefMatch = RegExp(r'^[a-z0-9]{16,}$', caseSensitive: false).firstMatch(trimmedUrl);
  if (projectRefMatch != null) {
    return 'https://$trimmedUrl.supabase.co';
  }

  return trimmedUrl.replaceAll(RegExp(r'/*$'), '');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Wildlife Alert App',
      theme: AppTheme.lightTheme,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    _listenForNewAlerts();
  }

  void _listenForNewAlerts() {
    final supabase = Supabase.instance.client;
    try {
      supabase.from('alerts').stream(primaryKey: ['id']).listen(
        (data) {
          if (data.isNotEmpty) {
            final latestAlert = data.last;
            final userId = supabase.auth.currentUser?.id;
            if (userId != null && latestAlert['user_id'] != userId) {
              NotificationService.showNotification(
                title: 'New Alert',
                body: latestAlert['message'] ?? 'Wildlife alert received',
              );
            }
          }
        },
        onError: (error) {
          debugPrint('Realtime alert subscription error: $error');
        },
      );
    } catch (e) {
      debugPrint('Failed to subscribe to realtime alerts: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            supabase.auth.currentSession == null) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
              ),
            ),
          );
        }
        if (supabase.auth.currentSession != null) return const HomeScreen();
        return const LoginScreen();
      },
    );
  }
}