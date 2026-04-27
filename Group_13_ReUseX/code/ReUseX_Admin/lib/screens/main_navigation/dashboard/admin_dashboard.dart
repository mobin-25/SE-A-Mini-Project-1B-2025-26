import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:reusex/screens/main_navigation/orders/admin/completed_orders_page.dart' hide AppColors;
import 'package:reusex/screens/main_navigation/orders/admin/pending_orders_page.dart' hide AppColors;
import '../../login/admin_login.dart';
import '../approval/approval_screen.dart';
import '../main_navigation.dart';
import '../orders/admin/cancelled_orders_page.dart';
import '../reports/reports_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String formatIndianPrice(double amount) {
    final formatter = NumberFormat('#,##,##0', 'en_IN');
    return "₹${formatter.format(amount)}";
  }

  Future<void> _showEditEWasteDialog(BuildContext context, double currentValue) async {
    final controller = TextEditingController(
      text: currentValue % 1 == 0
          ? currentValue.toInt().toString()
          : currentValue.toString(),
    );

    await showDialog(
      context: context,
      builder: (context) {
        bool isSaving = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Edit E-Waste Recycled"),
              content: TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  hintText: "Enter weight in kg",
                  labelText: "Weight (kg)",
                  border: OutlineInputBorder(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                    final value = double.tryParse(controller.text.trim());

                    if (value == null || value < 0) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(
                          content: Text("Please enter a valid weight"),
                        ),
                      );
                      return;
                    }

                    try {
                      setDialogState(() {
                        isSaving = true;
                      });

                      await FirebaseFirestore.instance
                          .collection("dashboard")
                          .doc("stats")
                          .set({
                        "eWasteRecycled": value,
                        "updatedAt": FieldValue.serverTimestamp(),
                      }, SetOptions(merge: true));

                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(
                            content: Text("E-Waste recycled updated successfully"),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(
                            content: Text("Failed to update: $e"),
                          ),
                        );
                      }
                    } finally {
                      if (mounted) {
                        setDialogState(() {
                          isSaving = false;
                        });
                      }
                    }
                  },
                  child: isSaving
                      ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatKg(double value) {
    if (value % 1 == 0) {
      return "${value.toInt()} kg";
    }
    return "$value kg";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AdminDrawer(),
      backgroundColor: AppColors.secondary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text("Admin Dashboard"),
        elevation: 0,
        leading: Builder(
          builder: (context) {
            return IconButton(
              tooltip: '',
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("dashboard")
                  .doc("stats")
                  .snapshots(),
              builder: (context, snapshot) {
                double eWasteValue = 0;

                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>?;
                  final rawValue = data?["eWasteRecycled"];

                  if (rawValue is num) {
                    eWasteValue = rawValue.toDouble();
                  } else {
                    eWasteValue =
                        double.tryParse(rawValue?.toString() ?? "0") ?? 0;
                  }
                }

                return _buildStaticStatCard(
                  title: "E-Waste Recycled",
                  value: _formatKg(eWasteValue),
                  icon: Icons.recycling,
                  color: Colors.green,
                  trailing: TextButton.icon(
                    onPressed: () => _showEditEWasteDialog(context, eWasteValue),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text("Edit"),
                    style: TextButton.styleFrom(
                      foregroundColor: Color(0xFF8F7AE5),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("categories")
                  .where("isActive", isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                final count = snapshot.data?.docs.length ?? 0;

                return _buildStaticStatCard(
                  title: "Active Categories",
                  value: count.toString(),
                  icon: Icons.category,
                  color: Colors.orange,
                );
              },
            ),

            const SizedBox(height: 16),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("orders")
                  .where("status", isEqualTo: "Pending")
                  .snapshots(),
              builder: (context, snapshot) {
                final count = snapshot.data?.docs.length ?? 0;

                return _buildStaticStatCard(
                  title: "Pending Order",
                  value: count.toString(),
                  icon: Icons.shopping_bag_outlined,
                  color: Colors.lightBlueAccent,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PendingOrdersPage(),
                      ),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 16),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("orders")
                  .where("status", isEqualTo: "Cancelled")
                  .snapshots(),
              builder: (context, snapshot) {
                final count = snapshot.data?.docs.length ?? 0;

                return _buildStaticStatCard(
                  title: "Cancel Order",
                  value: count.toString(),
                  icon: Icons.remove_shopping_cart,
                  color: Colors.red,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CancelledOrdersPage(),
                      ),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 16),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("orders")
                  .where("status", isEqualTo: "Delivered")
                  .snapshots(),
              builder: (context, snapshot) {
                final count = snapshot.data?.docs.length ?? 0;

                return _buildStaticStatCard(
                  title: "Completed Order",
                  value: count.toString(),
                  icon: Icons.shopping_cart_outlined,
                  color: Colors.indigo,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CompletedOrdersPage(),
                      ),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 16),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("orders")
                  .where("status", isEqualTo: "Delivered")
                  .snapshots(),
              builder: (context, snapshot) {
                final docs = snapshot.data?.docs ?? [];
                double totalRevenue = 0;

                for (var doc in docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final rawPrice = data["price"];

                  if (rawPrice is num) {
                    totalRevenue += rawPrice.toDouble();
                  } else {
                    final cleaned = rawPrice
                        .toString()
                        .replaceAll("₹", "")
                        .replaceAll("Rs.", "")
                        .replaceAll("Rs", "")
                        .replaceAll(",", "")
                        .trim();

                    totalRevenue += double.tryParse(cleaned) ?? 0;
                  }
                }

                return _buildStaticStatCard(
                  title: "Revenue",
                  value: formatIndianPrice(totalRevenue),
                  icon: Icons.receipt_sharp,
                  color: Colors.purpleAccent,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaticStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.30),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: color.withOpacity(0.15),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ),
      ),
    );
  }
}