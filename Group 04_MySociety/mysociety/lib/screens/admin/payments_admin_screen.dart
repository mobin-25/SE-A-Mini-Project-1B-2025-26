import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';

class PaymentsAdminScreen extends StatefulWidget {
  const PaymentsAdminScreen({super.key});

  @override
  State<PaymentsAdminScreen> createState() => _PaymentsAdminScreenState();
}

class _PaymentsAdminScreenState extends State<PaymentsAdminScreen>
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

class _PaymentsTab extends StatefulWidget {
  const _PaymentsTab();

  @override
  State<_PaymentsTab> createState() => _PaymentsTabState();
}

class _PaymentsTabState extends State<_PaymentsTab> {
  final _amountCtrl = TextEditingController();
  final _months = [
    'January','February','March','April','May','June',
    'July','August','September','October','November','December'
  ];
  String _selectedMonth = 'March';
  String? _selectedResidentUid;
  bool _recording = false;
  List<Map<String, dynamic>> _residents = [];
  bool _loadingResidents = true;

  @override
  void initState() {
    super.initState();
    _loadResidents();
  }

  Future<void> _loadResidents() async {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'resident')
        .where('status', isEqualTo: 'approved')
        .get();
    setState(() {
      _residents = snap.docs
          .map((d) => {
                'uid': d.id,
                'name': d['name'],
                'flatNo': d['flatNo'],
              })
          .toList();
      _loadingResidents = false;
    });
  }

  Future<void> _recordPayment() async {
    if (_selectedResidentUid == null || _amountCtrl.text.trim().isEmpty) return;
    setState(() => _recording = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final year = DateTime.now().year;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_selectedResidentUid)
          .collection('payments')
          .add({
        'amount': double.parse(_amountCtrl.text.trim()),
        'month': _selectedMonth,
        'year': year,
        'recordedBy': uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _amountCtrl.clear();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Payment recorded!'),
              backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to record payment: $e'),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _recording = false);
    }
  }

  void _showRecordDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          margin: const EdgeInsets.all(16),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 24,
            right: 24,
            top: 24,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Record Payment',
                  style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 16),

              // Resident selector
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButton<String>(
                  value: _selectedResidentUid,
                  isExpanded: true,
                  underline: const SizedBox(),
                  hint: Text('Select Resident',
                      style: GoogleFonts.poppins(
                          color: AppColors.textSecondary, fontSize: 14)),
                  items: _residents
                      .map((r) => DropdownMenuItem<String>(
                            value: r['uid'],
                            child: Text('${r['name']} (Flat ${r['flatNo']})',
                                style: GoogleFonts.poppins(fontSize: 14)),
                          ))
                      .toList(),
                  onChanged: (v) {
                    setS(() => _selectedResidentUid = v);
                    setState(() => _selectedResidentUid = v);
                  },
                ),
              ),
              const SizedBox(height: 14),

              // Month selector
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButton<String>(
                  value: _selectedMonth,
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: _months
                      .map((m) => DropdownMenuItem(
                          value: m,
                          child: Text(m,
                              style: GoogleFonts.poppins(fontSize: 14))))
                      .toList(),
                  onChanged: (v) {
                    setS(() => _selectedMonth = v!);
                    setState(() => _selectedMonth = v!);
                  },
                ),
              ),
              const SizedBox(height: 14),

              TextField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount (₹)',
                  prefixIcon: Icon(Icons.currency_rupee_rounded,
                      color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _recording ? null : _recordPayment,
                child: _recording
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Record Payment'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showRecordDialog,
        backgroundColor: AppColors.success,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('Record Payment',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: _loadingResidents
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Recent Payments',
                    style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 12),
                ..._residents.map((r) => _ResidentPaymentTile(
                      uid: r['uid'],
                      name: r['name'],
                      flatNo: r['flatNo'],
                    )),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }
}

class _ResidentPaymentTile extends StatelessWidget {
  final String uid;
  final String name;
  final String flatNo;
  final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

  _ResidentPaymentTile({
    required this.uid,
    required this.name,
    required this.flatNo,
  });

  Future<void> _updateDues(BuildContext context) async {
    final amountCtrl = TextEditingController();
    String selectedMonth = 'March';
    bool saving = false;

    // Fetch existing dues if any
    try {
      final snap = await FirebaseFirestore.instance.collection('dues').doc(uid).get();
      if (snap.exists) {
        final d = snap.data() as Map<String, dynamic>;
        amountCtrl.text = (d['amount'] ?? 0).toString();
        selectedMonth = d['month'] ?? 'March';
      }
    } catch (_) {}

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          margin: const EdgeInsets.all(16),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 24, right: 24, top: 24,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Update Dues for $name',
                  style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButton<String>(
                  value: selectedMonth,
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: [
                    'January', 'February', 'March', 'April', 'May', 'June',
                    'July', 'August', 'September', 'October', 'November', 'December'
                  ].map((m) => DropdownMenuItem(value: m, child: Text(m, style: GoogleFonts.poppins(fontSize: 14)))).toList(),
                  onChanged: (v) {
                    setS(() => selectedMonth = v!);
                  },
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Due Amount (₹)',
                  prefixIcon: Icon(Icons.warning_amber_rounded, color: AppColors.error),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                onPressed: saving ? null : () async {
                  if (amountCtrl.text.trim().isEmpty) return;
                  setS(() => saving = true);
                  try {
                    await FirebaseFirestore.instance.collection('dues').doc(uid).set({
                      'amount': double.parse(amountCtrl.text.trim()),
                      'month': selectedMonth,
                      'updatedAt': FieldValue.serverTimestamp(),
                    });
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Dues updated successfully!'), backgroundColor: AppColors.success),
                      );
                    }
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error updating dues: $e'), backgroundColor: AppColors.error),
                      );
                    }
                  } finally {
                    if (ctx.mounted) setS(() => saving = false);
                  }
                },
                child: saving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Update Dues'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('payments')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, snap) {
        String lastPayment = 'No records';
        if (snap.hasData && snap.data!.docs.isNotEmpty) {
          final d = snap.data!.docs.first.data() as Map<String, dynamic>;
          lastPayment = '${d['month']} ${d['year']} — ${fmt.format((d['amount'] ?? 0).toDouble())}';
        }
        return GestureDetector(
          onTap: () => _updateDues(context),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'R',
                    style: GoogleFonts.poppins(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: AppColors.textPrimary)),
                      Text('Flat $flatNo • Last: $lastPayment',
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Column(
                  children: [
                    const Icon(Icons.edit_square, color: AppColors.primary, size: 20),
                    const SizedBox(height: 4),
                    Text('Edit Dues', style: GoogleFonts.poppins(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Expenses Tab ─────────────────────────────────────────────────────────────

class _ExpensesTab extends StatefulWidget {
  const _ExpensesTab();

  @override
  State<_ExpensesTab> createState() => _ExpensesTabState();
}

class _ExpensesTabState extends State<_ExpensesTab> {
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _categories = ['Maintenance', 'Security', 'Utilities', 'Gardening', 'Events', 'Misc'];
  String _selectedCategory = 'Maintenance';
  bool _adding = false;

  static const _catColors = {
    'Maintenance': Color(0xFF6C63FF),
    'Security': Color(0xFF1E3A5F),
    'Utilities': Color(0xFF00BCD4),
    'Gardening': Color(0xFF4CAF50),
    'Events': Color(0xFFFF9800),
    'Misc': Color(0xFF9C27B0),
  };

  Future<void> _deleteExpense(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Expense', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text('Are you sure you want to delete this expense?', style: GoogleFonts.poppins(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.poppins(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance.collection('expenses').doc(id).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expense deleted!'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete expense: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _addExpense() async {
    if (_amountCtrl.text.trim().isEmpty) return;
    setState(() => _adding = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance.collection('expenses').add({
        'category': _selectedCategory,
        'amount': double.parse(_amountCtrl.text.trim()),
        'description': _descCtrl.text.trim(),
        'date': Timestamp.fromDate(DateTime.now()),
        'addedBy': uid,
      });
      _amountCtrl.clear();
      _descCtrl.clear();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Expense added!'),
              backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to add expense: $e'),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  void _showAddExpenseDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          margin: const EdgeInsets.all(16),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 24,
            right: 24,
            top: 24,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Add Expense',
                  style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: _categories
                      .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c,
                              style: GoogleFonts.poppins(fontSize: 14))))
                      .toList(),
                  onChanged: (v) {
                    setS(() => _selectedCategory = v!);
                    setState(() => _selectedCategory = v!);
                  },
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount (₹)',
                  prefixIcon: Icon(Icons.currency_rupee_rounded,
                      color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  prefixIcon:
                      Icon(Icons.description_outlined, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _adding ? null : _addExpense,
                child: _adding
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Add Expense'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddExpenseDialog,
        backgroundColor: const Color(0xFFFF6F00),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('Add Expense',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: StreamBuilder<QuerySnapshot>(
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

          final expenses = snap.data!.docs
              .map((d) => ExpenseModel.fromDoc(d))
              .toList();

          // Aggregate by category for pie chart
          final Map<String, double> categoryTotals = {};
          for (final e in expenses) {
            categoryTotals[e.category] =
                (categoryTotals[e.category] ?? 0) + e.amount;
          }
          final total = categoryTotals.values.fold(0.0, (a, b) => a + b);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              // Pie chart
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
                            color: _catColors[e.category] ?? AppColors.primary,
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
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => _deleteExpense(e.id),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.delete_outline_rounded,
                              size: 18, color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }
}
