import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SkeletonLoader extends StatefulWidget {
  final int itemCount;

  const SkeletonLoader({super.key, this.itemCount = 4});

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.only(top: 8),
          itemCount: widget.itemCount,
          itemBuilder: (context, index) => _SkeletonCard(
            opacity: _animation.value,
          ),
        );
      },
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  final double opacity;

  const _SkeletonCard({required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _bone(opacity, width: 60, height: 20, radius: 10),
              const SizedBox(width: 8),
              _bone(opacity, width: 80, height: 20, radius: 10),
              const Spacer(),
              _bone(opacity, width: 50, height: 20, radius: 20),
            ],
          ),
          const SizedBox(height: 12),
          _bone(opacity, width: double.infinity, height: 14, radius: 6),
          const SizedBox(height: 6),
          _bone(opacity, width: 200, height: 14, radius: 6),
          const SizedBox(height: 12),
          _bone(opacity, width: 100, height: 12, radius: 6),
        ],
      ),
    );
  }

  Widget _bone(double opacity,
      {required double width,
      required double height,
      required double radius}) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppTheme.bgCardAlt,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}
