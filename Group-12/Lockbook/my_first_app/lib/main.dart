import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'package:my_first_app/screens/Home_page/Home_page.dart';
import 'package:my_first_app/screens/MultiFactor_Page/MultiFactor_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

String? loggedInUser;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  try {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: androidSettings);

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
    );
  } catch (e) {
    debugPrint("Notification init failed: $e");
  }

  runApp(
    DevicePreview(
      enabled: false,
      builder: (context) => const LockBookApp(),
    ),
  );
}

class LockBookApp extends StatefulWidget {
  const LockBookApp({super.key});

  @override
  State<LockBookApp> createState() => _LockBookAppState();

  static void updateTheme(BuildContext context) {
    final state = context.findAncestorStateOfType<_LockBookAppState>();
    state?.loadTheme();
  }
}

class _LockBookAppState extends State<LockBookApp> {
  bool isDarkMode = false;
  Color selectedColor = Colors.deepPurple;

  @override
  void initState() {
    super.initState();
    loadTheme();
    requestNotificationPermission();
  }

  Future<void> requestNotificationPermission() async {
    final androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidImplementation?.requestNotificationsPermission();
  }

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      isDarkMode = prefs.getBool("dark_mode") ?? false;

      String? colorString = prefs.getString("theme_color");
      if (colorString != null) {
        selectedColor = Color(int.parse(colorString));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      useInheritedMediaQuery: true,
      builder: DevicePreview.appBuilder,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: isDarkMode ? Brightness.dark : Brightness.light,
        primaryColor: selectedColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: selectedColor,
          brightness: isDarkMode ? Brightness.dark : Brightness.light,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

/// ================= SPLASH SCREEN =================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    checkLogin();
  }

  void checkLogin() async {
    final user = FirebaseAuth.instance.currentUser;

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;

      if (user != null) {
        loggedInUser = user.email;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const MultiFactorPage(),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const HomeScreen(),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color.fromARGB(255, 158, 240, 233),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock, size: 100, color: Colors.white),
            SizedBox(height: 20),
            Text(
              "LockBook",
              style: TextStyle(
                fontSize: 30,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}