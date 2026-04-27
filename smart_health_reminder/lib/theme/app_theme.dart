/// MEDITOUCH – Vivid Dark Health-Tech Theme
/// Deep space background with pops of Electric Blue, Neon Green,
/// Vivid Orange, Radiant Pink. Glassmorphism, glowing accents, gradients.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ─── Backwards-compat gradients for legacy code ─────────────
  static const LinearGradient greenBlueGradient = bluePurpleGradient;
  static const LinearGradient orangePinkGradient = orangeMagentaGradient;
  AppTheme._();

  // ─── Spider-Verse Color Palette ───────────────────────────────────
  static const Color bgPrimary = Color(0xFF0A0A23); // Spider Black
  static const Color bgSecondary = Color(0xFF181A20); // Deep Cosmic Black
  static const Color electricBlue = Color(0xFF00CFFF); // Electric Blue
  static const Color neonGreen = Color(0xFF00FFB0); // Neon Green (keep)
  static const Color vividOrange = Color(0xFFFFB300); // Spider Orange
  static const Color radiantPink = Color(0xFFFF1C7E); // Neon Magenta
  static const Color vividPurple = Color(0xFF7C3AED); // Vivid Purple
  static const Color textPrimary = Color(0xFFFFFFFF); // Web White
  static const Color textSecondary = Color(0xFFB0B3C6); // Silk Gray
  static const Color glassWhite = Color(0x14FFFFFF); // Glassmorphic card fill
  static const Color glassBorder = Color(0x30FFFFFF); // Glow border

  // Gradients
  static const LinearGradient accentGradient = LinearGradient(
    colors: [radiantPink, electricBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient spiderVerseGradient = LinearGradient(
    colors: [radiantPink, electricBlue, vividPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient orangeMagentaGradient = LinearGradient(
    colors: [vividOrange, radiantPink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient bluePurpleGradient = LinearGradient(
    colors: [electricBlue, vividPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── Backwards-Compat Aliases ──────────────────────────────────────
  static const Color bgDark = bgPrimary;
  static const Color bgDark1 = bgPrimary;
  static const Color bgDark2 = bgSecondary;
  static const Color bgDark3 = Color(0xFF1E1F30);
  static const Color bgLight = bgPrimary;
  static const Color bgCard = Color(0x14FFFFFF);
  static const Color bgCardLight = Color(0x0CFFFFFF);
  static const Color primaryBlue = electricBlue;
  static const Color teal = electricBlue;
  static const Color tealDark = Color(0xFF0090D0);
  static const Color tealLight = Color(0xFF66CFFF);
  static const Color white = textPrimary;
  static const Color grey = textSecondary;
  static const Color greyLight = Color(0x99B0B3C6);
  static const Color textDark = textPrimary;
  static const Color textLight = textSecondary;
  static const Color chipBg = Color(0x3300B4FF);
  static const Color errorRed = Color(0xFFFF4F8B);
  static const Color error = errorRed;
  static const Color accent = radiantPink;
  static const Color success = neonGreen;
  static const Color warning = vividOrange;
  static const Color secondaryBlue = Color(0xFF6C63FF);

  // ─── ThemeData ─────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    final base = ThemeData.dark();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgPrimary,
      colorScheme: const ColorScheme.dark(
        primary: electricBlue,
        secondary: radiantPink,
        surface: bgSecondary,
        error: errorRed,
        onPrimary: bgPrimary,
        onSecondary: textPrimary,
        onSurface: textPrimary,
        onError: textPrimary,
      ),
      textTheme: base.textTheme.copyWith(
        // Headings: Bebas Neue or Poppins, all-caps, bold, neon glow
        headlineLarge: GoogleFonts.bebasNeue(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: 4,
          shadows: [
            Shadow(color: electricBlue.withValues(alpha: 0.6), blurRadius: 12),
            Shadow(color: radiantPink.withValues(alpha: 0.3), blurRadius: 28),
          ],
        ),
        headlineMedium: GoogleFonts.bebasNeue(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: 3,
          shadows: [
            Shadow(color: electricBlue.withValues(alpha: 0.5), blurRadius: 10),
            Shadow(color: radiantPink.withValues(alpha: 0.25), blurRadius: 24),
          ],
        ),
        titleLarge: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: 2,
        ),
        titleMedium: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: textSecondary,
          fontWeight: FontWeight.w500,
          shadows: [Shadow(color: glassBorder, blurRadius: 2)],
        ),
        bodyMedium: GoogleFonts.inter(fontSize: 14, color: textSecondary),
        labelLarge: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: radiantPink,
          letterSpacing: 1.5,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.bebasNeue(
          color: textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: 3,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: glassWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: glassBorder, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: glassWhite,
        selectedItemColor: radiantPink,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 11),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: electricBlue,
        foregroundColor: bgPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: glassWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: glassBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: glassBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: electricBlue, width: 2),
        ),
        hintStyle: GoogleFonts.inter(color: textSecondary, fontSize: 14),
        labelStyle: GoogleFonts.inter(color: textSecondary, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: electricBlue,
          foregroundColor: bgPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: chipBg,
        selectedColor: electricBlue.withValues(alpha: 0.3),
        labelStyle: GoogleFonts.inter(color: textPrimary, fontSize: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: glassBorder),
        ),
        side: BorderSide.none,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.selected)) return electricBlue;
          return textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.selected)) {
            return electricBlue.withValues(alpha: 0.35);
          }
          return glassWhite;
        }),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: glassWhite,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: glassBorder, width: 1),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: bgSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: glassBorder, width: 1),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: bgSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
    );
  }

  // ─── Decorations & Helpers ─────────────────────────────────────────

  /// Glassmorphic card decoration with blur-ready styling and soft shadow.
  static BoxDecoration glassCard({
    double borderRadius = 20,
    Color? borderColor,
    Color? glowColor,
  }) {
    return BoxDecoration(
      color: glassWhite,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: borderColor ?? glassBorder, width: 1),
      boxShadow: [
        BoxShadow(
          color: (glowColor ?? electricBlue).withValues(alpha: 0.08),
          blurRadius: 18,
          spreadRadius: 0,
        ),
        const BoxShadow(
          color: Color(0x20000000),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    );
  }

  /// Glowing box-shadow for accent-coloured elements.
  static List<BoxShadow> glow(Color c, {double blur = 20, double spread = 0}) {
    return [
      BoxShadow(
        color: c.withValues(alpha: 0.45),
        blurRadius: blur,
        spreadRadius: spread,
      ),
    ];
  }

  /// Double-layer glow for more intense neon effect.
  static List<BoxShadow> neonGlow(Color c) {
    return [
      BoxShadow(
        color: c.withValues(alpha: 0.6),
        blurRadius: 16,
        spreadRadius: 1,
      ),
      BoxShadow(
        color: c.withValues(alpha: 0.25),
        blurRadius: 40,
        spreadRadius: 4,
      ),
    ];
  }

  static List<BoxShadow> get fabGlow => glow(electricBlue, blur: 24, spread: 2);

  /// Neon-glowing text style for headings.
  static TextStyle neonText({
    double fontSize = 28,
    FontWeight fontWeight = FontWeight.w800,
    Color color = textPrimary,
    Color glowColor = electricBlue,
  }) {
    return GoogleFonts.poppins(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      shadows: [
        Shadow(color: glowColor.withValues(alpha: 0.6), blurRadius: 16),
        Shadow(color: glowColor.withValues(alpha: 0.3), blurRadius: 40),
      ],
    );
  }

  /// Full-screen gradient background.
  static BoxDecoration get scaffoldGradient => const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [bgPrimary, bgSecondary, bgPrimary],
      stops: [0.0, 0.5, 1.0],
    ),
  );

  /// Fade + Scale page transition for screen navigation.
  static Widget fadeScaleTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.95, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        ),
        child: child,
      ),
    );
  }

  /// Slide + Fade page transition.
  static Widget slideFadeTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.05, 0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        ),
        child: child,
      ),
    );
  }
}
