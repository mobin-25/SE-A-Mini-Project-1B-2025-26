import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Core colours ──────────────────────────────────────────────────────────
  static const Color bgPrimary = Color(0xFFF5F7FA); // warm off-white
  static const Color bgSecondary = Color(0xFFE8F4F8); // light teal tint
  static const Color bgCard = Color(0xFFFFFFFF); // pure white
  static const Color bgCardAlt = Color(0xFFF8FAFC); // very light gray
  static const Color accentTeal = Color(0xFF1A6B72); // deep teal
  static const Color accentAmber = Color(0xFFF4A261); // soft amber
  static const Color textPrimary = Color(0xFF2D3748); // dark charcoal
  static const Color textSecondary = Color(0xFF4A5568); // medium gray
  static const Color textMuted = Color(0xFF718096); // light gray
  static const Color divider = Color(0xFFE2E8F0); // very light gray
  static const Color inputBorder = Color(0xFFCBD5E0); // light gray
  static const Color error = Color(0xFFE53E3E); // muted red
  static const Color success = Color(0xFF38A169); // soft green

  // ── Priority colours ──────────────────────────────────────────────────────
  static const Color priorityLow = Color(0xFF68D391); // soft green
  static const Color priorityMedium = accentAmber; // soft amber
  static const Color priorityHigh = Color(0xFFED8936); // orange
  static const Color priorityCritical = error; // muted red

  // ── Status colours ────────────────────────────────────────────────────────
  static const Color statusOpen = accentTeal; // deep teal
  static const Color statusInProgress = accentAmber; // soft amber
  static const Color statusResolved = success; // soft green

  // ── Category colours ──────────────────────────────────────────────────────
  static const Color categoryFire = Color(0xFFE53E3E); // red
  static const Color categoryFlood = Color(0xFF3182CE); // blue
  static const Color categoryMedical = Color(0xFF38A169); // green
  static const Color categoryCrime = Color(0xFF805AD5); // purple
  static const Color categoryAccident = Color(0xFFED8936); // orange
  static const Color categoryOther = Color(0xFF718096); // gray

  // ── Gradients ─────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1A6B72), Color(0xFF2C7A7B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient dangerGradient = LinearGradient(
    colors: [Color(0xFFE53E3E), Color(0xFFC53030)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Helpers ───────────────────────────────────────────────────────────────
  static Color priorityColor(String priority) {
    switch (priority) {
      case 'Low':
        return priorityLow;
      case 'Medium':
        return priorityMedium;
      case 'High':
        return priorityHigh;
      case 'Critical':
        return priorityCritical;
      default:
        return priorityMedium;
    }
  }

  static Color statusColor(String status) {
    switch (status) {
      case 'Open':
        return statusOpen;
      case 'In Progress':
        return statusInProgress;
      case 'Resolved':
        return statusResolved;
      default:
        return statusOpen;
    }
  }

  static Color categoryColor(String category) {
    switch (category) {
      case 'Fire':
        return categoryFire;
      case 'Flood':
        return categoryFlood;
      case 'Medical':
        return categoryMedical;
      case 'Crime':
        return categoryCrime;
      case 'Accident':
        return categoryAccident;
      case 'Other':
        return categoryOther;
      default:
        return categoryOther;
    }
  }

  static int priorityOrder(String priority) {
    switch (priority) {
      case 'Critical':
        return 0;
      case 'High':
        return 1;
      case 'Medium':
        return 2;
      case 'Low':
        return 3;
      default:
        return 2;
    }
  }

  // ── Light Theme ────────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: bgPrimary,
      colorScheme: const ColorScheme.light(
        primary: accentTeal,
        secondary: accentAmber,
        surface: bgCard,
        onPrimary: Color(0xFFFFFFFF),
        onSecondary: textPrimary,
        onSurface: textPrimary,
      ),
      textTheme: GoogleFonts.interTextTheme(
        const TextTheme(
          displayLarge: TextStyle(
              color: textPrimary, fontWeight: FontWeight.bold),
          headlineLarge: TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 28),
          headlineMedium: TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 22),
          headlineSmall: TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 18),
          titleLarge: TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 16),
          titleMedium: TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.w500,
              fontSize: 14),
          bodyLarge: TextStyle(color: textPrimary, fontSize: 16),
          bodyMedium: TextStyle(color: textSecondary, fontSize: 14),
          bodySmall: TextStyle(color: textMuted, fontSize: 12),
          labelLarge: TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 14),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bgCard,
        elevation: 2,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFFFFFFFF),
        selectedItemColor: accentTeal,
        unselectedItemColor: textMuted,
        selectedLabelStyle:
            TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 12),
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
      cardTheme: const CardThemeData(
        color: bgCard,
        elevation: 4,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16))),
        margin:
            EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgCardAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentTeal, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: error, width: 1),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textMuted),
        prefixIconColor: textMuted,
        suffixIconColor: textMuted,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentTeal,
          foregroundColor: Color(0xFFFFFFFF),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(
              vertical: 14, horizontal: 24),
          elevation: 2,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: bgCard,
        selectedColor: accentTeal,
        checkmarkColor: textPrimary,
        labelStyle:
            const TextStyle(color: textSecondary, fontSize: 12),
        selectedShadowColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        side: const BorderSide(color: inputBorder),
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      dividerTheme:
          const DividerThemeData(color: divider, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: bgCard,
        contentTextStyle:
            GoogleFonts.inter(color: textPrimary, fontSize: 14),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: bgCard,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        titleTextStyle: GoogleFonts.inter(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle:
            GoogleFonts.inter(color: textSecondary, fontSize: 14),
      ),
    );
  }
}
