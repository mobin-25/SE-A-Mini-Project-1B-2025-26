import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/subject_service.dart';
import '../../services/excel_service.dart';

// ═══════════════════════════════════════════════════════════
//  ExaminationMarksScreen
//  Lists all students from the `students` collection
//  (inserted via Excel upload) filtered by division.
//  Teacher enters UT-I, UT-II, Sem-I, Sem-II per subject.
// ═══════════════════════════════════════════════════════════

// App-wide theme colors (matching teacher_dashboard.dart)
const Color _kPrimary   = Color(0xFF00483E); // Deep Teal
const Color _kBg        = Color(0xFFF8FAFB);
const Color _kSurface   = Color(0xFFF2F4F5);
const Color _kTextDark  = Color(0xFF191C1D);
const Color _kTextLight = Color(0xFF526772);

class ExaminationMarksScreen extends StatefulWidget {
  final String division;
  const ExaminationMarksScreen({super.key, required this.division});

  @override
  State<ExaminationMarksScreen> createState() =>
      _ExaminationMarksScreenState();
}

class _ExaminationMarksScreenState extends State<ExaminationMarksScreen> {
  String _searchQuery = '';
  String? _selectedSubject;
  List<String> _subjects = [];
  bool _loadingSubjects = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _fetchSubjects();
  }

  Future<void> _fetchSubjects() async {
    try {
      final subData = await SubjectService.getSubjects(widget.division);

      final subjects = subData
          .map((s) => (s['name'] ?? '').toString())
          .where((n) => n.isNotEmpty)
          .toList()
        ..sort();

      if (mounted) {
        setState(() {
          _subjects = subjects;
          _loadingSubjects = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingSubjects = false);
      }
    }
  }

  void _handleExport() async {
    setState(() => _isProcessing = true);
    await ExcelService.exportMarksToExcel(context, widget.division);
    if (mounted) setState(() => _isProcessing = false);
  }

  void _handleImport() async {
    setState(() => _isProcessing = true);
    await ExcelService.importMarksFromExcel(context, widget.division);
    if (mounted) setState(() => _isProcessing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Examination Marks',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'Division ${widget.division}',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload),
            tooltip: 'Import from Excel',
            onPressed: _isProcessing ? null : _handleImport,
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: 'Export to Excel',
            onPressed: _isProcessing ? null : _handleExport,
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(66),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                // ── Search Field ──
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search student...',
                      hintStyle: const TextStyle(color: Colors.white60, fontSize: 14),
                      prefixIcon: const Icon(Icons.search, color: Colors.white60, size: 20),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.15),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // ── Subject Filter ──
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      canvasColor: _kPrimary,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedSubject,
                        hint: const Text('All Subjects', style: TextStyle(color: Colors.white60, fontSize: 13)),
                        icon: const Icon(Icons.filter_list, color: Colors.white, size: 18),
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('All Subjects'),
                          ),
                          ..._subjects.map((s) => DropdownMenuItem(
                            value: s,
                            child: SizedBox(
                              width: 100,
                              child: Text(s, overflow: TextOverflow.ellipsis),
                            ),
                          )),
                        ],
                        onChanged: (v) => setState(() => _selectedSubject = v),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          _loadingSubjects 
              ? const Center(child: CircularProgressIndicator(color: _kPrimary))
              : _buildMainContent(),
          if (_isProcessing)
            Container(
              color: Colors.black26,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: _kPrimary),
                        SizedBox(height: 16),
                        Text('Processing Excel...', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('students')
            .where('division', isEqualTo: widget.division)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: _kPrimary));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: _kPrimary.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.people_outline, size: 52, color: _kPrimary.withValues(alpha: 0.5)),
                  ),
                  const SizedBox(height: 20),
                  Text('No students in Division ${widget.division}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _kTextLight)),
                  const SizedBox(height: 8),
                  Text('Upload students via Excel from the home screen', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                ],
              ),
            );
          }

          final docs = [...snapshot.data!.docs]..sort((a, b) {
              final aRoll = int.tryParse((a.data() as Map)['roll_no']?.toString() ?? '0') ?? 0;
              final bRoll = int.tryParse((b.data() as Map)['roll_no']?.toString() ?? '0') ?? 0;
              return aRoll.compareTo(bRoll);
            });

          final filtered = _searchQuery.isEmpty ? docs : docs.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  final roll = (data['roll_no'] ?? '').toString().toLowerCase();
                  return name.contains(_searchQuery) || roll.contains(_searchQuery);
                }).toList();

          if (filtered.isEmpty) {
            return Center(child: Text('No students match "$_searchQuery"', style: const TextStyle(color: _kTextLight)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final doc = filtered[index];
              final data = doc.data() as Map<String, dynamic>;
              return _StudentMarksTile(
                studentName: data['name'] ?? 'Unknown',
                rollNo: data['roll_no'] ?? '',
                division: widget.division,
                filterSubject: _selectedSubject,
              );
            },
          );
        },
    );
  }
}

// ─────────────────────────────────────────────────────────
//  _StudentMarksTile  –  Expandable card per student
// ─────────────────────────────────────────────────────────
class _StudentMarksTile extends StatefulWidget {
  final String studentName;
  final String rollNo;
  final String division;
  final String? filterSubject;

  const _StudentMarksTile({
    required this.studentName,
    required this.rollNo,
    required this.division,
    this.filterSubject,
  });

  @override
  State<_StudentMarksTile> createState() => _StudentMarksTileState();
}

class _StudentMarksTileState extends State<_StudentMarksTile>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _animCtrl;
  late final Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 260));
    _expandAnim =
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _animCtrl.forward() : _animCtrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final initial = widget.studentName.isNotEmpty
        ? widget.studentName[0].toUpperCase()
        : 'S';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        children: [
          // ── Header row ──────────────────────────────────
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _toggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: _kPrimary.withValues(alpha: 0.1),
                    child: Text(
                      initial,
                      style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: _kPrimary),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.studentName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: _kTextDark),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Roll No: ${widget.rollNo}',
                          style: const TextStyle(
                              fontSize: 12, color: _kTextLight),
                        ),
                      ],
                    ),
                  ),
                  // Live marks % badge
                  _MarksBadge(rollNo: widget.rollNo, filterSubject: widget.filterSubject),
                  const SizedBox(width: 8),
                  RotationTransition(
                    turns:
                        Tween(begin: 0.0, end: 0.5).animate(_expandAnim),
                    child: Icon(Icons.expand_more,
                        color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),
          ),

          // ── Expandable marks form ────────────────────────
          SizeTransition(
            sizeFactor: _expandAnim,
            child: _MarksForm(
              rollNo: widget.rollNo,
              studentName: widget.studentName,
              division: widget.division,
              filterSubject: widget.filterSubject,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  _MarksBadge  –  Live percentage pill
// ─────────────────────────────────────────────────────────
class _MarksBadge extends StatelessWidget {
  final String rollNo;
  final String? filterSubject;
  const _MarksBadge({required this.rollNo, this.filterSubject});

  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance
          .collection('exam_marks')
          .where('roll_no', isEqualTo: rollNo);
    
    if (filterSubject != null) {
      query = query.where('subject', isEqualTo: filterSubject);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: _kSurface,
                borderRadius: BorderRadius.circular(20)),
            child: const Text('No marks',
                style: TextStyle(fontSize: 11, color: _kTextLight)),
          );
        }
        final docs = snap.data!.docs;
        double total = 0;
        double max = 0;
        for (final d in docs) {
          final m = d.data() as Map<String, dynamic>;
          total += ((m['ut1'] ?? 0) as num).toDouble() +
              ((m['ut2'] ?? 0) as num).toDouble() +
              ((m['sem_exam'] ?? 0) as num).toDouble();
          max += 140; // 20+20+100 per subject
        }
        final pct = max > 0 ? (total / max * 100) : 0.0;
        final color = pct >= 75
            ? Colors.green.shade600
            : (pct >= 50 ? Colors.orange.shade700 : Colors.red.shade600);
        return Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20)),
          child: Text(
            '${pct.toStringAsFixed(0)}%',
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold, color: color),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────
//  _MarksForm  –  Inline subject × marks table
// ─────────────────────────────────────────────────────────
class _MarksForm extends StatefulWidget {
  final String rollNo;
  final String studentName;
  final String division;
  final String? filterSubject;

  const _MarksForm({
    required this.rollNo,
    required this.studentName,
    required this.division,
    this.filterSubject,
  });

  @override
  State<_MarksForm> createState() => _MarksFormState();
}

class _MarksFormState extends State<_MarksForm> {
  bool _loading = true;
  bool _saving = false;

  Map<String, String?> _docIds = {};
  Map<String, Map<String, TextEditingController>> _controllers = {};
  List<String> _subjects = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // 1. Fetch subjects for this division using SubjectService
    final subData = await SubjectService.getSubjects(widget.division);

    List<String> subjects = subData
        .map((s) => (s['name'] ?? '').toString())
        .where((n) => n.isNotEmpty)
        .toList()
      ..sort();

    if (subjects.isEmpty) subjects = ['General'];

    // 2. Set up controllers
    final controllers =
        <String, Map<String, TextEditingController>>{};
    final docIds = <String, String?>{};

    for (final s in subjects) {
      controllers[s] = {
        'ut1': TextEditingController(),
        'ut2': TextEditingController(),
        'sem_exam': TextEditingController(),
      };
      docIds[s] = null;
    }

    // 3. Load existing saved marks
    final marksSnap = await FirebaseFirestore.instance
        .collection('exam_marks')
        .where('roll_no', isEqualTo: widget.rollNo)
        .get();

    for (final doc in marksSnap.docs) {
      final d = doc.data();
      final subject = d['subject'] as String? ?? '';
      if (controllers.containsKey(subject)) {
        controllers[subject]!['ut1']!.text =
            (d['ut1'] ?? '').toString();
        controllers[subject]!['ut2']!.text =
            (d['ut2'] ?? '').toString();
        controllers[subject]!['sem_exam']!.text =
            (d['sem_exam'] ?? '').toString();
        docIds[subject] = doc.id;
      }
    }

    if (mounted) {
      setState(() {
        _subjects = subjects;
        _controllers = controllers;
        _docIds = docIds;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    for (final m in _controllers.values) {
      for (final c in m.values) c.dispose();
    }
    super.dispose();
  }

  Future<void> _saveAll() async {
    setState(() => _saving = true);
    try {
      final batch = FirebaseFirestore.instance.batch();
      final col = FirebaseFirestore.instance.collection('exam_marks');

      for (final subject in _subjects) {
        final cMap = _controllers[subject]!;
        final data = {
          'roll_no': widget.rollNo,
          'student_name': widget.studentName,
          'division': widget.division,
          'subject': subject,
          'ut1': double.tryParse(cMap['ut1']!.text) ?? 0,
          'ut2': double.tryParse(cMap['ut2']!.text) ?? 0,
          'sem_exam': double.tryParse(cMap['sem_exam']!.text) ?? 0,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        final docId = _docIds[subject];
        final ref = docId != null ? col.doc(docId) : col.doc();
        batch.set(ref, data, SetOptions(merge: true));
        _docIds[subject] = ref.id;
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text('Marks saved for ${widget.studentName}')),
            ]),
            backgroundColor: _kPrimary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child:
            Center(child: CircularProgressIndicator(color: _kPrimary, strokeWidth: 2)),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: _kBg,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Row ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Academic Performance",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _kTextDark)),
                  Text("Manage marks for ${_subjects.length} subjects",
                      style: const TextStyle(fontSize: 11, color: _kTextLight)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _saving ? null : _saveAll,
                icon: _saving
                    ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save_rounded, size: 14),
                label: Text(_saving ? 'Saving...' : 'Save All', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Subject Cards Grid/List ──
          ..._subjects
              .where((s) => widget.filterSubject == null || s == widget.filterSubject)
              .map((subject) {
            final cMap = _controllers[subject]!;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Subject Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _kPrimary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.menu_book_rounded, color: _kPrimary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(subject,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _kTextDark),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            const Text("Core Subject", style: TextStyle(color: _kTextLight, fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Marks Input Section
                  Row(
                    children: [
                      _cardField("UT-I", cMap['ut1']!, 20),
                      _divider(),
                      _cardField("UT-II", cMap['ut2']!, 20),
                      _divider(),
                      _cardField("Sem Exam", cMap['sem_exam']!, 100),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 30, color: Colors.grey.shade100, margin: const EdgeInsets.symmetric(horizontal: 4));

  Widget _cardField(String title, TextEditingController c, int max) {
    return Expanded(
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: _kTextLight)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              SizedBox(
                width: 30,
                child: TextField(
                  controller: c,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _kTextDark),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    hintText: '0',
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 15),
                  ),
                ),
              ),
              Text("/$max", style: TextStyle(color: Colors.grey.shade400, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
