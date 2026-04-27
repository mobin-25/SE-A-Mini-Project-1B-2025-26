import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../dashboard/admin_dashboard.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  double _parsePrice(dynamic rawPrice) {
    if (rawPrice == null) return 0.0;
    if (rawPrice is num) return rawPrice.toDouble();

    final cleaned = rawPrice
        .toString()
        .replaceAll("₹", "")
        .replaceAll("Rs.", "")
        .replaceAll("RS.", "")
        .replaceAll("Rs", "")
        .replaceAll("rs.", "")
        .replaceAll("rs", "")
        .replaceAll(",", "")
        .trim();

    return double.tryParse(cleaned) ?? 0.0;
  }

  String _formatIndianPrice(double amount) {
    final formatter = NumberFormat('#,##,##0', 'en_IN');
    return "₹${formatter.format(amount)}";
  }

  String _formatEWaste(double value) {
    if (value >= 1000) {
      final tons = value / 1000;
      return "${tons.toStringAsFixed(1)}T";
    }
    if (value % 1 == 0) {
      return "${value.toInt()}kg";
    }
    return "${value.toStringAsFixed(1)}kg";
  }

  DateTime? _extractOrderDate(Map<String, dynamic> data) {
    final rawDate = data["createdAt"] ?? data["timestamp"] ?? data["orderDate"];

    if (rawDate is Timestamp) return rawDate.toDate();
    if (rawDate is DateTime) return rawDate;

    return null;
  }

  List<Map<String, dynamic>> _getLastSixMonths() {
    final now = DateTime.now();
    return List.generate(6, (index) {
      final monthDate = DateTime(now.year, now.month - 5 + index, 1);
      return {
        "year": monthDate.year,
        "month": monthDate.month,
        "label": DateFormat('MMM').format(monthDate),
      };
    });
  }

  List<double> _buildMonthlyRevenue(List<QueryDocumentSnapshot> docs) {
    final months = _getLastSixMonths();
    final revenueMap = <String, double>{};

    for (final monthData in months) {
      final key = "${monthData["year"]}-${monthData["month"]}";
      revenueMap[key] = 0.0;
    }

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final status = (data["status"] ?? "").toString().trim().toLowerCase();

      if (status != "delivered") continue;

      final date = _extractOrderDate(data);
      if (date == null) continue;

      final key = "${date.year}-${date.month}";
      if (revenueMap.containsKey(key)) {
        revenueMap[key] = (revenueMap[key] ?? 0) + _parsePrice(data["price"]);
      }
    }

    return months.map((monthData) {
      final key = "${monthData["year"]}-${monthData["month"]}";
      return revenueMap[key] ?? 0.0;
    }).toList();
  }

  double _getMaxY(List<double> values) {
    double maxVal = 0;
    for (final v in values) {
      if (v > maxVal) maxVal = v;
    }
    if (maxVal <= 0) return 10;
    return (maxVal * 1.25);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminDashboard()),
          ),
        ),
        title: const Text(
          "Reports & Insights",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection("dashboard")
            .doc("stats")
            .snapshots(),
        builder: (context, dashboardSnapshot) {
          double eWasteValue = 0;

          if (dashboardSnapshot.hasData && dashboardSnapshot.data!.exists) {
            final data =
            dashboardSnapshot.data!.data() as Map<String, dynamic>?;
            final rawValue = data?["eWasteRecycled"];

            if (rawValue is num) {
              eWasteValue = rawValue.toDouble();
            } else {
              eWasteValue =
                  double.tryParse(rawValue?.toString() ?? "0") ?? 0;
            }
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection("orders").snapshots(),
            builder: (context, orderSnapshot) {
              if (orderSnapshot.connectionState == ConnectionState.waiting ||
                  dashboardSnapshot.connectionState ==
                      ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (orderSnapshot.hasError) {
                return Center(
                  child: Text(
                    "Something went wrong:\n${orderSnapshot.error}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                );
              }

              final docs = orderSnapshot.data?.docs ?? [];

              int deliveredCount = 0;
              int pendingCount = 0;
              int cancelledCount = 0;
              double totalRevenue = 0;

              for (final doc in docs) {
                final data = doc.data() as Map<String, dynamic>;
                final status =
                (data["status"] ?? "").toString().trim().toLowerCase();

                if (status == "delivered") {
                  deliveredCount++;
                  totalRevenue += _parsePrice(data["price"]);
                } else if (status == "pending") {
                  pendingCount++;
                } else if (status == "cancelled") {
                  cancelledCount++;
                }
              }

              final totalOrdersForPie =
                  deliveredCount + pendingCount + cancelledCount;

              final monthlyRevenue = _buildMonthlyRevenue(docs);
              final maxY = _getMaxY(monthlyRevenue);
              final lastSixMonths = _getLastSixMonths();

              return SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF22C55E), Color(0xFF06B6D4)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Performance Overview",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.2,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Track revenue, e-waste & completed orders",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        height: 140,
                        child: Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                title: "Revenue",
                                value: _formatIndianPrice(totalRevenue),
                                icon: Icons.currency_rupee_rounded,
                                color: const Color(0xFF22C55E),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                title: "E-Waste\nRecycled",
                                value: _formatEWaste(eWasteValue),
                                icon: Icons.recycling_rounded,
                                color: const Color(0xFF06B6D4),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                title: "Orders Done",
                                value: deliveredCount.toString(),
                                icon: Icons.check_circle_rounded,
                                color: const Color(0xFFA78BFA),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Monthly Revenue",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              "Last 6 months",
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 180,
                              child: LineChart(
                                LineChartData(
                                  minY: 0,
                                  maxY: maxY,
                                  gridData: FlGridData(
                                    show: true,
                                    drawVerticalLine: false,
                                    getDrawingHorizontalLine: (value) => FlLine(
                                      color: Colors.white10,
                                      strokeWidth: 1,
                                    ),
                                  ),
                                  titlesData: FlTitlesData(
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    rightTitles: AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    topTitles: AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        interval: 1,
                                        getTitlesWidget: (value, meta) {
                                          if (value.toInt() <
                                              lastSixMonths.length) {
                                            return Text(
                                              lastSixMonths[value.toInt()]["label"]
                                                  .toString(),
                                              style: const TextStyle(
                                                color: Colors.white38,
                                                fontSize: 11,
                                              ),
                                            );
                                          }
                                          return const SizedBox();
                                        },
                                      ),
                                    ),
                                  ),
                                  borderData: FlBorderData(show: false),
                                  lineBarsData: [
                                    LineChartBarData(
                                      isCurved: true,
                                      color: const Color(0xFF22C55E),
                                      barWidth: 3,
                                      dotData: FlDotData(
                                        show: true,
                                        getDotPainter:
                                            (spot, percent, bar, index) =>
                                            FlDotCirclePainter(
                                              radius: 4,
                                              color: const Color(0xFF22C55E),
                                              strokeWidth: 2,
                                              strokeColor: Colors.white,
                                            ),
                                      ),
                                      belowBarData: BarAreaData(
                                        show: true,
                                        gradient: LinearGradient(
                                          colors: [
                                            const Color(0xFF22C55E)
                                                .withOpacity(0.3),
                                            const Color(0xFF22C55E)
                                                .withOpacity(0.0),
                                          ],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ),
                                      ),
                                      spots: List.generate(
                                        monthlyRevenue.length,
                                            (index) => FlSpot(
                                          index.toDouble(),
                                          monthlyRevenue[index],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Order Distribution",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              "Delivered · Pending · Cancelled",
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                SizedBox(
                                  height: 180,
                                  width: 150,
                                  child: totalOrdersForPie == 0
                                      ? const Center(
                                    child: Text(
                                      "No order data",
                                      style: TextStyle(
                                        color: Colors.white54,
                                      ),
                                    ),
                                  )
                                      : PieChart(
                                    PieChartData(
                                      sectionsSpace: 3,
                                      centerSpaceRadius: 48,
                                      sections: [
                                        PieChartSectionData(
                                          value: deliveredCount.toDouble(),
                                          color: const Color(0xFF22C55E),
                                          title:
                                          "${((deliveredCount / totalOrdersForPie) * 100).toStringAsFixed(0)}%",
                                          radius: 50,
                                          titleStyle: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        PieChartSectionData(
                                          value: pendingCount.toDouble(),
                                          color: const Color(0xFFF59E0B),
                                          title:
                                          "${((pendingCount / totalOrdersForPie) * 100).toStringAsFixed(0)}%",
                                          radius: 50,
                                          titleStyle: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        PieChartSectionData(
                                          value: cancelledCount.toDouble(),
                                          color: const Color(0xFFEF4444),
                                          title:
                                          "${((cancelledCount / totalOrdersForPie) * 100).toStringAsFixed(0)}%",
                                          radius: 50,
                                          titleStyle: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 24),
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _LegendDot(
                                        color: const Color(0xFF22C55E),
                                        label: "Delivered ($deliveredCount)",
                                      ),
                                      const SizedBox(height: 12),
                                      _LegendDot(
                                        color: const Color(0xFFF59E0B),
                                        label: "Pending ($pendingCount)",
                                      ),
                                      const SizedBox(height: 12),
                                      _LegendDot(
                                        color: const Color(0xFFEF4444),
                                        label: "Cancelled ($cancelledCount)",
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 30,
            child: Center(
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  height: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ),
      ],
    );
  }
}