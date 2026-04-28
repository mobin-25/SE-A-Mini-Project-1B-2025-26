import 'package:flutter/material.dart';

class AppTheme {
  static const Color deepNavy = Color(0xFF1a1a2e);
  static const Color electricBlue = Color(0xFF16213e);
  static const Color accentBlue = Color(0xFF0f3460);
  static const Color lightBlue = Color(0xFFe94560); // for accents
  static const Color white = Colors.white;

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: electricBlue,
    scaffoldBackgroundColor: deepNavy,
    appBarTheme: AppBarTheme(
      backgroundColor: electricBlue,
      foregroundColor: white,
      elevation: 0,
    ),
    cardTheme: const CardThemeData(
      color: electricBlue,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accentBlue,
        foregroundColor: white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    textTheme: TextTheme(
      headlineLarge: TextStyle(color: white, fontSize: 32, fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(color: white, fontSize: 24, fontWeight: FontWeight.bold),
      headlineSmall: TextStyle(color: white, fontSize: 20, fontWeight: FontWeight.bold),
      bodyLarge: TextStyle(color: white, fontSize: 16),
      bodyMedium: TextStyle(color: white, fontSize: 14),
      bodySmall: TextStyle(color: white.withOpacity(0.7), fontSize: 12),
    ),
  );
}