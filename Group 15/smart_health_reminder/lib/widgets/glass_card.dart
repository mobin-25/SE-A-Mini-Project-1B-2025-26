import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Glassmorphic card: frosted-glass blur background with glowing
/// coloured border, soft drop shadow, and optional accent glow.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? borderColor;
  final Color? glowColor;
  final double blurAmount;

  const GlassCard({
    super.key,
    required this.child,
    this.margin,
    this.padding,
    this.borderRadius = 20,
    this.borderColor,
    this.glowColor,
    this.blurAmount = 12,
  });

  @override
  Widget build(BuildContext context) {
    final bColor = borderColor ?? AppTheme.glassBorder;
    final gColor = glowColor ?? AppTheme.radiantPink;

    return Container(
      margin: margin ?? const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: gColor.withValues(alpha: 0.12),
            blurRadius: 22,
            spreadRadius: 0,
          ),
          const BoxShadow(
            color: Color(0x18000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
          child: Container(
            padding: padding ?? const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0x1EFFFFFF),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: bColor, width: 1),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
