import 'package:flutter/material.dart';

import '../models/bank.dart';
import '../services/bank_service.dart';

class BalanceScreen extends StatefulWidget {
  const BalanceScreen({super.key});

  @override
  State<BalanceScreen> createState() => _BalanceScreenState();
}

class _BalanceScreenState extends State<BalanceScreen>
    with TickerProviderStateMixin {
  List<BankModel> banks = [];
  bool loading = true;

  late AnimationController _headerController;
  late AnimationController _listController;
  late Animation<double> _headerFade;
  late Animation<double> _headerScale;

  // ── Design tokens (consistent with app palette) ─────────────────────────
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

  // Cycling accent colors for bank cards
  static const _cardAccents = [
    [Color(0xFF4F8EF7), Color(0xFF7C5CFC)],
    [Color(0xFF1ECBE1), Color(0xFF4F8EF7)],
    [Color(0xFF7C5CFC), Color(0xFFB06EF7)],
    [Color(0xFF22C55E), Color(0xFF1ECBE1)],
    [Color(0xFFF59E0B), Color(0xFFEF4444)],
  ];

  @override
  void initState() {
    super.initState();

    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _listController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _headerFade = CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOut,
    );
    _headerScale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOutBack),
    );

    loadBalances();
  }

  @override
  void dispose() {
    _headerController.dispose();
    _listController.dispose();
    super.dispose();
  }

  Future<void> loadBalances() async {
    final data = await BankService.fetchBanks(1);

    setState(() {
      banks = data;
      loading = false;
    });

    _headerController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _listController.forward();
    });
  }

  // Compute total balance across all banks
  double get _totalBalance => banks.fold(0.0, (sum, b) => sum + b.balance);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: _buildAppBar(),
      body: loading ? _buildLoader() : _buildBody(),
    );
  }

  // ── AppBar ───────────────────────────────────────────────────────────────

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
            "Bank Balance",
            style: TextStyle(
              color: _textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          Text(
            "Linked accounts overview",
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

  // ── Loader ───────────────────────────────────────────────────────────────

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
            "Fetching balances...",
            style: TextStyle(color: _textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ── Body ─────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      children: [
        // ── Total balance hero card ───────────────────────────────────────
        FadeTransition(
          opacity: _headerFade,
          child: ScaleTransition(scale: _headerScale, child: _buildTotalCard()),
        ),

        const SizedBox(height: 24),

        // ── Section label ─────────────────────────────────────────────────
        FadeTransition(
          opacity: _headerFade,
          child: const Text(
            "LINKED ACCOUNTS",
            style: TextStyle(
              color: _textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // ── Bank cards ────────────────────────────────────────────────────
        ...List.generate(banks.length, (index) {
          final bank = banks[index];
          final delay = index * 80;
          return _AnimatedBankCard(
            bank: bank,
            index: index,
            accentColors: _cardAccents[index % _cardAccents.length],
            parentController: _listController,
            delayMs: delay,
          );
        }),

        const SizedBox(height: 16),

        // ── Footer strip ──────────────────────────────────────────────────
        FadeTransition(
          opacity: _headerFade,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
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
        ),
      ],
    );
  }

  // ── Total balance card ───────────────────────────────────────────────────

  Widget _buildTotalCard() {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      "Total Balance",
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _accentBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "${banks.length} ${banks.length == 1 ? 'Account' : 'Accounts'}",
                  style: const TextStyle(
                    color: _accentBlue,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            "Net worth across banks",
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
              "₹${_totalBalance.toInt()}",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 38,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Animated bank card ────────────────────────────────────────────────────────

class _AnimatedBankCard extends StatefulWidget {
  final BankModel bank;
  final int index;
  final List<Color> accentColors;
  final AnimationController parentController;
  final int delayMs;

  const _AnimatedBankCard({
    required this.bank,
    required this.index,
    required this.accentColors,
    required this.parentController,
    required this.delayMs,
  });

  @override
  State<_AnimatedBankCard> createState() => _AnimatedBankCardState();
}

class _AnimatedBankCardState extends State<_AnimatedBankCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  static const _cardColor = Color(0xFF131929);
  static const _textPrimary = Color(0xFFF0F4FF);
  static const _textSecondary = Color(0xFF7B8BAD);
  static const _borderColor = Color(0xFF242E45);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    Future.delayed(Duration(milliseconds: widget.delayMs), () {
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
    final color1 = widget.accentColors[0];
    final color2 = widget.accentColors[1];
    final initial = widget.bank.bankName.isNotEmpty
        ? widget.bank.bankName[0]
        : "B";

    // Rough percentage share of total (visual only)
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
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                // Bank initial avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color1.withOpacity(0.25),
                        color2.withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: color1.withOpacity(0.25)),
                  ),
                  child: Center(
                    child: ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [color1, color2],
                      ).createShader(bounds),
                      child: Text(
                        initial,
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

                // Bank name + account type
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
                      const SizedBox(height: 3),
                      Text(
                        "Savings Account",
                        style: TextStyle(
                          color: _textSecondary.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // Balance with gradient
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [color1, color2],
                      ).createShader(bounds),
                      child: Text(
                        "₹${widget.bank.balance.toInt()}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: color1.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "Available",
                        style: TextStyle(
                          color: color1,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
