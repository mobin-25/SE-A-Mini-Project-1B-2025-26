import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/csv_service.dart';
import '../student_info_screen.dart';

class DivisionManagerCard extends StatefulWidget {
  const DivisionManagerCard({super.key});

  @override
  State<DivisionManagerCard> createState() => _DivisionManagerCardState();
}

class _DivisionManagerCardState extends State<DivisionManagerCard> {
  List<String> _divisions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDivisions();
  }

  Future<void> _loadDivisions() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('divisions')
          .get();
      if (doc.exists) {
        final List<dynamic> divs = (doc.data()!['list'] ?? []);
        setState(() {
          _divisions = divs.map((e) => e.toString()).toList()..sort();
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveDivisions() async {
    await FirebaseFirestore.instance
        .collection('settings')
        .doc('divisions')
        .set({'list': _divisions});
  }

  // ── Add Division ─────────────────────────────────────────
  Future<void> _showAddDivisionDialog() async {
    final available = ['A', 'B', 'C', 'D', 'E', 'F']
        .where((d) => !_divisions.contains(d))
        .toList();

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All divisions already added!')),
      );
      return;
    }

    String picked = available.first;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.add_circle, color: Colors.teal, size: 26),
              SizedBox(width: 10),
              Text("Add Division",
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Select a division to add:"),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: available.map((div) {
                  final bool sel = picked == div;
                  return GestureDetector(
                    onTap: () => setS(() => picked = div),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: sel
                            ? Colors.teal.shade700
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: sel
                              ? Colors.teal.shade700
                              : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(div,
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: sel
                                    ? Colors.white
                                    : Colors.grey.shade600)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                setState(() {
                  if (!_divisions.contains(picked)) {
                    _divisions.add(picked);
                    _divisions.sort();
                  }
                });
                _saveDivisions();
                Navigator.pop(context);
              },
              child: Text("Add Division $picked"),
            ),
          ],
        ),
      ),
    );
  }

  // ── Division Options — uses AlertDialog (web safe) ────────
  void _showDivisionOptions(BuildContext context, String division) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.teal.shade700,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(division,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18)),
              ),
            ),
            const SizedBox(width: 12),
            Text("Division $division",
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Option 1: Upload
            _buildOptionTile(
              icon: Icons.upload_file,
              color: Colors.teal,
              title: "Upload Student List",
              subtitle: "Assign students to Division $division via Excel",
              onTap: () async {
                // ✅ Close dialog FIRST
                Navigator.pop(ctx);

                // ✅ Pick file immediately (no loading dialog blocking it)
                final file = await CsvService.pickFileOnly();

                if (file == null) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No file selected.')),
                    );
                  }
                  return;
                }

                // ✅ Now show loading dialog after file is picked
                if (context.mounted) {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => AlertDialog(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      content: Row(
                        children: [
                          CircularProgressIndicator(
                              color: Colors.teal.shade700),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Text(
                              "Assigning Division $division...",
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final result = await CsvService
                    .assignDivisionFromPickedFile(file, division);

                if (context.mounted) Navigator.pop(context); // close loading

                if (context.mounted) {
                  final bool success = result.startsWith('✅');
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      title: Row(
                        children: [
                          Icon(
                            success
                                ? Icons.check_circle
                                : Icons.error_outline,
                            color: success ? Colors.green : Colors.red,
                            size: 28,
                          ),
                          const SizedBox(width: 10),
                          Text(success ? "Success" : "Failed",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      content: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: success
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(result,
                            style: const TextStyle(fontSize: 14)),
                      ),
                      actions: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal.shade700,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text("OK"),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 12),

            // Option 2: View Students
            _buildOptionTile(
              icon: Icons.people,
              color: Colors.blue,
              title: "View Students",
              subtitle: "See all students in Division $division",
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        StudentInfoScreen(initialDivision: division),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            // Option 3: Remove Division
            _buildOptionTile(
              icon: Icons.delete_outline,
              color: Colors.red,
              title: "Remove Division",
              subtitle: "Remove from list (students not deleted)",
              onTap: () {
                Navigator.pop(ctx);
                _confirmRemoveDivision(context, division);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(subtitle,
                      style: TextStyle(
                          color: Colors.grey.shade600, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  void _confirmRemoveDivision(BuildContext context, String division) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Remove Division?",
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text("Remove Division $division?\nStudent records are kept."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              setState(() => _divisions.remove(division));
              _saveDivisions();
              Navigator.pop(ctx);
            },
            child: const Text("Remove"),
          ),
        ],
      ),
    );
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
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isSmall ? 6 : 8),
                decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.apartment,
                    color: Colors.blue.shade600, size: isSmall ? 18 : 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text("Divisions Assigned",
                    style:
                    TextStyle(fontSize: isSmall ? 16 : 18, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 4),
              SizedBox(
                height: 32,
                child: TextButton(
                  onPressed: _showAddDivisionDialog,
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.teal.shade50,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, color: Colors.teal.shade700, size: 16),
                      const SizedBox(width: 2),
                      Text("Add",
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.teal.shade700,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (_loading)
            const Center(
                child: CircularProgressIndicator(color: Colors.teal))
          else if (_divisions.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200, width: 1.5),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: Colors.grey.shade400, size: 20),
                  const SizedBox(width: 12),
                  Text("No divisions added yet. Tap + Add to start.",
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 13)),
                ],
              ),
            )
          else
            ...(_divisions.map((div) => _buildDivisionTile(div))),
        ],
      ),
    );
  }

  Widget _buildDivisionTile(String division) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('students')
          .where('division', isEqualTo: division)
          .snapshots(),
      builder: (context, snapshot) {
        final int count =
        snapshot.hasData ? snapshot.data!.docs.length : 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _showDivisionOptions(context, division),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.teal.shade700,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(division,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Division $division",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                          Text(
                            count == 0
                                ? "No students yet • Tap to upload"
                                : "$count student${count == 1 ? '' : 's'}",
                            style: TextStyle(
                                color: count == 0
                                    ? Colors.orange.shade600
                                    : Colors.grey.shade500,
                                fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.more_vert,
                        color: Colors.grey.shade400, size: 20),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}