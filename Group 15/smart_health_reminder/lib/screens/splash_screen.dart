import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/parallax_controller.dart';

// ── Spider-Verse palette ────────────────────────────────────────────
const _kNeonMagenta = Color(0xFFFF2D95);
const _kElectricBlue = Color(0xFF00B4FF);
const _kVividPurple = Color(0xFF9B30FF);
const _kDeepViolet = Color(0xFF2D004F);
const _kCosmicBlack = Color(0xFF0A0012);

/// Spider-Verse–inspired splash screen: dark cosmic swirl, neon magenta /
/// electric blue / vivid purple gradients, glassmorphic centre circle with
/// glowing health icon, floating orbs, web-pattern lines, gradient app name
/// with neon glow, and vivid-purple tagline.
class SplashScreen extends StatefulWidget {
  final VoidCallback onFinished;
  const SplashScreen({super.key, required this.onFinished});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final ParallaxController _parallax;
  late final AnimationController _gradCtrl;
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulse;
  late final AnimationController _ringCtrl;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fade;
  late final AnimationController _tagCtrl;
  late final Animation<double> _tagAnim;
  late final AnimationController _webCtrl;

  @override
  void initState() {
    super.initState();
    _parallax = ParallaxController();
    // Cosmic gradient rotation
    _gradCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    // Pulsing glassmorphic circle
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulse = Tween(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    // Rotating progress ring
    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    // Web-pattern expansion
    _webCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    // Fade-in app name
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    // Tagline slide-up
    _tagCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _tagAnim = CurvedAnimation(parent: _tagCtrl, curve: Curves.easeOutCubic);
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _fadeCtrl.forward();
    });
    Future.delayed(const Duration(milliseconds: 850), () {
      if (mounted) _tagCtrl.forward();
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) widget.onFinished();
    });
  }

  @override
  void dispose() {
    _gradCtrl.dispose();
    _pulseCtrl.dispose();
    _ringCtrl.dispose();
    _fadeCtrl.dispose();
    _tagCtrl.dispose();
    _webCtrl.dispose();
    _parallax.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sz = MediaQuery.of(context).size;
    return AnimatedBuilder(
      animation: Listenable.merge([
        _gradCtrl,
        _pulseCtrl,
        _ringCtrl,
        _webCtrl,
        _parallax,
      ]),
      builder: (context, _) {
        final t = _gradCtrl.value;
        final angle = t * 2 * math.pi;
        final cosA = math.cos(angle);
        final sinA = math.sin(angle);
        final parallax = _parallax.offset;
        double orbScale = 40;
        double particleScale = 20;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin:
                  Alignment(cosA, sinA) +
                  Alignment(parallax.dx * 0.2, parallax.dy * 0.2),
              end:
                  Alignment(-cosA, -sinA) +
                  Alignment(-parallax.dx * 0.2, -parallax.dy * 0.2),
              colors: [
                _kCosmicBlack,
                _kDeepViolet.withValues(alpha: 0.8),
                _kNeonMagenta.withValues(alpha: 0.15),
                _kCosmicBlack,
                _kElectricBlue.withValues(alpha: 0.12),
                _kCosmicBlack,
              ],
              stops: const [0.0, 0.2, 0.4, 0.55, 0.75, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // ── Web pattern lines ──────────────────────────────
              Positioned.fill(
                child: CustomPaint(
                  painter: _WebPatternPainter(
                    progress: _webCtrl.value,
                    center: Offset(sz.width / 2, sz.height * 0.38),
                  ),
                ),
              ),

              // ── Floating neon orbs ─────────────────────────────
              _posOrb(
                60 + 35 * math.sin(angle) + parallax.dy * orbScale,
                null,
                null,
                30 + 20 * math.cos(angle) - parallax.dx * orbScale,
                130,
                _kNeonMagenta,
                0.12,
              ),
              _posOrb(
                null,
                140 + 45 * math.cos(angle + 1) - parallax.dy * orbScale,
                20 + 30 * math.sin(angle + 1) + parallax.dx * orbScale,
                null,
                170,
                _kElectricBlue,
                0.09,
              ),
              _posOrb(
                sz.height * 0.55 +
                    20 * math.sin(angle + 2) +
                    parallax.dy * orbScale * 0.7,
                null,
                null,
                60 + 25 * math.cos(angle + 2) - parallax.dx * orbScale * 0.7,
                90,
                _kVividPurple,
                0.10,
              ),
              _posOrb(
                sz.height * 0.2 +
                    18 * math.cos(angle + 3) +
                    parallax.dy * orbScale * 0.5,
                null,
                50 + 20 * math.sin(angle + 3) + parallax.dx * orbScale * 0.5,
                null,
                65,
                _kNeonMagenta,
                0.07,
              ),
              _posOrb(
                null,
                80 + 28 * math.sin(angle + 4) - parallax.dy * orbScale * 0.6,
                null,
                70 + 22 * math.cos(angle + 4) - parallax.dx * orbScale * 0.6,
                55,
                _kElectricBlue,
                0.08,
              ),

              // ── Shimmer particles ──────────────────────────────
              ..._particles(sz, angle, parallax, particleScale),

              // ── Main content ───────────────────────────────────
              Scaffold(
                backgroundColor: Colors.transparent,
                body: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Glassmorphic circle + progress ring + icon
                      SizedBox(
                        width: 180,
                        height: 180,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer rotating gradient ring
                            Transform.rotate(
                              angle: _ringCtrl.value * 2 * math.pi,
                              child: CustomPaint(
                                size: const Size(180, 180),
                                painter: _SpiderRingPainter(progress: 0.78),
                              ),
                            ),
                            // Inner pulsing glassmorphic circle
                            Transform.scale(
                              scale: 0.88 + 0.12 * _pulse.value,
                              child: Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      _kNeonMagenta.withValues(alpha: 0.18),
                                      _kVividPurple.withValues(alpha: 0.1),
                                      _kElectricBlue.withValues(alpha: 0.05),
                                      Colors.transparent,
                                    ],
                                    stops: const [0.0, 0.35, 0.65, 1.0],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _kNeonMagenta.withValues(
                                        alpha: 0.25 + 0.15 * _pulse.value,
                                      ),
                                      blurRadius: 35 + 15 * _pulse.value,
                                      spreadRadius: 3,
                                    ),
                                    BoxShadow(
                                      color: _kElectricBlue.withValues(
                                        alpha: 0.12,
                                      ),
                                      blurRadius: 50,
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                      sigmaX: 18,
                                      sigmaY: 18,
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0x18FFFFFF),
                                        border: Border.all(
                                          color: _kNeonMagenta.withValues(
                                            alpha: 0.35,
                                          ),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: ShaderMask(
                                        shaderCallback:
                                            (bounds) => const LinearGradient(
                                              colors: [
                                                _kNeonMagenta,
                                                _kElectricBlue,
                                              ],
                                            ).createShader(bounds),
                                        child: Image.asset(
                                          'assets/APP_LOGO.png',
                                          width: 70,
                                          height: 70,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 44),

                      // App name — gradient fill with neon glow
                      FadeTransition(
                        opacity: _fade,
                        child: ShaderMask(
                          shaderCallback:
                              (bounds) => const LinearGradient(
                                colors: [
                                  _kNeonMagenta,
                                  _kElectricBlue,
                                  _kVividPurple,
                                ],
                              ).createShader(bounds),
                          child: Text(
                            'MEDITOUCH',
                            style: GoogleFonts.poppins(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 10,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: _kNeonMagenta.withValues(alpha: 0.7),
                                  blurRadius: 24,
                                ),
                                Shadow(
                                  color: _kElectricBlue.withValues(alpha: 0.5),
                                  blurRadius: 48,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Tagline — vivid purple
                      AnimatedBuilder(
                        animation: _tagAnim,
                        builder:
                            (context, child) => Opacity(
                              opacity: _tagAnim.value,
                              child: Transform.translate(
                                offset: Offset(0, 14 * (1 - _tagAnim.value)),
                                child: child,
                              ),
                            ),
                        child: Text(
                          'Your Digital Health Guardian',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _kVividPurple,
                            letterSpacing: 2,
                            shadows: [
                              Shadow(
                                color: _kVividPurple.withValues(alpha: 0.6),
                                blurRadius: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────

  Widget _posOrb(
    double? top,
    double? bottom,
    double? left,
    double? right,
    double size,
    Color color,
    double alpha,
  ) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: _orb(size, color.withValues(alpha: alpha)),
    );
  }

  List<Widget> _particles(
    Size sz,
    double angle, [
    Offset parallax = Offset.zero,
    double scale = 20,
  ]) {
    const count = 16;
    final rng = math.Random(13);
    final palette = [_kNeonMagenta, _kElectricBlue, _kVividPurple];
    return List.generate(count, (i) {
      final bx = rng.nextDouble() * sz.width;
      final by = rng.nextDouble() * sz.height;
      final drift = 18.0 + rng.nextDouble() * 28;
      final phase = rng.nextDouble() * 2 * math.pi;
      final opacity = 0.25 + rng.nextDouble() * 0.35;
      final d = 2.0 + rng.nextDouble() * 3.5;
      final c = palette[i % palette.length];
      return Positioned(
        left: bx + drift * math.sin(angle + phase) + parallax.dx * scale,
        top: by + drift * math.cos(angle * 0.55 + phase) + parallax.dy * scale,
        child: Container(
          width: d,
          height: d,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: c.withValues(alpha: opacity),
            boxShadow: [
              BoxShadow(
                color: c.withValues(alpha: opacity * 0.7),
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
          stops: const [0.0, 0.55, 1.0],
        ),
      ),
    );
  }
}

// ── Gradient progress ring ──────────────────────────────────────────
class _SpiderRingPainter extends CustomPainter {
  final double progress;
  _SpiderRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    const sw = 3.0;
    final paint =
        Paint()
          ..shader = const SweepGradient(
            colors: [
              _kNeonMagenta,
              _kElectricBlue,
              _kVividPurple,
              _kNeonMagenta,
            ],
          ).createShader(rect)
          ..style = PaintingStyle.stroke
          ..strokeWidth = sw
          ..strokeCap = StrokeCap.round;

    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - sw) / 2;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_SpiderRingPainter old) => old.progress != progress;
}

// ── Subtle web pattern lines radiating from centre ──────────────────
class _WebPatternPainter extends CustomPainter {
  final double progress;
  final Offset center;
  _WebPatternPainter({required this.progress, required this.center});

  @override
  void paint(Canvas canvas, Size size) {
    const lineCount = 12;
    final maxRadius = size.longestSide * 0.75;
    final paint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5;

    // Radial lines
    for (int i = 0; i < lineCount; i++) {
      final a = (i / lineCount) * 2 * math.pi + progress * 2 * math.pi;
      final end = Offset(
        center.dx + maxRadius * math.cos(a),
        center.dy + maxRadius * math.sin(a),
      );
      paint.color = _kVividPurple.withValues(
        alpha: 0.07 + 0.03 * math.sin(progress * 2 * math.pi + i),
      );
      canvas.drawLine(center, end, paint);
    }

    // Concentric rings
    const ringCount = 4;
    for (int r = 1; r <= ringCount; r++) {
      final radius = (maxRadius / ringCount) * r;
      paint.color = _kNeonMagenta.withValues(
        alpha: 0.04 + 0.02 * (r / ringCount),
      );
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_WebPatternPainter old) => old.progress != progress;
}
