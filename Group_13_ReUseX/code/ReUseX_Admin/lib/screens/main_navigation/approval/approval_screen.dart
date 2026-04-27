import 'package:flutter/material.dart';
import 'package:reusex/screens/main_navigation/approval/product_approval/product_approval.dart';
import 'package:reusex/screens/main_navigation/approval/recycle_approval/recycle_approval.dart';
import '../../../widgets/constants/approval_widgets.dart';
import '../main_navigation.dart';

class ApprovalScreen extends StatelessWidget {
  const ApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AdminDrawer(),
      backgroundColor: Color(0xFFD6D9F7),
      appBar: AppBar(
        title: const Text(
          "Approval Section",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xFF8F7AE5),
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

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 5),
            ApprovalCard(
              icon: Icons.recycling,
              title: "Recycle Approvals",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ApprovalPage(),
                  ),
                );
              },
            ),

            const SizedBox(height: 25),

            ApprovalCard(
              icon: Icons.inventory_2,
              title: "Product Approvals",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PhoneApprovalPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}