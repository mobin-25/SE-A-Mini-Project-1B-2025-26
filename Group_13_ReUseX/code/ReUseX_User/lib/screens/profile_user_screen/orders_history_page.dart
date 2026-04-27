import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrderHistoryPage extends StatelessWidget {
  const OrderHistoryPage({super.key});

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

  Widget _buildProductImage(String productImage) {
    if (productImage.isNotEmpty && productImage.startsWith("http")) {
      return Image.network(
        productImage,
        height: 60,
        width: 60,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          height: 60,
          width: 60,
          color: Colors.grey.shade200,
          child: const Icon(Icons.image_not_supported),
        ),
      );
    }

    return Container(
      height: 60,
      width: 60,
      color: Colors.grey.shade200,
      child: const Icon(Icons.image, color: Colors.grey),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF0FDF4),
        appBar: AppBar(
          title: const Text("Order History"),
          backgroundColor: Colors.green,
        ),
        body: const Center(
          child: Text(
            "User not logged in",
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0FDF4),
      appBar: AppBar(
        title: const Text("Order History"),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("orders")
            .where("userId", isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Something went wrong\n${snapshot.error}",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            );
          }

          final allOrders = snapshot.data?.docs ?? [];

          final orders = allOrders.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final status = (data["status"] ?? "").toString();
            return status == "Delivered" || status == "Cancelled";
          }).toList();

          orders.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;

            final aCreatedAt = aData["createdAt"] as Timestamp?;
            final bCreatedAt = bData["createdAt"] as Timestamp?;

            final aTime = aCreatedAt?.millisecondsSinceEpoch ?? 0;
            final bTime = bCreatedAt?.millisecondsSinceEpoch ?? 0;

            return bTime.compareTo(aTime);
          });

          if (orders.isEmpty) {
            return const Center(
              child: Text(
                "No order history",
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final data = orders[index].data() as Map<String, dynamic>;

              final productName = (data["productName"] ?? "").toString();
              final productImage = (data["productImage"] ?? "").toString();
              final status = (data["status"] ?? "").toString();

              final originalPrice = _getOriginalPrice(data);
              final finalPrice = _getFinalPrice(data);
              final couponDiscount = _getCouponDiscount(data);
              final hasDiscount = couponDiscount > 0 && finalPrice < originalPrice;

              final isDelivered = status == "Delivered";
              final bgColor = isDelivered
                  ? Colors.green.withOpacity(0.2)
                  : Colors.red.withOpacity(0.2);
              final textColor = isDelivered ? Colors.green : Colors.red;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _buildProductImage(productImage),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            productName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
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
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ] else ...[
                            Text(
                              _formatPrice(finalPrice),
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
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
                        color: bgColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: textColor,
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