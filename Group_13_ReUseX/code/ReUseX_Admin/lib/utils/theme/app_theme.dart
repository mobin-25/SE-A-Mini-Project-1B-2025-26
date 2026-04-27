import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    scaffoldBackgroundColor: Colors.grey.shade100,
    primaryColor: const Color(0xFF8F7AE5),

    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF8F7AE5),
      brightness: Brightness.light,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF8F7AE5),
      foregroundColor: Color(0xFFD6D9F7),
      centerTitle: true,
    ),
  );
}