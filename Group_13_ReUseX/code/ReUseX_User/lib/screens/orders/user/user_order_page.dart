import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../widgets/order_card/order_card.dart';

class UserOrderPage extends StatelessWidget {
  const UserOrderPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("My Orders",style: TextStyle(fontFamily: 'Lora'),),
          backgroundColor: Colors.green,
        ),
        body: const Center(
          child: Text(
            "User not logged in",
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Orders",style: TextStyle(fontFamily: 'Lora'),),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("orders")
            .where("userId", isEqualTo: userId)
            .where("status", isEqualTo: "Pending")
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

          final orders = snapshot.data?.docs ?? [];

          if (orders.isEmpty) {
            return const Center(
              child: Text(
                "No active orders",
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          return Column(
            children: [
              const SizedBox(height: 15),
              const Text(
                "Order placed successfully",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                "Waiting for Delivery",
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final doc = orders[index];
                    final data = doc.data() as Map<String, dynamic>;

                    final productName = (data["productName"] ?? "").toString();
                    final imageUrl = (data["productImage"] ?? "").toString();
                    final status = (data["status"] ?? "").toString();

                    return _OrderItem(
                      docId: doc.id,
                      productName: productName,
                      imageUrl: imageUrl,
                      status: status,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OrderItem extends StatelessWidget {
  final String docId;
  final String productName;
  final String imageUrl;
  final String status;

  const _OrderItem({
    required this.docId,
    required this.productName,
    required this.imageUrl,
    required this.status,
  });

  Future<void> _cancelOrder(BuildContext context) async {
    await FirebaseFirestore.instance.collection("orders").doc(docId).update({
      "status": "Cancelled",
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        OrderCard(
          productName: productName,
          imageUrl: imageUrl,
          status: status,
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16, bottom: 10),
          child: Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () => _cancelOrder(context),
              child: const Text("Cancel Order"),
            ),
          ),
        ),
      ],
    );
  }
}