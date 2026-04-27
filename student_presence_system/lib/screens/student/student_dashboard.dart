import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../login_screen.dart';
import 'student_report_screen.dart';
import 'student_subjects_screen.dart';
import '../../services/notification_service.dart';

class StudentDashboard extends StatefulWidget {
  final String studentId;      // roll_no
  final String studentName;
  final String division;

  const StudentDashboard({
    super.key,
    required this.studentId,
    required this.studentName,
    required this.division,
  });

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  // Premium Colors from your design
  final Color _primaryBlue = const Color(0xFF253BFF); // Deep royal blue
  final Color _bgGray = const Color(0xFFF4F7FE);
  final Color _textDark = const Color(0xFF1E293B);

  @override
  void initState() {
    super.initState();
    // Use a post-frame callback to ensure the UI is fully loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAttendance();
    });
  }

  Future<void> _checkAttendance() async {
    // 🔥 Give the OS 1 second to register the notification channel after login
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      // This calls the logic that checks the 75% threshold
      await NotificationService.checkAttendanceAndNotify(
        widget.studentId,
        widget.studentId,
      );
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
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
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
      }
    }
  }

  void _navToReport() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentReportScreen(
          studentId: widget.studentId,
          uid: FirebaseAuth.instance.currentUser?.uid ?? '',
          division: widget.division,
        ),
      ),
    );
  }

  void _navToSubjects() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentSubjectsScreen(
          studentId: widget.studentId,
          division: widget.division,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgGray,
      body: FutureBuilder<QuerySnapshot>(
        // Fetching all records to calculate accurate stats
          future: FirebaseFirestore.instance
              .collection('attendance')
              .where('roll_no', isEqualTo: widget.studentId)
              .orderBy('date', descending: true)
              .get(),
          builder: (context, snapshot) {

            bool isLoading = snapshot.connectionState == ConnectionState.waiting;
            List<QueryDocumentSnapshot> docs = snapshot.hasData ? snapshot.data!.docs : [];

            // Calculate Stats
            int totalClasses = docs.length;
            int presentCount = docs.where((doc) => (doc.data() as Map<String, dynamic>)['status'] == 'Present').length;
            int absentCount = totalClasses - presentCount;
            double percentage = totalClasses > 0 ? (presentCount / totalClasses) * 100 : 0.0;

            return LayoutBuilder(
              builder: (context, constraints) {
                bool isDesktop = constraints.maxWidth > 900;

                if (isDesktop) {
                  return Row(
                    children: [
                      _buildSidebar(),
                      Expanded(
                        child: Column(
                          children: [
                            _buildDesktopHeader(),
                            Expanded(
                              child: isLoading
                                  ? const Center(child: CircularProgressIndicator())
                                  : _buildMainContent(docs, totalClasses, presentCount, absentCount, percentage, isDesktop),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }

                // MOBILE LAYOUT
                return Column(
                  children: [
                    _buildMobileAppBar(),
                    Expanded(
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _buildMainContent(docs, totalClasses, presentCount, absentCount, percentage, isDesktop),
                    ),
                  ],
                );
              },
            );
          }
      ),
    );
  }

  // ==================== SIDEBAR (DESKTOP) ====================
  Widget _buildSidebar() {
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
                  decoration: BoxDecoration(color: _primaryBlue, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.school, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Smart Student", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textDark), overflow: TextOverflow.ellipsis),
                      Text("Student Dashboard", style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    ],
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.dashboard_rounded, color: _primaryBlue, size: 22),
                const SizedBox(width: 16),
                Text("Dashboard", style: TextStyle(color: _primaryBlue, fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
          ),
          InkWell(
            onTap: _navToSubjects,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(Icons.book, color: Colors.grey.shade500, size: 22),
                  const SizedBox(width: 16),
                  Text("Subjects & Notes", style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w500, fontSize: 15)),
                ],
              ),
            ),
          ),
          const Spacer(),
          const Divider(),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: Colors.orange.shade100,
              child: Text(widget.studentName.isNotEmpty ? widget.studentName[0].toUpperCase() : 'S', style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.bold)),
            ),
            title: Text(widget.studentName, style: TextStyle(fontWeight: FontWeight.bold, color: _textDark, fontSize: 14)),
            subtitle: Text("Roll No: ${widget.studentId}", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            trailing: IconButton(icon: const Icon(Icons.logout, color: Colors.grey), onPressed: () => _handleLogout(context)),
          ),
        ],
      ),
    );
  }

  // ==================== HEADERS ====================
  Widget _buildDesktopHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 16),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Attendance Dashboard", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _textDark)),
              const SizedBox(height: 4),
              Text("Welcome back, view your attendance statistics and records below.", style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
            ],
          ),
          const Spacer(),
          Container(
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade200)),
            child: IconButton(icon: const Icon(Icons.notifications_none, color: Colors.grey), onPressed: () {}),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: _navToReport,
            icon: const Icon(Icons.assessment, size: 18),
            label: const Text("View Full Report"),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Dashboard", style: TextStyle(color: _textDark, fontWeight: FontWeight.bold, fontSize: 18)),
          Text("Welcome, ${widget.studentName}", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        ],
      ),
      actions: [
        IconButton(icon: Icon(Icons.book, color: _primaryBlue), onPressed: _navToSubjects, tooltip: "Subjects & Notes"),
        IconButton(icon: Icon(Icons.assessment, color: _primaryBlue), onPressed: _navToReport, tooltip: "Reports"),
        IconButton(icon: const Icon(Icons.logout, color: Colors.grey), onPressed: () => _handleLogout(context)),
      ],
    );
  }

  // ==================== MAIN CONTENT AREA ====================
  Widget _buildMainContent(List<QueryDocumentSnapshot> docs, int total, int present, int absent, double pct, bool isDesktop) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 32 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. STATS ROW
          if (isDesktop)
            Row(
              children: [
                Expanded(child: _buildStatCard("Total Classes", total.toString(), Icons.class_, Colors.blue, "+2 this week")),
                const SizedBox(width: 20),
                Expanded(child: _buildStatCard("Present", present.toString(), Icons.check_circle_outline, Colors.green, "Keeping up well")),
                const SizedBox(width: 20),
                Expanded(child: _buildStatCard("Absent", absent.toString(), Icons.cancel_outlined, Colors.red, "Needs attention")),
                const SizedBox(width: 20),
                Expanded(child: _buildStatCard("Attendance %", "${pct.toStringAsFixed(1)}%", Icons.pie_chart_outline, _primaryBlue, "", isPercentage: true)),
              ],
            )
          else
            Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildStatCard("Total", total.toString(), Icons.class_, Colors.blue, "")),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatCard("Present", present.toString(), Icons.check_circle_outline, Colors.green, "")),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildStatCard("Absent", absent.toString(), Icons.cancel_outlined, Colors.red, "")),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatCard("Att. %", "${pct.toStringAsFixed(1)}%", Icons.pie_chart_outline, _primaryBlue, "", isPercentage: true)),
                  ],
                ),
              ],
            ),

          const SizedBox(height: 24),

          // 2. PROFILE & RECORDS
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      _buildProfileCard(pct),
                      const SizedBox(height: 24),
                      _buildAcademicSummaryCard(),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 2, 
                  child: Column(
                    children: [
                      _buildRecordsCard(docs),
                      const SizedBox(height: 24),
                      _buildOverallAttendanceCard(docs),
                    ],
                  ),
                ),
              ],
            )
          else
            Column(
              children: [
                _buildProfileCard(pct),
                const SizedBox(height: 24),
                _buildAcademicSummaryCard(),
                const SizedBox(height: 24),
                _buildRecordsCard(docs),
                const SizedBox(height: 24),
                _buildOverallAttendanceCard(docs),
              ],
            )
        ],
      ),
    );
  }

  // --- ACADEMIC SUMMARY CARD ---
  Widget _buildAcademicSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_stories_rounded, color: _primaryBlue, size: 20),
                  const SizedBox(width: 10),
                  Text("Academic Performance", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textDark)),
                ],
              ),
              GestureDetector(
                onTap: _navToReport,
                child: Text("Details", style: TextStyle(color: _primaryBlue, fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('exam_marks')
                .where('roll_no', isEqualTo: widget.studentId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: LinearProgressIndicator());
              
              final marksDocs = snapshot.data?.docs ?? [];
              if (marksDocs.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: Text("No marks published yet", style: TextStyle(color: Colors.grey.shade500, fontSize: 13))),
                );
              }

              return Column(
                children: marksDocs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final String subject = data['subject'] ?? 'Unknown';
                  final double ut1 = double.tryParse(data['ut1'].toString()) ?? 0;
                  final double ut2 = double.tryParse(data['ut2'].toString()) ?? 0;
                  final double sem = double.tryParse(data['sem_exam'].toString()) ?? 0;
                  final double total = ut1 + ut2 + sem;
                  final double pct = total / 140.0;
                  
                  Color scoreColor = pct >= 0.75 ? Colors.green : pct >= 0.5 ? Colors.orange : Colors.red;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(subject, style: TextStyle(color: _textDark, fontWeight: FontWeight.w600, fontSize: 14), overflow: TextOverflow.ellipsis),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: scoreColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                          child: Text(
                            "${total.toInt()}/140",
                            style: TextStyle(color: scoreColor, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- STAT CARD ---
  Widget _buildStatCard(String title, String value, IconData icon, Color color, String subtitle, {bool isPercentage = false}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600, fontSize: 13)),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 18),
              )
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _textDark)),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.trending_up, color: color, size: 14),
                const SizedBox(width: 4),
                Text(subtitle, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            )
          ],
          if (isPercentage) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: double.parse(value.replaceAll('%', '')) / 100,
              backgroundColor: color.withValues(alpha: 0.1),
              color: color,
              minHeight: 6,
              borderRadius: BorderRadius.circular(10),
            )
          ]
        ],
      ),
    );
  }

  // --- PROFILE CARD ---
  Widget _buildProfileCard(double pct) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        children: [
          // Blue Header Top Half
          Container(
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [_primaryBlue, const Color(0xFF6366F1)]),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
          ),
          // Avatar overlapping
          Transform.translate(
            offset: const Offset(0, -40),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.orange.shade100,
                    child: Text(widget.studentName.isNotEmpty ? widget.studentName[0].toUpperCase() : 'S', style: TextStyle(fontSize: 32, color: Colors.orange.shade800, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 8),
                Text(widget.studentName, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _textDark)),
                Text("Computer Science Department", style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),

                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(color: _bgGray, borderRadius: BorderRadius.circular(12)),
                          child: Column(
                            children: [
                              Text("ROLL NO", style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(widget.studentId, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textDark)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(color: _bgGray, borderRadius: BorderRadius.circular(12)),
                          child: Column(
                            children: [
                              Text("DIVISION", style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(widget.division, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textDark)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Semester Progress", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700, fontSize: 13)),
                          Text("${pct.toStringAsFixed(0)}%", style: TextStyle(fontWeight: FontWeight.bold, color: _primaryBlue)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: pct / 100,
                        backgroundColor: _bgGray,
                        color: _primaryBlue,
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          )
        ],
      ),
    );
  }

  // --- RECORDS TABLE / LIST ---
  Widget _buildRecordsCard(List<QueryDocumentSnapshot> docs) {
    // Show only recent 10 max
    final recentDocs = docs.take(10).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, color: _primaryBlue),
              const SizedBox(width: 12),
              Text("Recent Attendance Records", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textDark)),
            ],
          ),
          const SizedBox(height: 24),

          if (recentDocs.isEmpty)
            Center(child: Padding(padding: const EdgeInsets.all(32), child: Text("No records found", style: TextStyle(color: Colors.grey.shade500))))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentDocs.length,
              separatorBuilder: (context, index) => Divider(color: Colors.grey.shade100, height: 24),
              itemBuilder: (context, index) {
                final data = recentDocs[index].data() as Map<String, dynamic>;

                DateTime date = DateTime.now();
                if (data['date'] is Timestamp) {
                  date = (data['date'] as Timestamp).toDate();
                }

                final String subject = data['subject'] ?? 'Unknown';
                final bool isPresent = data['status'] == 'Present';

                return LayoutBuilder(
                  builder: (context, constraints) {
                    bool isMobile = !kIsWeb && constraints.maxWidth < 600;
                    
                    Widget statusPill = Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isPresent ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isPresent ? "Present" : "Absent",
                        style: TextStyle(
                          color: isPresent ? Colors.green.shade700 : Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    );

                    if (isMobile) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Text(subject, style: TextStyle(fontWeight: FontWeight.w600, color: _textDark, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis)),
                              statusPill,
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(DateFormat('MMM dd, yyyy • hh:mm a').format(date), style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w500)),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(subject, style: TextStyle(fontWeight: FontWeight.w600, color: _textDark, fontSize: 14)),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(DateFormat('MMM dd, yyyy • hh:mm a').format(date), style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                        ),
                        statusPill,
                      ],
                    );
                  }
                );
              },
            ),

          const SizedBox(height: 24),
          Center(
            child: TextButton(
              onPressed: _navToReport,
              child: Text("Show all records →", style: TextStyle(color: _primaryBlue, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
  // --- OVERALL ATTENDANCE CARD ---
  Widget _buildOverallAttendanceCard(List<QueryDocumentSnapshot> docs) {
    // 1. Group by subject
    Map<String, int> totalClassesPerSubject = {};
    Map<String, int> presentClassesPerSubject = {};

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final subject = data['subject'] as String? ?? 'Unknown';
      final status = data['status'] as String? ?? 'Absent';

      totalClassesPerSubject[subject] = (totalClassesPerSubject[subject] ?? 0) + 1;
      if (status == 'Present') {
        presentClassesPerSubject[subject] = (presentClassesPerSubject[subject] ?? 0) + 1;
      }
    }

    final subjects = totalClassesPerSubject.keys.toList()..sort();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart_outline, color: _primaryBlue),
              const SizedBox(width: 12),
              Text("Overall Attendance", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textDark)),
            ],
          ),
          const SizedBox(height: 24),

          if (subjects.isEmpty)
            Center(child: Padding(padding: const EdgeInsets.all(32), child: Text("No attendance data found", style: TextStyle(color: Colors.grey.shade500))))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: subjects.length,
              separatorBuilder: (context, index) => const Divider(height: 24),
              itemBuilder: (context, index) {
                final subject = subjects[index];
                final total = totalClassesPerSubject[subject]!;
                final present = presentClassesPerSubject[subject] ?? 0;
                final percentage = total > 0 ? (present / total) * 100 : 0.0;
                
                Color scoreColor = percentage >= 75 ? Colors.green : percentage >= 50 ? Colors.orange : Colors.red;

                return Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(subject, style: TextStyle(fontWeight: FontWeight.w600, color: _textDark, fontSize: 14)),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text("$present / $total", style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: scoreColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "${percentage.toStringAsFixed(1)}%",
                        style: TextStyle(
                          color: scoreColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}