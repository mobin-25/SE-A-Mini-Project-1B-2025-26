import 'package:flutter/material.dart';
import '../models/bank.dart';
import '../services/bank_service.dart';
import 'dashboard_screen.dart';

class BankDetailScreen extends StatefulWidget {
  final BankModel bank;

  const BankDetailScreen({super.key, required this.bank});

  @override
  State<BankDetailScreen> createState() => _BankDetailScreenState();
}

class _BankDetailScreenState extends State<BankDetailScreen>
    with TickerProviderStateMixin {
  late double balance;

  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  // ── Design tokens ──────────────────────────────────────────────────────────
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

  static const _gradientGreen = LinearGradient(
    colors: [Color(0xFF22C55E), Color(0xFF1ECBE1)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  // ──────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    balance = widget.bank.balance;

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _scaleAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack),
    );

    _fadeController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void showAddMoneyDialog() {
    TextEditingController amountController = TextEditingController();

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
              // Header
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _accentGreen.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.add_circle_outline_rounded,
                      color: _accentGreen,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Add Money",
                        style: TextStyle(
                          color: _textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        "Top up your account",
                        style: TextStyle(color: _textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Amount input
              Container(
                decoration: BoxDecoration(
                  color: _surfaceColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _borderColor),
                ),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: ShaderMask(
                        shaderCallback: (bounds) =>
                            _gradientGreen.createShader(bounds),
                        child: const Text(
                          "₹",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          color: _textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: const InputDecoration(
                          hintText: "Enter amount",
                          hintStyle: TextStyle(
                            color: _textSecondary,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 16),
                        ),
                        cursorColor: _accentGreen,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Buttons
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
                      label: "Add",
                      gradient: _gradientGreen,
                      glowColor: _accentGreen,
                      onPressed: () async {
                        double? amount = double.tryParse(amountController.text);

                        if (amount == null || amount <= 0) return;

                        await BankService.depositMoney(
                          1, // user_id
                          widget.bank.id,
                          amount,
                        );

                        // ✅ Close dialog
                        Navigator.pop(context);

                        // ✅ Go back directly to Dashboard
                        Navigator.popUntil(context, (route) => route.isFirst);

                        // ✅ Send refresh signal to Dashboard
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DashboardScreen(),
                          ),
                        );
                      },
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

  @override
  Widget build(BuildContext context) {
    final initial = widget.bank.bankName.isNotEmpty
        ? widget.bank.bankName[0].toUpperCase()
        : "B";

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            children: [
              // ── Balance hero card ─────────────────────────────────────────
              ScaleTransition(
                scale: _scaleAnimation,
                child: _buildBalanceCard(initial),
              ),

              const SizedBox(height: 24),

              // ── Account info card ─────────────────────────────────────────
              _buildInfoCard(),

              const SizedBox(height: 24),

              // ── Add Money button ──────────────────────────────────────────
              _GradientButton(
                label: "Add Money",
                gradient: _gradientGreen,
                glowColor: _accentGreen,
                height: 58,
                fontSize: 16,
                icon: Icons.add_circle_outline_rounded,
                onPressed: showAddMoneyDialog,
              ),

              const SizedBox(height: 16),

              // ── Security footer ───────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: _surfaceColor.withOpacity(0.4),
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
            ],
          ),
        ),
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────

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
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.bank.bankName,
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const Text(
            "Account Details",
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
              Icons.account_balance_outlined,
              color: _accentBlue,
              size: 18,
            ),
          ),
        ),
      ],
    );
  }

  // ── Balance hero card ──────────────────────────────────────────────────────

  Widget _buildBalanceCard(String initial) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
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
          // Top row: avatar + status pill
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _accentBlue.withOpacity(0.22),
                      _accentPurple.withOpacity(0.12),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _accentBlue.withOpacity(0.25)),
                ),
                child: Center(
                  child: ShaderMask(
                    shaderCallback: (bounds) =>
                        _gradientMain.createShader(bounds),
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.bank.bankName,
                      style: const TextStyle(
                        color: _textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "Acc: ${widget.bank.accountNumber}",
                      style: const TextStyle(
                        color: _textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _accentGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
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
                    const SizedBox(width: 5),
                    const Text(
                      "Active",
                      style: TextStyle(
                        color: _accentGreen,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Balance label + amount
          const Text(
            "Available Balance",
            style: TextStyle(
              color: _textSecondary,
              fontSize: 13,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 6),
          ShaderMask(
            shaderCallback: (bounds) => _gradientMain.createShader(bounds),
            child: Text(
              "₹${balance.toInt()}",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Account info card ──────────────────────────────────────────────────────

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _infoRow(
            icon: Icons.person_outline_rounded,
            label: "Account Holder",
            value: "User Account",
            iconColor: _accentBlue,
          ),
          _rowDivider(),
          _infoRow(
            icon: Icons.numbers_outlined,
            label: "Account Number",
            value: widget.bank.accountNumber,
            iconColor: _accentPurple,
          ),
          _rowDivider(),
          _infoRow(
            icon: Icons.business_outlined,
            label: "Bank Name",
            value: widget.bank.bankName,
            iconColor: _accentTeal,
          ),
          _rowDivider(),
          _infoRow(
            icon: Icons.savings_outlined,
            label: "Account Type",
            value: "Savings Account",
            iconColor: _accentGreen,
          ),
        ],
      ),
    );
  }

  Widget _rowDivider() => Container(
    height: 1,
    margin: const EdgeInsets.symmetric(vertical: 12),
    color: _borderColor,
  );

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: iconColor, size: 17),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
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
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
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
  final Color glowColor;
  final double height;
  final double fontSize;
  final IconData? icon;

  const _GradientButton({
    required this.label,
    required this.onPressed,
    required this.gradient,
    required this.glowColor,
    this.height = 50,
    this.fontSize = 14,
    this.icon,
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
          width: double.infinity,
          height: widget.height,
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withOpacity(0.32),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: widget.fontSize,
                  fontWeight: FontWeight.w700,
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
