import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/subject_service.dart';

class StudentReportScreen extends StatelessWidget {
  final String studentId; // roll_no
  final String uid;       // Firebase UID
  final String division;

  const StudentReportScreen({super.key, required this.studentId, required this.uid, required this.division});

  static const Color _primaryBlue = Color(0xFF3B1EED);
  static const Color _bgGray = Color(0xFFF4F7FE);
  static const Color _textDark = Color(0xFF1E293B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgGray,
      appBar: AppBar(
        title: const Text("Comprehensive Report", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: _textDark,
        elevation: 0,
        centerTitle: false,
      ),
      body: SafeArea(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: SubjectService.getSubjects(division),
          builder: (context, subjectSnapshot) {
            if (subjectSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (subjectSnapshot.hasError) {
              return Center(child: Text("Error loading subjects: ${subjectSnapshot.error}", style: const TextStyle(color: Colors.red)));
            }
            final allSubjectsData = subjectSnapshot.data ?? [];
            final dynamicSubjects = allSubjectsData.map((s) => s['name'] as String).toList();

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('attendance')
                  .where('roll_no', isEqualTo: studentId)
                  .snapshots(),
              builder: (context, attendanceSnapshot) {
                if (attendanceSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final attendanceDocs = attendanceSnapshot.data?.docs ?? [];

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('exam_marks')
                      .where('roll_no', isEqualTo: studentId)
                      .snapshots(),
                  builder: (context, marksSnapshot) {
                    if (marksSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    // Process Marks Data
                    Map<String, Map<String, double>> marksData = {};
                    if (marksSnapshot.hasData) {
                      for (var doc in marksSnapshot.data!.docs) {
                        final data = doc.data() as Map<String, dynamic>;
                        String subject = data['subject'] ?? 'Unknown';
                        marksData[subject] = {
                          'ut1': double.tryParse(data['ut1'].toString()) ?? 0,
                          'ut2': double.tryParse(data['ut2'].toString()) ?? 0,
                          'sem_exam': double.tryParse(data['sem_exam'].toString()) ?? 0,
                        };
                      }
                    }

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        bool isDesktop = constraints.maxWidth > 900;
                        return SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.all(isDesktop ? 32 : 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildStudentHeader(),
                              const SizedBox(height: 24),
                              if (isDesktop)
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(flex: 1, child: _buildAttendanceAnalytics(attendanceDocs, dynamicSubjects)),
                                      const SizedBox(width: 24),
                                      Expanded(flex: 2, child: _buildMarksSection(marksData, isDesktop, allSubjectsData)),
                                    ],
                                  )
                                else
                                  Column(
                                    children: [
                                      _buildAttendanceAnalytics(attendanceDocs, dynamicSubjects),
                                      const SizedBox(height: 24),
                                      _buildMarksSection(marksData, isDesktop, allSubjectsData),
                                    ],
                                  ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  // ==================== 1. STUDENT HEADER ====================
  Widget _buildStudentHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.orange.shade100,
            child: Text(studentId.isNotEmpty ? studentId[0].toUpperCase() : 'S', style: TextStyle(fontSize: 22, color: Colors.orange.shade800, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Academic Record", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textDark), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.badge_outlined, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text("Roll No: $studentId", style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
            child: Text("Status: Verified", style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 12)),
          )
        ],
      ),
    );
  }

  // ==================== 2. ATTENDANCE ANALYTICS ====================
  Widget _buildAttendanceAnalytics(List<QueryDocumentSnapshot> docs, List<String> courses) {
    int totalClasses = docs.length;
    int presentCount = docs.where((d) => (d.data() as Map)['status'] == 'Present').length;
    double overallPct = totalClasses > 0 ? (presentCount / totalClasses) * 100 : 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Attendance Analytics", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textDark)),
              const Icon(Icons.more_horiz, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 32),
          // Circular Progress
          SizedBox(
            height: 160, width: 160,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: overallPct / 100,
                  strokeWidth: 16,
                  backgroundColor: _primaryBlue.withValues(alpha: 0.1),
                  color: _primaryBlue,
                  strokeCap: StrokeCap.round,
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("${overallPct.toStringAsFixed(1)}%", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: _textDark)),
                      Text("Overall", style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                    ],
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Subject Bars
          ...courses.map((subject) {
            int total = docs.where((d) => (d.data() as Map)['subject'] == subject).length;
            int present = docs.where((d) => (d.data() as Map)['subject'] == subject && (d.data() as Map)['status'] == 'Present').length;
            double progress = total > 0 ? present / total : 0.0;
            return _buildSubjectBar(subject, progress, "$present/$total");
          }),
        ],
      ),
    );
  }

  Widget _buildSubjectBar(String title, double percentage, String fraction) {
    bool isLow = percentage < 0.75 && percentage > 0.0; // Don't turn red if no classes yet
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: _textDark, fontSize: 13), overflow: TextOverflow.ellipsis)),
              Text("$fraction Classes", style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percentage,
            backgroundColor: _primaryBlue.withValues(alpha: 0.1),
            color: isLow ? Colors.red : _primaryBlue,
            minHeight: 8,
            borderRadius: BorderRadius.circular(10),
          ),
        ],
      ),
    );
  }

  // ==================== 3. MARKS PERFORMANCE ====================
  Widget _buildMarksSection(Map<String, Map<String, double>> marksData, bool isDesktop, List<Map<String, dynamic>> allSubjectsData) {
    final sem1Subjects = allSubjectsData.where((s) => s['semester'] == 'Semester I').map((s) => s['name'] as String).toList();
    final sem2Subjects = allSubjectsData.where((s) => s['semester'] == 'Semester II').map((s) => s['name'] as String).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text("Academic Performance", style: TextStyle(fontSize: isDesktop ? 20 : 16, fontWeight: FontWeight.bold, color: _textDark), overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: _primaryBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.download, size: 16, color: _primaryBlue),
                  const SizedBox(width: 6),
                  Text("Export", style: TextStyle(color: _primaryBlue, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        if (allSubjectsData.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
            child: const Column(
              children: [
                Icon(Icons.book_outlined, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text("No subjects configured for your division.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
              ],
            ),
          )
        else ...[
          if (sem1Subjects.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: _primaryBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: const Text("Semester I", style: TextStyle(fontWeight: FontWeight.bold, color: _primaryBlue, fontSize: 16)),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 450,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: isDesktop ? 1.6 : 1.3,
              ),
              itemCount: sem1Subjects.length,
              itemBuilder: (context, index) => _buildGradeCard(sem1Subjects[index], marksData[sem1Subjects[index]]),
            ),
            const SizedBox(height: 32),
          ],
          if (sem2Subjects.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: Colors.indigo.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: const Text("Semester II", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo, fontSize: 16)),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 450,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: isDesktop ? 1.6 : 1.3,
              ),
              itemCount: sem2Subjects.length,
              itemBuilder: (context, index) => _buildGradeCard(sem2Subjects[index], marksData[sem2Subjects[index]]),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildGradeCard(String subject, Map<String, double>? marks) {
    double ut1 = marks?['ut1'] ?? 0;
    double ut2 = marks?['ut2'] ?? 0;
    double sem = marks?['sem_exam'] ?? 0;
    double total = ut1 + ut2 + sem;
    
    double pct = total / 140.0;
    String grade = pct >= 0.9 ? "A+" : pct >= 0.8 ? "A" : pct >= 0.7 ? "B" : pct >= 0.6 ? "C" : "F";
    Color gradeColor = pct >= 0.75 ? Colors.green : pct >= 0.5 ? Colors.orange : Colors.red;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: _primaryBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.school_rounded, color: _primaryBlue, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(subject, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _textDark), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: gradeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                      child: Text("Grade $grade", style: TextStyle(color: gradeColor, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(text: "${total.toInt()}", style: TextStyle(color: _primaryBlue, fontSize: 18, fontWeight: FontWeight.bold)),
                    TextSpan(text: "/140", style: TextStyle(color: Colors.grey.shade400, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(child: _buildTermScore("UT-I", ut1.toInt(), 20)),
              const SizedBox(width: 8),
              Expanded(child: _buildTermScore("UT-II", ut2.toInt(), 20)),
              const SizedBox(width: 8),
              Expanded(child: _buildTermScore("SEM EXAM", sem.toInt(), 100)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildTermScore(String term, int score, int max) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: _bgGray, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(term, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(text: "$score", style: TextStyle(color: _textDark, fontSize: 14, fontWeight: FontWeight.bold)),
                TextSpan(text: "/$max", style: TextStyle(color: Colors.grey.shade400, fontSize: 9)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}