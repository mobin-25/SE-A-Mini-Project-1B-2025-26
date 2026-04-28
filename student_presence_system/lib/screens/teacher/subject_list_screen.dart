import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/subject_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// --- PREMIUM COLOR PALETTE ---
const Color _primaryColor = Color(0xFF00483E); // Deep Teal
const Color _bgColor = Color(0xFFF8FAFB);
const Color _surfaceLow = Color(0xFFF2F4F5);
const Color _secondaryFixed = Color(0xFFCFE6F2); // Light Blue
const Color _primaryFixed = Color(0xFFA0F2E1); // Mint Green
const Color _tertiaryFixed = Color(0xFFFFDBC7); // Peach
const Color _textDark = Color(0xFF191C1D);
const Color _textLight = Color(0xFF526772);

// ═══════════════════════════════════════════════════════════
//  SubjectListScreen
// ═══════════════════════════════════════════════════════════
class SubjectListScreen extends StatefulWidget {
  const SubjectListScreen({super.key});

  @override
  State<SubjectListScreen> createState() => _SubjectListScreenState();
}

class _SubjectListScreenState extends State<SubjectListScreen> {
  List<String> _divisions = [];
  String? _selectedDivision;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDivisions();
  }

  Future<void> _loadDivisions() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('settings').doc('divisions').get();
      if (doc.exists) {
        final List<dynamic> divs = doc.data()!['list'] ?? [];
        setState(() {
          _divisions = divs.map((e) => e.toString()).toList()..sort();
          _selectedDivision = _divisions.isNotEmpty ? _divisions.first : null;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _showSubjectDialog({String? docId, Map<String, dynamic>? existing}) async {
    final nameC = TextEditingController(text: existing?['name'] ?? '');
    final codeC = TextEditingController(text: existing?['code'] ?? '');
    String type = existing?['type'] ?? 'Core';
    String semester = existing?['semester'] ?? 'Semester I';
    int credits = existing?['credits'] ?? 4;
    int hours = existing?['weeklyHours'] ?? 4;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Icon(docId == null ? Icons.add_circle : Icons.edit, color: _primaryColor, size: 26),
              const SizedBox(width: 10),
              Text(docId == null ? "Add Subject" : "Edit Subject", style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: _primaryFixed.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(8)),
                  child: Text("Division $_selectedDivision", style: const TextStyle(color: _primaryColor, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameC,
                  decoration: InputDecoration(
                    labelText: "Subject Name *",
                    hintText: "e.g. Data Science",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _primaryColor, width: 2)),
                    prefixIcon: const Icon(Icons.menu_book),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: codeC,
                  decoration: InputDecoration(
                    labelText: "Subject Code *",
                    hintText: "e.g. DS101",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _primaryColor, width: 2)),
                    prefixIcon: const Icon(Icons.tag),
                  ),
                ),
                const SizedBox(height: 16),
                const Text("Semester", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: _textLight, letterSpacing: 1)),
                const SizedBox(height: 8),
                Row(
                  children: ['Semester I', 'Semester II'].map((s) {
                    final bool sel = semester == s;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: GestureDetector(
                        onTap: () => setS(() => semester = s),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: sel ? _primaryColor : _surfaceLow,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: sel ? _primaryColor : Colors.grey.shade300),
                          ),
                          child: Text(s, style: TextStyle(color: sel ? Colors.white : _textLight, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text("Type", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: _textLight, letterSpacing: 1)),
                const SizedBox(height: 8),
                Row(
                  children: ['Core', 'Elective'].map((t) {
                    final bool sel = type == t;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: GestureDetector(
                        onTap: () => setS(() => type = t),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: sel ? _primaryColor : _surfaceLow,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: sel ? _primaryColor : Colors.grey.shade300),
                          ),
                          child: Text(t, style: TextStyle(color: sel ? Colors.white : _textLight, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text("Credits", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: _textLight, letterSpacing: 1)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [1, 2, 3, 4, 5].map((c) {
                    final bool sel = credits == c;
                    return GestureDetector(
                      onTap: () => setS(() => credits = c),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: sel ? _primaryColor : _surfaceLow,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: sel ? _primaryColor : Colors.grey.shade300),
                        ),
                        child: Center(child: Text("$c", style: TextStyle(color: sel ? Colors.white : _textLight, fontWeight: FontWeight.bold, fontSize: 16))),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text("Weekly Hours", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: _textLight, letterSpacing: 1)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: [2, 3, 4, 5, 6, 8, 10, 12].map((h) {
                    final bool sel = hours == h;
                    return GestureDetector(
                      onTap: () => setS(() => hours = h),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: sel ? _primaryColor : _surfaceLow,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: sel ? _primaryColor : Colors.grey.shade300),
                        ),
                        child: Center(child: Text("$h", style: TextStyle(color: sel ? Colors.white : _textLight, fontWeight: FontWeight.bold, fontSize: 14))),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: _textLight))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
              onPressed: () async {
                if (nameC.text.trim().isEmpty || codeC.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name and Code are required!')));
                  return;
                }
                if (docId == null) {
                  await SubjectService.addSubject(division: _selectedDivision!, name: nameC.text, code: codeC.text, type: type, semester: semester, credits: credits, weeklyHours: hours);
                } else {
                  await SubjectService.updateSubject(division: _selectedDivision!, docId: docId, name: nameC.text, code: codeC.text, type: type, semester: semester, credits: credits, weeklyHours: hours);
                }
                if (context.mounted) Navigator.pop(context);
              },
              child: Text(docId == null ? "Add Subject" : "Save Changes"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(String docId, String name) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Delete Subject?", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Delete "$name"?\nThis cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await SubjectService.deleteSubject(division: _selectedDivision!, docId: docId);
    }
  }

  void _openSubject(String docId, Map<String, dynamic> data) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => SubjectDetailScreen(subjectId: docId, subjectData: data, division: _selectedDivision!)));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(backgroundColor: _bgColor, body: Center(child: CircularProgressIndicator(color: _primaryColor)));

    final bool isMobile = !kIsWeb && MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: _bgColor,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.all(isMobile ? 16.0 : 48.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Premium Header ──
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.end,
              runSpacing: 16.0,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("CURRICULUM 2024", style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 2)),
                    const SizedBox(height: 8),
                    const Text("Subject\nManagement", style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, height: 1.1, color: _textDark)),
                  ],
                ),

                // 🔥 THE FIX: Added () => to ensure it fires correctly! 🔥
                ElevatedButton.icon(
                  onPressed: _selectedDivision == null ? null : () => _showSubjectDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text("Add New Subject"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor, foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // ── Division Tabs ──
            if (_divisions.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _divisions.map((div) {
                    final bool sel = _selectedDivision == div;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedDivision = div),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: sel ? _primaryColor : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: sel ? _primaryColor : Colors.grey.shade300),
                        ),
                        child: Text("Division $div", style: TextStyle(color: sel ? Colors.white : _textLight, fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: 32),

            // ── Bento Grid Content ──
            _selectedDivision == null
                ? const Center(child: Text("No divisions available. Add a division in the Teacher Profile."))
                : StreamBuilder<QuerySnapshot>(
              stream: SubjectService.streamSubjects(_selectedDivision!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: _primaryColor)));
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        Icon(Icons.auto_stories, size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text("No subjects found in Division $_selectedDivision", style: TextStyle(color: Colors.grey.shade500, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                }

                final docs = snapshot.data!.docs;
                int totalCredits = docs.fold(0, (acc, doc) => acc + ((doc.data() as Map<String, dynamic>)['credits'] as int? ?? 0));

                final coreDocs = docs.where((d) => (d.data() as Map<String, dynamic>)['type'] == 'Core').toList();
                final electiveDocs = docs.where((d) => (d.data() as Map<String, dynamic>)['type'] != 'Core').toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Summary Card ──
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: SizedBox(
                          width: double.infinity,
                          child: _buildSummaryCard(docs.length, totalCredits),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ── Core Subjects ──
                    if (coreDocs.isNotEmpty) ...[
                      const Text("Core Subjects", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textDark, letterSpacing: 1)),
                      const SizedBox(height: 16),
                      GridView.count(
                        crossAxisCount: isMobile ? 1 : 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 24,
                        mainAxisSpacing: 24,
                        childAspectRatio: isMobile ? 1.5 : 1.1,
                        children: coreDocs.map((doc) => _buildGridCard(doc)).toList(),
                      ),
                      const SizedBox(height: 32),
                    ],

                    // ── Elective Subjects ──
                    if (electiveDocs.isNotEmpty) ...[
                      const Text("Elective Subjects", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textDark, letterSpacing: 1)),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: _surfaceLow, borderRadius: BorderRadius.circular(32)),
                        child: Column(
                          children: electiveDocs.map((doc) => _buildListCard(doc)).toList(),
                        ),
                      )
                    ]
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }



  // --- UI COMPONENT: Resource Index Card ---
  Widget _buildSummaryCard(int totalSubjects, int totalCredits) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: _primaryColor, borderRadius: BorderRadius.circular(40), boxShadow: [BoxShadow(color: _primaryColor.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.analytics, color: _primaryFixed, size: 36),
              const SizedBox(height: 16),
              const Text("Resource Index", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text("Total aggregated resources and curriculum coverage for this division.", style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13, height: 1.5)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("$totalSubjects", style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900)),
                  const Padding(padding: EdgeInsets.only(bottom: 8.0), child: Text("Total Subjects", style: TextStyle(color: _primaryFixed, fontSize: 12, fontWeight: FontWeight.bold))),
                ],
              ),
              const SizedBox(height: 12),
              Container(width: double.infinity, height: 6, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)), child: FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: 0.8, child: Container(decoration: BoxDecoration(color: _primaryFixed, borderRadius: BorderRadius.circular(10))))),
            ],
          )
        ],
      ),
    );
  }

  // --- UI COMPONENT: Standard Grid Card ---
  Widget _buildGridCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final bool isCore = data['type'] == 'Core';
    final Color iconBg = isCore ? _secondaryFixed : _tertiaryFixed;
    final Color iconColor = isCore ? Colors.blue.shade700 : Colors.orange.shade700;
    final IconData icon = isCore ? Icons.calculate : Icons.menu_book;

    return GestureDetector(
      onTap: () => _openSubject(doc.id, data),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(width: 48, height: 48, decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle), child: Icon(icon, color: iconColor)),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.grey),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (val) => val == 'edit' ? _showSubjectDialog(docId: doc.id, existing: data) : _confirmDelete(doc.id, data['name']),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Edit')])),
                  const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 18), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
                ],
              ),
            ],
          ),
          const Spacer(),
          Text(data['name'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textDark), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text("${data['code']} • ${data['type']}", style: const TextStyle(fontSize: 12, color: _textLight)),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: _surfaceLow, borderRadius: BorderRadius.circular(8)), child: Text("${data['credits']} Credits", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _textLight))),
              Row(
                children: const [
                  Text("Open", style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold, fontSize: 12)),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward, color: _primaryColor, size: 16),
                ],
              )
            ],
          )
        ],
      ),
    ));
  }

  // --- UI COMPONENT: Horizontal List Card ---
  Widget _buildListCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final bool isCore = data['type'] == 'Core';

    return GestureDetector(
      onTap: () => _openSubject(doc.id, data),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
        child: Row(
          children: [
          Icon(isCore ? Icons.history_edu : Icons.language, color: Colors.grey.shade400, size: 28),
          const SizedBox(width: 24),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _textDark)),
                const SizedBox(height: 4),
                Text(data['code'] ?? '', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Expanded(flex: 1, child: Text(isCore ? "CORE SUBJECT" : "ELECTIVE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isCore ? _primaryColor : Colors.orange.shade700, letterSpacing: 1))),
          Row(
            children: [
              IconButton(onPressed: () => _showSubjectDialog(docId: doc.id, existing: data), icon: const Icon(Icons.edit, color: Colors.grey, size: 20)),
              IconButton(
                onPressed: () => _openSubject(doc.id, data),
                icon: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: _primaryColor, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.arrow_forward, color: Colors.white, size: 16)),
              )
            ],
          )
        ],
      ),
    ));
  }
}


// ═══════════════════════════════════════════════════════════
//  SubjectDetailScreen
// ═══════════════════════════════════════════════════════════
class SubjectDetailScreen extends StatefulWidget {
  final String subjectId;
  final Map<String, dynamic> subjectData;
  final String division;

  const SubjectDetailScreen({super.key, required this.subjectId, required this.subjectData, required this.division});

  @override
  State<SubjectDetailScreen> createState() => _SubjectDetailScreenState();
}

class _SubjectDetailScreenState extends State<SubjectDetailScreen> {

  Future<void> _showAddResourceDialog() async {
    final titleC = TextEditingController();
    final linkC  = TextEditingController();
    String selectedType = 'PDF';
    final types = ['PDF', 'Slides', 'Video', 'Doc', 'Other'];

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: const [
              Icon(Icons.add_link, color: _primaryColor, size: 26),
              SizedBox(width: 10),
              Text("Add Resource", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleC,
                  decoration: InputDecoration(
                    labelText: "Title *", hintText: "e.g. Unit 1 Notes",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _primaryColor, width: 2)),
                    prefixIcon: const Icon(Icons.title),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: linkC, keyboardType: TextInputType.url,
                  decoration: InputDecoration(
                    labelText: "Link *", hintText: "https://drive.google.com/...",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _primaryColor, width: 2)),
                    prefixIcon: const Icon(Icons.link),
                  ),
                ),
                const SizedBox(height: 16),
                const Text("Type", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: types.map((t) {
                    final bool sel = selectedType == t;
                    return GestureDetector(
                      onTap: () => setS(() => selectedType = t),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: sel ? _primaryColor : _surfaceLow,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: sel ? _primaryColor : Colors.grey.shade300),
                        ),
                        child: Text(t, style: TextStyle(color: sel ? Colors.white : _textLight, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: _textLight))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
              onPressed: () async {
                final title = titleC.text.trim();
                final link  = linkC.text.trim();

                if (title.isEmpty || link.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title and Link are required!')));
                  return;
                }
                if (!link.startsWith('http://') && !link.startsWith('https://')) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid URL starting with http:// or https://')));
                  return;
                }

                await FirebaseFirestore.instance.collection('notes').add({
                  'title':     title,
                  'link':      link,
                  'type':      selectedType,
                  'subject':   widget.subjectData['name'] ?? '',
                  'subjectId': widget.subjectId,
                  'division':  widget.division,
                  'addedBy':   FirebaseAuth.instance.currentUser?.uid ?? '',
                  'timestamp': FieldValue.serverTimestamp(),
                });

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Resource added!'), backgroundColor: Colors.green));
                }
              },
              child: const Text("Add Resource"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteNote(String docId, String title) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Delete Resource?", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Delete "$title"?\nThis cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    await FirebaseFirestore.instance.collection('notes').doc(docId).delete();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Resource deleted.'), backgroundColor: Colors.orange));
    }
  }

  IconData _typeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':    return Icons.picture_as_pdf;
      case 'slides': return Icons.slideshow;
      case 'video':  return Icons.play_circle_outline;
      case 'doc':    return Icons.description;
      default:       return Icons.insert_link;
    }
  }

  Color _typeColor(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':    return Colors.red;
      case 'slides': return Colors.orange;
      case 'video':  return Colors.purple;
      case 'doc':    return Colors.blue;
      default:       return Colors.teal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final data    = widget.subjectData;
    final String name    = data['name']        ?? '';
    final String code    = data['code']        ?? '';
    final String type    = data['type']        ?? 'Core';
    final int    credits = data['credits']     ?? 0;
    final int    hours   = data['weeklyHours'] ?? 0;
    final bool isMobile  = !kIsWeb && MediaQuery.of(context).size.width < 850;

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _primaryColor,
        elevation: 0,
        title: const Text("Resource Management", style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 12 : 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Premium Subject Header ──
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(isMobile ? 16 : 32),
              decoration: BoxDecoration(
                color: _primaryColor,
                borderRadius: BorderRadius.circular(isMobile ? 20 : 32),
                boxShadow: [BoxShadow(color: _primaryColor.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isMobile ? 10 : 20),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(24)),
                    child: Icon(Icons.science, color: _primaryFixed, size: isMobile ? 24 : 48),
                  ),
                  SizedBox(width: isMobile ? 12 : 32),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: TextStyle(fontSize: isMobile ? 20 : 32, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 6),
                        Text(code, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: isMobile ? 12 : 16)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: _primaryFixed, borderRadius: BorderRadius.circular(6)),
                              child: Text(type.toUpperCase(), style: const TextStyle(color: _primaryColor, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1)),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star, size: 14, color: Colors.amber.shade400),
                                const SizedBox(width: 4),
                                Text("$credits Credits", style: const TextStyle(fontSize: 12, color: Colors.white)),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.access_time, size: 14, color: Colors.white),
                                const SizedBox(width: 4),
                                Text("$hours hrs/week", style: const TextStyle(fontSize: 12, color: Colors.white)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: isMobile ? 24 : 48),

            // ── Notes List ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text("Curriculum Materials", style: TextStyle(fontSize: isMobile ? 18 : 24, fontWeight: FontWeight.bold, color: _textDark), overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _showAddResourceDialog(),
                  icon: Icon(Icons.add, size: isMobile ? 14 : 18),
                  label: Text(isMobile ? "Add" : "Upload Material", style: TextStyle(fontSize: isMobile ? 12 : 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryFixed, foregroundColor: _primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24, vertical: isMobile ? 8 : 16),
                    elevation: 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('notes').where('subjectId', isEqualTo: widget.subjectId).where('division', isEqualTo: widget.division).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: _primaryColor));

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(48),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32), border: Border.all(color: Colors.grey.shade200, width: 2)),
                    child: Column(
                      children: [
                        Icon(Icons.folder_open, size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text("No resources available.\nClick 'Upload Material' to add links.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade500, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                }

                // Local sort to avoid requiring a composite index in Firestore
                final docs = snapshot.data!.docs.toList();
                docs.sort((a, b) {
                  final aTime = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                  final bTime = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                  if (aTime == null && bTime == null) return 0;
                  if (aTime == null) return 1;
                  if (bTime == null) return -1;
                  return bTime.compareTo(aTime); // Descending
                });

                return Column(
                  children: docs.map((doc) {
                    final note      = doc.data() as Map<String, dynamic>;
                    final String t  = note['title'] ?? 'Untitled';
                    final String l  = note['link']  ?? '';
                    final String tp = note['type']  ?? 'Other';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: EdgeInsets.all(isMobile ? 12 : 24),
                      decoration: BoxDecoration(
                        color: Colors.white, borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(isMobile ? 10 : 16),
                            decoration: BoxDecoration(color: _typeColor(tp).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                            child: Icon(_typeIcon(tp), color: _typeColor(tp), size: isMobile ? 20 : 28),
                          ),
                          SizedBox(width: isMobile ? 10 : 24),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(t, style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 14 : 18, color: _textDark), overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                Text(tp.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _typeColor(tp), letterSpacing: 1)),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () async {
                              final uri = Uri.tryParse(l);
                              if (uri != null && await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
                            },
                            icon: Icon(Icons.open_in_new, color: _primaryColor, size: isMobile ? 16 : 24),
                            style: IconButton.styleFrom(backgroundColor: _secondaryFixed, padding: EdgeInsets.all(isMobile ? 6 : 12)),
                          ),
                          SizedBox(width: isMobile ? 4 : 12),
                          IconButton(
                            onPressed: () => _deleteNote(doc.id, t),
                            icon: Icon(Icons.delete, color: Colors.red, size: isMobile ? 16 : 24),
                            style: IconButton.styleFrom(backgroundColor: Colors.red.shade50, padding: EdgeInsets.all(isMobile ? 6 : 12)),
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
      ),
    );
  }
}