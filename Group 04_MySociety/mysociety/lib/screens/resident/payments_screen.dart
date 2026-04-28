import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Finance'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelStyle:
              GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
          unselectedLabelStyle: GoogleFonts.poppins(fontSize: 13),
          tabs: const [
            Tab(text: 'Payments'),
            Tab(text: 'Expenses'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _PaymentsTab(),
          _ExpensesTab(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

// ─── Payments Tab ─────────────────────────────────────────────────────────────

class _PaymentsTab extends StatelessWidget {
  const _PaymentsTab();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, userSnap) {
        if (!userSnap.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }
        final user = UserModel.fromDoc(userSnap.data!);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Due Amount Card
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('dues')
                  .doc(uid)
                  .snapshots(),
              builder: (context, dueSnap) {
                double dueAmount = 0;
                String dueMonth = '';
                if (dueSnap.hasData && dueSnap.data!.exists) {
                  final d =
                      dueSnap.data!.data() as Map<String, dynamic>;
                  dueAmount = (d['amount'] ?? 0).toDouble();
                  dueMonth = d['month'] ?? '';
                }

                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              color: Colors.white70, size: 20),
                          const SizedBox(width: 8),
                          Text('Pending Due',
                              style: GoogleFonts.poppins(
                                  color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        dueAmount > 0 ? fmt.format(dueAmount) : 'No Dues!',
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold),
                      ),
                      if (dueMonth.isNotEmpty)
                        Text(
                          'For $dueMonth',
                          style: GoogleFonts.poppins(
                              color: Colors.white70, fontSize: 13),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        'Flat ${user.flatNo} • ${user.name}',
                        style: GoogleFonts.poppins(
                            color: Colors.white60, fontSize: 12),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Payment History & Total Bill
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('payments')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snap) {
                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 24),
                      Text('Payment History',
                          style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text('No payment records yet.',
                              style: GoogleFonts.poppins(
                                  color: AppColors.textSecondary, fontSize: 13)),
                        ),
                      ),
                    ],
                  );
                }

                final payments = snap.data!.docs
                    .map((d) => PaymentModel.fromDoc(d))
                    .toList();

                final double totalPaid =
                    payments.fold(0.0, (sum, p) => sum + p.amount);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    // Total Paid Summary Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppColors.success.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                                Icons.account_balance_wallet_rounded,
                                color: AppColors.success,
                                size: 26),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Total Maintenance Paid',
                                    style: GoogleFonts.poppins(
                                        color: AppColors.textPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600)),
                                Text(fmt.format(totalPaid),
                                    style: GoogleFonts.poppins(
                                        color: AppColors.success,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('Payment History',
                        style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 12),
                    ...payments
                        .map((p) => Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color:
                                          AppColors.success.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                        Icons.check_circle_rounded,
                                        color: AppColors.success,
                                        size: 22),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            '${p.month} ${p.year}',
                                            style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                                color: AppColors.textPrimary)),
                                        Text(
                                          DateFormat('dd MMM yyyy')
                                              .format(p.createdAt),
                                          style: GoogleFonts.poppins(
                                              fontSize: 11,
                                              color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    fmt.format(p.amount),
                                    style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: AppColors.success),
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }
}

// ─── Expenses Tab (read-only for residents) ────────────────────────────────────

class _ExpensesTab extends StatelessWidget {
  const _ExpensesTab();

  static const _catColors = {
    'Maintenance': Color(0xFF6C63FF),
    'Security': Color(0xFF1E3A5F),
    'Utilities': Color(0xFF00BCD4),
    'Gardening': Color(0xFF4CAF50),
    'Events': Color(0xFFFF9800),
    'Misc': Color(0xFF9C27B0),
  };

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('expenses')
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.account_balance_wallet_outlined,
                    size: 72,
                    color: AppColors.textSecondary.withOpacity(0.4)),
                const SizedBox(height: 14),
                Text('No expenses recorded yet.',
                    style: GoogleFonts.poppins(
                        color: AppColors.textSecondary, fontSize: 14)),
              ],
            ),
          );
        }

        final expenses =
            snap.data!.docs.map((d) => ExpenseModel.fromDoc(d)).toList();

        // Aggregate by category for pie chart
        final Map<String, double> categoryTotals = {};
        for (final e in expenses) {
          categoryTotals[e.category] =
              (categoryTotals[e.category] ?? 0) + e.amount;
        }
        final total = categoryTotals.values.fold(0.0, (a, b) => a + b);

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            // Pie chart card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 3)),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Expense Breakdown',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.textPrimary)),
                      Text('Total: ${fmt.format(total)}',
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.adminAccent)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 180,
                    child: PieChart(
                      PieChartData(
                        sections: categoryTotals.entries.map((e) {
                          final color =
                              _catColors[e.key] ?? AppColors.primary;
                          return PieChartSectionData(
                            value: e.value,
                            title: e.key,
                            color: color,
                            radius: 70,
                            titleStyle: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          );
                        }).toList(),
                        sectionsSpace: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: categoryTotals.entries.map((e) {
                      final color = _catColors[e.key] ?? AppColors.primary;
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                  color: color, shape: BoxShape.circle)),
                          const SizedBox(width: 4),
                          Text('${e.key}: ${fmt.format(e.value)}',
                              style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: AppColors.textSecondary)),
                        ],
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text('All Expenses',
                style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            ...expenses.map(
              (e) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (_catColors[e.category] ?? AppColors.primary)
                            .withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.receipt_outlined,
                          color:
                              _catColors[e.category] ?? AppColors.primary,
                          size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.description,
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: AppColors.textPrimary)),
                          Text(
                            '${e.category} • ${DateFormat('dd MMM yyyy').format(e.date)}',
                            style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      fmt.format(e.amount),
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.error),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
