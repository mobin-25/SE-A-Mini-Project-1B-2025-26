import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A rounded button filled with the magenta→blue accent gradient, animated
/// neon glow on press, scale pop, and Material ripple effect.
class GradientButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final double height;
  final Gradient? gradient;

  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.height = 54,
    this.gradient,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late final AnimationController _glowCtrl;
  late final Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _glowAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    setState(() => _pressed = true);
    _glowCtrl.forward();
  }

  void _onTapUp(TapUpDetails _) {
    setState(() => _pressed = false);
    _glowCtrl.reverse();
    widget.onPressed();
  }

  void _onTapCancel() {
    setState(() => _pressed = false);
    _glowCtrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _glowAnim,
        builder: (context, child) {
          final glowValue = _glowAnim.value;
          return AnimatedScale(
            scale: _pressed ? 0.96 : 1.0,
            duration: const Duration(milliseconds: 120),
            child: Container(
              height: widget.height,
              decoration: BoxDecoration(
                gradient: widget.gradient ?? AppTheme.accentGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.electricBlue.withValues(
                      alpha: 0.15 + 0.35 * glowValue,
                    ),
                    blurRadius: 12 + 18 * glowValue,
                    spreadRadius: glowValue * 2,
                  ),
                  BoxShadow(
                    color: AppTheme.radiantPink.withValues(
                      alpha: 0.08 + 0.2 * glowValue,
                    ),
                    blurRadius: 20 + 10 * glowValue,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  splashColor: Colors.white.withValues(alpha: 0.15),
                  highlightColor: Colors.white.withValues(alpha: 0.05),
                  onTap: () {}, // handled by GestureDetector
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          widget.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
