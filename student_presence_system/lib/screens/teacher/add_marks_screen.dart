import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddMarksScreen extends StatefulWidget {
  const AddMarksScreen({super.key});

  @override
  State<AddMarksScreen> createState() => _AddMarksScreenState();
}

class _AddMarksScreenState extends State<AddMarksScreen> {
  String? selectedStudentId;
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  // Controllers for all subject marks
  final Map<String, TextEditingController> _controllers = {
    'ds_mid': TextEditingController(), 'ds_end': TextEditingController(),
    'pb_mid': TextEditingController(), 'pb_end': TextEditingController(),
    'ai_mid': TextEditingController(), 'ai_end': TextEditingController(),
    'py_mid': TextEditingController(), 'py_end': TextEditingController(),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Upload Marks"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text("Select Student", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('Users')
                    .where('role', isEqualTo: 'student')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const LinearProgressIndicator();

                  var students = snapshot.data!.docs;
                  return DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    hint: const Text("Choose a student..."),
                    initialValue: selectedStudentId,
                    items: students.map((doc) {
                      var data = doc.data() as Map<String, dynamic>;
                      String name = data['name'] ?? 'Unknown';
                      String roll = data['roll_no'] ?? 'No Roll';
                      return DropdownMenuItem(
                        value: roll,
                        child: Text("$name ($roll)"),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() => selectedStudentId = val);
                      _loadExistingMarks(val!);
                    },
                    validator: (val) => val == null ? 'Please select a student' : null,
                  );
                },
              ),
              const SizedBox(height: 24),

              _buildSubjectCard("Data Science", "ds", Icons.analytics),
              _buildSubjectCard("PowerBI & Analytics", "pb", Icons.bar_chart),
              _buildSubjectCard("Artificial Intelligence", "ai", Icons.psychology),
              _buildSubjectCard("Python Programming", "py", Icons.code),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveMarks,
                  icon: _isSaving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.save),
                  label: Text(_isSaving ? "Saving..." : "Save All Marks"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.indigo.shade300,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectCard(String title, String prefix, IconData icon) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.indigo),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _markInput(_controllers['${prefix}_mid']!, "Mid Term (100)")),
                const SizedBox(width: 16),
                Expanded(child: _markInput(_controllers['${prefix}_end']!, "End Term (100)")),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _markInput(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );
  }

  Future<void> _loadExistingMarks(String rollNo) async {
    _controllers.forEach((_, c) => c.clear());

    // Check all subjects for this student
    var querySnapshot = await FirebaseFirestore.instance
        .collection('marks')
        .where('roll_no', isEqualTo: rollNo)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      for (var doc in querySnapshot.docs) {
        var data = doc.data();
        String? subject = data['subject'];
        String prefix = "";
        if (subject == "Data Science") { prefix = "ds"; }
        else if (subject == "PowerBI & Analytics") { prefix = "pb"; }
        else if (subject == "Artificial Intelligence") { prefix = "ai"; }
        else if (subject == "Python Programming") { prefix = "py"; }

        if (prefix.isNotEmpty) {
          _controllers['${prefix}_mid']!.text = (data['mid_term'] ?? 0).toString();
          _controllers['${prefix}_end']!.text = (data['end_term'] ?? 0).toString();
        }
      }
    }
  }

  Future<void> _saveMarks() async {
    if (!_formKey.currentState!.validate() || selectedStudentId == null) return;

    setState(() => _isSaving = true);

    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      // ✅ OPTIMIZED: Single query to fetch ALL existing marks for this student
      final existingDocs = await firestore
          .collection('marks')
          .where('roll_no', isEqualTo: selectedStudentId)
          .get();

      // Build a map of subject → existing doc reference for fast lookup
      final Map<String, DocumentReference> existingRefs = {};
      for (var doc in existingDocs.docs) {
        final subject = (doc.data())['subject'] as String?;
        if (subject != null) existingRefs[subject] = doc.reference;
      }

      // Subject definitions
      final subjects = {
        "Data Science": "ds",
        "PowerBI & Analytics": "pb",
        "Artificial Intelligence": "ai",
        "Python Programming": "py",
      };

      for (var entry in subjects.entries) {
        final subjectName = entry.key;
        final prefix = entry.value;

        // Reuse existing doc if it exists, otherwise create a new one
        final docRef = existingRefs[subjectName] ?? firestore.collection('marks').doc();

        batch.set(docRef, {
          'roll_no': selectedStudentId,
          'subject': subjectName,
          'mid_term': int.tryParse(_controllers['${prefix}_mid']!.text) ?? 0,
          'end_term': int.tryParse(_controllers['${prefix}_end']!.text) ?? 0,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      // ✅ Single batch write for all subjects
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Marks saved successfully!"), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
