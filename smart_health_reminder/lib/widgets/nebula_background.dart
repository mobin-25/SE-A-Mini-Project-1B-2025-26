import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'parallax_controller.dart';

/// Animated nebula background with 5 floating glowing orbs, drifting
/// shimmer particles, and a shifting gradient — deep-space health-tech vibe.
class NebulaBackground extends StatefulWidget {
  final Widget child;
  const NebulaBackground({super.key, required this.child});

  @override
  State<NebulaBackground> createState() => _NebulaBackgroundState();
}

class _NebulaBackgroundState extends State<NebulaBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final ParallaxController _parallax;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
    _parallax = ParallaxController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _parallax.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return AnimatedBuilder(
      animation: Listenable.merge([_ctrl, _parallax]),
      builder: (context, child) {
        final t = _ctrl.value;
        final angle = t * 2 * math.pi;
        final slow = t * math.pi;
        final parallax = _parallax.offset;
        // Parallax scale factors for orbs/particles
        double orbScale = 40;
        double particleScale = 20;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin:
                  Alignment.topLeft +
                  Alignment(parallax.dx * 0.2, parallax.dy * 0.2),
              end:
                  Alignment.bottomRight +
                  Alignment(-parallax.dx * 0.2, -parallax.dy * 0.2),
              colors: [
                AppTheme.bgPrimary,
                Color.lerp(
                  AppTheme.bgSecondary,
                  AppTheme.electricBlue.withValues(alpha: 0.08),
                  (math.sin(slow) + 1) / 2,
                )!,
                AppTheme.bgPrimary,
                Color.lerp(
                  AppTheme.bgPrimary,
                  AppTheme.radiantPink.withValues(alpha: 0.05),
                  (math.cos(slow) + 1) / 2,
                )!,
              ],
              stops: const [0.0, 0.35, 0.65, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Orb 1 – Electric Blue (top-right)
              Positioned(
                top: 60 + 35 * math.sin(angle) + parallax.dy * orbScale,
                right: 20 + 25 * math.cos(angle) - parallax.dx * orbScale,
                child: _orb(140, AppTheme.electricBlue.withValues(alpha: 0.16)),
              ),
              // Orb 2 – Neon Magenta (bottom-left)
              Positioned(
                bottom: 180 + 45 * math.cos(angle + 1) - parallax.dy * orbScale,
                left: 15 + 30 * math.sin(angle + 1) + parallax.dx * orbScale,
                child: _orb(180, AppTheme.radiantPink.withValues(alpha: 0.14)),
              ),
              // Orb 3 – Vivid Purple (center-right)
              Positioned(
                top:
                    size.height * 0.42 +
                    25 * math.sin(angle + 2) +
                    parallax.dy * orbScale * 0.7,
                right:
                    50 +
                    35 * math.cos(angle + 2) -
                    parallax.dx * orbScale * 0.7,
                child: _orb(120, AppTheme.vividPurple.withValues(alpha: 0.12)),
              ),
              // Orb 4 – Vivid Orange (top-left)
              Positioned(
                top:
                    size.height * 0.18 +
                    20 * math.cos(angle + 3) +
                    parallax.dy * orbScale * 0.5,
                left:
                    40 +
                    20 * math.sin(angle + 3) +
                    parallax.dx * orbScale * 0.5,
                child: _orb(90, AppTheme.vividOrange.withValues(alpha: 0.10)),
              ),
              // Orb 5 – Neon Magenta (bottom-right)
              Positioned(
                bottom:
                    80 +
                    30 * math.sin(angle + 4) -
                    parallax.dy * orbScale * 0.6,
                right:
                    60 +
                    25 * math.cos(angle + 4) -
                    parallax.dx * orbScale * 0.6,
                child: _orb(80, AppTheme.radiantPink.withValues(alpha: 0.12)),
              ),
              // Shimmer particles
              ..._buildParticles(size, angle, parallax, particleScale),
              child!,
            ],
          ),
        );
      },
      child: widget.child,
    );
  }

  List<Widget> _buildParticles(
    Size size,
    double angle, [
    Offset parallax = Offset.zero,
    double scale = 20,
  ]) {
    const count = 8;
    final rng = math.Random(42); // deterministic seed for stable layout
    return List.generate(count, (i) {
      final baseX = rng.nextDouble() * size.width;
      final baseY = rng.nextDouble() * size.height;
      final drift = 15.0 + rng.nextDouble() * 20;
      final phase = rng.nextDouble() * 2 * math.pi;
      final opacity = 0.20 + rng.nextDouble() * 0.25;
      final dotSize = 2.0 + rng.nextDouble() * 3;
      final particleColor =
          i.isEven ? AppTheme.electricBlue : AppTheme.radiantPink;
      return Positioned(
        left: baseX + drift * math.sin(angle + phase) + parallax.dx * scale,
        top:
            baseY + drift * math.cos(angle * 0.7 + phase) + parallax.dy * scale,
        child: Container(
          width: dotSize,
          height: dotSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: particleColor.withValues(alpha: opacity),
            boxShadow: [
              BoxShadow(
                color: particleColor.withValues(alpha: opacity * 0.7),
                blurRadius: 10,
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _orb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0), Colors.transparent],
          stops: const [0.0, 0.6, 1.0],
        ),
      ),
    );
  }
}
