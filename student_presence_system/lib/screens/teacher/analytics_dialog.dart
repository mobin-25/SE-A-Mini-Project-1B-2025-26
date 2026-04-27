import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdvancedAnalyticsDashboard extends StatefulWidget {
  const AdvancedAnalyticsDashboard({super.key});

  @override
  State<AdvancedAnalyticsDashboard> createState() => _AdvancedAnalyticsDashboardState();
}

class _AdvancedAnalyticsDashboardState extends State<AdvancedAnalyticsDashboard> {
  // --- SYNCED FILTER STATE ---
  Map<String, double> divisionAttendance = {};
  Map<String, double> subjectPerformance = {};

  // --- LIVE DATA STATE ---
  double avgMonthlyRate = 0.0;
  int totalAbsences = 0;
  String highestDay = "N/A";
  String lowestDay = "N/A";

  // --- DYNAMIC FILTERS ---
  List<String> dynamicDivisions = ['All Divisions'];
  List<String> dynamicSubjects = ['All Subjects'];
  bool isLoadingSubjects = false;
  bool isLoadingDivisions = false;

  final List<String> months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  final List<String> academicYears = ['2025', '2026'];

  // Theme Colors
  final Color primaryBlue = const Color(0xFF1D4ED8);
  final Color bgGray = const Color(0xFFF4F7FE);
  final Color textDark = const Color(0xFF1E293B);
  final Color textLight = const Color(0xFF64748B);

  // Filter State
  String selectedDivision = 'All Divisions';
  String selectedSubject = 'All Subjects';
  String selectedMonth = 'October';
  String selectedYear = '2026';

  // Chart Colors
  final Color colorA = const Color(0xFF3B82F6);
  final Color colorB = const Color(0xFF10B981);
  final Color colorC = const Color(0xFFF59E0B);
  final Color colorD = const Color(0xFFEC4899);
  final Color colorE = const Color(0xFF8B5CF6);

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _initDashboard();
  }

  Future<void> _initDashboard() async {
    await _loadDivisions();
    await _loadSubjects();
    _applyFilters();
  }

  // 🔥 FETCH DIVISIONS DYNAMICALLY
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
          dynamicDivisions = ['All Divisions', ...divs.map((e) => 'Div ${e.toString()}')];
          if (!dynamicDivisions.contains(selectedDivision)) {
             selectedDivision = 'All Divisions';
          }
        });
      }
    } catch (e) {
      debugPrint("Error loading divisions: $e");
    }
    setState(() => isLoadingDivisions = false);
  }

  // 🔥 FETCH SUBJECTS DYNAMICALLY
  Future<void> _loadSubjects() async {
    setState(() => isLoadingSubjects = true);
    try {
      Set<String> allSubs = {'All Subjects'};
      
      if (selectedDivision == 'All Divisions') {
        // Fetch from the actual list of divisions we just loaded
        List<String> activeDivs = dynamicDivisions
            .where((d) => d != 'All Divisions')
            .map((d) => d.replaceAll('Div ', ''))
            .toList();

        for (var div in activeDivs) {
          final snap = await FirebaseFirestore.instance
              .collection('subjects')
              .doc(div)
              .collection('list')
              .get();
          for (var doc in snap.docs) {
            allSubs.add(doc['name'] as String);
          }
        }
      } else {
        // Fetch from specific division
        String div = selectedDivision.replaceAll('Div ', '');
        final snap = await FirebaseFirestore.instance
            .collection('subjects')
            .doc(div)
            .collection('list')
            .get();
        for (var doc in snap.docs) {
          allSubs.add(doc['name'] as String);
        }
      }

      setState(() {
        dynamicSubjects = allSubs.toList();
        // Reset selected subject if it's no longer valid
        if (!dynamicSubjects.contains(selectedSubject)) {
          selectedSubject = 'All Subjects';
        }
      });
    } catch (e) {
      debugPrint("Error loading subjects: $e");
    }
    setState(() => isLoadingSubjects = false);
  }

  // 🔥 CORE LOGIC: FIRESTORE AGGREGATION & SYNC
  Future<void> _applyFilters() async {
    setState(() => isLoading = true);

    try {
      int monthIndex = months.indexOf(selectedMonth) + 1;
      int year = int.parse(selectedYear);

      Query query = FirebaseFirestore.instance.collection('attendance');

      DateTime start = DateTime(year, monthIndex, 1);
      DateTime end = DateTime(year, monthIndex + 1, 1).subtract(const Duration(seconds: 1));

      query = query.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end));

      final snapshot = await query.get();
      var docs = snapshot.docs;

      // Local Filter for Division/Subject to match database strings
      if (selectedDivision != 'All Divisions') {
        String targetDiv = selectedDivision.replaceAll('Div ', '');
        docs = docs.where((d) => d['division'] == targetDiv).toList();
      }
      if (selectedSubject != 'All Subjects') {
        docs = docs.where((d) => d['subject'] == selectedSubject).toList();
      }

      if (docs.isEmpty) {
        setState(() {
          avgMonthlyRate = 0.0; totalAbsences = 0; highestDay = "N/A"; lowestDay = "N/A";
          divisionAttendance = {"A": 0, "B": 0, "C": 0, "D": 0};
          subjectPerformance = {};
          isLoading = false;
        });
        return;
      }

      // Calculate Metrics
      int totalDocs = docs.length;
      int presentCount = docs.where((d) => d['status'] == 'Present').length;
      int absentCount = docs.where((d) => d['status'] == 'Absent').length;

      // Division Comparison
      Map<String, double> newDivData = {};
      List<String> activeDivs = dynamicDivisions
          .where((d) => d != 'All Divisions')
          .map((d) => d.replaceAll('Div ', ''))
          .toList();

      for (var div in activeDivs) {
        var divDocs = docs.where((d) => d['division'] == div).toList();
        newDivData[div] = divDocs.isEmpty ? 0.0 :
        divDocs.where((d) => d['status'] == 'Present').length / divDocs.length;
      }

      // Subject Performance
      Map<String, double> newSubData = {};
      for (var sub in dynamicSubjects) {
        if (sub == 'All Subjects') continue;
        var subDocs = docs.where((d) => d['subject'] == sub).toList();
        newSubData[sub] = subDocs.isEmpty ? 0.0 :
        subDocs.where((d) => d['status'] == 'Present').length / subDocs.length;
      }

      // Highest/Lowest Attendance Days
      Map<String, int> dailyCounts = {};
      for (var d in docs) {
        String dateKey = DateFormat('MMM dd').format((d['date'] as Timestamp).toDate());
        if (d['status'] == 'Present') {
          dailyCounts[dateKey] = (dailyCounts[dateKey] ?? 0) + 1;
        }
      }
      var sortedDays = dailyCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

      setState(() {
        avgMonthlyRate = (presentCount / totalDocs) * 100;
        totalAbsences = absentCount;
        divisionAttendance = newDivData;
        subjectPerformance = newSubData;
        highestDay = sortedDays.isNotEmpty ? sortedDays.first.key : "N/A";
        lowestDay = sortedDays.isNotEmpty ? sortedDays.last.key : "N/A";
        isLoading = false;
      });

    } catch (e) {
      debugPrint("Analytics Error: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;
    return Scaffold(
      backgroundColor: bgGray,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isDesktop ? 32.0 : 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- HEADER WITH BACK ARROW ---
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, size: 24),
                    color: textDark,
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Overview Dashboard", style: TextStyle(fontSize: isDesktop ? 28 : 20, fontWeight: FontWeight.bold, color: textDark), overflow: TextOverflow.ellipsis),
                        Text("Real-time attendance tracking.", style: TextStyle(fontSize: isDesktop ? 15 : 12, color: textLight), overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFilterSidebar(isDesktop),
                    const SizedBox(width: 32),
                    Expanded(
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : Column(
                        children: [
                          _buildKPIRow(isDesktop),
                          const SizedBox(height: 32),
                          IntrinsicHeight(
                            child: Row(
                              children: [
                                Expanded(child: _buildDivisionChart()),
                                const SizedBox(width: 32),
                                Expanded(child: _buildSubjectChart()),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    _buildFilterSidebar(isDesktop),
                    const SizedBox(height: 16),
                    if (isLoading)
                      const Center(child: CircularProgressIndicator())
                    else ...[  
                      _buildKPIRow(isDesktop),
                      const SizedBox(height: 16),
                      _buildDivisionChart(),
                      const SizedBox(height: 16),
                      _buildSubjectChart(),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI WIDGETS ---

  Widget _buildFilterSidebar(bool isDesktop) {
    return Container(
      width: isDesktop ? 300 : double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: isDesktop
          ? Column(
              children: [
                _buildFilterDropdown("ACADEMIC YEAR", academicYears, selectedYear, (v) => setState(() => selectedYear = v!)),
                const SizedBox(height: 16),
                _buildFilterDropdown("MONTH", months, selectedMonth, (v) => setState(() => selectedMonth = v!)),
                const SizedBox(height: 16),
                _buildFilterDropdown("DIVISION", dynamicDivisions, selectedDivision, (v) {
                  setState(() => selectedDivision = v!);
                  _loadSubjects(); // Re-load subjects when division changes
                }),
                const SizedBox(height: 16),
                _buildFilterDropdown("SUBJECT", dynamicSubjects, selectedSubject, (v) => setState(() => selectedSubject = v!)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _applyFilters,
                  style: ElevatedButton.styleFrom(backgroundColor: primaryBlue, minimumSize: const Size(double.infinity, 48)),
                  child: const Text("Apply Filters", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                )
              ],
            )
          // Mobile: 2x2 grid layout for filters
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: _buildFilterDropdown("ACADEMIC YEAR", academicYears, selectedYear, (v) => setState(() => selectedYear = v!))),
                    const SizedBox(width: 12),
                    Expanded(child: _buildFilterDropdown("MONTH", months, selectedMonth, (v) => setState(() => selectedMonth = v!))),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildFilterDropdown("DIVISION", dynamicDivisions, selectedDivision, (v) {
                      setState(() => selectedDivision = v!);
                      _loadSubjects(); // Re-load subjects
                    })),
                    const SizedBox(width: 12),
                    Expanded(child: _buildFilterDropdown("SUBJECT", dynamicSubjects, selectedSubject, (v) => setState(() => selectedSubject = v!))),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _applyFilters,
                  style: ElevatedButton.styleFrom(backgroundColor: primaryBlue, minimumSize: const Size(double.infinity, 48)),
                  child: const Text("Apply Filters", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
    );
  }

  Widget _buildKPIRow(bool isDesktop) {
    if (isDesktop) {
      return Row(
        children: [
          Expanded(child: _buildKPIBox("Avg Monthly Rate", "${avgMonthlyRate.toStringAsFixed(1)}%", Icons.trending_up, Colors.green)),
          const SizedBox(width: 16),
          Expanded(child: _buildKPIBox("Highest Attendance", highestDay, Icons.event, primaryBlue)),
          const SizedBox(width: 16),
          Expanded(child: _buildKPIBox("Total Absences", totalAbsences.toString(), Icons.warning_amber, Colors.orange)),
          const SizedBox(width: 16),
          Expanded(child: _buildKPIBox("Lowest Day", lowestDay, Icons.trending_down, Colors.red)),
        ],
      );
    }
    // Mobile: 2x2 grid
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildKPIBox("Avg Rate", "${avgMonthlyRate.toStringAsFixed(1)}%", Icons.trending_up, Colors.green)),
            const SizedBox(width: 12),
            Expanded(child: _buildKPIBox("Highest Day", highestDay, Icons.event, primaryBlue)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildKPIBox("Total Absences", totalAbsences.toString(), Icons.warning_amber, Colors.orange)),
            const SizedBox(width: 12),
            Expanded(child: _buildKPIBox("Lowest Day", lowestDay, Icons.trending_down, Colors.red)),
          ],
        ),
      ],
    );
  }

  Widget _buildKPIBox(String title, String val, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 12),
          Text(val, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textDark)),
          Text(title, style: TextStyle(color: textLight, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildDivisionChart() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Attendance by Division", style: TextStyle(fontWeight: FontWeight.bold, color: textDark)),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: divisionAttendance.entries.map((e) => _buildBar(e.key, e.value)).toList(),
          ),
        ],
      ),
    );
  }

  // 🔥 UPGRADED: Percentage floating on top of the bars
  Widget _buildBar(String label, double val) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          "${(val * 100).toStringAsFixed(0)}%",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: textDark,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 30,
          height: 150 * (val > 0 ? val : 0.05),
          decoration: BoxDecoration(
            color: colorA,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Div $label",
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: textLight,
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectChart() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Subject Performance", style: TextStyle(fontWeight: FontWeight.bold, color: textDark)),
          const SizedBox(height: 24),
          ...subjectPerformance.entries.map((e) {
            List<Color> barColors = [colorA, colorB, colorC, colorD, colorE];
            int idx = subjectPerformance.keys.toList().indexOf(e.key);
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: _buildHorizontalBar(e.key, "${(e.value * 100).toStringAsFixed(0)}%", e.value, barColors[idx % 5]),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHorizontalBar(String label, String pct, double fill, Color col) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(fontSize: 12)), Text(pct, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))]),
        const SizedBox(height: 4),
        Stack(children: [
          Container(width: double.infinity, height: 8, decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4))),
          FractionallySizedBox(widthFactor: fill > 0 ? fill : 0.01, child: Container(height: 8, decoration: BoxDecoration(color: col, borderRadius: BorderRadius.circular(4)))),
        ]),
      ],
    );
  }

  Widget _buildFilterDropdown(String label, List<String> items, String current, ValueChanged<String?> onCh) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
        DropdownButton<String>(value: current, isExpanded: true, items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(), onChanged: onCh),
      ],
    );
  }
}