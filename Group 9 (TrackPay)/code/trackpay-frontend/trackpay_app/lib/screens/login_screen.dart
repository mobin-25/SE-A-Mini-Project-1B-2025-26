import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'dashboard_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final phoneController = TextEditingController();
  final passController = TextEditingController();

  bool loading = false;
  bool _obscure = true;

  late AnimationController _enterCtrl;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  // ── Design tokens (consistent with app palette) ──────────────────────────
  static const _bg = Color(0xFF0A0E1A);
  static const _card = Color(0xFF131929);
  static const _accentBlue = Color(0xFF4F8EF7);
  static const _accentPurple = Color(0xFF7C5CFC);
  static const _accentTeal = Color(0xFF1ECBE1);
  static const _textSecondary = Color(0xFF7B8BAD);
  static const _border = Color(0xFF242E45);

  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeIn = CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOutCubic));
    _enterCtrl.forward();
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    phoneController.dispose();
    passController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    setState(() => loading = true);

    final success = await AuthService.loginUser(
      phoneController.text,
      passController.text,
    );

    setState(() => loading = false);

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text(
                "Login Failed ❌",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // ── Background glow blobs ────────────────────────────────────────
          Positioned(
            top: -size.height * 0.1,
            right: -size.width * 0.2,
            child: _GlowBlob(
              color: _accentBlue,
              size: size.width * 0.7,
              opacity: 0.10,
            ),
          ),
          Positioned(
            bottom: size.height * 0.1,
            left: -size.width * 0.2,
            child: _GlowBlob(
              color: _accentPurple,
              size: size.width * 0.65,
              opacity: 0.09,
            ),
          ),
          Positioned(
            top: size.height * 0.45,
            right: size.width * 0.1,
            child: _GlowBlob(
              color: _accentTeal,
              size: size.width * 0.35,
              opacity: 0.06,
            ),
          ),

          // ── Main content ─────────────────────────────────────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: FadeTransition(
                  opacity: _fadeIn,
                  child: SlideTransition(
                    position: _slideUp,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Top branding ────────────────────────────────────
                        Center(
                          child: Column(
                            children: [
                              // Logo badge
                              Container(
                                width: 68,
                                height: 68,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [_accentBlue, _accentPurple],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(22),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _accentBlue.withOpacity(0.35),
                                      blurRadius: 24,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.account_balance_wallet_rounded,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),

                              const SizedBox(height: 22),

                              // Title
                              ShaderMask(
                                shaderCallback: (bounds) =>
                                    const LinearGradient(
                                      colors: [_accentBlue, _accentPurple],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ).createShader(bounds),
                                child: const Text(
                                  "TrackPay Login",
                                  style: TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 8),

                              // Subtitle
                              const Text(
                                "Secure UPI Payments + Budget Tracking",
                                style: TextStyle(
                                  color: _textSecondary,
                                  fontSize: 13,
                                  letterSpacing: 0.2,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 40),

                        // ── Form card ────────────────────────────────────────
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: _card,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: _border),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Section label
                              const Text(
                                "SIGN IN",
                                style: TextStyle(
                                  color: _textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.4,
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Phone Input
                              _PremiumField(
                                controller: phoneController,
                                hint: "Phone Number",
                                icon: Icons.phone_rounded,
                                iconColor: _accentBlue,
                                keyboardType: TextInputType.phone,
                              ),

                              const SizedBox(height: 14),

                              // Password Input
                              _PremiumField(
                                controller: passController,
                                hint: "Password",
                                icon: Icons.lock_outline_rounded,
                                iconColor: _accentPurple,
                                obscureText: _obscure,
                                suffixIcon: GestureDetector(
                                  onTap: () =>
                                      setState(() => _obscure = !_obscure),
                                  child: Icon(
                                    _obscure
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: _textSecondary,
                                    size: 18,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 28),

                              // Login Button
                              _AnimatedGradientButton(
                                label: "Login",
                                loading: loading,
                                onPressed: loading ? null : login,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── Register link ─────────────────────────────────────
                        Center(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const RegisterScreen(),
                                ),
                              );
                            },
                            child: RichText(
                              text: const TextSpan(
                                text: "New user? ",
                                style: TextStyle(
                                  color: _textSecondary,
                                  fontSize: 14,
                                ),
                                children: [
                                  TextSpan(
                                    text: "Create Account →",
                                    style: TextStyle(
                                      color: _accentBlue,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // ── Trust badges ──────────────────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _TrustBadge(
                              icon: Icons.shield_outlined,
                              label: "256-bit SSL",
                            ),
                            const SizedBox(width: 20),
                            _TrustBadge(
                              icon: Icons.verified_user_outlined,
                              label: "UPI Secure",
                            ),
                            const SizedBox(width: 20),
                            _TrustBadge(
                              icon: Icons.lock_outlined,
                              label: "Encrypted",
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
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
// _PremiumField
// =============================================================================
class _PremiumField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final Color iconColor;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;

  const _PremiumField({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.iconColor,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
  });

  static const _surface = Color(0xFF1C2438);
  static const _border = Color(0xFF242E45);
  static const _textPrimary = Color(0xFFF0F4FF);
  static const _textSecondary = Color(0xFF7B8BAD);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscureText,
              keyboardType: keyboardType,
              style: const TextStyle(
                color: _textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: _textSecondary, fontSize: 13),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                suffixIcon: suffixIcon != null
                    ? Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: suffixIcon,
                      )
                    : null,
                suffixIconConstraints: const BoxConstraints(
                  minWidth: 0,
                  minHeight: 0,
                ),
              ),
              cursorColor: const Color(0xFF4F8EF7),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// _AnimatedGradientButton
// =============================================================================
class _AnimatedGradientButton extends StatefulWidget {
  final String label;
  final bool loading;
  final VoidCallback? onPressed;

  const _AnimatedGradientButton({
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  @override
  State<_AnimatedGradientButton> createState() =>
      _AnimatedGradientButtonState();
}

class _AnimatedGradientButtonState extends State<_AnimatedGradientButton>
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
        widget.onPressed?.call();
      },
      onTapCancel: () => _ctrl.forward(),
      child: ScaleTransition(
        scale: _ctrl,
        child: Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            gradient: widget.onPressed == null
                ? const LinearGradient(
                    colors: [Color(0xFF2A3050), Color(0xFF2A3050)],
                  )
                : const LinearGradient(
                    colors: [Color(0xFF4F8EF7), Color(0xFF7C5CFC)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: widget.onPressed == null
                ? []
                : [
                    BoxShadow(
                      color: const Color(0xFF4F8EF7).withOpacity(0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: Center(
            child: widget.loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    widget.label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// _TrustBadge — small security indicator
// =============================================================================
class _TrustBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TrustBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF3A4260), size: 18),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF3A4260),
            fontSize: 10,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// _GlowBlob — atmospheric background radial gradient
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
