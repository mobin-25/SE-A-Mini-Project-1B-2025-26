import 'package:flutter/material.dart';

import '../models/bank.dart';
import '../services/bank_service.dart';
import 'bank_detail_screen.dart'; // ✅ NEW IMPORT

class BankScreen extends StatefulWidget {
  const BankScreen({super.key});

  @override
  State<BankScreen> createState() => _BankScreenState();
}

class _BankScreenState extends State<BankScreen> with TickerProviderStateMixin {
  List<BankModel> banks = [];
  bool loading = true;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // ── Design tokens ──────────────────────────────────────────────────────────
  static const _bgColor = Color(0xFF0A0E1A);
  static const _cardColor = Color(0xFF131929);
  static const _surfaceColor = Color(0xFF1C2438);
  static const _accentBlue = Color(0xFF4F8EF7);
  static const _accentPurple = Color(0xFF7C5CFC);
  static const _textPrimary = Color(0xFFF0F4FF);
  static const _textSecondary = Color(0xFF7B8BAD);
  static const _borderColor = Color(0xFF242E45);

  static const _gradientMain = LinearGradient(
    colors: [_accentBlue, _accentPurple],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const _cardAccents = [
    [Color(0xFF4F8EF7), Color(0xFF7C5CFC)],
    [Color(0xFF1ECBE1), Color(0xFF4F8EF7)],
    [Color(0xFF7C5CFC), Color(0xFFB06EF7)],
    [Color(0xFF22C55E), Color(0xFF1ECBE1)],
    [Color(0xFFF59E0B), Color(0xFFEF4444)],
  ];
  // ──────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    loadBanks();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> loadBanks() async {
    final userId = 1;
    final data = await BankService.fetchBanks(userId);
    setState(() {
      banks = data;
      loading = false;
    });
    _fadeController.forward(from: 0);
  }

  void showAddBankDialog() {
    TextEditingController nameController = TextEditingController();
    TextEditingController accController = TextEditingController();
    TextEditingController balController = TextEditingController();

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (_) {
        return Dialog(
          backgroundColor: _cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
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
                        color: _accentBlue.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.account_balance_outlined,
                        color: _accentBlue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Add Bank Account",
                          style: TextStyle(
                            color: _textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          "Link a new account",
                          style: TextStyle(color: _textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                _dialogField(
                  controller: nameController,
                  hint: "Bank Name (e.g. SBI)",
                  icon: Icons.business_outlined,
                ),
                const SizedBox(height: 12),
                _dialogField(
                  controller: accController,
                  hint: "Account Number",
                  icon: Icons.numbers_outlined,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                _dialogField(
                  controller: balController,
                  hint: "Initial Balance (₹)",
                  icon: Icons.currency_rupee_rounded,
                  keyboardType: TextInputType.number,
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
                        label: "Add Bank",
                        gradient: _gradientMain,
                        onPressed: () async {
                          await BankService.addBank(
                            userId: 1,
                            bankName: nameController.text,
                            accountNumber: accController.text,
                            balance: double.parse(balController.text),
                          );
                          Navigator.pop(context);
                          loadBanks();
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(_styledSnackBar("Bank Added ✅"));
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> deleteBank(int bankId) async {
    await BankService.deleteBank(bankId);
    loadBanks();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(_styledSnackBar("Bank Deleted 🗑"));
  }

  SnackBar _styledSnackBar(String message) {
    return SnackBar(
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
    );
  }

  Widget _dialogField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Icon(icon, color: _accentBlue, size: 18),
          ),
          Expanded(
            child: TextField(
              controller: controller,
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
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
              cursorColor: _accentBlue,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: _buildAppBar(),
      floatingActionButton: _buildFAB(),
      body: loading
          ? _buildLoader()
          : banks.isEmpty
          ? _buildEmptyState()
          : _buildList(),
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
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Bank Accounts",
            style: TextStyle(
              color: _textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          Text(
            "Manage linked accounts",
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
              Icons.account_balance_wallet_outlined,
              color: _accentBlue,
              size: 18,
            ),
          ),
        ),
      ],
    );
  }

  // ── FAB ────────────────────────────────────────────────────────────────────

  Widget _buildFAB() {
    return Container(
      decoration: BoxDecoration(
        gradient: _gradientMain,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _accentBlue.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: showAddBankDialog,
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
      ),
    );
  }

  // ── Loader ─────────────────────────────────────────────────────────────────

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
            "Loading accounts...",
            style: TextStyle(color: _textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ── Empty state ────────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _borderColor),
            ),
            child: const Icon(
              Icons.account_balance_outlined,
              color: _textSecondary,
              size: 36,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            "No bank accounts added yet",
            style: TextStyle(
              color: _textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Tap + to link your first account",
            style: TextStyle(
              color: _textSecondary.withOpacity(0.6),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ── List ───────────────────────────────────────────────────────────────────

  Widget _buildList() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        itemCount: banks.length,
        itemBuilder: (context, index) {
          final bank = banks[index];
          final colors = _cardAccents[index % _cardAccents.length];
          final color1 = colors[0];
          final color2 = colors[1];
          final initial = bank.bankName.isNotEmpty
              ? bank.bankName[0].toUpperCase()
              : "B";

          return _AnimatedBankTile(
            bank: bank,
            index: index,
            color1: color1,
            color2: color2,
            initial: initial,
            onTap: () async {
              final updated = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => BankDetailScreen(bank: bank)),
              );
              if (updated == true) {
                loadBanks();
                Navigator.pop(context, true);
              }
            },
            onDelete: () => deleteBank(bank.id),
          );
        },
      ),
    );
  }
}

// ── Animated bank tile ────────────────────────────────────────────────────────

class _AnimatedBankTile extends StatefulWidget {
  final BankModel bank;
  final int index;
  final Color color1;
  final Color color2;
  final String initial;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _AnimatedBankTile({
    required this.bank,
    required this.index,
    required this.color1,
    required this.color2,
    required this.initial,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<_AnimatedBankTile> createState() => _AnimatedBankTileState();
}

class _AnimatedBankTileState extends State<_AnimatedBankTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  static const _cardColor = Color(0xFF131929);
  static const _textPrimary = Color(0xFFF0F4FF);
  static const _textSecondary = Color(0xFF7B8BAD);
  static const _borderColor = Color(0xFF242E45);
  static const _accentRed = Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    Future.delayed(Duration(milliseconds: widget.index * 75), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
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
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(22),
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              splashColor: widget.color1.withOpacity(0.08),
              highlightColor: widget.color1.withOpacity(0.04),
              onTap: widget.onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    // Bank avatar
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            widget.color1.withOpacity(0.22),
                            widget.color2.withOpacity(0.10),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: widget.color1.withOpacity(0.25),
                        ),
                      ),
                      child: Center(
                        child: ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [widget.color1, widget.color2],
                          ).createShader(bounds),
                          child: Text(
                            widget.initial,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Bank info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.bank.bankName,
                            style: const TextStyle(
                              color: _textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: widget.color1.withOpacity(0.7),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "Acc: ${widget.bank.accountNumber}",
                                style: TextStyle(
                                  color: _textSecondary.withOpacity(0.8),
                                  fontSize: 12,
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Delete button
                    GestureDetector(
                      onTap: widget.onDelete,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _accentRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(
                            color: _accentRed.withOpacity(0.2),
                          ),
                        ),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          color: _accentRed,
                          size: 17,
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    // Chevron
                    Icon(
                      Icons.chevron_right_rounded,
                      color: _textSecondary.withOpacity(0.5),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
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
          height: 50,
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4F8EF7).withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Text(
              widget.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
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
