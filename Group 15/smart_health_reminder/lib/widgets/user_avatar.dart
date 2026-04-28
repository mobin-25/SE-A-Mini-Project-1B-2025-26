import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Reusable avatar with an animated rotating gradient border, ambient
/// neon glow, and fallback initials on a neon-accented background.
class UserAvatar extends StatefulWidget {
  final String? imageUrl;
  final String name;
  final double radius;
  final bool showGlow;
  final Gradient? borderGradient;
  final bool animate;

  const UserAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.radius = 44,
    this.showGlow = true,
    this.borderGradient,
    this.animate = true,
  });

  @override
  State<UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends State<UserAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotCtrl;

  @override
  void initState() {
    super.initState();
    _rotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    if (widget.animate) _rotCtrl.repeat();
  }

  @override
  void dispose() {
    _rotCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final letter = widget.name.isNotEmpty ? widget.name[0].toUpperCase() : '?';
    final hasImage = widget.imageUrl != null && widget.imageUrl!.isNotEmpty;

    return AnimatedBuilder(
      animation: _rotCtrl,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(
              startAngle: 0,
              endAngle: 2 * math.pi,
              transform: GradientRotation(_rotCtrl.value * 2 * math.pi),
              colors: const [
                AppTheme.electricBlue,
                AppTheme.radiantPink,
                AppTheme.vividPurple,
                AppTheme.electricBlue,
              ],
            ),
            boxShadow:
                widget.showGlow
                    ? [
                      BoxShadow(
                        color: AppTheme.electricBlue.withValues(
                          alpha:
                              0.3 +
                              0.15 * math.sin(_rotCtrl.value * 2 * math.pi),
                        ),
                        blurRadius: widget.radius * 0.5,
                        spreadRadius: 1,
                      ),
                      BoxShadow(
                        color: AppTheme.radiantPink.withValues(alpha: 0.15),
                        blurRadius: widget.radius * 0.3,
                        spreadRadius: 0,
                      ),
                    ]
                    : null,
          ),
          child: child,
        );
      },
      child: CircleAvatar(
        radius: widget.radius,
        backgroundColor: AppTheme.bgPrimary,
        backgroundImage: hasImage ? NetworkImage(widget.imageUrl!) : null,
        child:
            !hasImage
                ? ShaderMask(
                  shaderCallback:
                      (bounds) => const LinearGradient(
                        colors: [AppTheme.electricBlue, AppTheme.vividPurple],
                      ).createShader(bounds),
                  child: Text(
                    letter,
                    style: TextStyle(
                      fontSize: widget.radius * 0.75,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                )
                : null,
      ),
    );
  }
}
