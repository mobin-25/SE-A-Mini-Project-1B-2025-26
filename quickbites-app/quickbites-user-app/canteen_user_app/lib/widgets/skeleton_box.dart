import 'package:flutter/material.dart';
import 'skeleton_visibility_registry.dart';

class SkeletonBox extends StatefulWidget {
  final double? width;
  final double height;
  final BorderRadius? borderRadius;

  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();

    markSkeletonVisible();
  }

  @override
  void dispose() {
    markSkeletonHidden();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(10);

    return ClipRRect(
      borderRadius: radius,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final slide = (_controller.value * 2.4) - 1.2;
          return Container(
            width: widget.width,
            height: widget.height,
            decoration: const BoxDecoration(
              color: Color(0xFFE5E7EB),
            ),
            child: Transform.translate(
              offset: Offset(widget.width == null ? 280 * slide : widget.width! * slide, 0),
              child: Container(
                width: widget.width == null ? 140 : widget.width! * 0.55,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0),
                      Colors.white.withValues(alpha: 0.50),
                      Colors.white.withValues(alpha: 0),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
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
