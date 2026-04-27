import 'package:flutter/material.dart';
import 'package:reusex/screens/main_navigation/categories/categories_page.dart';
import 'package:reusex/screens/main_navigation/product_view/product_view.dart';
import 'package:reusex/screens/main_navigation/reports/reports_screen.dart';
import '../login/admin_login.dart';
import 'approval/approval_screen.dart';
import 'dashboard/admin_dashboard.dart';

class AdminDrawer extends StatelessWidget {
  const AdminDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white, // Drawer background
      child: ListView(
        padding: EdgeInsets.zero,
        children: [

          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFD6D9F7),
                  Color(0xFF6A5AE0),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                "ReUseX Admin",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.dashboard, color: Color(0xFF4A4A4A)),
            title: const Text(
              "Dashboard",
              style: TextStyle(color: Color(0xFF2E2E2E)),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminDashboard(),
                ),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF4A4A4A)),
            title: const Text(
              "Products",
              style: TextStyle(color: Color(0xFF2E2E2E)),
            ),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProductView(),
                ),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.add_box, color: Color(0xFF4A4A4A)),
            title: const Text(
              "Categories",
              style: TextStyle(color: Color(0xFF2E2E2E)),
            ),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const CategoriesPage(),
                ),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.event_note, color: Color(0xFF4A4A4A)),
            title: const Text(
              "Approval",
              style: TextStyle(color: Color(0xFF2E2E2E)),
            ),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const ApprovalScreen(),
                ),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.bar_chart, color: Color(0xFF4A4A4A)),
            title: const Text(
              "Reports",
              style: TextStyle(color: Color(0xFF2E2E2E)),
            ),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const ReportsScreen(),
                ),
              );
            },
          ),

          const Divider(color: Colors.grey),

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              "Logout",
              style: TextStyle(color: Colors.red),
            ),
            onTap: () {
              Navigator.pop(context);

              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  title: const Text("Logout"),
                  content: const Text("Are you sure you want to logout?"),
                  actions: [

                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text("Cancel"),
                    ),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminLogin(),
                          ),
                              (route) => false,
                        );
                      },
                      child: const Text("Logout"),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}