import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const TrackPayApp());
}

class TrackPayApp extends StatelessWidget {
  const TrackPayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: SplashScreen());
  }
}
