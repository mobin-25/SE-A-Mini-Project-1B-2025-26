import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import 'admin_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        centerTitle: true,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get(),
        builder: (context, snapshot) {
          // ⏳ Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // ❌ If no data exists
          if (!snapshot.hasData || snapshot.data!.data() == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("No user data found"),
                  const SizedBox(height: 10),

                  ElevatedButton(
                    onPressed: () async {
                      // 🔥 Create missing user data
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .set({
                        'name': 'New User',
                        'email': user.email,
                      });

                      // Refresh screen
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProfileScreen(),
                        ),
                      );
                    },
                    child: const Text("Fix Profile"),
                  ),
                ],
              ),
            );
          }

          // ✅ SAFE DATA
          final data =
              snapshot.data!.data() as Map<String, dynamic>;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 20),

                const CircleAvatar(
                  radius: 50,
                  child: Icon(Icons.person, size: 50),
                ),

                const SizedBox(height: 20),

                Text(
                  data['name'] ?? 'No Name',
                  style: const TextStyle(fontSize: 20),
                ),

                Text(
                  user.email ?? '',
                  style: const TextStyle(color: Colors.grey),
                ),

                const SizedBox(height: 40),

                // 👨‍💼 ADMIN BUTTON
                if (user.email == "admin@gmail.com") ...[
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminScreen(),
                        ),
                      );
                    },
                    child: const Text("Admin Panel"),
                  ),
                  const SizedBox(height: 20),
                ],

                // 🚪 LOGOUT
                ElevatedButton.icon(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();

                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text("Logout"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}