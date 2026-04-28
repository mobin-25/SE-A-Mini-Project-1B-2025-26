import 'package:flutter/material.dart';
import '../services/insights_service.dart';
import 'package:fl_chart/fl_chart.dart';

// ─── Shared Design System (mirrors dashboard_screen.dart) ────────────────────
class _C {
  static const bg = Color(0xFF0D0F1A);
  static const surface = Color(0xFF161827);
  static const card = Color(0xFF1E2138);
  static const cardBorder = Color(0xFF2A2D4A);

  static const primary = Color(0xFF6C63FF);
  static const accent = Color(0xFF00D4AA);
  static const accentBlue = Color(0xFF4FC3F7);

  static const textPrimary = Color(0xFFF0F2FF);
  static const textSecondary = Color(0xFF8A8FAE);
  static const textMuted = Color(0xFF545874);

  static const positive = Color(0xFF00D4AA);
  static const warning = Color(0xFFFFB86B);
  static const negative = Color(0xFFFF6B8A);

  // Chart palette
  static const List<Color> chartColors = [
    Color(0xFF6C63FF),
    Color(0xFF00D4AA),
    Color(0xFFFFB86B),
    Color(0xFFFF6B8A),
    Color(0xFF4FC3F7),
  ];
}

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen>
    with TickerProviderStateMixin {
  Map<String, dynamic>? data;
  bool loading = true;
  bool hasError = false;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    loadInsights();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> loadInsights() async {
    try {
      final result = await InsightsService.fetchInsights(1);

      assert(() {
        debugPrint("INSIGHTS DATA: $result");
        return true;
      }());

      setState(() {
        data = result;
        loading = false;
        hasError = false;
      });

      _fadeCtrl.forward();
    } catch (e) {
      setState(() {
        loading = false;
        hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final warnings = (data?["warnings"] ?? []) as List;
    final trend = data?["trend"];
    final savings = data?["savings_message"];
    final categorySpending = (data?["category_spending"] ?? []) as List;
    final hasChartData = categorySpending.isNotEmpty;

    return Scaffold(
      backgroundColor: _C.bg,
      appBar: _buildAppBar(context),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(
                color: _C.primary,
                strokeWidth: 2,
              ),
            )
          : hasError || data == null
          ? _buildErrorState()
          : FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Insight Cards ──────────────────────────────────────
                    if (warnings.isNotEmpty)
                      insightCard(
                        "⚠️ Budget Warning",
                        warnings.join("\n"),
                        _C.warning,
                      ),

                    if (trend != null)
                      insightCard("📈 Spending Trend", trend, _C.accentBlue),

                    if (savings != null)
                      insightCard("💰 Savings Insight", savings, _C.positive),

                    const SizedBox(height: 28),

                    // ── Section title ──────────────────────────────────────
                    _sectionTitle("Monthly Spending"),
                    const SizedBox(height: 14),

                    // ── BAR CHART ──────────────────────────────────────────
                    if (hasChartData)
                      chartContainer(
                        BarChart(
                          BarChartData(
                            borderData: FlBorderData(show: false),
                            gridData: FlGridData(
                              drawVerticalLine: false,
                              horizontalInterval: 500,
                              getDrawingHorizontalLine: (value) => FlLine(
                                color: Colors.white.withOpacity(0.06),
                                strokeWidth: 1,
                              ),
                            ),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 42,
                                  getTitlesWidget: (value, meta) {
                                    if (value % 500 != 0)
                                      return const SizedBox();
                                    return Text(
                                      "₹${value.toInt()}",
                                      style: const TextStyle(
                                        fontSize: 9,
                                        color: _C.textMuted,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final categories =
                                        (data?["category_spending"] ?? [])
                                            as List;
                                    if (value.toInt() >= categories.length)
                                      return const SizedBox();
                                    final name =
                                        categories[value.toInt()]["name"];
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        name,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                          color: _C.textSecondary,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            barGroups: buildBarChart(categorySpending),
                            barTouchData: BarTouchData(
                              enabled: true,
                              touchTooltipData: BarTouchTooltipData(
                                tooltipMargin: 8,
                                getTooltipItem:
                                    (group, groupIndex, rod, rodIndex) {
                                      return BarTooltipItem(
                                        "₹${rod.toY.toInt()}",
                                        const TextStyle(
                                          color: _C.textPrimary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      );
                                    },
                              ),
                            ),
                          ),
                        ),
                        label: "Bar Chart",
                      )
                    else
                      emptyChart(),

                    const SizedBox(height: 20),

                    // ── PIE CHART ──────────────────────────────────────────
                    if (hasChartData) ...[
                      _sectionTitle("Spending Breakdown"),
                      const SizedBox(height: 14),
                      chartContainer(
                        PieChart(
                          PieChartData(
                            sections: buildPieChart(categorySpending),
                            centerSpaceRadius: 36,
                            sectionsSpace: 3,
                          ),
                        ),
                        label: "Pie Chart",
                      ),

                      const SizedBox(height: 20),

                      // ── Legend ───────────────────────────────────────────
                      _buildLegend(categorySpending),
                    ] else ...[
                      _sectionTitle("Spending Breakdown"),
                      const SizedBox(height: 14),
                      emptyChart(),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  // ── Error State ───────────────────────────────────────────────────────────
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _C.negative.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _C.negative.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                color: _C.negative,
                size: 32,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Couldn't load insights",
              style: TextStyle(
                color: _C.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Check your connection and try again.",
              textAlign: TextAlign.center,
              style: TextStyle(color: _C.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () {
                setState(() {
                  loading = true;
                  hasError = false;
                });
                loadInsights();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_C.primary, _C.accent],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  "Retry",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: _C.surface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: _C.textPrimary,
          size: 18,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        "Insights",
        style: TextStyle(
          color: _C.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 18,
          letterSpacing: -0.3,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _C.cardBorder),
      ),
    );
  }

  // ── Section title ─────────────────────────────────────────────────────────
  Widget _sectionTitle(String text) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_C.primary, _C.accent],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _C.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  // ── Legend ────────────────────────────────────────────────────────────────
  Widget _buildLegend(List categorySpending) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.cardBorder, width: 1),
      ),
      child: Column(
        children: categorySpending.asMap().entries.map((entry) {
          final color = _C.chartColors[entry.key % _C.chartColors.length];
          final raw = entry.value is Map ? entry.value["amount"] : null;
          final amount = (raw is num ? raw : 0).toDouble();
          final name =
              (entry.value is Map ? entry.value["name"] : null)?.toString() ??
              "";
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      color: _C.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  "₹${amount.toInt()}",
                  style: const TextStyle(
                    color: _C.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // =========================
  // 📊 BAR CHART
  // =========================
  List<BarChartGroupData> buildBarChart(List list) {
    return list.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      // Fix 5 & 6: safe cast with fallback — handles null, int, double
      final raw = item is Map ? item["amount"] : null;
      final amount = (raw is num ? raw : 0).toDouble();
      final color = _C.chartColors[index % _C.chartColors.length];

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: amount,
            width: 18,
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.7), color],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
        ],
        showingTooltipIndicators: [0],
      );
    }).toList();
  }

  // =========================
  // 🥧 PIE CHART
  // =========================
  List<PieChartSectionData> buildPieChart(List list) {
    return list.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final color = _C.chartColors[index % _C.chartColors.length];
      // Fix 5 & 6: safe cast with fallback for both amount and name
      final raw = item is Map ? item["amount"] : null;
      final amount = (raw is num ? raw : 0).toDouble();
      final name = (item is Map ? item["name"] : null)?.toString() ?? "";

      return PieChartSectionData(
        value: amount,
        title: name,
        color: color,
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  // =========================
  // 📦 CHART CONTAINER
  // =========================
  Widget chartContainer(Widget child, {String? label}) {
    return Container(
      height: 240,
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 10),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _C.cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  // =========================
  // ❌ EMPTY STATE
  // =========================
  Widget emptyChart() {
    return Container(
      height: 240,
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _C.cardBorder, width: 1),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart_rounded, color: _C.textMuted, size: 36),
            const SizedBox(height: 10),
            const Text(
              "No spending data yet",
              style: TextStyle(
                color: _C.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // 🧾 INSIGHT CARD
  // =========================
  Widget insightCard(String title, String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Color accent bar
          Container(
            width: 4,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: color,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  text,
                  style: const TextStyle(
                    color: _C.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
