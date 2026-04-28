import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/subject_service.dart';

// ═══════════════════════════════════════════════════════════
//  SubjectsCard
//  Dynamic subjects card for teacher dashboard.
//  Teacher picks a division → sees subjects → can add/edit/delete
// ═══════════════════════════════════════════════════════════
class SubjectsCard extends StatefulWidget {
  final List<String> divisions; // divisions already added by teacher

  const SubjectsCard({super.key, required this.divisions});

  @override
  State<SubjectsCard> createState() => _SubjectsCardState();
}

class _SubjectsCardState extends State<SubjectsCard> {
  String? _selectedDivision;

  @override
  void initState() {
    super.initState();
    if (widget.divisions.isNotEmpty) {
      _selectedDivision = widget.divisions.first;
    }
  }

  // ── Add / Edit Subject dialog ─────────────────────────────
  Future<void> _showSubjectDialog({
    String? docId,
    Map<String, dynamic>? existing,
  }) async {
    final nameC =
    TextEditingController(text: existing?['name'] ?? '');
    final codeC =
    TextEditingController(text: existing?['code'] ?? '');
    String type = existing?['type'] ?? 'Core';
    String semester = existing?['semester'] ?? 'Semester I';
    int credits = existing?['credits'] ?? 4;
    int hours = existing?['weeklyHours'] ?? 4;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(
                docId == null ? Icons.add_circle : Icons.edit,
                color: Colors.purple.shade600,
                size: 26,
              ),
              const SizedBox(width: 10),
              Text(docId == null ? "Add Subject" : "Edit Subject",
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Division chip
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "Division $_selectedDivision",
                    style: TextStyle(
                        color: Colors.teal.shade700,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),

                // Subject Name
                TextField(
                  controller: nameC,
                  decoration: InputDecoration(
                    labelText: "Subject Name *",
                    hintText: "e.g. Data Science",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    prefixIcon: const Icon(Icons.menu_book),
                  ),
                ),
                const SizedBox(height: 12),

                // Subject Code
                TextField(
                  controller: codeC,
                  decoration: InputDecoration(
                    labelText: "Subject Code *",
                    hintText: "e.g. DS101",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    prefixIcon: const Icon(Icons.tag),
                  ),
                ),
                const SizedBox(height: 12),

                // Semester
                const Text("Semester",
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: sel
                                ? Colors.teal.shade600
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: sel
                                  ? Colors.teal.shade600
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Text(s,
                              style: TextStyle(
                                  color: sel
                                      ? Colors.white
                                      : Colors.grey.shade700,
                                  fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),

                // Type
                const Text("Type",
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: sel
                                ? Colors.purple.shade600
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: sel
                                  ? Colors.purple.shade600
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Text(t,
                              style: TextStyle(
                                  color: sel
                                      ? Colors.white
                                      : Colors.grey.shade700,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),

                // Credits
                const Text("Credits",
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  children: [1, 2, 3, 4, 5].map((c) {
                    final bool sel = credits == c;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setS(() => credits = c),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: sel
                                ? Colors.teal.shade700
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: sel
                                  ? Colors.teal.shade700
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Center(
                            child: Text("$c",
                                style: TextStyle(
                                    color: sel
                                        ? Colors.white
                                        : Colors.grey.shade700,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),

                // Weekly Hours
                const Text("Weekly Hours",
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  children: [2, 3, 4, 5, 6, 8, 10, 12].map((h) {
                    final bool sel = hours == h;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: GestureDetector(
                        onTap: () => setS(() => hours = h),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: sel
                                ? Colors.indigo.shade600
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: sel
                                  ? Colors.indigo.shade600
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Center(
                            child: Text("$h",
                                style: TextStyle(
                                    fontSize: 12,
                                    color: sel
                                        ? Colors.white
                                        : Colors.grey.shade700,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                if (nameC.text.trim().isEmpty ||
                    codeC.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Name and Code are required!')),
                  );
                  return;
                }

                if (docId == null) {
                  await SubjectService.addSubject(
                    division: _selectedDivision!,
                    name: nameC.text,
                    code: codeC.text,
                    semester: semester,
                    type: type,
                    credits: credits,
                    weeklyHours: hours,
                  );
                } else {
                  await SubjectService.updateSubject(
                    division: _selectedDivision!,
                    docId: docId,
                    name: nameC.text,
                    code: codeC.text,
                    semester: semester,
                    type: type,
                    credits: credits,
                    weeklyHours: hours,
                  );
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

  // ── Delete confirm ────────────────────────────────────────
  Future<void> _confirmDelete(String docId, String name) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Delete Subject?",
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Delete "$name"?\nThis cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await SubjectService.deleteSubject(
        division: _selectedDivision!,
        docId: docId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isSmall = MediaQuery.of(context).size.width < 380;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 20,
              offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isSmall ? 6 : 8),
                decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.menu_book,
                    color: Colors.purple.shade600, size: isSmall ? 18 : 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text("Subjects Taught",
                    style:
                    TextStyle(fontSize: isSmall ? 15 : 18, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 4),

              // Division selector
              if (widget.divisions.isNotEmpty)
                Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedDivision,
                      hint: const Text("Div", style: TextStyle(fontSize: 12)),
                      icon: const Icon(Icons.arrow_drop_down, size: 18),
                      items: widget.divisions
                          .map((d) => DropdownMenuItem(
                          value: d,
                          child: Text("Div $d",
                              style: const TextStyle(fontSize: 12))))
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedDivision = val),
                    ),
                  ),
                ),

              const SizedBox(width: 6),

              // + Add Subject button
              if (_selectedDivision != null)
                SizedBox(
                  height: 32,
                  child: TextButton(
                    onPressed: () => _showSubjectDialog(),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.purple.shade50,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, color: Colors.purple.shade600, size: 16),
                        const SizedBox(width: 2),
                        Text("Add",
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.purple.shade600,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Subject list ──
          if (_selectedDivision == null)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: Colors.grey.shade400, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                        "Add a division first to manage subjects.",
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 13)),
                  ),
                ],
              ),
            )
          else
            StreamBuilder<QuerySnapshot>(
              stream:
              SubjectService.streamSubjects(_selectedDivision!),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: Colors.purple));
                }

                if (!snapshot.hasData ||
                    snapshot.data!.docs.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.add_circle_outline,
                            color: Colors.grey.shade400, size: 20),
                        const SizedBox(width: 12),
                        Text(
                            "No subjects yet. Tap + Add to create one.",
                            style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 13)),
                      ],
                    ),
                  );
                }

                final docs = snapshot.data!.docs;
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return _buildSubjectTile(
                        doc.id, data, context);
                  }).toList(),
                );
              },
            ),
        ],
      ),
    );
  }

  // ── Subject tile ──────────────────────────────────────────
  Widget _buildSubjectTile(
      String docId, Map<String, dynamic> data, BuildContext context) {
    final String name = data['name'] ?? '';
    final String code = data['code'] ?? '';
    final String semester = data['semester'] ?? 'Semester I';
    final String type = data['type'] ?? 'Core';
    final int credits = data['credits'] ?? 0;
    final int hours = data['weeklyHours'] ?? 0;

    final Color color =
    type == 'Core' ? Colors.blue : Colors.orange;

    return Container(
      width: 190,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle),
                child: Icon(Icons.menu_book, color: color, size: 22),
              ),
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: Colors.teal.shade50,
                            borderRadius: BorderRadius.circular(4)),
                        child: Text(semester == 'Semester I' ? 'SEM I' : 'SEM II',
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal.shade700)),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: type == 'Core'
                                ? Colors.blue.shade50
                                : Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(4)),
                        child: Text(type,
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: color)),
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  // Edit/Delete menu
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      iconSize: 18,
                      icon: Icon(Icons.more_vert,
                          color: Colors.grey.shade400, size: 18),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      onSelected: (val) {
                        if (val == 'edit') {
                          _showSubjectDialog(
                              docId: docId, existing: data);
                        } else if (val == 'delete') {
                          _confirmDelete(docId, name);
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(children: [
                            Icon(Icons.edit,
                                color: Colors.blue, size: 16),
                            SizedBox(width: 8),
                            Text('Edit', style: TextStyle(fontSize: 13)),
                          ]),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(children: [
                            Icon(Icons.delete,
                                color: Colors.red, size: 16),
                            SizedBox(width: 8),
                            Text('Delete',
                                style: TextStyle(fontSize: 13)),
                          ]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(name,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15)),
          Text(code,
              style: TextStyle(
                  fontSize: 12, color: Colors.grey.shade500)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("$credits Credits",
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey.shade500)),
              Text("$hours hrs/wk",
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54)),
            ],
          ),
        ],
      ),
    );
  }
}