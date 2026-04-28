import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF6C63FF);
  static const primaryDark = Color(0xFF3B35C9);
  static const secondary = Color(0xFF00BCD4);
  static const accent = Color(0xFFFF6584);
  static const success = Color(0xFF4CAF50);
  static const warning = Color(0xFFFF9800);
  static const error = Color(0xFFE53935);
  static const background = Color(0xFFF5F7FA);
  static const cardBg = Colors.white;
  static const textPrimary = Color(0xFF1A1A2E);
  static const textSecondary = Color(0xFF6B7280);
  static const adminPrimary = Color(0xFF1E3A5F);
  static const adminAccent = Color(0xFFFF6F00);
  static const gradient1 = Color(0xFF6C63FF);
  static const gradient2 = Color(0xFF3B35C9);
}

class AppGradients {
  static const primaryGradient = LinearGradient(
    colors: [AppColors.gradient1, AppColors.gradient2],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const adminGradient = LinearGradient(
    colors: [Color(0xFF1E3A5F), Color(0xFF0D1B2A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const cardGradient = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFF5A52E0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTextStyles {
  static const heading1 = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  static const heading2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );
  static const body = TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary,
    height: 1.5,
  );
}
