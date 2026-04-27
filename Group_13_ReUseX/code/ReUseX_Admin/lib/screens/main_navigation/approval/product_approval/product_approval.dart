import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:reusex/screens/main_navigation/approval/product_approval/phone_approval_details/phone_approval_details.dart';

class PhoneApprovalPage extends StatelessWidget {
  const PhoneApprovalPage({super.key});

  String getDisplayTitle(Map<String, dynamic> data) {
    final title = (data['title'] ?? '').toString().trim();
    final deviceType = (data['deviceType'] ?? '').toString().trim();

    if (title.isNotEmpty &&
        title != 'Phone Sell Request' &&
        title != 'Laptop Sell Request' &&
        title != 'Other Item Sell Request') {
      return title;
    }

    switch (deviceType.toLowerCase()) {
      case 'phone':
        return 'Phone Sell Request';
      case 'laptop':
        return 'Laptop Sell Request';
      case 'others':
        return 'Other Item Sell Request';
      default:
        return 'Sell Request';
    }
  }

  String getSubtitle(Map<String, dynamic> data) {
    final requestType = (data['requestType'] ?? '').toString().trim();
    final deviceType = (data['deviceType'] ?? '').toString().trim();
    final userName = (data['userName'] ?? '').toString().trim();

    final requestText = requestType.isEmpty
        ? ''
        : requestType[0].toUpperCase() + requestType.substring(1);

    final deviceText = deviceType.isEmpty
        ? ''
        : deviceType[0].toUpperCase() + deviceType.substring(1);

    final typeText = deviceText.isEmpty
        ? requestText
        : '$requestText • $deviceText';

    if (userName.isEmpty) return typeText;
    return '$typeText\n$userName';
  }

  IconData getDeviceIcon(String deviceType) {
    switch (deviceType.toLowerCase()) {
      case 'laptop':
        return Icons.laptop_mac;
      case 'others':
        return Icons.devices_other;
      case 'phone':
      default:
        return Icons.phone_android;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD6D9F7),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Device Approvals',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Lora',
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFF8F7AE5),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('approval_requests')
            .where('status', isEqualTo: 'pending')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Something went wrong:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'No pending requests',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final title = getDisplayTitle(data);
              final subtitle = getSubtitle(data);

              // 🔥 FIXED LINE (SAFE)
              final imageUrl =
              (data['imageUrl'] ?? '').toString().trim();

              final deviceType =
              (data['deviceType'] ?? '').toString();

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.07),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: imageUrl.isNotEmpty
                            ? Image.network(
                          imageUrl,
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 90,
                            height: 90,
                            color: const Color(0xFFD6D9F7),
                            child: Icon(
                              getDeviceIcon(deviceType),
                              color: const Color(0xFF5B6CFF),
                              size: 36,
                            ),
                          ),
                        )
                            : Container(
                          width: 90,
                          height: 90,
                          color: const Color(0xFFD6D9F7),
                          child: Icon(
                            getDeviceIcon(deviceType),
                            color: const Color(0xFF5B6CFF),
                            size: 36,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              subtitle,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 10),

                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PhoneDetailPage(
                                      docId: doc.id,
                                      requestData: data,
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8F7AE5),
                              ),
                              child: const Text("View More"),
                            ),
                          ],
                        ),
                      ),
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