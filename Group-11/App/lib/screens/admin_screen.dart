import 'package:flutter/material.dart';
import 'admin_appointments_screen.dart';
import 'admin_requests_screen.dart';
class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  Widget buildCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Container(
          height: 120,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: color.withOpacity(0.1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
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
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        backgroundColor: Colors.teal,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// 🔥 HEADER
            const Text(
              "Welcome Admin 👋",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            /// 📊 GRID
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                children: [

                  /// 🐶 Adoption Requests
                  buildCard(
                    title: "Adoption Requests",
                    icon: Icons.pets,
                    color: Colors.orange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminRequestsScreen(),
                        ),
                      );
                    },
                  ),

                  /// 🏥 Vet Appointments
                  buildCard(
                    title: "Vet Appointments",
                    icon: Icons.calendar_today,
                    color: Colors.teal,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminAppointmentsScreen(),
                        ),
                      );
                    },
                  ),

                  /// ➕ Add Pet (optional)
                  buildCard(
                    title: "Add Pet",
                    icon: Icons.add,
                    color: Colors.green,
                    onTap: () {
                      // connect later if needed
                    },
                  ),

                  /// 🛒 Add Product (optional)
                  buildCard(
                    title: "Add Product",
                    icon: Icons.shopping_cart,
                    color: Colors.blue,
                    onTap: () {
                      // connect later if needed
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}