import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:reusex/screens/login/login.dart';
import 'package:reusex/screens/profile_user_screen/orders_history_page.dart';
import 'package:reusex/screens/profile_user_screen/reward_points.dart';
import 'package:reusex/screens/profile_user_screen/user_requests.dart';
import 'package:reusex/widgets/profile_user/profile_info.dart';
import 'package:reusex/widgets/profile_user/profile_option_tile.dart';
import '../../firebase/auth_helper.dart';
import 'about_us_page.dart';
import 'edit_profile_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Future<void> _handleLogout() async {
    try {
      await AuthHelper.instance.logout();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const Login()),
            (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Logout failed")),
      );
    }
  }

  Widget _buildProfileAvatar(String profileImageUrl) {
    if (profileImageUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 45,
        backgroundColor: Colors.green.shade100,
        backgroundImage: NetworkImage(profileImageUrl),
      );
    }

    return CircleAvatar(
      radius: 45,
      backgroundColor: Colors.green.shade100,
      child: const Icon(
        Icons.person,
        size: 45,
        color: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text(
            "  Profile",
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Lora',
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: Colors.green,
        ),
        body: const Center(
          child: Text("User not logged in"),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          "  Profile",
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Lora',
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection("users")
            .doc(currentUser.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data?.data() as Map<String, dynamic>?;

          final userName =
          (data?["name"] ?? currentUser.displayName ?? "User").toString();

          final userEmail =
          (data?["email"] ?? currentUser.email ?? "No Email").toString();

          final profileImageUrl =
          (data?["profileImageUrl"] ?? "").toString();

          return Column(
            children: [
              const SizedBox(height: 30),
              _buildProfileAvatar(profileImageUrl),
              const SizedBox(height: 12),
              ProfileInfo(
                name: userName,
                email: userEmail,
              ),
              const SizedBox(height: 30),
              ProfileOptionTile(
                icon: Icons.info,
                title: "About Us",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AboutUsPage()),
                  );
                },
              ),
              ProfileOptionTile(
                icon: Icons.edit,
                title: "Edit Profile",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EditProfilePage(),
                    ),
                  );
                },
              ),
              ProfileOptionTile(
                icon: Icons.approval,
                title: "Approvals",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MyRequestsPage()),
                  );
                },
              ),
              ProfileOptionTile(
                icon: Icons.history,
                title: "Order History",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const OrderHistoryPage(),
                    ),
                  );
                },
              ),
              ProfileOptionTile(
                icon: Icons.star,
                title: "Reward Points",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RewardPointsPage(),
                    ),
                  );
                },
              ),
              ProfileOptionTile(
                icon: Icons.logout,
                title: "Logout",
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      title: const Text("Logout"),
                      content:
                      const Text("Are you sure you want to logout?"),
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
                          onPressed: () async {
                            Navigator.pop(context);
                            await _handleLogout();
                          },
                          child: const Text("Logout"),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}