import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../services/subject_service.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  String selectedDivision = 'A';
  String? selectedSubject;

  List<String> dynamicDivisions = [];
  List<String> dynamicSubjects = ['Loading...'];
  bool isLoadingSubjects = true;
  bool isLoadingDivisions = true;

  final Map<String, bool> attendanceMap = {};
  // Cache student data from the live stream — avoids re-fetching on save
  Map<String, Map<String, dynamic>> _cachedStudents = {};
  DateTime selectedDate = DateTime.now();
  bool isSaving = false;

  final Color primaryPurple = const Color(0xFF5B4BCE);
  final Color bgGray = const Color(0xFFF4F7FE);
  final Color textDark = const Color(0xFF1E293B);
  final Color textLight = const Color(0xFF64748B);

  Stream<QuerySnapshot>? _studentsStream;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    await _loadDivisions();
    _loadSubjectsForDivision();
    _updateStream();
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
          dynamicDivisions = divs.map((e) => e.toString()).toList();
          // Set initial division to first one if present
          if (dynamicDivisions.isNotEmpty && !dynamicDivisions.contains(selectedDivision)) {
            selectedDivision = dynamicDivisions.first;
          }
        });
      }
    } catch (_) {}
    setState(() => isLoadingDivisions = false);
  }

  Future<void> _loadSubjectsForDivision() async {
    if (selectedDivision == 'All') {
      setState(() {
        dynamicSubjects = ['Select Division First'];
        selectedSubject = dynamicSubjects.first;
        isLoadingSubjects = false;
      });
      return;
    }
    setState(() => isLoadingSubjects = true);
    try {
      final subDocs = await SubjectService.getSubjects(selectedDivision);
      setState(() {
        if (subDocs.isNotEmpty) {
           dynamicSubjects = subDocs.map((s) => s['name'] as String).toList();
           selectedSubject = dynamicSubjects.first;
        } else {
           dynamicSubjects = ['No Subjects Available'];
           selectedSubject = dynamicSubjects.first;
        }
      });
    } catch (e) {
       setState(() {
         dynamicSubjects = ['Error loading subjects'];
         selectedSubject = dynamicSubjects.first;
       });
    }
    setState(() => isLoadingSubjects = false);
  }

  // ✅ Removed .orderBy('roll_no') — Firestore sorts strings not numbers.
  //    We sort numerically in Dart instead.
  void _updateStream() {
    if (selectedDivision == 'All') {
      _studentsStream = FirebaseFirestore.instance
          .collection('students')
          .snapshots();
    } else {
      _studentsStream = FirebaseFirestore.instance
          .collection('students')
          .where('division', isEqualTo: selectedDivision)
          .snapshots();
    }
  }

  // ✅ Helper: parse roll_no as integer for proper numeric sorting
  int _parseRoll(dynamic rollNo) {
    return int.tryParse(rollNo?.toString() ?? '0') ?? 0;
  }

  String get formattedDate =>
      DateFormat('MMM dd, yyyy').format(selectedDate);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bgGray,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              // ── HEADER ──────────────────────────────────────────
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                runSpacing: 16.0,
                spacing: 16.0,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Mark Attendance",
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: textDark)),
                      const SizedBox(height: 4),
                      Text(
                          "Manage daily attendance for your class",
                          style: TextStyle(
                              fontSize: 13, color: textLight)),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: (attendanceMap.isNotEmpty && !isSaving)
                        ? _saveAllAttendance
                        : null,
                    icon: isSaving 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.save, size: 20),
                    label: Text(isSaving ? "Saving..." : "Save Attendance",
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryPurple,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // ── FILTERS ─────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4)),
                  ],
                ),
                child: StreamBuilder<QuerySnapshot>(
                  stream: _studentsStream,
                  builder: (context, snapshot) {
                    int totalStudents = snapshot.hasData
                        ? snapshot.data!.docs.length
                        : 0;
                    bool isDesktop = kIsWeb || MediaQuery.of(context).size.width > 600;
                    return Column(
                      children: [
                        if (isDesktop)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                  flex: 2,
                                  child: _buildFilterColumn(
                                      "DATE", _buildDatePicker())),
                              const SizedBox(width: 20),
                              Expanded(
                                  flex: 2,
                                  child: _buildFilterColumn("DIVISION",
                                      _buildDivisionDropdown())),
                              const SizedBox(width: 20),
                              Expanded(
                                  flex: 3,
                                  child: _buildFilterColumn("SUBJECT",
                                      _buildSubjectDropdown())),
                              const Spacer(flex: 2),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: Text(
                                    "$totalStudents Students Total",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: textLight)),
                              ),
                            ],
                          )
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildFilterColumn("DATE", _buildDatePicker()),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(child: _buildFilterColumn("DIVISION", _buildDivisionDropdown())),
                                  const SizedBox(width: 16),
                                  Expanded(child: _buildFilterColumn("SUBJECT", _buildSubjectDropdown())),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text("$totalStudents Students Total", style: TextStyle(fontWeight: FontWeight.bold, color: textLight), textAlign: TextAlign.right),
                            ],
                          ),
                        if (isDesktop) ...[
                          const SizedBox(height: 24),
                          const Divider(color: Colors.black12, height: 1),
                          const SizedBox(height: 16),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0),
                            child: Row(
                              children: [
                                Expanded(flex: 1, child: Text("AVATAR", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey))),
                                Expanded(flex: 3, child: Text("STUDENT NAME", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey))),
                                Expanded(flex: 2, child: Text("ROLL NO", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey))),
                                Expanded(flex: 2, child: Align(alignment: Alignment.centerRight, child: Text("STATUS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)))),
                              ],
                            ),
                          ),
                        ]
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // ── STUDENT LIST ─────────────────────────────────────
              StreamBuilder<QuerySnapshot>(
                stream: _studentsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return Center(
                        child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: CircularProgressIndicator(
                                color: primaryPurple)));
                  }
                  if (!snapshot.hasData ||
                      snapshot.data!.docs.isEmpty) {
                    return const Center(
                        child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Text(
                                'No students found for this division.',
                                style:
                                TextStyle(color: Colors.grey))));
                  }

                  // ✅ Sort students numerically by roll_no
                  final sortedDocs = [...snapshot.data!.docs]..sort(
                        (a, b) {
                      final aRoll = _parseRoll(
                          (a.data() as Map)['roll_no']);
                      final bRoll = _parseRoll(
                          (b.data() as Map)['roll_no']);
                      return aRoll.compareTo(bRoll);
                    },
                  );

                  // Cache student data so _saveAllAttendance skips a network round-trip
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _cachedStudents = {
                      for (var doc in snapshot.data!.docs)
                        doc.id: doc.data() as Map<String, dynamic>
                    };
                  });

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: sortedDocs.length,
                    itemBuilder: (context, index) {
                      final doc = sortedDocs[index];
                      final data =
                      doc.data() as Map<String, dynamic>;
                      final studentId = doc.id;
                      final name = data['name'] ?? 'Unknown';
                      final email = data['email'] ?? 'No Email';
                      final rollNo = data['roll_no'] ?? '-';

                      bool? isPresent = attendanceMap[studentId];

                      bool isDesktop = kIsWeb || MediaQuery.of(context).size.width > 600;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: EdgeInsets.symmetric(
                            horizontal: isDesktop ? 32 : 16, vertical: 16),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.grey.shade200)),
                        child: isDesktop
                            ? Row(
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: CircleAvatar(
                                        backgroundColor: primaryPurple.withValues(alpha: 0.1),
                                        child: Text(name[0].toUpperCase(), style: TextStyle(color: primaryPurple, fontWeight: FontWeight.bold))),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold, color: textDark, fontSize: 15)),
                                          Text(email, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: textLight, fontSize: 12))
                                        ]),
                                  ),
                                  Expanded(flex: 2, child: Text("#$rollNo", style: TextStyle(fontWeight: FontWeight.w600, color: textLight, fontSize: 14))),
                                  Expanded(
                                    flex: 2,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        _buildStatusPill(text: "Present", isActive: isPresent == true, activeColor: Colors.green, onTap: () => setState(() => attendanceMap[studentId] = true)),
                                        const SizedBox(width: 8),
                                        _buildStatusPill(text: "Absent", isActive: isPresent == false, activeColor: Colors.red, onTap: () => setState(() => attendanceMap[studentId] = false)),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                          radius: 20,
                                          backgroundColor: primaryPurple.withValues(alpha: 0.1),
                                          child: Text(name[0].toUpperCase(), style: TextStyle(color: primaryPurple, fontWeight: FontWeight.bold))),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold, color: textDark, fontSize: 15)),
                                            Text(email, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: textLight, fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                      Text("#$rollNo", style: TextStyle(fontWeight: FontWeight.w600, color: primaryPurple, fontSize: 14)),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(child: _buildStatusPill(text: "Present", isActive: isPresent == true, activeColor: Colors.green, onTap: () => setState(() => attendanceMap[studentId] = true))),
                                      const SizedBox(width: 8),
                                      Expanded(child: _buildStatusPill(text: "Absent", isActive: isPresent == false, activeColor: Colors.red, onTap: () => setState(() => attendanceMap[studentId] = false))),
                                    ],
                                  ),
                                ],
                              ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
      ),
    );
  }

  // ── UI HELPERS ───────────────────────────────────────────────

  Widget _buildFilterColumn(String label, Widget child) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey)),
          const SizedBox(height: 8),
          child
        ]);
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
            context: context,
            initialDate: selectedDate,
            firstDate: DateTime(2020),
            lastDate: DateTime.now());
        if (picked != null) setState(() => selectedDate = picked);
      },
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8)),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(formattedDate,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14)),
              ),
              const Icon(Icons.calendar_today,
                  size: 16, color: Colors.grey)
            ]),
      ),
    );
  }

  Widget _buildDivisionDropdown() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8)),
      child: DropdownButtonHideUnderline(
        child: isLoadingDivisions 
          ? const Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))
          : DropdownButton<String>(
          value: dynamicDivisions.contains(selectedDivision) ? selectedDivision : (dynamicDivisions.isNotEmpty ? dynamicDivisions.first : null),
          isExpanded: true,
          items: dynamicDivisions
              .map((d) => DropdownMenuItem(
              value: d,
              child: Text(
                  d == 'All' ? 'All Divisions' : 'Div $d',
                  style: const TextStyle(fontSize: 14))))
              .toList(),
          onChanged: (val) {
            setState(() {
              selectedDivision = val!;
              attendanceMap.clear();
              _loadSubjectsForDivision();
              _updateStream();
            });
          },
        ),
      ),
    );
  }

  Widget _buildSubjectDropdown() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: dynamicSubjects.contains(selectedSubject) ? selectedSubject : (dynamicSubjects.isNotEmpty ? dynamicSubjects.first : null),
          isExpanded: true,
          items: dynamicSubjects
              .map((s) => DropdownMenuItem(
              value: s,
              child: Text(s,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14))))
              .toList(),
          onChanged: (val) {
            if (val != null && val != 'Select Division First' && val != 'No Subjects Available' && val != 'Loading...' && val != 'Error loading subjects') {
              setState(() => selectedSubject = val);
            }
          },
        ),
      ),
    );
  }

  Widget _buildStatusPill(
      {required String text,
        required bool isActive,
        required Color activeColor,
        required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
            color: isActive ? activeColor : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color:
                isActive ? activeColor : Colors.grey.shade300)),
        child: Center(
          child: Text(text,
              style: TextStyle(
                  color: isActive
                      ? Colors.white
                      : Colors.grey.shade600,
                  fontWeight: isActive
                      ? FontWeight.bold
                      : FontWeight.w600,
                  fontSize: 12)),
        ),
      ),
    );
  }

  // ── SAVE ATTENDANCE ──────────────────────────────────────────
  Future<void> _saveAllAttendance() async {
    if (attendanceMap.isEmpty) return;
    if (selectedSubject == null || selectedSubject == 'Select Division First' || selectedSubject == 'No Subjects Available' || selectedSubject == 'Loading...' || selectedSubject == 'Error loading subjects') {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a valid subject first.'), backgroundColor: Colors.red));
       return;
    }

    setState(() => isSaving = true);

    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();
      final normalizedDate = DateTime(
          selectedDate.year, selectedDate.month, selectedDate.day);
      final dateKey =
          '${normalizedDate.year}-${normalizedDate.month}-${normalizedDate.day}';

      // ✅ Use cached student data from the stream — no extra network call
      final studentDataMap = _cachedStudents;

      for (var entry in attendanceMap.entries) {
        final studentId = entry.key;
        final isPresent = entry.value;

        if (!studentDataMap.containsKey(studentId)) continue;

        final data = studentDataMap[studentId]!;
        final docId = '${studentId}_${selectedSubject}_$dateKey';
        final ref = firestore.collection('attendance').doc(docId);

        batch.set(
            ref,
            {
              'studentId': studentId,
              'name': data['name'],
              'roll_no': data['roll_no'],
              'division': data['division'],
              'subject': selectedSubject,
              'status': isPresent ? 'Present' : 'Absent',
              'date': Timestamp.fromDate(normalizedDate),
              'markedAt': Timestamp.now(),
              'markedBy': FirebaseAuth.instance.currentUser?.uid,
            },
            SetOptions(merge: true));
      }

      await batch.commit();

      if (mounted) {
        setState(() {
          attendanceMap.clear();
          isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Attendance saved successfully!'),
            backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        setState(() => isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red));
      }
    }
  }
}