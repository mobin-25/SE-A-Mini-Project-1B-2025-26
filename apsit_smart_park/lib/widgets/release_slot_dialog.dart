import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class ReleaseSlotDialog extends StatelessWidget {
  final String slotId;
  final VoidCallback onRelease;

  const ReleaseSlotDialog({
    super.key,
    required this.slotId,
    required this.onRelease,
  });

  static Future<void> show(
    BuildContext context, {
    required String slotId,
    required VoidCallback onRelease,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      isScrollControlled: true,
      builder: (ctx) => ReleaseSlotDialog(slotId: slotId, onRelease: onRelease),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
            color: AppColors.inputBorder.withAlpha((0.5 * 255).round())),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.5 * 255).round()),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: AppColors.inputBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Warning icon
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.red.withAlpha((0.15 * 255).round()),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child:
                  Icon(Icons.warning_rounded, color: AppColors.red, size: 38),
            ),
          ),
          const SizedBox(height: 20),
          // Title
          Text(
            'Release Slot?',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          // Body
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Are you sure you want to end your reservation for ',
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
                TextSpan(
                  text: 'Slot $slotId',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.6,
                  ),
                ),
                TextSpan(
                  text: '? This action cannot be undone.',
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          // Yes, Release button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRelease();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.red,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 4,
                shadowColor: AppColors.red.withAlpha((0.4 * 255).round()),
              ),
              child: Text(
                'Yes, Release',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Cancel button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 4,
                shadowColor: AppColors.primary.withAlpha((0.4 * 255).round()),
              ),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
