import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class ApsitLogo extends StatelessWidget {
  final double size;
  const ApsitLogo({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.2 * 255).round()),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school, color: AppColors.primary, size: size * 0.4),
            Text(
              'APSIT',
              style: GoogleFonts.inter(
                color: AppColors.primary,
                fontWeight: FontWeight.w900,
                fontSize: size * 0.15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
