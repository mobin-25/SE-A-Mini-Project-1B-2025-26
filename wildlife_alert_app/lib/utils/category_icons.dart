import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CategoryIcons {
  static IconData getIcon(String category) {
    switch (category) {
      case 'Fire':
        return Icons.local_fire_department;
      case 'Flood':
        return Icons.water;
      case 'Medical':
        return Icons.local_hospital;
      case 'Crime':
        return Icons.security;
      case 'Accident':
        return Icons.warning;
      case 'Other':
      default:
        return Icons.info;
    }
  }

  static Color getColor(String category) {
    return AppTheme.categoryColor(category);
  }
}
