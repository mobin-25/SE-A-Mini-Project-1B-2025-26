import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TeacherProfileScreen extends StatefulWidget {
  const TeacherProfileScreen({super.key});

  @override
  State<TeacherProfileScreen> createState() => _TeacherProfileScreenState();
}

class _TeacherProfileScreenState extends State<TeacherProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text("My Profile", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          StreamBuilder<DocumentSnapshot>(
            // ✅ FIX 1: Path changed to 'teachers'
            stream: FirebaseFirestore.instance.collection('teachers').doc(currentUserId).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || !snapshot.data!.exists) return const SizedBox();
              var data = snapshot.data!.data() as Map<String, dynamic>;
              return IconButton(
                icon: const Icon(Icons.edit_note, size: 28),
                tooltip: "Edit Profile",
                onPressed: () => _showEditDialog(context, currentUserId, data),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        // ✅ FIX 2: Path changed to 'teachers'
        stream: FirebaseFirestore.instance.collection('teachers').doc(currentUserId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Teacher data not found in 'teachers' collection"));
          }

          var data = snapshot.data!.data() as Map<String, dynamic>;
          String name = data['name'] ?? 'Not Set';
          String tId = data['t_id'] ?? 'Not Set';
          String divisions = data['division_assigned'] ?? 'Not Set';
          String subjects = data['subjects_assigned'] ?? 'Not Set';

          String initials = name.isNotEmpty
              ? name.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
              : 'T';

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(bottom: 40, top: 20),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade700,
                    borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                        child: CircleAvatar(
                          radius: 55,
                          backgroundColor: Colors.white,
                          child: Text(
                            initials,
                            style: TextStyle(fontSize: 40, color: Colors.teal.shade700, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                        child: Text("ID: $tId", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                ),

                Transform.translate(
                  offset: const Offset(0, -20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 15, offset: const Offset(0, 5))],
                      ),
                      child: Column(
                        children: [
                          _buildProfileItem(Icons.class_, "Divisions Assigned", divisions, Colors.blue),
                          const Divider(height: 30),
                          _buildProfileItem(Icons.menu_book, "Subjects Assigned", subjects, Colors.indigo),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[500], fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
            ],
          ),
        ),
      ],
    );
  }

  void _showEditDialog(BuildContext context, String uid, Map<String, dynamic> data) {
    final nameC = TextEditingController(text: data['name']);
    final tIdC = TextEditingController(text: data['t_id']);
    final divC = TextEditingController(text: data['division_assigned']);
    final subC = TextEditingController(text: data['subjects_assigned']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Edit Profile", style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(nameC, "Full Name", Icons.person),
              const SizedBox(height: 12),
              _buildTextField(tIdC, "Teacher ID", Icons.badge),
              const SizedBox(height: 12),
              _buildTextField(divC, "Divisions (e.g. A, B)", Icons.class_),
              const SizedBox(height: 12),
              _buildTextField(subC, "Subjects", Icons.menu_book),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              // ✅ FIX 3: Update target changed to 'teachers'
              await FirebaseFirestore.instance.collection('teachers').doc(uid).update({
                'name': nameC.text.trim(),
                't_id': tIdC.text.trim(),
                'division_assigned': divC.text.trim(),
                'subjects_assigned': subC.text.trim(),
              });
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Profile Updated Successfully!"), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
                );
              }
            },
            child: const Text("Save Changes"),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.teal.shade700),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.teal.shade700, width: 2),
        ),
      ),
    );
  }
}