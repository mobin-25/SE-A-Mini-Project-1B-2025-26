import 'package:flutter/material.dart';

import '../models/bank.dart';
import '../models/category.dart';

import '../services/bank_service.dart';
import '../services/dashboard_service.dart';
import '../services/payment_service.dart';
import 'payment_success_screen.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with TickerProviderStateMixin {
  final receiverController = TextEditingController();
  final amountController = TextEditingController();
  final pinController = TextEditingController();

  List<BankModel> banks = [];
  List<CategoryModel> categories = [];

  BankModel? selectedBank;
  CategoryModel? selectedCategory;

  bool loading = true;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // ── Design tokens ──────────────────────────────────────────────────────────
  static const _bgColor = Color(0xFF0A0E1A);
  static const _cardColor = Color(0xFF131929);
  static const _surfaceColor = Color(0xFF1C2438);
  static const _accentBlue = Color(0xFF4F8EF7);
  static const _accentPurple = Color(0xFF7C5CFC);
  static const _accentTeal = Color(0xFF1ECBE1);
  static const _textPrimary = Color(0xFFF0F4FF);
  static const _textSecondary = Color(0xFF7B8BAD);
  static const _borderColor = Color(0xFF242E45);

  static const _gradientMain = LinearGradient(
    colors: [_accentBlue, _accentPurple],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // ───────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    loadData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    receiverController.dispose();
    amountController.dispose();
    pinController.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    const userId = 1;

    banks = await BankService.fetchBanks(userId);
    categories = await DashboardService.fetchCategories(userId);

    setState(() {
      loading = false;
    });

    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> payNow({bool override = false}) async {
    if (selectedBank == null || selectedCategory == null) {
      _showStyledSnackBar("Please select a bank and category");
      return;
    }

    final result = await PaymentService.makePayment(
      userId: 1,
      bankId: selectedBank!.id,
      categoryId: selectedCategory!.id,
      receiver: receiverController.text,
      amount: double.parse(amountController.text),
      pin: pinController.text,
      override: override,
    );

    // Budget Exceeded Alert
    if (result["error"] == true &&
        result["message"].contains("Override required")) {
      showOverrideDialog();
      return;
    }

    // Payment Success
    if (result["error"] != true) {
      final resultDone = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentSuccessScreen(
            amount: double.parse(amountController.text),
            receiver: receiverController.text,
            categoryId: selectedCategory!.id,
            category: selectedCategory!.name,
          ),
        ),
      );

      // ✅ When Done clicked
      if (resultDone == true) {
        Navigator.pop(context, true);
      }
    } else {
      _showStyledSnackBar(result["message"]);
    }
  }

  void _showStyledSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: _textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: _surfaceColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  void showOverrideDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (_) => Dialog(
        backgroundColor: _cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon badge
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFA726).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFFFA726),
                  size: 28,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                "Budget Exceeded",
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "This payment exceeds your category budget. Do you want to override and continue?",
                style: TextStyle(
                  color: _textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: _borderColor),
                        ),
                      ),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(
                          color: _textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _GradientButton(
                      label: "Override",
                      onPressed: () {
                        Navigator.pop(context);
                        payNow(override: true);
                      },
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFA726), Color(0xFFFF6B35)],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: _buildAppBar(),
      body: loading ? _buildLoader() : _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _bgColor,
      elevation: 0,
      centerTitle: false,
      leading: Padding(
        padding: const EdgeInsets.all(10),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            decoration: BoxDecoration(
              color: _surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _borderColor),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: _textPrimary,
              size: 16,
            ),
          ),
        ),
      ),
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Make Payment",
            style: TextStyle(
              color: _textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          Text(
            "Secure UPI Transfer",
            style: TextStyle(
              color: _textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _accentBlue.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              color: _accentBlue,
              size: 18,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoader() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _borderColor),
            ),
            child: const Padding(
              padding: EdgeInsets.all(18),
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(_accentBlue),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Loading...",
            style: TextStyle(color: _textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Amount hero card ────────────────────────────────────────
              _buildAmountCard(),
              const SizedBox(height: 24),

              // ── Section: Transfer Details ───────────────────────────────
              _sectionLabel("Transfer Details"),
              const SizedBox(height: 12),
              _buildGlassCard(
                child: Column(
                  children: [
                    _buildPremiumField(
                      controller: receiverController,
                      label: "Receiver Name",
                      icon: Icons.person_outline_rounded,
                    ),
                    _divider(),
                    _buildPremiumField(
                      controller: amountController,
                      label: "Amount (₹)",
                      icon: Icons.currency_rupee_rounded,
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Section: Payment Method ─────────────────────────────────
              _sectionLabel("Payment Method"),
              const SizedBox(height: 12),
              _buildGlassCard(
                child: Column(
                  children: [
                    _buildDropdownField<BankModel>(
                      value: selectedBank,
                      hint: "Select Bank Account",
                      icon: Icons.account_balance_outlined,
                      items: banks
                          .map(
                            (b) => DropdownMenuItem<BankModel>(
                              value: b,
                              child: Text(
                                "${b.bankName}  •  ₹${b.balance.toInt()}",
                                style: const TextStyle(
                                  color: _textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedBank = value as BankModel;
                        });
                      },
                    ),
                    _divider(),
                    _buildDropdownField<CategoryModel>(
                      value: selectedCategory,
                      hint: "Select Category",
                      icon: Icons.grid_view_rounded,
                      items: categories
                          .map(
                            (c) => DropdownMenuItem<CategoryModel>(
                              value: c,
                              child: Text(
                                "${c.icon}  ${c.name}",
                                style: const TextStyle(
                                  color: _textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedCategory = value;
                        });
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Section: Security ───────────────────────────────────────
              _sectionLabel("Security"),
              const SizedBox(height: 12),
              _buildGlassCard(
                child: _buildPremiumField(
                  controller: pinController,
                  label: "UPI PIN",
                  icon: Icons.pin_outlined,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                ),
              ),

              const SizedBox(height: 32),

              // ── Pay Button ──────────────────────────────────────────────
              _GradientButton(
                label: "Pay Now",
                onPressed: () => payNow(),
                gradient: _gradientMain,
                height: 58,
                fontSize: 16,
                icon: Icons.arrow_forward_rounded,
              ),

              const SizedBox(height: 16),

              // ── Footer trust row ────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.verified_user_outlined,
                    color: _accentTeal,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "256-bit encrypted · RBI regulated",
                    style: TextStyle(
                      color: _textSecondary.withOpacity(0.7),
                      fontSize: 11,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Amount hero card ────────────────────────────────────────────────────────

  Widget _buildAmountCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A2340), Color(0xFF1E1535)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: _accentBlue.withOpacity(0.08),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _accentTeal.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: _accentTeal,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      "Instant Transfer",
                      style: TextStyle(
                        color: _accentTeal,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  _dot(_accentBlue),
                  const SizedBox(width: 4),
                  _dot(_accentPurple),
                  const SizedBox(width: 4),
                  _dot(_accentTeal),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            "You're sending",
            style: TextStyle(
              color: _textSecondary,
              fontSize: 13,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 6),
          ShaderMask(
            shaderCallback: (bounds) => _gradientMain.createShader(bounds),
            child: const Text(
              "₹ — — —",
              style: TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Enter details below to continue",
            style: TextStyle(color: _textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _dot(Color color) => Container(
    width: 8,
    height: 8,
    decoration: BoxDecoration(
      color: color.withOpacity(0.5),
      shape: BoxShape.circle,
    ),
  );

  // ── Helpers ─────────────────────────────────────────────────────────────────

  Widget _sectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        color: _textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(22), child: child),
    );
  }

  Widget _divider() => Container(
    height: 1,
    margin: const EdgeInsets.symmetric(horizontal: 18),
    color: _borderColor,
  );

  Widget _buildPremiumField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _accentBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _accentBlue, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscureText,
              keyboardType: keyboardType,
              style: const TextStyle(
                color: _textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: const TextStyle(
                  color: _textSecondary,
                  fontSize: 13,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
              cursorColor: _accentBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required T? value,
    required String hint,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _accentPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _accentPurple, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                hint: Text(
                  hint,
                  style: const TextStyle(color: _textSecondary, fontSize: 13),
                ),
                items: items,
                onChanged: onChanged,
                dropdownColor: _surfaceColor,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: _textSecondary,
                ),
                style: const TextStyle(color: _textPrimary, fontSize: 14),
                isExpanded: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable gradient button ────────────────────────────────────────────────

class _GradientButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final Gradient gradient;
  final double height;
  final double fontSize;
  final IconData? icon;

  const _GradientButton({
    required this.label,
    required this.onPressed,
    required this.gradient,
    this.height = 52,
    this.fontSize = 14,
    this.icon,
  });

  @override
  State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.96,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnim = _controller;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.reverse(),
      onTapUp: (_) {
        _controller.forward();
        widget.onPressed();
      },
      onTapCancel: () => _controller.forward(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          width: double.infinity,
          height: widget.height,
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4F8EF7).withOpacity(0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: widget.fontSize,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              if (widget.icon != null) ...[
                const SizedBox(width: 8),
                Icon(widget.icon, color: Colors.white, size: 18),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
