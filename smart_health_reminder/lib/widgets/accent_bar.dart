import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A thin vertical accent bar used on the left side of list items
/// (medicines, appointments) for a colourful indicator.
class AccentBar extends StatelessWidget {
  final Color color;
  final double height;
  final double width;

  const AccentBar({
    super.key,
    this.color = AppTheme.electricBlue,
    this.height = 44,
    this.width = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color, color.withValues(alpha: 0.5)],
        ),
        borderRadius: BorderRadius.circular(width / 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.5),
            blurRadius: 10,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }
}
