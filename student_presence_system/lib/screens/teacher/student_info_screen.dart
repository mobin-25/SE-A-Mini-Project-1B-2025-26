import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/student_service.dart';
import 'student_profile_screen.dart';
import 'student_marks_manager.dart';

class StudentInfoScreen extends StatefulWidget {
  final String? initialDivision;

  const StudentInfoScreen({super.key, this.initialDivision});

  @override
  State<StudentInfoScreen> createState() => _StudentInfoScreenState();
}

class _StudentInfoScreenState extends State<StudentInfoScreen> {
  String? selectedDivision;
  final List<String> divisions = ['A', 'B', 'C', 'D'];
  String searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  Future<QuerySnapshot>? _studentsFuture;

  @override
  void initState() {
    super.initState();
    if (widget.initialDivision != null) {
      _selectDivision(widget.initialDivision!);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _selectDivision(String div) {
    setState(() {
      selectedDivision = div;
      searchQuery = "";
      _searchController.clear();
      _studentsFuture = FirebaseFirestore.instance
          .collection('students')
          .where('division', isEqualTo: div)
          .get();
    });
  }

  // ✅ Sort roll numbers numerically (1, 2, 3 ... not 1, 10, 11)
  int _parseRoll(dynamic rollNo) {
    return int.tryParse(rollNo?.toString() ?? '0') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final StudentService studentService = StudentService();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: selectedDivision != null
            ? IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (widget.initialDivision != null) {
              Navigator.pop(context);
            } else {
              setState(() {
                selectedDivision = null;
                searchQuery = "";
                _searchController.clear();
              });
            }
          },
        )
            : null,
        title: selectedDivision == null
            ? const Text("Select Division",
            style: TextStyle(fontWeight: FontWeight.bold))
            : TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white, fontSize: 18),
          cursorColor: Colors.white,
          decoration: InputDecoration(
            hintText: "Search in Div $selectedDivision...",
            hintStyle:
            TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search,
                color: Colors.white.withValues(alpha: 0.7)),
          ),
          onChanged: (value) {
            setState(() {
              searchQuery = value.toLowerCase();
            });
          },
        ),
      ),
      body: selectedDivision == null
          ? _buildDivisionSelector()
          : _buildStudentList(studentService),
    );
  }

  Widget _buildDivisionSelector() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: divisions.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: InkWell(
            onTap: () => _selectDivision(divisions[index]),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [Colors.teal.shade500, Colors.teal.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                      color: Colors.teal.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle),
                          child: const Icon(Icons.class_,
                              color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          "Division ${divisions[index]}",
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Icon(Icons.arrow_forward_ios,
                        color: Colors.white70, size: 20),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStudentList(StudentService studentService) {
    return FutureBuilder<QuerySnapshot>(
      future: _studentsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.teal));
        }

        if (snapshot.hasError) {
          return const Center(
              child: Text("Error fetching students.",
                  style: TextStyle(color: Colors.red)));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_off,
                    size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text('No students found in Division $selectedDivision',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          );
        }

        // ✅ Filter by search query
        var filteredDocs = snapshot.data!.docs.where((doc) {
          var data = doc.data() as Map<String, dynamic>;
          String name = (data['name'] ?? "").toString().toLowerCase();
          String roll = (data['roll_no'] ?? "").toString().toLowerCase();
          return name.contains(searchQuery) || roll.contains(searchQuery);
        }).toList();

        // ✅ Sort numerically by roll_no (1, 2, 3... not 1, 10, 11...)
        filteredDocs.sort((a, b) {
          final aRoll = _parseRoll((a.data() as Map)['roll_no']);
          final bRoll = _parseRoll((b.data() as Map)['roll_no']);
          return aRoll.compareTo(bRoll);
        });

        if (filteredDocs.isEmpty) {
          return Center(
              child: Text(
                  "No matching students found for '$searchQuery'"));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            final doc = filteredDocs[index];
            final data = doc.data() as Map<String, dynamic>;
            final String name = data['name'] ?? 'Unknown';
            final String rollNo = data['roll_no'] ?? 'N/A';
            final String initials =
            name.isNotEmpty ? name[0].toUpperCase() : '?';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey.shade200,
                      blurRadius: 8,
                      offset: const Offset(0, 3))
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.teal.shade50,
                  child: Text(initials,
                      style: TextStyle(
                          color: Colors.teal.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 18)),
                ),
                title: Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                subtitle: Text("Roll: $rollNo",
                    style: TextStyle(color: Colors.grey.shade600)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StudentProfileScreen(
                        studentId: doc.id,
                        studentData: data,
                      ),
                    ),
                  );
                },
                trailing: PopupMenuButton<String>(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                  onSelected: (value) {
                    if (value == 'marks') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => StudentMarksManager(
                                studentRollNo: rollNo,
                                studentName: name)),
                      );
                    } else if (value == 'edit') {
                      _editStudentDialog(
                          context, doc.id, data, studentService);
                    } else if (value == 'delete') {
                      _confirmDelete(context, doc.id, studentService);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                        value: 'marks',
                        child: Row(children: [
                          Icon(Icons.edit_note, color: Colors.teal),
                          SizedBox(width: 12),
                          Text('Manage Marks')
                        ])),
                    const PopupMenuItem(
                        value: 'edit',
                        child: Row(children: [
                          Icon(Icons.edit, color: Colors.blue),
                          SizedBox(width: 12),
                          Text('Edit Info')
                        ])),
                    const PopupMenuItem(
                        value: 'delete',
                        child: Row(children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 12),
                          Text('Delete')
                        ])),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(
      BuildContext context, String docId, StudentService service) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Student?"),
        content: const Text("Are you sure? This cannot be undone."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade50, elevation: 0),
            onPressed: () async {
              await service.deleteStudent(docId);
              if (!ctx.mounted || !context.mounted) return;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text("Student deleted"),
                  backgroundColor: Colors.red));
              _selectDivision(selectedDivision!);
            },
            child: const Text("Delete",
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _editStudentDialog(BuildContext context, String docId,
      Map<String, dynamic> data, StudentService service) {
    final nameC = TextEditingController(text: data['name'] ?? '');
    final rollC = TextEditingController(text: data['roll_no'] ?? '');
    final phoneC = TextEditingController(text: data['phone'] ?? '');
    final deptC = TextEditingController(text: data['dept'] ?? '');
    final divC = TextEditingController(text: data['division'] ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Edit Student",
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: nameC,
                  decoration:
                  const InputDecoration(labelText: "Name")),
              TextField(
                  controller: rollC,
                  decoration:
                  const InputDecoration(labelText: "Roll No")),
              TextField(
                  controller: phoneC,
                  decoration:
                  const InputDecoration(labelText: "Phone")),
              TextField(
                  controller: deptC,
                  decoration:
                  const InputDecoration(labelText: "Department")),
              TextField(
                  controller: divC,
                  decoration:
                  const InputDecoration(labelText: "Division")),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade700,
                foregroundColor: Colors.white),
            child: const Text("Update"),
            onPressed: () async {
              await service.updateStudent(
                docId: docId,
                name: nameC.text,
                rollNo: rollC.text,
                phone: phoneC.text,
                dept: deptC.text,
                division: divC.text,
              );
              if (!dialogContext.mounted || !context.mounted) return;
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text("Student updated"),
                  backgroundColor: Colors.green));
              _selectDivision(selectedDivision!);
            },
          ),
        ],
      ),
    );
  }
}