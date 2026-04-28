import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../login_screen.dart';
import 'attendance_screen.dart';
import 'subject_list_screen.dart';
import 'attendance_report_screen.dart';
import 'teacher_profile_screen.dart';
import '../../services/csv_service.dart';
import 'widgets/division_manager_card.dart';
import 'widgets/subjects_card.dart';
import 'examination_marks_screen.dart';

// --- PREMIUM COLOR PALETTE ---
const Color _primaryColor = Color(0xFF00483E); // Deep Teal
const Color _bgColor = Color(0xFFF8FAFB);
const Color _surfaceLow = Color(0xFFF2F4F5);
const Color _secondaryFixed = Color(0xFFCFE6F2); // Light Blue
const Color _textDark = Color(0xFF191C1D);
const Color _textLight = Color(0xFF526772);

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  int _selectedIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    _screens = [
      _TeacherHomeScreen(uid: currentUserId, primaryColor: _primaryColor),
      const AttendanceScreen(),
      SubjectListScreen(),
      const AttendanceReportScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _handleLogout(BuildContext context) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  // 🔥 MASTER UPLOAD LOGIC FOR THE SIDEBAR BUTTON 🔥
  Future<void> _handleMasterUpload(BuildContext context) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.upload_file, color: _primaryColor, size: 28),
            SizedBox(width: 10),
            Text("Master Upload", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          "Upload the full student list Excel file.\n\n"
              "This creates Firebase Auth accounts for all students.\n"
              "Division will be assigned separately via each Division tile.",
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Select File"),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Row(
          children: [
            const CircularProgressIndicator(color: _primaryColor),
            const SizedBox(width: 20),
            const Expanded(
              child: Text(
                "Creating student accounts...\nThis may take 1–2 minutes.",
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );

    final result = await CsvService.uploadStudentsFromFile();

    if (context.mounted) Navigator.pop(context); // Close loading dialog

    if (context.mounted) {
      final bool success = result.startsWith('✅');
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(
                success ? Icons.check_circle : Icons.error_outline,
                color: success ? Colors.green : Colors.red,
                size: 28,
              ),
              const SizedBox(width: 10),
              Text(success ? "Upload Complete" : "Upload Failed", style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: success ? Colors.green.shade50 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(result, style: const TextStyle(fontSize: 14)),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (kIsWeb || constraints.maxWidth > 800) {
          return Scaffold(
            backgroundColor: _bgColor,
            body: Row(
              children: [
                _buildDesktopSidebar(),
                Expanded(
                  child: Column(
                    children: [
                      _buildDesktopHeader(),
                      Expanded(child: ClipRRect(child: _screens[_selectedIndex])),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        // Mobile Layout
        return Scaffold(
          backgroundColor: _bgColor,
          appBar: _selectedIndex == 0
              ? AppBar(
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            leading: const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircleAvatar(backgroundColor: Colors.white24, child: Icon(Icons.person, color: Colors.white, size: 20)),
            ),
            title: const Text("Teacher Portal", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            titleSpacing: 0,
            actions: [IconButton(onPressed: () => _handleLogout(context), icon: const Icon(Icons.logout))],
          )
              : null,
          body: _screens[_selectedIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            selectedItemColor: _primaryColor,
            unselectedItemColor: Colors.grey.shade400,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.how_to_reg), label: 'Attendance'),
              BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Subjects'),
              BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Reports'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDesktopSidebar() {
    return Container(
      width: 260,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: _primaryColor, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.auto_stories, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Smart Student", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: _primaryColor), overflow: TextOverflow.ellipsis, maxLines: 1),
                      Text("ADMIN MANAGEMENT", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 1)),
                    ],
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSidebarItem(0, Icons.account_circle, "Teacher Profile"),
          _buildSidebarItem(1, Icons.calendar_today, "Attendance"),
          _buildSidebarItem(2, Icons.menu_book, "Subjects"),
          _buildSidebarItem(3, Icons.analytics, "Reports"),
          const Spacer(),

          Padding(
            padding: const EdgeInsets.all(24.0),
            child: ElevatedButton.icon(
              onPressed: () => _handleMasterUpload(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text("Add New Record"),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          _buildSidebarItem(99, Icons.logout, "Logout", isLogout: true),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(int index, IconData icon, String title, {bool isLogout = false}) {
    bool isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => isLogout ? _handleLogout(context) : _onItemTapped(index),
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: isSelected ? _primaryColor : Colors.transparent, width: 4)),
          color: isSelected ? _bgColor : Colors.transparent,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? _primaryColor : (isLogout ? Colors.red : _textLight), size: 22),
            const SizedBox(width: 16),
            Text(title, style: TextStyle(color: isSelected ? _primaryColor : (isLogout ? Colors.red : _textLight), fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopHeader() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 48),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.8), border: const Border(bottom: BorderSide(color: Colors.black12))),
      child: Row(
        children: [
          Container(
            width: 350,
            height: 40,
            decoration: BoxDecoration(color: _surfaceLow, borderRadius: BorderRadius.circular(20)),
            child: TextField(
              decoration: InputDecoration(hintText: "Search academic records...", hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13), prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 10)),
            ),
          ),
          const Spacer(),
          const Icon(Icons.notifications, color: Colors.grey),
          const SizedBox(width: 16),
          const Icon(Icons.settings, color: Colors.grey),
          const SizedBox(width: 24),
          Container(width: 1, height: 30, color: Colors.grey.shade300),
          const SizedBox(width: 24),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text("Academic Curator", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _primaryColor)),
              Text("SUPPORT", style: TextStyle(fontSize: 10, color: Colors.grey.shade500, letterSpacing: 1)),
            ],
          ),
          const SizedBox(width: 12),
          CircleAvatar(backgroundColor: _secondaryFixed, child: const Icon(Icons.admin_panel_settings, color: _primaryColor)),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  Examination Marks Button Widget
// ══════════════════════════════════════════════════════════════
class _ExaminationMarksButton extends StatelessWidget {
  final List<String> divisions;

  const _ExaminationMarksButton({required this.divisions});

  void _open(BuildContext context) {
    if (divisions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a division first.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (divisions.length == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ExaminationMarksScreen(division: divisions.first),
        ),
      );
      return;
    }

    // Multiple divisions → picker dialog
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.edit_note, color: _primaryColor),
            SizedBox(width: 10),
            Text('Select Division',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: divisions
              .map(
                (d) => ListTile(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor: _primaryColor.withValues(alpha: 0.1),
                    child: Text(d,
                        style: const TextStyle(
                            color: _primaryColor,
                            fontWeight: FontWeight.bold)),
                  ),
                  title: Text('Division $d',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.arrow_forward_ios,
                      size: 14, color: Colors.grey),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ExaminationMarksScreen(division: d),
                      ),
                    );
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _open(context),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _primaryColor.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 16,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.edit_note,
                  color: _primaryColor, size: 26),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Examination Marks',
                    style: TextStyle(
                        color: _primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Enter UT-I, UT-II, Sem-I & Sem-II marks for students',
                    style: TextStyle(color: _textLight, fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.arrow_forward_ios,
                  color: _primaryColor, size: 14),
            ),
          ],
        ),
      ),
    );
  }
}


// ══════════════════════════════════════════════════════════════
//  HOME TAB CONTENT
// ══════════════════════════════════════════════════════════════
class _TeacherHomeScreen extends StatelessWidget {
  final String uid;
  final Color primaryColor;

  const _TeacherHomeScreen({required this.uid, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('teachers').doc(uid).snapshots(),
      builder: (context, snapshot) {
        String name = "Teacher";
        String initials = "T";
        String subjectsAssigned = "No subjects assigned";
        String email = "No email provided";
        String tId = "T-XXXX";

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          name = data['name'] ?? "Teacher";
          initials = name.isNotEmpty ? name[0].toUpperCase() : "T";
          subjectsAssigned = data['subjects_assigned'] ?? "No subjects assigned";
          email = data['email'] ?? "No email provided";
          tId = data['t_id'] ?? "T-XXXX";
        }

        bool isDesktop = kIsWeb || MediaQuery.of(context).size.width > 800;
        return isDesktop
            ? _buildDesktopProfile(context, name, initials, subjectsAssigned, email, tId)
            : _buildMobileProfile(context, name, initials, subjectsAssigned);
      },
    );
  }

  Widget _buildDesktopProfile(BuildContext context, String name, String initials, String subjectsAssigned, String email, String tId) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(48.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Premium Top Profile Card ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(40),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 20, offset: const Offset(0, 5))],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF84D5C5), width: 6)),
                      child: CircleAvatar(radius: 50, backgroundColor: _bgColor, child: Text(initials, style: const TextStyle(fontSize: 36, color: _primaryColor, fontWeight: FontWeight.bold))),
                    ),
                    Positioned(bottom: 4, right: 4, child: Container(width: 20, height: 20, decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)))),
                  ],
                ),
                const SizedBox(width: 32),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: _primaryColor)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.school, size: 16, color: _textLight),
                                  const SizedBox(width: 8),
                                  Text("Senior Educator • $tId", style: TextStyle(fontSize: 14, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                                ],
                              )
                            ],
                          ),
                          Row(
                            children: [
                              ElevatedButton(
                                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TeacherProfileScreen())),
                                style: ElevatedButton.styleFrom(backgroundColor: _secondaryFixed, foregroundColor: _primaryColor, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
                                child: const Text("Edit Profile", style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ],
                          )
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          _buildInfoChip("CONTACT EMAIL", email),
                          const SizedBox(width: 16),
                          _buildInfoChip("OFFICE NUMBER", "+1 (555) 234-8901"),
                          const SizedBox(width: 16),
                          _buildInfoChip("EXPERIENCE", "12 Years Tenured", isHighlighted: true),
                        ],
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 32),

          // ── Bottom Section: Your Custom Cards ──
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('settings').doc('divisions').snapshots(),
            builder: (context, divSnapshot) {
              List<String> divisions = [];
              if (divSnapshot.hasData && divSnapshot.data!.exists) {
                final List<dynamic> divs = (divSnapshot.data!.data() as Map<String, dynamic>)['list'] ?? [];
                divisions = divs.map((e) => e.toString()).toList()..sort();
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(flex: 5, child: DivisionManagerCard()),
                      const SizedBox(width: 32),
                      Expanded(flex: 7, child: SubjectsCard(divisions: divisions)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _ExaminationMarksButton(divisions: divisions),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, {bool isHighlighted = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: _surfaceLow, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 1)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isHighlighted ? _primaryColor : _textDark), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  // ── MOBILE PROFILE ──
  Widget _buildMobileProfile(BuildContext context, String name, String initials, String subjectsAssigned) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 60),
            decoration: const BoxDecoration(
              color: _primaryColor,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 46,
                  backgroundColor: Colors.white,
                  child: Text(initials, style: const TextStyle(fontSize: 36, color: _primaryColor, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 16),
                Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center),
                const SizedBox(height: 4),
                const Text("Senior Educator", style: TextStyle(color: Colors.white70, fontSize: 13, letterSpacing: 1.1)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                  child: Text(subjectsAssigned, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TeacherProfileScreen())),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: _primaryColor, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                  child: const Text("Edit Profile", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -32),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const DivisionManagerCard(),
                  const SizedBox(height: 16),
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance.collection('settings').doc('divisions').snapshots(),
                    builder: (context, divSnapshot) {
                      List<String> divisions = [];
                      if (divSnapshot.hasData && divSnapshot.data!.exists) {
                        final List<dynamic> divs = (divSnapshot.data!.data() as Map<String, dynamic>)['list'] ?? [];
                        divisions = divs.map((e) => e.toString()).toList()..sort();
                      }
                      return SubjectsCard(divisions: divisions);
                    },
                  ),
                  const SizedBox(height: 16),
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance.collection('settings').doc('divisions').snapshots(),
                    builder: (context, divSnapshot) {
                      List<String> divisions = [];
                      if (divSnapshot.hasData && divSnapshot.data!.exists) {
                        final List<dynamic> divs = (divSnapshot.data!.data() as Map<String, dynamic>)['list'] ?? [];
                        divisions = divs.map((e) => e.toString()).toList()..sort();
                      }
                      return _ExaminationMarksButton(divisions: divisions);
                    },
                  ),
                  const SizedBox(height: 16),
                  // ── Add New Record Button (mobile) ──
                  Builder(
                    builder: (ctx) => ElevatedButton.icon(
                      onPressed: () {
                        // Walk up to find the TeacherDashboard state
                        final scaffold = ctx.findAncestorStateOfType<_TeacherDashboardState>();
                        if (scaffold != null) {
                          scaffold._handleMasterUpload(ctx);
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: const Text("Add New Record", style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}