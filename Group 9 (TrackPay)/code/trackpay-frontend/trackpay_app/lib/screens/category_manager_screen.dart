import 'package:flutter/material.dart';
import '../models/category.dart';
import '../services/category_service.dart';

// =============================================================================
// Shared design tokens — single source of truth for all widgets
// =============================================================================
abstract class _T {
  static const bgColor = Color(0xFF0A0E1A);
  static const cardColor = Color(0xFF131929);
  static const surfaceColor = Color(0xFF1C2438);
  static const accentBlue = Color(0xFF4F8EF7);
  static const accentPurple = Color(0xFF7C5CFC);
  static const accentTeal = Color(0xFF1ECBE1);
  static const accentGreen = Color(0xFF22C55E);
  static const accentRed = Color(0xFFEF4444);
  static const textPrimary = Color(0xFFF0F4FF);
  static const textSecondary = Color(0xFF7B8BAD);
  static const borderColor = Color(0xFF242E45);

  static const gradientMain = LinearGradient(
    colors: [accentBlue, accentPurple],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const List<List<Color>> cardAccents = [
    [Color(0xFF4F8EF7), Color(0xFF7C5CFC)],
    [Color(0xFF1ECBE1), Color(0xFF4F8EF7)],
    [Color(0xFF7C5CFC), Color(0xFFB06EF7)],
    [Color(0xFF22C55E), Color(0xFF1ECBE1)],
    [Color(0xFFF59E0B), Color(0xFFEF4444)],
  ];
}

// =============================================================================
// CategoryManagerScreen
// =============================================================================
class CategoryManagerScreen extends StatefulWidget {
  const CategoryManagerScreen({super.key});

  @override
  State<CategoryManagerScreen> createState() => _CategoryManagerScreenState();
}

class _CategoryManagerScreenState extends State<CategoryManagerScreen>
    with TickerProviderStateMixin {
  List<CategoryModel> categories = [];
  bool loading = true;

  final nameController = TextEditingController();
  final budgetController = TextEditingController();
  final emojiController = TextEditingController(text: "📁");

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

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
    loadCategories();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    nameController.dispose();
    budgetController.dispose();
    emojiController.dispose();
    super.dispose();
  }

  // ✅ Load categories
  Future<void> loadCategories() async {
    setState(() => loading = true);
    categories = await CategoryService.fetchCategories(1);
    setState(() => loading = false);
    _fadeController.forward(from: 0);
  }

  // ✅ Delete category
  Future<void> deleteCategory(int id) async {
    await CategoryService.deleteCategory(id);
    Navigator.pop(context, true);
  }

  // ✅ Create category
  Future<void> createCategory() async {
    final name = nameController.text.trim();
    final budget = double.tryParse(budgetController.text.trim());
    final emoji = emojiController.text.trim();

    if (name.isEmpty || budget == null) return;

    await CategoryService.createCategory(
      userId: 1,
      name: name,
      budget: budget,
      icon: emoji.isEmpty ? "📁" : emoji,
    );

    nameController.clear();
    budgetController.clear();
    emojiController.text = "📁";

    Navigator.pop(context);
    Navigator.pop(context, true);
  }

  // ✅ Show dialog
  void showCreateDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (_) => Dialog(
        backgroundColor: _T.cardColor,
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
                      color: _T.accentPurple.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: _T.accentPurple.withOpacity(0.2),
                      ),
                    ),
                    child: const Icon(
                      Icons.create_new_folder_outlined,
                      color: _T.accentPurple,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Add New Category",
                        style: TextStyle(
                          color: _T.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        "Create a budget folder",
                        style: TextStyle(color: _T.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),

              _dialogField(
                controller: nameController,
                hint: "Category Name",
                icon: Icons.label_outline_rounded,
                iconColor: _T.accentBlue,
              ),
              const SizedBox(height: 12),
              _dialogField(
                controller: budgetController,
                hint: "Total Budget (₹)",
                icon: Icons.currency_rupee_rounded,
                iconColor: _T.accentGreen,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              _dialogField(
                controller: emojiController,
                hint: "Emoji Icon",
                icon: Icons.emoji_emotions_outlined,
                iconColor: _T.accentPurple,
                maxLength: 2,
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
                          side: const BorderSide(color: _T.borderColor),
                        ),
                      ),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(
                          color: _T.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _GradientButton(
                      label: "Create",
                      gradient: _T.gradientMain,
                      glowColor: _T.accentBlue,
                      onPressed: createCategory,
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

  Widget _dialogField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color iconColor,
    TextInputType? keyboardType,
    int? maxLength,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _T.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _T.borderColor),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              maxLength: maxLength,
              style: const TextStyle(
                color: _T.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(
                  color: _T.textSecondary,
                  fontSize: 13,
                ),
                border: InputBorder.none,
                counterText: "",
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
              cursorColor: _T.accentBlue,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.bgColor,
      appBar: _buildAppBar(),
      body: loading ? _buildLoader() : _buildBody(),
    );
  }

  // ── AppBar ──────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _T.bgColor,
      elevation: 0,
      centerTitle: false,
      leading: Padding(
        padding: const EdgeInsets.all(10),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            decoration: BoxDecoration(
              color: _T.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _T.borderColor),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: _T.textPrimary,
              size: 16,
            ),
          ),
        ),
      ),
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Manage Categories",
            style: TextStyle(
              color: _T.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          Text(
            "Budget folders",
            style: TextStyle(
              color: _T.textSecondary,
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
              color: _T.accentPurple.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _T.accentPurple.withOpacity(0.18)),
            ),
            child: const Icon(
              Icons.folder_outlined,
              color: _T.accentPurple,
              size: 18,
            ),
          ),
        ),
      ],
    );
  }

  // ── Loader ──────────────────────────────────────────────────────────────────
  Widget _buildLoader() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _T.cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _T.borderColor),
            ),
            child: const Padding(
              padding: EdgeInsets.all(18),
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(_T.accentBlue),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Loading categories...",
            style: TextStyle(color: _T.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ── Body ────────────────────────────────────────────────────────────────────
  Widget _buildBody() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: _buildSummaryStrip(),
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "YOUR CATEGORIES",
                style: TextStyle(
                  color: _T.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: categories.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      final colors =
                          _T.cardAccents[index % _T.cardAccents.length];
                      return _AnimatedCategoryTile(
                        cat: cat,
                        index: index,
                        color1: colors[0],
                        color2: colors[1],
                        onDelete: () => deleteCategory(cat.id),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            child: _GradientButton(
              label: "Add Category",
              gradient: _T.gradientMain,
              glowColor: _T.accentBlue,
              height: 58,
              fontSize: 16,
              icon: Icons.add_rounded,
              onPressed: showCreateDialog,
            ),
          ),
        ],
      ),
    );
  }

  // ── Summary strip ───────────────────────────────────────────────────────────
  Widget _buildSummaryStrip() {
    final totalRemaining = categories.fold<double>(
      0,
      (sum, c) => sum + c.remainingBudget,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A2340), Color(0xFF1E1535)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _T.borderColor),
        boxShadow: [
          BoxShadow(
            color: _T.accentBlue.withOpacity(0.07),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _summaryCell(
              label: "Remaining",
              value: "₹${totalRemaining.toInt()}",
              color: _T.accentGreen,
              icon: Icons.savings_outlined,
            ),
          ),
          Container(width: 1, height: 40, color: _T.borderColor),
          Expanded(
            child: _summaryCell(
              label: "Categories",
              value: "${categories.length}",
              color: _T.accentPurple,
              icon: Icons.folder_outlined,
            ),
          ),
          Container(width: 1, height: 40, color: _T.borderColor),
          Expanded(
            child: _summaryCell(
              label: "Status",
              value: categories.isNotEmpty ? "Active" : "Empty",
              color: _T.accentTeal,
              icon: Icons.check_circle_outline_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCell({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: _T.textSecondary,
            fontSize: 10,
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }

  // ── Empty state ─────────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _T.cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _T.borderColor),
              ),
              child: const Icon(
                Icons.folder_open_outlined,
                color: _T.textSecondary,
                size: 36,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              "No categories yet",
              style: TextStyle(
                color: _T.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Tap Add Category to create your first budget folder",
              style: TextStyle(color: Color(0x997B8BAD), fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// _AnimatedCategoryTile
// =============================================================================
class _AnimatedCategoryTile extends StatefulWidget {
  final CategoryModel cat;
  final int index;
  final Color color1;
  final Color color2;
  final VoidCallback onDelete;

  const _AnimatedCategoryTile({
    required this.cat,
    required this.index,
    required this.color1,
    required this.color2,
    required this.onDelete,
  });

  @override
  State<_AnimatedCategoryTile> createState() => _AnimatedCategoryTileState();
}

class _AnimatedCategoryTileState extends State<_AnimatedCategoryTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    Future.delayed(Duration(milliseconds: widget.index * 70), () {
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
    // Progress bar — uses only remainingBudget (guaranteed on CategoryModel).
    // To use totalBudget if available, replace with:
    //   final usedFraction =
    //       (1 - widget.cat.remainingBudget / widget.cat.totalBudget).clamp(0.0, 1.0);
    final remaining = widget.cat.remainingBudget;
    final usedFraction = remaining <= 0 ? 1.0 : 0.0;

    final Color barColor;
    if (usedFraction >= 0.9) {
      barColor = _T.accentRed;
    } else if (usedFraction >= 0.7) {
      barColor = const Color(0xFFFFA726);
    } else {
      barColor = _T.accentGreen;
    }

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: _T.cardColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _T.borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.14),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    // Emoji avatar
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            widget.color1.withOpacity(0.2),
                            widget.color2.withOpacity(0.08),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: widget.color1.withOpacity(0.22),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          widget.cat.icon,
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                    ),

                    const SizedBox(width: 14),

                    // Name + remaining
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.cat.name,
                            style: const TextStyle(
                              color: _T.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: barColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "₹${remaining.toInt()} remaining",
                                style: TextStyle(
                                  color: barColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
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
                          color: _T.accentRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(
                            color: _T.accentRed.withOpacity(0.2),
                          ),
                        ),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          color: _T.accentRed,
                          size: 17,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: usedFraction,
                    minHeight: 5,
                    backgroundColor: _T.borderColor,
                    valueColor: AlwaysStoppedAnimation<Color>(barColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// _GradientButton — reusable press-animated gradient button
// =============================================================================
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
                color: widget.glowColor.withOpacity(0.3),
                blurRadius: 18,
                offset: const Offset(0, 7),
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
