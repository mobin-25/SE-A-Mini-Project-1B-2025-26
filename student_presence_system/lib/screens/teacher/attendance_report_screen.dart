import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../services/subject_service.dart';
import '../../services/excel_service.dart';

// 🔥 IMPORT THE NEW DASHBOARD FILE HERE
import 'analytics_dialog.dart';

class AttendanceReportScreen extends StatefulWidget {
  const AttendanceReportScreen({super.key});

  @override
  State<AttendanceReportScreen> createState() => _AttendanceReportScreenState();
}

class _AttendanceReportScreenState extends State<AttendanceReportScreen> {
  String selectedDivision = 'All';
  String selectedSubject = 'All';
  DateTime selectedDate = DateTime.now();

  List<String> dynamicDivisions = ['All'];
  List<String> dynamicSubjects = ['All'];
  bool isLoadingSubjects = false;
  bool isLoadingDivisions = false;

  // Overall Report State
  bool isGeneratingReport = false;
  bool hasGeneratedReport = false;
  List<Map<String, dynamic>> overallReportData = [];
  List<String> reportSubjects = [];

  final Color primaryBlue = const Color(0xFF1D4ED8);
  final Color bgGray = const Color(0xFFF4F7FE);
  final Color textDark = const Color(0xFF1E293B);
  final Color textLight = const Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    await _loadDivisions();
    _loadSubjectsForDivision();
  }

  Future<void> _loadDivisions() async {
    setState(() => isLoadingDivisions = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('divisions')
          .get();
      if (doc.exists) {
        final List<dynamic> divs = (doc.data()!['list'] ?? []);
        setState(() {
          dynamicDivisions = ['All', ...divs.map((e) => e.toString())];
          if (!dynamicDivisions.contains(selectedDivision)) {
            selectedDivision = 'All';
          }
        });
      }
    } catch (_) {}
    setState(() => isLoadingDivisions = false);
  }

  Future<void> _loadSubjectsForDivision() async {
    setState(() => isLoadingSubjects = true);
    try {
      if (selectedDivision == 'All') {
        Set<String> allSubs = {'All'};
        // Use the current active divisions
        final activeOnly = dynamicDivisions.where((d) => d != 'All');
        for (String d in activeOnly) {
          final subDocs = await SubjectService.getSubjects(d);
          allSubs.addAll(subDocs.map((s) => s['name'] as String));
        }
        setState(() {
          dynamicSubjects = allSubs.toList();
          if (!dynamicSubjects.contains(selectedSubject)) {
             selectedSubject = 'All';
          }
        });
      } else {
        final subDocs = await SubjectService.getSubjects(selectedDivision);
        setState(() {
          dynamicSubjects = ['All', ...subDocs.map((s) => s['name'] as String)];
          if (!dynamicSubjects.contains(selectedSubject)) {
             selectedSubject = 'All';
          }
        });
      }
    } catch (_) {}
    setState(() => isLoadingSubjects = false);
  }

  // 🔥 UPDATED NAVIGATION LOGIC
  void _showAnalyticsDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdvancedAnalyticsDashboard()),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2025, 1, 1),
      lastDate: DateTime.now(),
      selectableDayPredicate: (DateTime day) => day.weekday != DateTime.sunday,
    );
    if (picked != null && picked != selectedDate) {
      setState(() => selectedDate = picked);
    }
  }

  Future<void> _generateOverallReport() async {
    if (selectedDivision == 'All') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a specific division first.'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() {
      isGeneratingReport = true;
      hasGeneratedReport = false;
      overallReportData.clear();
      reportSubjects.clear();
    });

    try {
      // 1. Get subjects for division
      final subDocs = await SubjectService.getSubjects(selectedDivision);
      List<String> subjects = subDocs.map((s) => s['name'] as String).toList();
      subjects.sort();

      // 2. Get students for division
      final studentsSnap = await FirebaseFirestore.instance
          .collection('students')
          .where('division', isEqualTo: selectedDivision)
          .get();
          
      // 3. Get all attendance for division
      final attendanceSnap = await FirebaseFirestore.instance
          .collection('attendance')
          .where('division', isEqualTo: selectedDivision)
          .get();

      // Aggregate data
      // Map<studentId, Map<subject, int>>
      Map<String, Map<String, int>> studentSubjectPresent = {};
      Map<String, int> studentTotalLectures = {}; 

      for (var doc in attendanceSnap.docs) {
        final data = doc.data();
        final sid = data['studentId'] as String?;
        final sub = data['subject'] as String?;
        final status = data['status'] as String?;

        if (sid == null || sub == null || status == null) continue;

        studentSubjectPresent.putIfAbsent(sid, () => {});
        studentSubjectPresent[sid]!.putIfAbsent(sub, () => 0);
        studentTotalLectures.putIfAbsent(sid, () => 0);

        studentTotalLectures[sid] = studentTotalLectures[sid]! + 1;
        if (status == 'Present') {
          studentSubjectPresent[sid]![sub] = studentSubjectPresent[sid]![sub]! + 1;
        }
      }

      List<Map<String, dynamic>> processedData = [];

      for (var doc in studentsSnap.docs) {
        final data = doc.data();
        final sid = doc.id;
        final name = data['name'] ?? 'Unknown';
        final rollNo = data['roll_no']?.toString() ?? '-';
        
        int totalPresent = 0;
        final subCounts = studentSubjectPresent[sid] ?? {};
        for (var count in subCounts.values) {
          totalPresent += count;
        }
        
        int totalLectures = studentTotalLectures[sid] ?? 0;
        double percentage = totalLectures > 0 ? (totalPresent / totalLectures) * 100 : 0.0;

        processedData.add({
          'studentId': sid,
          'name': name,
          'rollNo': rollNo,
          'subjectCounts': subCounts,
          'totalPresent': totalPresent,
          'totalLectures': totalLectures,
          'percentage': percentage,
        });
      }

      // Sort by roll no
      processedData.sort((a, b) {
        int rA = int.tryParse(a['rollNo']) ?? 0;
        int rB = int.tryParse(b['rollNo']) ?? 0;
        return rA.compareTo(rB);
      });

      if (mounted) {
        setState(() {
          reportSubjects = subjects;
          overallReportData = processedData;
          hasGeneratedReport = true;
          isGeneratingReport = false;
        });
      }

    } catch (e) {
      if (mounted) {
        setState(() => isGeneratingReport = false);
        String msg = e.toString().contains('resource-exhausted') || e.toString().contains('Quota exceeded')
            ? 'Database limit exceeded. Try again later.' 
            : 'Error: $e';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final startDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final endDate = startDate.add(const Duration(days: 1));
    String formattedDateStr = DateFormat('dd-MM-yyyy').format(selectedDate);

    bool isDesktop = kIsWeb || MediaQuery.of(context).size.width > 800;

    return Container(
      color: bgGray,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.all(isDesktop ? 32.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==========================================
            // HEADER (Title & Analytics Button)
            // ==========================================
            if (isDesktop)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Attendance Reports", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textDark)),
                      const SizedBox(height: 4),
                      Text("Daily summary and student records management", style: TextStyle(fontSize: 15, color: textLight)),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(icon: const Icon(Icons.notifications_none), onPressed: () {}),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: _showAnalyticsDialog, // Opens the new Full Screen Dashboard!
                        icon: const Icon(Icons.analytics, size: 18),
                        label: const Text("View Analytics", style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    ],
                  )
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Attendance Reports", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textDark)),
                  const SizedBox(height: 4),
                  Text("Daily summary and student records management", style: TextStyle(fontSize: 13, color: textLight)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _showAnalyticsDialog,
                    icon: const Icon(Icons.analytics, size: 18),
                    label: const Text("View Analytics", style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 32),

            // ==========================================
            // FILTERS SECTION
            // ==========================================
            Container(
              padding: EdgeInsets.all(isDesktop ? 24 : 16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))]),
              child: isDesktop ? Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(flex: 2, child: _buildFilterColumn("DIVISION", _buildDivisionDropdown())),
                  const SizedBox(width: 20),
                  Expanded(flex: 3, child: _buildFilterColumn("SUBJECT", _buildSubjectDropdown())),
                  const SizedBox(width: 20),
                  Expanded(
                      flex: 2,
                      child: _buildFilterColumn(
                          "DATE",
                          InkWell(
                            onTap: () => _selectDate(context),
                            child: Container(
                              height: 40, padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(formattedDateStr, style: const TextStyle(fontSize: 14)), const Icon(Icons.calendar_today, size: 16, color: Colors.grey)]),
                            ),
                          )
                      )
                  ),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: () {}, icon: const Icon(Icons.filter_list, size: 18), label: const Text("More Filters"),
                    style: OutlinedButton.styleFrom(foregroundColor: textDark, side: BorderSide(color: Colors.grey.shade300), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    height: 40, width: 40,
                    decoration: BoxDecoration(color: primaryBlue, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.search, color: Colors.white, size: 20),
                  )
                ],
              ) : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildFilterColumn("DIVISION", _buildDivisionDropdown())),
                      const SizedBox(width: 12),
                      Expanded(child: _buildFilterColumn("SUBJECT", _buildSubjectDropdown())),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildFilterColumn(
                      "DATE",
                      InkWell(
                        onTap: () => _selectDate(context),
                        child: Container(
                          height: 40, padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(formattedDateStr, style: const TextStyle(fontSize: 14)), const Icon(Icons.calendar_today, size: 16, color: Colors.grey)]),
                        ),
                      )
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ==========================================
            // STAT CARDS & TABLE
            // ==========================================
            StreamBuilder<QuerySnapshot>(
                stream: selectedDivision == 'All'
                    ? FirebaseFirestore.instance.collection('students').snapshots()
                    : FirebaseFirestore.instance.collection('students').where('division', isEqualTo: selectedDivision).snapshots(),
                builder: (context, studentsSnapshot) {

                  return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('attendance')
                          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
                          .where('date', isLessThan: Timestamp.fromDate(endDate)).snapshots(),
                      builder: (context, attendanceSnapshot) {

                        if (studentsSnapshot.hasError) return Text("Error loading students: ${studentsSnapshot.error}", style: const TextStyle(color: Colors.red));
                        if (attendanceSnapshot.hasError) return Text("Error loading attendance: ${attendanceSnapshot.error}", style: const TextStyle(color: Colors.red));

                        if (!studentsSnapshot.hasData || !attendanceSnapshot.hasData) {
                          return Center(child: Padding(padding: const EdgeInsets.all(40.0), child: CircularProgressIndicator(color: primaryBlue)));
                        }

                        // Filter attendance based on dropdowns locally
                        final attendanceDocs = attendanceSnapshot.data!.docs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          if (selectedDivision != 'All' && data['division'] != selectedDivision) return false;
                          if (selectedSubject != 'All' && data['subject'] != selectedSubject) return false;
                          return true;
                        }).toList();

                        // Calculate Data
                        final totalStudents = studentsSnapshot.data!.docs.length;
                        final uniquePresent = <String>{};
                        for (var doc in attendanceDocs) {
                          final data = doc.data() as Map<String, dynamic>;
                          if (data['status'] == 'Present') uniquePresent.add(data['studentId']);
                        }

                        final presentCount = uniquePresent.length;
                        final absentCount = totalStudents > 0 ? totalStudents - presentCount : 0;
                        final rate = totalStudents > 0 ? (presentCount / totalStudents) * 100 : 0.0;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // DESKTOP: Stat cards on top
                            if (isDesktop) ...[
                              Row(
                                children: [
                                  Expanded(child: _buildStatCard("Total Students", totalStudents.toString(), Icons.people_outline, Colors.blue.shade100, Colors.blue, "+2 new")),
                                  const SizedBox(width: 20),
                                  Expanded(child: _buildStatCard("Total Present", presentCount.toString(), Icons.check_circle_outline, Colors.green.shade50, Colors.green, "${rate.toStringAsFixed(0)}% of class")),
                                  const SizedBox(width: 20),
                                  Expanded(child: _buildStatCard("Total Absent", absentCount.toString(), Icons.cancel_outlined, Colors.red.shade50, Colors.red, "${(100-rate).toStringAsFixed(0)}% of class")),
                                  const SizedBox(width: 20),
                                  Expanded(child: _buildRateCard(rate)),
                                ],
                              ),
                              const SizedBox(height: 32),
                              _buildOverallAttendanceTable(),
                            ]
                            // MOBILE: Records table first, stat cards at the bottom
                            else ...[
                              _buildOverallAttendanceTable(),
                              const SizedBox(height: 24),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: _buildStatCard("Students", totalStudents.toString(), Icons.people_outline, Colors.blue.shade100, Colors.blue, "Total Class")),
                                  const SizedBox(width: 8),
                                  Expanded(child: _buildStatCard("Present", presentCount.toString(), Icons.check_circle_outline, Colors.green.shade50, Colors.green, "${rate.toStringAsFixed(0)}%")),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: _buildStatCard("Absent", absentCount.toString(), Icons.cancel_outlined, Colors.red.shade50, Colors.red, "${(100-rate).toStringAsFixed(0)}%")),
                                  const SizedBox(width: 8),
                                  Expanded(child: _buildRateCard(rate)),
                                ],
                              ),
                            ],
                          ]
                        );
                      }
                  );
                }
            )
          ],
        ),
      ),
    );
  }

  Widget _buildOverallAttendanceTable() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    "Overall Student Records", 
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasGeneratedReport && overallReportData.isNotEmpty) ...[
                      IconButton(
                        onPressed: () => ExcelService.exportOverallAttendanceToExcel(context, selectedDivision, reportSubjects, overallReportData),
                        icon: Icon(Icons.download, color: primaryBlue, size: 20),
                        tooltip: 'Export Excel',
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(8),
                      ),
                      const SizedBox(width: 4),
                    ],
                    ElevatedButton.icon(
                      onPressed: isGeneratingReport ? null : _generateOverallReport,
                      icon: isGeneratingReport 
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.refresh, size: 14),
                      label: const Text("Generate", style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
          const Divider(color: Colors.black12, height: 1),

          if (!hasGeneratedReport && !isGeneratingReport)
            const Padding(
              padding: EdgeInsets.all(40.0),
              child: Center(child: Text("Click 'Generate Overall Report' to load data.", style: TextStyle(color: Colors.grey))),
            )
          else if (isGeneratingReport)
            const Padding(
              padding: EdgeInsets.all(40.0),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (overallReportData.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40.0),
              child: Center(child: Text("No records found for this division.", style: TextStyle(color: Colors.grey))),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - (kIsWeb || MediaQuery.of(context).size.width > 800 ? 64 : 32)),
                child: DataTable(
                  headingTextStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                  dataTextStyle: TextStyle(fontSize: 13, color: textDark),
                  columns: [
                    const DataColumn(label: Text("ROLL NO")),
                    const DataColumn(label: Text("STUDENT NAME")),
                    ...reportSubjects.map((sub) => DataColumn(label: Text(sub.toUpperCase()))).toList(),
                    const DataColumn(label: Text("OVERALL %")),
                  ],
                  rows: overallReportData.map((data) {
                    final name = data['name'];
                    final rollNo = data['rollNo'];
                    final subCounts = data['subjectCounts'] as Map<String, int>;
                    final percentage = data['percentage'] as double;

                    Color pctColor = percentage >= 75 ? Colors.green : (percentage >= 50 ? Colors.orange : Colors.red);

                    return DataRow(
                      cells: [
                        DataCell(Text(rollNo, style: const TextStyle(fontWeight: FontWeight.bold))),
                        DataCell(
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 14, 
                                backgroundColor: primaryBlue.withValues(alpha: 0.1), 
                                child: Text(name.toString().isNotEmpty ? name[0].toUpperCase() : '?', style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold, fontSize: 10))
                              ),
                              const SizedBox(width: 8),
                              Text(name),
                            ],
                          )
                        ),
                        ...reportSubjects.map((sub) {
                          int count = subCounts[sub] ?? 0;
                          return DataCell(Text(count.toString()));
                        }).toList(),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: pctColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "${percentage.toStringAsFixed(1)}%",
                              style: TextStyle(color: pctColor, fontWeight: FontWeight.bold),
                            ),
                          )
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- UI HELPER WIDGETS ---

  Widget _buildFilterColumn(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildDivisionDropdown() {
    return Container(
      height: 40, padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedDivision, isExpanded: true, icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          items: dynamicDivisions.map((d) => DropdownMenuItem(value: d, child: Text(d == 'All' ? 'All Divisions' : 'Div $d', style: const TextStyle(fontSize: 14)))).toList(),
          onChanged: (val) {
             setState(() => selectedDivision = val!);
             _loadSubjectsForDivision();
          },
        ),
      ),
    );
  }

  Widget _buildSubjectDropdown() {
    return Container(
      height: 40, padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: dynamicSubjects.contains(selectedSubject) ? selectedSubject : (dynamicSubjects.isNotEmpty ? dynamicSubjects.first : null),
          isExpanded: true, icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          items: dynamicSubjects.map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14)))).toList(),
          onChanged: (val) => setState(() => selectedSubject = val!),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color iconBg, Color iconColor, String subtitle) {
    final bool isDesktop = kIsWeb || MediaQuery.of(context).size.width > 800;
    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: Text(title, style: TextStyle(color: textLight, fontSize: isDesktop ? 13 : 10, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
              Container(padding: EdgeInsets.all(isDesktop ? 7 : 4), decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle), child: Icon(icon, color: iconColor, size: isDesktop ? 16 : 12)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: isDesktop ? 32 : 20, fontWeight: FontWeight.bold, color: textDark)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(color: iconColor, fontSize: isDesktop ? 12 : 9, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildRateCard(double rate) {
    final bool isDesktop = kIsWeb || MediaQuery.of(context).size.width > 800;
    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: Text("Attendance Rate", style: TextStyle(color: textLight, fontSize: isDesktop ? 13 : 10, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
              Container(padding: EdgeInsets.all(isDesktop ? 7 : 4), decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle), child: Icon(Icons.pie_chart_outline, color: Colors.grey, size: isDesktop ? 16 : 12)),
            ],
          ),
          const SizedBox(height: 8),
          Text("${rate.toStringAsFixed(0)}%", style: TextStyle(fontSize: isDesktop ? 32 : 20, fontWeight: FontWeight.bold, color: textDark)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: rate / 100, backgroundColor: Colors.grey.shade200, color: primaryBlue, minHeight: isDesktop ? 6 : 4),
          )
        ],
      ),
    );
  }
}