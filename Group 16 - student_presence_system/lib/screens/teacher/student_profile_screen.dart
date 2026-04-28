import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../services/subject_service.dart';

class StudentProfileScreen extends StatefulWidget {
  final String studentId; // This is the UID
  final Map<String, dynamic> studentData;

  const StudentProfileScreen({
    super.key,
    required this.studentId,
    required this.studentData,
  });

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  String _selectedMonth = 'All';
  int _selectedSemester = 1; // 1 = Semester I, 2 = Semester II

  // 🔥 THEME UPDATED: Perfectly matches your Teal Teacher Dashboard
  final Color _primaryTeal = Colors.teal.shade700;
  static const Color _bgGray = Color(0xFFF4F7FE);
  static const Color _textDark = Color(0xFF1E293B);

  final List<String> _months = [
    'All', 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'
  ];

  List<String> _sem1Subjects = [];
  List<String> _sem2Subjects = [];
  List<String> get _availableSubjects => [..._sem1Subjects, ..._sem2Subjects];
  bool _isLoadingSubjects = true;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    final division = widget.studentData['division']?.toString().toUpperCase() ?? '';
    if (division.isNotEmpty) {
      try {
        final subDocs = await SubjectService.getSubjects(division);
        if (mounted) {
          setState(() {
            _sem1Subjects = subDocs.where((s) => s['semester'] == 'Semester I').map((s) => s['name'] as String).toList();
            _sem2Subjects = subDocs.where((s) => s['semester'] == 'Semester II').map((s) => s['name'] as String).toList();
            _isLoadingSubjects = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _isLoadingSubjects = false);
      }
    } else {
      if (mounted) setState(() {
        _sem1Subjects = [];
        _sem2Subjects = [];
        _isLoadingSubjects = false;
      });
    }
  }

  Color _getScoreColor(double pct) {
    if (pct >= 0.75) return Colors.green;
    if (pct >= 0.50) return Colors.orange;
    return Colors.red;
  }

  IconData _getSubjectIcon(String subject) {
    if (subject.contains('Data')) return Icons.insights;
    if (subject.contains('Python')) return Icons.code;
    if (subject.contains('AI') || subject.contains('Artificial')) return Icons.psychology;
    if (subject.contains('PowerBI')) return Icons.bar_chart;
    return Icons.menu_book;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgGray,
      appBar: AppBar(
        title: const Text("Student Profile", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        foregroundColor: _textDark,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: Text("Home > Students > ${widget.studentData['name'] ?? 'Profile'}", style: TextStyle(color: Colors.grey.shade500, fontSize: 12))),
          )
        ],
      ),
      body: LayoutBuilder(
          builder: (context, constraints) {
            bool isDesktop = constraints.maxWidth > 900;
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.all(isDesktop ? 32 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderCard(),
                  const SizedBox(height: 24),
                  if (isDesktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 1, child: _buildAttendanceSection()),
                        const SizedBox(width: 24),
                        Expanded(flex: 2, child: _buildAcademicSection()),
                      ],
                    )
                  else
                    Column(
                      children: [
                        _buildAttendanceSection(),
                        const SizedBox(height: 24),
                        _buildAcademicSection(),
                      ],
                    )
                ],
              ),
            );
          }
      ),
    );
  }

  // ==================== 1. HEADER BANNER ====================
  Widget _buildHeaderCard() {
    final data = widget.studentData;
    final String name = data['name'] ?? 'Unknown';
    final String roll = (data['roll_no'] ?? '').toString().trim();
    final String division = data['division'] ?? '';
    final String initials = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 700;
        final double avatarRadius = isMobile ? 36.0 : 50.0;
        final double bannerHeight = isMobile ? 110.0 : 140.0;
        // How much avatar overlaps the banner
        const double overlap = 20.0;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Teal Banner: name is safely inside ──
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Banner background + name text
                    Container(
                      width: double.infinity,
                      height: bannerHeight,
                      color: _primaryTeal,
                      padding: EdgeInsets.fromLTRB(
                        isMobile ? 16 : 32,
                        20,
                        isMobile ? 100 : 120, // Reserved space for avatar on the right
                        14,
                      ),
                      alignment: Alignment.bottomLeft,
                      child: Text(
                        name,
                        style: TextStyle(
                          fontSize: isMobile ? 18 : 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Avatar positioned to overlap banner bottom
                    Positioned(
                      bottom: -overlap,
                      right: isMobile ? 16 : 32,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: CircleAvatar(
                          radius: avatarRadius,
                          backgroundColor: _primaryTeal,
                          child: Text(
                            initials,
                            style: TextStyle(
                              fontSize: avatarRadius * 0.75,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // ── White section: space for avatar + badges + buttons ──
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    isMobile ? 16 : 32,
                    overlap + avatarRadius - 2, // push down enough for avatar
                    isMobile ? 16 : 32,
                    20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badges
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _badge(Icons.badge_outlined, "Roll No: $roll"),
                          _badge(Icons.class_outlined, "Class $division"),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle, color: Colors.green.shade600, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  "Active Student",
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {},
                              icon: Icon(Icons.mail_outline, size: isMobile ? 16 : 18),
                              label: const Text("Message"),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _textDark,
                                side: BorderSide(color: Colors.grey.shade300),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {},
                              icon: Icon(Icons.edit, size: isMobile ? 16 : 18),
                              label: const Text("Edit Profile"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primaryTeal,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }



  Widget _badge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: _bgGray, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ==================== 2. ATTENDANCE SECTION ====================
  Widget _buildAttendanceSection() {
    final roll = widget.studentData['roll_no']?.toString() ?? '';
    final division = widget.studentData['division']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Attendance", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textDark)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedMonth,
                    isDense: true,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                    icon: const Icon(Icons.keyboard_arrow_down, size: 16),
                    onChanged: (v) => setState(() => _selectedMonth = v!),
                    items: _months.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildAttendanceStream(roll, division),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(foregroundColor: _primaryTeal, side: BorderSide(color: _primaryTeal.withValues(alpha: 0.3)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: const Text("View Full Report", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildAttendanceStream(String roll, String division) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('attendance').where('division', isEqualTo: division).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data!.docs;
        final Map<String, Set<String>> total = {};
        final Map<String, Set<String>> present = {};

        for (var doc in docs) {
          final d = doc.data() as Map<String, dynamic>;
          final subject = d['subject'] ?? 'Unknown';
          DateTime? recordDate = d['date'] is Timestamp ? (d['date'] as Timestamp).toDate() : null;

          if (recordDate == null || (_selectedMonth != 'All' && DateFormat('MMMM').format(recordDate) != _selectedMonth)) continue;

          final key = "${d['date']}_${d['time']}";
          total.putIfAbsent(subject, () => {}).add(key);
          if (d['roll_no'] == roll && d['status'] == 'Present') present.putIfAbsent(subject, () => {}).add(key);
        }

        double sum = 0;
        int active = 0;
        int totalClassesCount = 0;
        int totalPresentCount = 0;
        List<Map<String, dynamic>> stats = [];

        // Dynamic Subjects logic: Use the division's subjects
        final displaySubjects = _availableSubjects.isNotEmpty ? _availableSubjects : total.keys.toList();

        for (var sub in displaySubjects) {
          final dates = total[sub] ?? {};
          int t = dates.length;
          int p = present[sub]?.length ?? 0;
          
          double pct = t > 0 ? p / t : 0.0;
          if (t > 0) {
            sum += pct;
            active++;
            totalClassesCount += t;
            totalPresentCount += p;
          }
          stats.add({'subject': sub, 'present': p, 'total': t, 'pct': pct});
        }

        final avg = active == 0 ? 0.0 : sum / active;
        Color avgColor = _primaryTeal;

        return Column(
            children: [
              // Big Circular Indicator
              SizedBox(
                height: 140, width: 140,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: avg,
                      strokeWidth: 12,
                      backgroundColor: _primaryTeal.withValues(alpha: 0.1),
                      color: avgColor,
                      strokeCap: StrokeCap.round,
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("${(avg * 100).toInt()}%", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: _textDark)),
                          Text("AVERAGE", style: TextStyle(color: Colors.grey.shade500, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(children: [Text("$totalPresentCount", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textDark)), Text("Present", style: TextStyle(fontSize: 12, color: Colors.grey.shade500))]),
                  const SizedBox(width: 40),
                  Column(children: [Text("${totalClassesCount - totalPresentCount}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)), Text("Absent", style: TextStyle(fontSize: 12, color: Colors.grey.shade500))]),
                ],
              ),
              const SizedBox(height: 32),
              // Subject Bars
              if (stats.isEmpty)
                Padding(padding: const EdgeInsets.all(20), child: Text("No attendance records for $_selectedMonth", style: const TextStyle(color: Colors.grey)))
              else
                ...stats.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(s['subject'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textDark), overflow: TextOverflow.ellipsis)),
                                Text("${(s['pct'] * 100).toInt()}%", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _getScoreColor(s['pct']))),
                              ]
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(value: s['pct'], color: _getScoreColor(s['pct']), backgroundColor: Colors.grey.shade200, minHeight: 6, borderRadius: BorderRadius.circular(10)),
                        ]
                    )
                )),
            ]
        );
      },
    );
  }

  // ==================== 3. ACADEMIC PERFORMANCE (MARKS) ====================
  Widget _buildAcademicSection() {
    final roll = widget.studentData['roll_no']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Row ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Academic History", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textDark)),
              ElevatedButton.icon(
                onPressed: () => _showAddSubjectDialog(roll),
                icon: const Icon(Icons.add, size: 14),
                label: const Text("Add Marks", style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryTeal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              )
            ],
          ),
          const SizedBox(height: 16),

          if (_isLoadingSubjects)
            const Center(child: CircularProgressIndicator())
          else if (_sem1Subjects.isEmpty && _sem2Subjects.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(32), child: Text("No subjects configured.", style: TextStyle(color: Colors.grey))))
          else
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('exam_marks').where('roll_no', isEqualTo: roll).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                Map<String, Map<String, dynamic>> marksMap = {};
                if (snapshot.hasData) {
                  for (var doc in snapshot.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    if (data['subject'] != null) marksMap[data['subject']] = {'id': doc.id, ...data};
                  }
                }

                return Column(children: [
                  if (_sem1Subjects.isNotEmpty) ...[
                    _buildSemesterHistoryBlock(semLabel: "Semester I", semColor: _primaryTeal, roll: roll, marksMap: marksMap, subjects: _sem1Subjects),
                    const SizedBox(height: 20),
                  ],
                  if (_sem2Subjects.isNotEmpty) ...[
                    _buildSemesterHistoryBlock(semLabel: "Semester II", semColor: Colors.indigo.shade600, roll: roll, marksMap: marksMap, subjects: _sem2Subjects),
                  ]
                ]);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSemesterHistoryBlock({
    required String semLabel, required Color semColor,
    required String roll, required Map<String, Map<String, dynamic>> marksMap,
    required List<String> subjects,
  }) {
    double totalObtained = 0;
    for (final s in subjects) {
      if (marksMap.containsKey(s)) {
        totalObtained += (double.tryParse(marksMap[s]!['ut1'].toString()) ?? 0);
        totalObtained += (double.tryParse(marksMap[s]!['ut2'].toString()) ?? 0);
        totalObtained += (double.tryParse(marksMap[s]!['sem_exam'].toString()) ?? 0);
      }
    }
    final double semPct = subjects.isNotEmpty ? totalObtained / (subjects.length * 140.0) : 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: semColor.withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        // Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: semColor.withValues(alpha: 0.07),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
          ),
          child: Row(children: [
            Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: semColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
              child: Icon(Icons.school_rounded, color: semColor, size: 16)),
            const SizedBox(width: 10),
            Text(semLabel, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: semColor)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: semColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
              child: Text("${(semPct * 100).toStringAsFixed(0)}% Overall", style: TextStyle(color: semColor, fontWeight: FontWeight.bold, fontSize: 11)),
            ),
          ]),
        ),

        // Column headers
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: Row(children: [
            const Expanded(flex: 3, child: Text("Subject", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey))),
            const Expanded(flex: 2, child: Text("UT-I", textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey))),
            const Expanded(flex: 2, child: Text("UT-II", textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey))),
            const Expanded(flex: 2, child: Text("Sem Exam", textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey))),
            const Expanded(flex: 2, child: Text("Grade", textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey))),
          ]),
        ),
        Divider(height: 1, color: Colors.grey.shade100),

        // Subject rows
        ...subjects.map((subject) {
          final data = marksMap[subject];
          final bool hasData = data != null;
          final double ut1 = hasData ? (double.tryParse(data['ut1'].toString()) ?? 0) : -1;
          final double ut2 = hasData ? (double.tryParse(data['ut2'].toString()) ?? 0) : -1;
          final double sem = hasData ? (double.tryParse(data['sem_exam'].toString()) ?? 0) : -1;
          final bool hasMarks = ut1 >= 0 && ut2 >= 0 && sem >= 0;
          final double pct = hasMarks ? (ut1 + ut2 + sem) / 140.0 : 0;
          final String grade = !hasMarks ? '-' : pct >= 0.9 ? "A+" : pct >= 0.8 ? "A" : pct >= 0.7 ? "B" : pct >= 0.6 ? "C" : "F";
          final Color gradeColor = _getScoreColor(pct);

          return Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(children: [
                Expanded(flex: 3, child: Row(children: [
                  Icon(_getSubjectIcon(subject), color: semColor.withValues(alpha: 0.7), size: 14),
                  const SizedBox(width: 6),
                  Expanded(child: Text(subject, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: _textDark), overflow: TextOverflow.ellipsis)),
                ])),
                Expanded(flex: 2, child: hasMarks
                  ? Column(children: [
                      Text("${ut1.toInt()}", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: ut1 >= 14 ? Colors.green.shade600 : ut1 >= 10 ? Colors.orange.shade700 : Colors.red.shade600)),
                      Text("/20", textAlign: TextAlign.center, style: TextStyle(fontSize: 9, color: Colors.grey.shade400)),
                    ])
                  : const Center(child: Text("-", style: TextStyle(color: Colors.grey)))),
                Expanded(flex: 2, child: hasMarks
                  ? Column(children: [
                      Text("${ut2.toInt()}", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: ut2 >= 14 ? Colors.green.shade600 : ut2 >= 10 ? Colors.orange.shade700 : Colors.red.shade600)),
                      Text("/20", textAlign: TextAlign.center, style: TextStyle(fontSize: 9, color: Colors.grey.shade400)),
                    ])
                  : const Center(child: Text("-", style: TextStyle(color: Colors.grey)))),
                Expanded(flex: 2, child: hasMarks
                  ? Column(children: [
                      Text("${sem.toInt()}", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: sem >= 70 ? Colors.green.shade600 : sem >= 50 ? Colors.orange.shade700 : Colors.red.shade600)),
                      Text("/100", textAlign: TextAlign.center, style: TextStyle(fontSize: 9, color: Colors.grey.shade400)),
                    ])
                  : const Center(child: Text("-", style: TextStyle(color: Colors.grey)))),
                Expanded(flex: 2, child: Center(child: hasMarks
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: gradeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                      child: Text(grade, textAlign: TextAlign.center, style: TextStyle(color: gradeColor, fontWeight: FontWeight.bold, fontSize: 11)))
                  : TextButton(
                      onPressed: () => _showAddSubjectDialog(roll, preFilledSubject: subject),
                      style: TextButton.styleFrom(foregroundColor: semColor, padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                      child: const Text("+ Add", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))))),
              ]),
            ),
            if (subject != subjects.last) Divider(height: 1, indent: 16, endIndent: 16, color: Colors.grey.shade100),
          ]);
        }),

        // Edit footer
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14))),
          child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            InkWell(
              onTap: () => _showAddSubjectDialog(roll),
              child: Row(children: [Icon(Icons.edit_note_rounded, size: 14, color: semColor), const SizedBox(width: 4), Text("Edit Marks", style: TextStyle(color: semColor, fontSize: 11, fontWeight: FontWeight.bold))]),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildTermScore(String title, int score, int max) {
    return Column(
      children: [
        Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
        const SizedBox(height: 4),
        RichText(text: TextSpan(children: [
          TextSpan(text: "$score", style: const TextStyle(color: _textDark, fontSize: 18, fontWeight: FontWeight.bold)),
          TextSpan(text: "/$max", style: TextStyle(color: Colors.grey.shade400, fontSize: 12, fontWeight: FontWeight.bold)),
        ])),
      ],
    );
  }

  // ==================== DIALOGS ====================
  void _showAddSubjectDialog(String roll, {String? preFilledSubject}) {
    String selectedSem = (preFilledSubject != null && _sem2Subjects.contains(preFilledSubject)) ? 'Semester II' : 'Semester I';
    final subC = TextEditingController(text: preFilledSubject ?? '');
    final ut1C = TextEditingController();
    final ut2C = TextEditingController();
    final s1C = TextEditingController();
    bool isLoading = false;

    showDialog(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(builder: (context, setDialogState) {
            List<String> currentSubjects = selectedSem == 'Semester I' ? _sem1Subjects : _sem2Subjects;
            return AlertDialog(
                title: const Text('Add Marks', style: TextStyle(fontWeight: FontWeight.bold)),
                content: SingleChildScrollView(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Semester'),
                        value: selectedSem,
                        items: ['Semester I', 'Semester II'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setDialogState(() {
                              selectedSem = v;
                              subC.clear(); 
                            });
                          }
                        }
                    ),
                    const SizedBox(height: 10),
                    Autocomplete<String>(
                      initialValue: TextEditingValue(text: subC.text),
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          return currentSubjects;
                        }
                        return currentSubjects.where((String option) {
                          return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                        });
                      },
                      onSelected: (String selection) {
                        subC.text = selection;
                      },
                      fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                        // Keep our subC in sync with the internal controller
                        controller.addListener(() {
                          subC.text = controller.text;
                        });
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: const InputDecoration(labelText: 'Subject'),
                          onEditingComplete: onEditingComplete,
                        );
                      },
                    ),
                    TextField(controller: ut1C, decoration: const InputDecoration(labelText: 'UT-I (20)'), keyboardType: TextInputType.number),
                    TextField(controller: ut2C, decoration: const InputDecoration(labelText: 'UT-II (20)'), keyboardType: TextInputType.number),
                    TextField(controller: s1C, decoration: const InputDecoration(labelText: 'Sem Exam (100)'), keyboardType: TextInputType.number),
                    if (isLoading) const Padding(padding: EdgeInsets.only(top: 15), child: LinearProgressIndicator()),
                  ]),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
                  ElevatedButton(
                      onPressed: isLoading ? null : () async {
                        final sub = subC.text.trim();
                        if (sub.isEmpty) return;
                        setDialogState(() => isLoading = true);
                        try {
                          await FirebaseFirestore.instance.collection('exam_marks').add({
                            'roll_no': roll,
                            'studentId': widget.studentId,
                            'subject': sub,
                            'ut1': double.tryParse(ut1C.text) ?? 0,
                            'ut2': double.tryParse(ut2C.text) ?? 0,
                            'sem_exam': double.tryParse(s1C.text) ?? 0,
                            'updatedAt': FieldValue.serverTimestamp()
                          });
                          if (!dialogContext.mounted || !mounted) return;
                          Navigator.pop(dialogContext);
                          ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('Marks Added!'), backgroundColor: Colors.green));
                        } catch (e) {
                          setDialogState(() => isLoading = false);
                          if (!mounted) return;
                          String msg = e.toString().contains('resource-exhausted') || e.toString().contains('Quota exceeded')
                              ? 'Database limit exceeded. Please try again tomorrow.'
                              : 'Error: $e';
                          ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: _primaryTeal, foregroundColor: Colors.white),
                      child: const Text('Save Marks')
                  )
                ]
            );
          });
        }
    );
  }

  void _showEditMarksDialog(String docId, String sub, double ut1, double ut2, double sem1, String roll) {
    final ut1C = TextEditingController(text: ut1.toString());
    final ut2C = TextEditingController(text: ut2.toString());
    final s1C = TextEditingController(text: sem1.toString());
    bool isLoading = false;

    showDialog(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(builder: (context, setDialogState) {
            return AlertDialog(
                title: Text('Edit $sub', style: const TextStyle(fontWeight: FontWeight.bold)),
                content: SingleChildScrollView(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    TextField(controller: ut1C, decoration: const InputDecoration(labelText: 'UT-I (20)'), keyboardType: TextInputType.number),
                    TextField(controller: ut2C, decoration: const InputDecoration(labelText: 'UT-II (20)'), keyboardType: TextInputType.number),
                    TextField(controller: s1C, decoration: const InputDecoration(labelText: 'Sem Exam (100)'), keyboardType: TextInputType.number),
                    if (isLoading) const Padding(padding: EdgeInsets.only(top: 15), child: LinearProgressIndicator()),
                  ]),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
                  ElevatedButton(
                      onPressed: isLoading ? null : () async {
                        setDialogState(() => isLoading = true);
                        try {
                          await FirebaseFirestore.instance.collection('exam_marks').doc(docId).set({
                            'roll_no': roll,
                            'studentId': widget.studentId,
                            'subject': sub,
                            'ut1': double.tryParse(ut1C.text) ?? 0,
                            'ut2': double.tryParse(ut2C.text) ?? 0,
                            'sem_exam': double.tryParse(s1C.text) ?? 0,
                            'updatedAt': FieldValue.serverTimestamp(),
                          }, SetOptions(merge: true));

                          if (!dialogContext.mounted || !mounted) return;
                          Navigator.pop(dialogContext);
                          ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('Marks Updated!'), backgroundColor: Colors.green));
                        } catch (e) {
                          setDialogState(() => isLoading = false);
                          if (!mounted) return;
                          String msg = e.toString().contains('resource-exhausted') || e.toString().contains('Quota exceeded')
                              ? 'Database limit exceeded. Please try again tomorrow.'
                              : 'Error: $e';
                          ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: _primaryTeal, foregroundColor: Colors.white),
                      child: const Text('Update')
                  ),
                ]);
          });
        });
  }
}