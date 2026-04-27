import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentMarksManager extends StatefulWidget {
  final String studentRollNo;
  final String studentName;

  const StudentMarksManager({
    super.key,
    required this.studentRollNo,
    required this.studentName,
  });

  @override
  State<StudentMarksManager> createState() => _StudentMarksManagerState();
}

class _StudentMarksManagerState extends State<StudentMarksManager> {
  final List<String> _availableSubjects = [
    'Data Science',
    'Python Programming',
    'Artificial Intelligence',
    'PowerBI & Analytics',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Marks'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddSubjectDialog(),
            tooltip: 'Add Subject',
          ),
        ],
      ),
      body: Column(
        children: [
          // Student Info Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo.shade400, Colors.indigo.shade600],
              ),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Text(
                    widget.studentName.isNotEmpty
                        ? widget.studentName[0].toUpperCase()
                        : 'S',
                    style: const TextStyle(
                      fontSize: 24,
                      color: Colors.indigo,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.studentName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Roll No: ${widget.studentRollNo}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),

          // Marks List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('marks')
                  .where('roll_no', isEqualTo: widget.studentRollNo)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.school, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text('No marks added yet'),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _showAddSubjectDialog(),
                          icon: const Icon(Icons.add),
                          label: const Text('Add First Subject'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final marksDocs = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: marksDocs.length,
                  itemBuilder: (context, index) {
                    final doc = marksDocs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    return _buildMarkCard(
                      docId: doc.id,
                      subject: data['subject'] ?? 'Unknown',
                      midTerm: data['mid_term'] ?? 0,
                      endTerm: data['end_term'] ?? 0,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarkCard({
    required String docId,
    required String subject,
    required int midTerm,
    required int endTerm,
  }) {
    int total = midTerm + endTerm;
    double percentage = (total / 200) * 100;
    Color scoreColor = percentage >= 75
        ? Colors.green
        : (percentage >= 50 ? Colors.orange : Colors.red);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    subject,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: scoreColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$total / 200',
                    style: TextStyle(
                      color: scoreColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Mid Term',
                            style: TextStyle(fontSize: 11, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text(
                          '$midTerm / 100',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('End Term',
                            style: TextStyle(fontSize: 11, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text(
                          '$endTerm / 100',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showEditMarksDialog(
                        docId, subject, midTerm, endTerm),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmDelete(docId, subject),
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Add new subject
  void _showAddSubjectDialog() {
    String? selectedSubject;
    final midController = TextEditingController();
    final endController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Subject Marks'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedSubject,
                decoration: const InputDecoration(
                  labelText: 'Select Subject',
                  border: OutlineInputBorder(),
                ),
                items: _availableSubjects
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (val) => selectedSubject = val,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: midController,
                decoration: const InputDecoration(
                  labelText: 'Mid Term (out of 100)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: endController,
                decoration: const InputDecoration(
                  labelText: 'End Term (out of 100)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (selectedSubject == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select a subject')),
                );
                return;
              }

              final mid = int.tryParse(midController.text) ?? 0;
              final end = int.tryParse(endController.text) ?? 0;

              await FirebaseFirestore.instance.collection('marks').add({
                'roll_no': widget.studentRollNo,
                'subject': selectedSubject,
                'mid_term': mid,
                'end_term': end,
                'createdAt': FieldValue.serverTimestamp(),
              });

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Marks added successfully')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  // Edit existing marks
  void _showEditMarksDialog(
      String docId, String subject, int currentMid, int currentEnd) {
    final midController = TextEditingController(text: currentMid.toString());
    final endController = TextEditingController(text: currentEnd.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Marks - $subject'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: midController,
              decoration: const InputDecoration(
                labelText: 'Mid Term (out of 100)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: endController,
              decoration: const InputDecoration(
                labelText: 'End Term (out of 100)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final mid = int.tryParse(midController.text) ?? 0;
              final end = int.tryParse(endController.text) ?? 0;

              await FirebaseFirestore.instance
                  .collection('marks')
                  .doc(docId)
                  .update({
                'mid_term': mid,
                'end_term': end,
                'updatedAt': FieldValue.serverTimestamp(),
              });

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Marks updated successfully')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  // Delete subject
  void _confirmDelete(String docId, String subject) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Subject'),
        content: Text('Are you sure you want to delete $subject marks?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('marks')
                  .doc(docId)
                  .delete();

              if (context.mounted) {
                Navigator.pop(context);ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$subject deleted successfully')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}