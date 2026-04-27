import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


ThemeData themeData = ThemeData(
    scaffoldBackgroundColor: Colors.white,
    primaryColor: Colors.green,

    appBarTheme: const AppBarTheme(   // ← ONLY THIS WAS ADDED
      backgroundColor: Colors.green,
      foregroundColor: Colors.white,
      elevation: 0,
    ),

    inputDecorationTheme: const InputDecorationTheme(
      border: outlineInputBorder,
      errorBorder: outlineInputBorder,
      enabledBorder: outlineInputBorder,
      prefixIconColor: Colors.grey,
      suffixIconColor: Colors.grey,
      focusedBorder: outlineInputBorder,
      disabledBorder: outlineInputBorder,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.white,
        textStyle: const TextStyle(
          fontSize: 20,
        ),
      ),
    )
);

const OutlineInputBorder outlineInputBorder = OutlineInputBorder(
  borderSide: BorderSide(
    color: Colors.grey,
  ),
);

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    scaffoldBackgroundColor: Colors.white,
    primaryColor: Colors.green,

    textTheme: GoogleFonts.poppinsTextTheme(),

    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Colors.green,
          width: 2,
        ),
      ),
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.green,
      foregroundColor: Colors.white,
      elevation: 0,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  );
}