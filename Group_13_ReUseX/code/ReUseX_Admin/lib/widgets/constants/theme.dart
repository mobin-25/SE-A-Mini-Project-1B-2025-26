import 'package:flutter/material.dart';

ThemeData themeData = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,

  // Background color
  scaffoldBackgroundColor: const Color(0xFFF5F5DC),

  primaryColor: Color(0xFF7B61FF),

  colorScheme: ColorScheme.fromSeed(
    seedColor: Color(0xFF7B61FF),
    brightness: Brightness.light,
  ),

  fontFamily: 'Poppins',

  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF7B61FF),
    foregroundColor: Colors.white,
    elevation: 0,
    centerTitle: true,
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Color(0xFF7B61FF),
      foregroundColor: Colors.white,
      elevation: 4,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
  ),

  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    contentPadding: EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 14,
    ),
    border: outlineInputBorder,
    enabledBorder: outlineInputBorder,
    focusedBorder: outlineInputBorder,
    errorBorder: outlineInputBorder,
    disabledBorder: outlineInputBorder,
  ),
);

const OutlineInputBorder outlineInputBorder = OutlineInputBorder(
  borderSide: BorderSide.none,
  borderRadius: BorderRadius.all(Radius.circular(12)),
);

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    scaffoldBackgroundColor: Colors.grey.shade100,
    primaryColor: const Color(0xFF7B61FF),

    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF7B61FF),
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF7B61FF),
      foregroundColor: Colors.white,
      centerTitle: true,
    ),
  );
}