import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../services/subject_service.dart';

class StudentSubjectsScreen extends StatefulWidget {
  final String division;
  final String studentId;

  const StudentSubjectsScreen({
    super.key,
    required this.division,
    required this.studentId,
  });

  @override
  State<StudentSubjectsScreen> createState() => _StudentSubjectsScreenState();
}

class _StudentSubjectsScreenState extends State<StudentSubjectsScreen> {
  final Color _primaryBlue = const Color(0xFF1D4ED8);
  final Color _bgGray = const Color(0xFFF4F7FE);
  final Color _textDark = const Color(0xFF1E293B);

  List<Map<String, dynamic>> _subjects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    try {
      final subjects = await SubjectService.getSubjects(widget.division);
      if (mounted) {
        setState(() {
          _subjects = subjects;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load subjects: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _openLink(String url) async {
    try {
      final uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid or broken link'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgGray,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Subjects & Notes", style: TextStyle(color: _textDark, fontWeight: FontWeight.bold, fontSize: 18)),
            Text("Division ${widget.division}", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _subjects.isEmpty
              ? Center(child: Text("No subjects found.", style: TextStyle(color: Colors.grey.shade500)))
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: _subjects.length,
                  itemBuilder: (context, index) {
                    final subject = _subjects[index];
                    final subjectId = subject['id'];
                    final subjectName = subject['name'] ?? 'Unknown';
                    final subjectCode = subject['code'] ?? '';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
                      child: ExpansionTile(
                        shape: const Border(), // Removes internal borders
                        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: _primaryBlue.withValues(alpha: 0.1),
                          child: Icon(Icons.book, color: _primaryBlue),
                        ),
                        title: Text(subjectName, style: TextStyle(fontWeight: FontWeight.bold, color: _textDark, fontSize: 16)),
                        subtitle: Text(subjectCode, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                        children: [
                          _buildNotesStream(subjectId),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildNotesStream(String subjectId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notes')
          .where('division', isEqualTo: widget.division)
          .where('subjectId', isEqualTo: subjectId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(24.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Center(child: Text("Error loading notes: ${snapshot.error}", style: TextStyle(color: Colors.red.shade300))),
          );
        }

        final notes = snapshot.data?.docs.toList() ?? [];
        
        // Sort locally to avoid Firebase index requirement
        notes.sort((a, b) {
          final timeA = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
          final timeB = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
          if (timeA == null && timeB == null) return 0;
          if (timeA == null) return 1;
          if (timeB == null) return -1;
          return timeB.compareTo(timeA); // descending
        });

        if (notes.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Center(child: Text("No notes uploaded yet.", style: TextStyle(color: Colors.grey.shade500))),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: notes.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final data = notes[index].data() as Map<String, dynamic>;
              final title = data['title'] ?? 'Untitled';
              final desc = data['type'] ?? '';
              final url = data['link'] ?? '';
              final createdAt = data['timestamp'] as Timestamp?;

              String dateStr = '';
              if (createdAt != null) {
                dateStr = DateFormat('MMM dd, yyyy').format(createdAt.toDate());
              }

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: _textDark, fontSize: 14)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (desc.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(desc, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    ],
                    if (dateStr.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text("Added $dateStr", style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                    ]
                  ],
                ),
                trailing: url.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.open_in_new, color: _primaryBlue),
                        onPressed: () => _openLink(url),
                        tooltip: "Open Link",
                      )
                    : null,
              );
            },
          ),
        );
      },
    );
  }
}
