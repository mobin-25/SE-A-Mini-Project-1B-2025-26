import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../services/category_service.dart';
import '../services/budget_service.dart';
import '../services/category_detail_service.dart';

class CategoryDetailScreen extends StatefulWidget {
  final CategoryModel category;

  const CategoryDetailScreen({super.key, required this.category});

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen>
    with TickerProviderStateMixin {
  bool changed = false;
  late CategoryModel cat;
  List<TransactionModel> transactions = [];
  bool loading = true;

  late AnimationController _fadeController;
  late AnimationController _progressController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _progressAnimation;

  // ── Design tokens ──────────────────────────────────────────────────────────
  static const _bgColor = Color(0xFF0A0E1A);
  static const _cardColor = Color(0xFF131929);
  static const _surfaceColor = Color(0xFF1C2438);
  static const _accentBlue = Color(0xFF4F8EF7);
  static const _accentPurple = Color(0xFF7C5CFC);
  static const _accentTeal = Color(0xFF1ECBE1);
  static const _accentGreen = Color(0xFF22C55E);
  static const _accentOrange = Color(0xFFFFA726);
  static const _textPrimary = Color(0xFFF0F4FF);
  static const _textSecondary = Color(0xFF7B8BAD);
  static const _borderColor = Color(0xFF242E45);

  static const _gradientMain = LinearGradient(
    colors: [_accentBlue, _accentPurple],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  // ──────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    cat = widget.category;

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOut,
    );

    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _progressController.forward();
    });

    loadTransactions();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  Future<void> loadTransactions() async {
    final txns = await CategoryService.fetchCategoryTransactions(cat.id);
    setState(() {
      transactions = txns;
      loading = false;
    });
  }

  Future<void> refreshCategory() async {
    final updated = await CategoryDetailService.fetchCategoryDetail(cat.id);
    setState(() {
      cat = updated;
    });
    // Re-animate progress bar on refresh
    _progressController.forward(from: 0);
  }

  // ── Emoji Picker ───────────────────────────────────────────────────────────

  void showEmojiPicker() {
    TextEditingController emojiController = TextEditingController(
      text: cat.icon,
    );

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
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _accentPurple.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.emoji_emotions_outlined,
                      color: _accentPurple,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Change Emoji",
                        style: TextStyle(
                          color: _textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        "Pick a new category icon",
                        style: TextStyle(color: _textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Container(
                decoration: BoxDecoration(
                  color: _surfaceColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _borderColor),
                ),
                child: Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14),
                      child: Icon(
                        Icons.tag_faces_outlined,
                        color: _accentPurple,
                        size: 18,
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: emojiController,
                        autofocus: true,
                        maxLength: 2,
                        style: const TextStyle(
                          color: _textPrimary,
                          fontSize: 22,
                        ),
                        decoration: const InputDecoration(
                          hintText: "Enter Emoji",
                          hintStyle: TextStyle(
                            color: _textSecondary,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          counterText: "",
                          contentPadding: EdgeInsets.symmetric(vertical: 14),
                        ),
                        cursorColor: _accentPurple,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
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
                      label: "Save",
                      gradient: const LinearGradient(
                        colors: [_accentPurple, _accentBlue],
                      ),
                      glowColor: _accentPurple,
                      onPressed: () async {
                        final newEmoji = emojiController.text;
                        await CategoryService.updateCategoryEmoji(
                          cat.id,
                          newEmoji,
                        );
                        await refreshCategory();
                        changed = true;
                        Navigator.pop(context);
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

  // ── Update Budget Dialog ───────────────────────────────────────────────────

  void _showUpdateBudgetDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) {
        TextEditingController controller = TextEditingController();
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
                        Icons.edit_outlined,
                        color: _accentBlue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Update Budget",
                          style: TextStyle(
                            color: _textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          "Set a new budget limit",
                          style: TextStyle(color: _textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 22),
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
                              _gradientMain.createShader(bounds),
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
                          controller: controller,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            color: _textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: const InputDecoration(
                            hintText: "Enter new total budget",
                            hintStyle: TextStyle(
                              color: _textSecondary,
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 16),
                          ),
                          cursorColor: _accentBlue,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
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
                        label: "Update",
                        gradient: _gradientMain,
                        glowColor: _accentBlue,
                        onPressed: () async {
                          final newBudget = double.parse(controller.text);
                          await BudgetService.updateCategoryBudget(
                            cat.id,
                            newBudget,
                          );
                          await refreshCategory();
                          changed = true;
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            _styledSnackBar("Budget Updated Successfully ✨"),
                          );
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

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Determine progress bar color based on usage
    Color progressColor;
    if (cat.usedPercent >= 90) {
      progressColor = const Color(0xFFEF4444);
    } else if (cat.usedPercent >= 70) {
      progressColor = _accentOrange;
    } else {
      progressColor = _accentGreen;
    }

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, changed);
        return false;
      },
      child: Scaffold(
        backgroundColor: _bgColor,
        appBar: _buildAppBar(),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Budget Card ─────────────────────────────────────────────
                _buildBudgetCard(progressColor),

                const SizedBox(height: 24),

                // ── Section label ───────────────────────────────────────────
                const Text(
                  "TRANSACTIONS",
                  style: TextStyle(
                    color: _textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),

                const SizedBox(height: 12),

                // ── Transaction list ────────────────────────────────────────
                Expanded(child: _buildTransactionList()),
              ],
            ),
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
      leading: Padding(
        padding: const EdgeInsets.all(10),
        child: GestureDetector(
          onTap: () => Navigator.pop(context, changed),
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
      title: Row(
        children: [
          GestureDetector(
            onTap: showEmojiPicker,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _accentPurple.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _accentPurple.withOpacity(0.2)),
              ),
              child: Center(
                child: Text(cat.icon, style: const TextStyle(fontSize: 20)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cat.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const Text(
                  "Category Details",
                  style: TextStyle(
                    color: _textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Budget Card ────────────────────────────────────────────────────────────

  Widget _buildBudgetCard(Color progressColor) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A2340), Color(0xFF1E1535)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: _accentBlue.withOpacity(0.08),
            blurRadius: 28,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: total budget pill + used percent badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _accentTeal.withOpacity(0.1),
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
                    Text(
                      "Budget  ₹${cat.totalBudget.toInt()}",
                      style: const TextStyle(
                        color: _accentTeal,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
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
                  color: progressColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: progressColor.withOpacity(0.25)),
                ),
                child: Text(
                  "${cat.usedPercent}% used",
                  style: TextStyle(
                    color: progressColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Remaining amount
          const Text(
            "Remaining Balance",
            style: TextStyle(
              color: _textSecondary,
              fontSize: 13,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 5),
          ShaderMask(
            shaderCallback: (bounds) => _gradientMain.createShader(bounds),
            child: Text(
              "₹${cat.remainingBudget.toInt()}",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.2,
              ),
            ),
          ),

          const SizedBox(height: 18),

          // Animated progress bar
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (_, __) {
              final value = (cat.usedPercent / 100) * _progressAnimation.value;
              return Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: value,
                      minHeight: 8,
                      backgroundColor: _borderColor,
                      valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "₹0",
                        style: TextStyle(
                          color: _textSecondary.withOpacity(0.6),
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        "₹${cat.totalBudget.toInt()}",
                        style: TextStyle(
                          color: _textSecondary.withOpacity(0.6),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 18),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: _GradientButton(
                  label: "Reset Month",
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1C2438), Color(0xFF242E45)],
                  ),
                  glowColor: Colors.transparent,
                  borderColor: _borderColor,
                  textColor: _textPrimary,
                  onPressed: () async {
                    await BudgetService.resetAllBudgets(1);
                    await refreshCategory();
                    changed = true;
                    ScaffoldMessenger.of(context).showSnackBar(
                      _styledSnackBar("Monthly Budgets Reset Successfully ✅"),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _GradientButton(
                  label: "Update Budget",
                  gradient: _gradientMain,
                  glowColor: _accentBlue,
                  onPressed: _showUpdateBudgetDialog,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Transaction List ───────────────────────────────────────────────────────

  Widget _buildTransactionList() {
    if (loading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _borderColor),
              ),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(_accentBlue),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              "Loading transactions...",
              style: TextStyle(color: _textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: _borderColor),
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                color: _textSecondary,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "No transactions yet",
              style: TextStyle(
                color: _textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Transactions in this category will appear here",
              style: TextStyle(
                color: _textSecondary.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final txn = transactions[index];
        final initial = txn.receiverName.isNotEmpty
            ? txn.receiverName[0].toUpperCase()
            : "?";

        return _AnimatedTxnTile(txn: txn, initial: initial, index: index);
      },
    );
  }
}

// ── Animated transaction tile ─────────────────────────────────────────────────

class _AnimatedTxnTile extends StatefulWidget {
  final TransactionModel txn;
  final String initial;
  final int index;

  const _AnimatedTxnTile({
    required this.txn,
    required this.initial,
    required this.index,
  });

  @override
  State<_AnimatedTxnTile> createState() => _AnimatedTxnTileState();
}

class _AnimatedTxnTileState extends State<_AnimatedTxnTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  static const _cardColor = Color(0xFF131929);
  static const _textPrimary = Color(0xFFF0F4FF);
  static const _textSecondary = Color(0xFF7B8BAD);
  static const _borderColor = Color(0xFF242E45);
  static const _accentBlue = Color(0xFF4F8EF7);
  static const _accentRed = Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    Future.delayed(Duration(milliseconds: widget.index * 60), () {
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
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _accentBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: _accentBlue.withOpacity(0.2)),
                ),
                child: Center(
                  child: ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [_accentBlue, Color(0xFF7C5CFC)],
                    ).createShader(bounds),
                    child: Text(
                      widget.initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 14),

              // Name + label
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.txn.receiverName,
                      style: const TextStyle(
                        color: _textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "Payment sent",
                      style: TextStyle(
                        color: _textSecondary.withOpacity(0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              // Amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "- ₹${widget.txn.amount}",
                    style: const TextStyle(
                      color: _accentRed,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _accentRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      "Debit",
                      style: TextStyle(
                        color: _accentRed,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
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
}

// ── Reusable gradient button ──────────────────────────────────────────────────

class _GradientButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final Gradient gradient;
  final Color glowColor;
  final Color? textColor;
  final Color? borderColor;

  const _GradientButton({
    required this.label,
    required this.onPressed,
    required this.gradient,
    required this.glowColor,
    this.textColor,
    this.borderColor,
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
          height: 48,
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(14),
            border: widget.borderColor != null
                ? Border.all(color: widget.borderColor!)
                : null,
            boxShadow: widget.glowColor != Colors.transparent
                ? [
                    BoxShadow(
                      color: widget.glowColor.withOpacity(0.28),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              widget.label,
              style: TextStyle(
                color: widget.textColor ?? Colors.white,
                fontSize: 13,
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
