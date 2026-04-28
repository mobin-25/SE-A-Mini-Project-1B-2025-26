import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;

import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> fade;
  late Animation<double> scale;

  // Extra UI-only animations (same controller, different curves/intervals)
  late Animation<double> _taglineFade;
  late Animation<double> _dotsFade;
  late Animation<double> _ringScale;
  late Animation<double> _ringOpacity;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    fade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeIn));

    scale = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOutBack));

    // UI-only extras
    _taglineFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.55, 1.0, curve: Curves.easeOut),
      ),
    );
    _dotsFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
      ),
    );
    _ringScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );
    _ringOpacity = Tween<double>(begin: 0.0, end: 0.12).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    controller.forward();

    // ✅ Auto Navigate after 2.5 sec
    Timer(const Duration(milliseconds: 2500), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: Stack(
        children: [
          // ── Background mesh blobs ──────────────────────────────────────────
          Positioned(
            top: -size.height * 0.12,
            left: -size.width * 0.2,
            child: _GlowBlob(
              color: const Color(0xFF4F8EF7),
              size: size.width * 0.75,
              opacity: 0.13,
            ),
          ),
          Positioned(
            bottom: size.height * 0.05,
            right: -size.width * 0.15,
            child: _GlowBlob(
              color: const Color(0xFF7C5CFC),
              size: size.width * 0.65,
              opacity: 0.11,
            ),
          ),
          Positioned(
            top: size.height * 0.38,
            left: size.width * 0.3,
            child: _GlowBlob(
              color: const Color(0xFF1ECBE1),
              size: size.width * 0.4,
              opacity: 0.07,
            ),
          ),

          // ── Animated concentric rings (decorative) ─────────────────────────
          AnimatedBuilder(
            animation: controller,
            builder: (_, __) => Center(
              child: Opacity(
                opacity: _ringOpacity.value,
                child: Transform.scale(
                  scale: _ringScale.value,
                  child: SizedBox(
                    width: size.width * 0.85,
                    height: size.width * 0.85,
                    child: CustomPaint(painter: _RingsPainter()),
                  ),
                ),
              ),
            ),
          ),

          // ── Main content ──────────────────────────────────────────────────
          Center(
            child: FadeTransition(
              opacity: fade,
              child: ScaleTransition(
                scale: scale,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo icon badge
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4F8EF7), Color(0xFF7C5CFC)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4F8EF7).withOpacity(0.4),
                            blurRadius: 28,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // "TrackPay" wordmark — preserves original ShaderMask + text
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [
                          Color(0xFF4F8EF7),
                          Color(0xFF7C5CFC),
                          Color(0xFF1ECBE1),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ).createShader(bounds),
                      child: const Text(
                        "TrackPay",
                        style: TextStyle(
                          fontSize: 52,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: Colors.white, // required for shader
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Tagline
                    FadeTransition(
                      opacity: _taglineFade,
                      child: const Text(
                        "Smart money, smarter you",
                        style: TextStyle(
                          color: Color(0xFF7B8BAD),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Bottom loading dots ───────────────────────────────────────────
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _dotsFade,
              child: const _PulsingDots(),
            ),
          ),

          // ── Version label ─────────────────────────────────────────────────
          Positioned(
            bottom: 28,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _taglineFade,
              child: const Text(
                "v1.0.0",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF3A4260),
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// _GlowBlob — soft radial gradient circle for background atmosphere
// =============================================================================
class _GlowBlob extends StatelessWidget {
  final Color color;
  final double size;
  final double opacity;

  const _GlowBlob({
    required this.color,
    required this.size,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withOpacity(opacity), Colors.transparent],
        ),
      ),
    );
  }
}

// =============================================================================
// _RingsPainter — decorative concentric dashed rings
// =============================================================================
class _RingsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = const Color(0xFF4F8EF7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 1; i <= 3; i++) {
      paint.color = const Color(0xFF4F8EF7).withOpacity(0.08 + (i * 0.04));
      canvas.drawCircle(center, size.width * 0.18 * i, paint);
    }
  }

  @override
  bool shouldRepaint(_RingsPainter oldDelegate) => false;
}

// =============================================================================
// _PulsingDots — three animated loading dots
// =============================================================================
class _PulsingDots extends StatefulWidget {
  const _PulsingDots();

  @override
  State<_PulsingDots> createState() => _PulsingDotsState();
}

class _PulsingDotsState extends State<_PulsingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            // Each dot is offset by 120° in the cycle
            final phase = (_ctrl.value + i / 3) % 1.0;
            final opacity = (math.sin(phase * math.pi * 2) * 0.5 + 0.5).clamp(
              0.2,
              1.0,
            );
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF4F8EF7).withOpacity(opacity),
              ),
            );
          },
        );
      }),
    );
  }
}
