import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppColors {
  static const primary = Color(0xFF8F7AE5);
  static const secondary = Color(0xFFD6D9F7);
}

class PendingOrdersPage extends StatelessWidget {
  const PendingOrdersPage({super.key});

  Widget _buildProductImage(String imagePath) {
    if (imagePath.isNotEmpty && imagePath.startsWith("http")) {
      return Image.network(
        imagePath,
        height: 65,
        width: 65,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 65,
            width: 65,
            color: Colors.grey.shade200,
            child: const Icon(Icons.image_not_supported),
          );
        },
      );
    }

    return Image.asset(
      imagePath,
      height: 65,
      width: 65,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          height: 65,
          width: 65,
          color: Colors.grey.shade200,
          child: const Icon(Icons.image_not_supported),
        );
      },
    );
  }

  String _fullAddress(Map<String, dynamic> data) {
    final addressLabel = (data["addressLabel"] ?? "").toString();
    final fullName = (data["fullName"] ?? "").toString();
    final phoneNumber = (data["phoneNumber"] ?? "").toString();
    final addressLine1 = (data["addressLine1"] ?? "").toString();
    final city = (data["city"] ?? "").toString();
    final pincode = (data["pincode"] ?? "").toString();

    return "$addressLabel\n$fullName\n$phoneNumber\n$addressLine1\n$city - $pincode";
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

  DateTime _getOrderDate(Map<String, dynamic> data) {
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
        title: const Text("Pending Orders"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("orders")
            .where("status", isEqualTo: "Pending")
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
            return _getOrderDate(dataB).compareTo(_getOrderDate(dataA));
          });

          if (orders.isEmpty) {
            return const Center(
              child: Text(
                "No pending orders",
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final doc = orders[index];
              final data = doc.data() as Map<String, dynamic>;

              final originalPrice = _getOriginalPrice(data);
              final finalPrice = _getFinalPrice(data);
              final couponDiscount = _getCouponDiscount(data);
              final hasDiscount =
                  couponDiscount > 0 && finalPrice < originalPrice;

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
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
                                  fontSize: 16,
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
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _formatPrice(finalPrice),
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
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
                              const SizedBox(height: 4),
                              Text(
                                "Category: ${data["category"] ?? ""}",
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54,
                                ),
                              ),
                              Text(
                                "Grade: ${data["gradeLevel"] ?? ""}",
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54,
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
                            color: Colors.orange.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            "Pending",
                            style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Shipping Address",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _fullAddress(data),
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection("orders")
                                  .doc(doc.id)
                                  .update({
                                "status": "Delivered",
                                "completedAt": FieldValue.serverTimestamp(),
                              });
                            },
                            child: const Text(
                              "Complete",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection("orders")
                                  .doc(doc.id)
                                  .update({
                                "status": "Cancelled",
                                "cancelledAt": FieldValue.serverTimestamp(),
                              });
                            },
                            child: const Text(
                              "Cancel",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
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