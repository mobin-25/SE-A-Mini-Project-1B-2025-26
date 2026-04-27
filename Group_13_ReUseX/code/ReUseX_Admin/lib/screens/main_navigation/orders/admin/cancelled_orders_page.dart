import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppColors {
  static const primary = Color(0xFF8F7AE5);
  static const secondary = Color(0xFFD6D9F7);
}

class CancelledOrdersPage extends StatelessWidget {
  const CancelledOrdersPage({super.key});

  Widget _buildProductImage(String imagePath) {
    if (imagePath.isNotEmpty && imagePath.startsWith("http")) {
      return Image.network(
        imagePath,
        height: 60,
        width: 60,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 60,
            width: 60,
            color: Colors.grey.shade200,
            child: const Icon(Icons.image_not_supported),
          );
        },
      );
    }

    return Container(
      height: 60,
      width: 60,
      color: Colors.grey.shade200,
      child: const Icon(Icons.image, color: Colors.grey),
    );
  }

  String _formatPrice(dynamic value) {
    final amount = (value is num) ? value.toDouble() : 0.0;
    final formatter = NumberFormat('#,##,##0.00', 'en_IN');
    return "₹${formatter.format(amount)}";
  }

  double _getOriginalPrice(Map<String, dynamic> data) {
    final price = data["price"];
    if (price is num) return price.toDouble();
    return 0.0;
  }

  double _getFinalPrice(Map<String, dynamic> data) {
    final totalAfterDiscount = data["totalAfterDiscount"];
    if (totalAfterDiscount is num) return totalAfterDiscount.toDouble();

    final price = data["price"];
    if (price is num) return price.toDouble();

    return 0.0;
  }

  double _getCouponDiscount(Map<String, dynamic> data) {
    final couponDiscount = data["couponDiscount"];
    if (couponDiscount is num) return couponDiscount.toDouble();
    return 0.0;
  }

  DateTime _getCancelledDate(Map<String, dynamic> data) {
    final cancelledAt = data["cancelledAt"];
    if (cancelledAt is Timestamp) {
      return cancelledAt.toDate();
    }

    final timestamp = data["timestamp"];
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }

    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text("Cancelled Orders"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("orders")
            .where("status", isEqualTo: "Cancelled")
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders =
          List<QueryDocumentSnapshot>.from(snapshot.data?.docs ?? []);

          orders.sort((a, b) {
            final dataA = a.data() as Map<String, dynamic>;
            final dataB = b.data() as Map<String, dynamic>;
            return _getCancelledDate(dataB).compareTo(_getCancelledDate(dataA));
          });

          if (orders.isEmpty) {
            return const Center(
              child: Text(
                "No cancelled orders",
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final data = orders[index].data() as Map<String, dynamic>;

              final originalPrice = _getOriginalPrice(data);
              final finalPrice = _getFinalPrice(data);
              final couponDiscount = _getCouponDiscount(data);
              final hasDiscount =
                  couponDiscount > 0 && finalPrice < originalPrice;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _buildProductImage(
                        (data["productImage"] ?? "").toString(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (data["productName"] ?? "").toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (hasDiscount) ...[
                            Text(
                              _formatPrice(originalPrice),
                              style: const TextStyle(
                                color: Colors.grey,
                                decoration: TextDecoration.lineThrough,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatPrice(finalPrice),
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ] else ...[
                            Text(
                              _formatPrice(finalPrice),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        "Cancelled",
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}