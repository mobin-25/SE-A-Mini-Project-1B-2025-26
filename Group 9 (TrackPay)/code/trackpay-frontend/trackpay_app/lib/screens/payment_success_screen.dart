import 'package:flutter/material.dart';
import 'package:animated_check/animated_check.dart';

import '../models/category.dart';
import 'category_detail_screen.dart';
import '../services/category_detail_service.dart';

class PaymentSuccessScreen extends StatefulWidget {
  final double amount;
  final String receiver;
  final int categoryId;
  final String category;

  const PaymentSuccessScreen({
    super.key,
    required this.amount,
    required this.receiver,
    required this.categoryId,
    required this.category,
  });

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  // Extra animation controllers for staggered content reveal
  late AnimationController _contentController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _scaleAnim;

  // ── Design tokens (matches PaymentScreen palette) ────────────────────────
  static const _bgColor = Color(0xFF0A0E1A);
  static const _cardColor = Color(0xFF131929);
  static const _surfaceColor = Color(0xFF1C2438);
  static const _accentBlue = Color(0xFF4F8EF7);
  static const _accentPurple = Color(0xFF7C5CFC);
  static const _accentTeal = Color(0xFF1ECBE1);
  static const _accentGreen = Color(0xFF22C55E);
  static const _textPrimary = Color(0xFFF0F4FF);
  static const _textSecondary = Color(0xFF7B8BAD);
  static const _borderColor = Color(0xFF242E45);

  static const _gradientMain = LinearGradient(
    colors: [_accentBlue, _accentPurple],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnim = CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _contentController, curve: Curves.easeOut),
        );
    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOutBack),
    );

    // ✅ Start tick animation after slight delay
    Future.delayed(const Duration(milliseconds: 300), () {
      _controller.forward();
    });

    // Staggered content reveal
    Future.delayed(const Duration(milliseconds: 600), () {
      _contentController.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _contentController.dispose();
    super.dispose();
  }

  String getCurrentDateTime() {
    final now = DateTime.now();
    return "${now.day} Feb ${now.year}, ${now.hour}:${now.minute}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            children: [
              const SizedBox(height: 52),

              // ── Success badge with animated tick ──────────────────────────
              _buildSuccessBadge(),

              const SizedBox(height: 28),

              // ── Headline ──────────────────────────────────────────────────
              FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) =>
                          _gradientMain.createShader(bounds),
                      child: const Text(
                        "Payment Successful!",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Your payment has been processed",
                      style: TextStyle(
                        color: _textSecondary,
                        fontSize: 14,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ── Payment Info Card ─────────────────────────────────────────
              SlideTransition(
                position: _slideAnim,
                child: ScaleTransition(
                  scale: _scaleAnim,
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: _buildInfoCard(),
                  ),
                ),
              ),

              // ── Transaction ID strip ──────────────────────────────────────
              FadeTransition(opacity: _fadeAnim, child: _buildTxnStrip()),

              const Spacer(),

              // ── Action buttons ────────────────────────────────────────────
              FadeTransition(opacity: _fadeAnim, child: _buildButtons()),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ── Success Badge ────────────────────────────────────────────────────────

  Widget _buildSuccessBadge() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer glow ring
        Container(
          width: 130,
          height: 130,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _accentGreen.withOpacity(0.06),
            border: Border.all(color: _accentGreen.withOpacity(0.15), width: 1),
          ),
        ),
        // Inner filled circle
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _accentGreen.withOpacity(0.12),
            border: Border.all(
              color: _accentGreen.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _accentGreen.withOpacity(0.2),
                blurRadius: 28,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: AnimatedCheck(
              progress: _controller,
              size: 58,
              color: _accentGreen,
            ),
          ),
        ),
      ],
    );
  }

  // ── Info Card ────────────────────────────────────────────────────────────

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Amount hero row at top
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A2340), Color(0xFF1E1535)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Amount Paid",
                      style: TextStyle(
                        color: _textSecondary,
                        fontSize: 12,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ShaderMask(
                      shaderCallback: (bounds) =>
                          _gradientMain.createShader(bounds),
                      child: Text(
                        "₹${widget.amount.toInt()}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                        ),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _accentGreen.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _accentGreen.withOpacity(0.25)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: _accentGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        "Success",
                        style: TextStyle(
                          color: _accentGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Detail rows
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
            child: Column(
              children: [
                infoRow("To", widget.receiver, Icons.person_outline_rounded),
                _rowDivider(),
                infoRow("Category", widget.category, Icons.grid_view_rounded),
                _rowDivider(),
                infoRow(
                  "Date & Time",
                  getCurrentDateTime(),
                  Icons.schedule_rounded,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rowDivider() => Container(
    height: 1,
    margin: const EdgeInsets.symmetric(vertical: 10),
    color: _borderColor,
  );

  // ── Transaction ID strip ──────────────────────────────────────────────────

  Widget _buildTxnStrip() {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: _surfaceColor.withOpacity(0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _borderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.verified_user_outlined,
              color: _accentTeal,
              size: 14,
            ),
            const SizedBox(width: 8),
            Text(
              "256-bit encrypted · RBI regulated",
              style: TextStyle(
                color: _textSecondary.withOpacity(0.7),
                fontSize: 11,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Buttons ───────────────────────────────────────────────────────────────

  Widget _buildButtons() {
    return Row(
      children: [
        // DONE Button
        Expanded(
          child: _GradientButton(
            label: "Done",
            gradient: _gradientMain,
            onPressed: () {
              Navigator.pop(context, true); // ✅ Return success
            },
          ),
        ),

        const SizedBox(width: 12),

        // VIEW FOLDER Button
        Expanded(
          child: _OutlineButton(
            label: "View Folder",
            icon: Icons.folder_outlined,
            onPressed: () async {
              // ✅ Fetch latest category from backend
              CategoryModel cat =
                  await CategoryDetailService.fetchCategoryDetail(
                    widget.categoryId,
                  );

              // ✅ Open Category Detail Screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CategoryDetailScreen(category: cat),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ✅ Info Row Helper Widget
  Widget infoRow(String title, String value, IconData icon) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: _accentBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: _accentBlue, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _textSecondary,
                  fontSize: 11,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: _textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Reusable gradient button ──────────────────────────────────────────────────

class _GradientButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final Gradient gradient;

  const _GradientButton({
    required this.label,
    required this.onPressed,
    required this.gradient,
  });

  @override
  State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.96,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.reverse(),
      onTapUp: (_) {
        _ctrl.forward();
        widget.onPressed();
      },
      onTapCancel: () => _ctrl.forward(),
      child: ScaleTransition(
        scale: _ctrl,
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4F8EF7).withOpacity(0.3),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Center(
            child: Text(
              widget.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Outline button ────────────────────────────────────────────────────────────

class _OutlineButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _OutlineButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  State<_OutlineButton> createState() => _OutlineButtonState();
}

class _OutlineButtonState extends State<_OutlineButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.96,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.reverse(),
      onTapUp: (_) {
        _ctrl.forward();
        widget.onPressed();
      },
      onTapCancel: () => _ctrl.forward(),
      child: ScaleTransition(
        scale: _ctrl,
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            color: const Color(0xFF131929),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF242E45), width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: const Color(0xFF7B8BAD), size: 16),
              const SizedBox(width: 7),
              Text(
                widget.label,
                style: const TextStyle(
                  color: Color(0xFF7B8BAD),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
