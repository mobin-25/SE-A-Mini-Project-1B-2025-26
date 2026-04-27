import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'stat_item.dart';

class AnalyticsResults extends StatelessWidget {
  final String division;
  final String subject;
  final int month;
  final int year;

  const AnalyticsResults({
    super.key,
    required this.division,
    required this.subject,
    required this.month,
    required this.year,
  });

  @override
  Widget build(BuildContext context) {
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 1);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('attendance')
          .where('date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('date', isLessThan: Timestamp.fromDate(endOfMonth))
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final filteredDocs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;

          if (division != 'All' && data['division'] != division) {
            return false;
          }

          if (subject != 'All' && data['subject'] != subject) {
            return false;
          }

          return true;
        }).toList();

        // Calculate statistics
        Map<String, Map<String, dynamic>> stats = {};
        Map<String, Set<String>> uniqueStudents = {}; // Track unique students

        if (subject == 'All') {
          // Group by subject
          for (var doc in filteredDocs) {
            final data = doc.data() as Map<String, dynamic>;
            final subj = data['subject'] as String;
            final date = (data['date'] as Timestamp).toDate();
            final dateKey = '${date.year}-${date.month}-${date.day}';
            final studentName = data['name'] as String;

            if (!stats.containsKey(subj)) {
              stats[subj] = {
                'uniqueDates': <String>{},
                'presentCount': 0,
                'absentCount': 0,
              };
              uniqueStudents[subj] = <String>{};
            }

            // Track unique lecture dates
            stats[subj]!['uniqueDates'].add(dateKey);

            // Track unique students
            uniqueStudents[subj]!.add(studentName);

            // Count attendance
            if (data['status'] == 'Present') {
              stats[subj]!['presentCount']++;
            } else {
              stats[subj]!['absentCount']++;
            }
          }
        } else {
          // Single subject stats
          stats[subject] = {
            'uniqueDates': <String>{},
            'presentCount': 0,
            'absentCount': 0,
          };
          uniqueStudents[subject] = <String>{};

          for (var doc in filteredDocs) {
            final data = doc.data() as Map<String, dynamic>;
            final date = (data['date'] as Timestamp).toDate();
            final dateKey = '${date.year}-${date.month}-${date.day}';
            final studentName = data['name'] as String;

            stats[subject]!['uniqueDates'].add(dateKey);
            uniqueStudents[subject]!.add(studentName);

            if (data['status'] == 'Present') {
              stats[subject]!['presentCount']++;
            } else {
              stats[subject]!['absentCount']++;
            }
          }
        }

        if (stats.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'No data found for selected filters',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Results',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ...stats.entries.map((entry) {
              final subjectName = entry.key;
              final data = entry.value;
              final totalLectures = (data['uniqueDates'] as Set).length;
              final present = data['presentCount'] as int;
              final absent = data['absentCount'] as int;
              final totalStudents = uniqueStudents[subjectName]!.length;
              final totalRecords = present + absent;
              final attendanceRate =
              totalRecords > 0 ? (present / totalRecords * 100) : 0;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subjectName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.people,
                              size: 16,
                              color: Colors.indigo,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Total Students: $totalStudents',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.indigo,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          StatItem(
                            icon: Icons.assignment,
                            label: 'Total Lectures',
                            value: totalLectures.toString(),
                            color: Colors.blue,
                          ),
                          StatItem(
                            icon: Icons.check_circle,
                            label: 'Present',
                            value: present.toString(),
                            color: Colors.green,
                          ),
                          StatItem(
                            icon: Icons.cancel,
                            label: 'Absent',
                            value: absent.toString(),
                            color: Colors.red,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: attendanceRate / 100,
                        backgroundColor: Colors.red.shade100,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          attendanceRate >= 75
                              ? Colors.green
                              : attendanceRate >= 50
                              ? Colors.orange
                              : Colors.red,
                        ),
                        minHeight: 8,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Attendance Rate: ${attendanceRate.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: attendanceRate >= 75
                              ? Colors.green
                              : attendanceRate >= 50
                              ? Colors.orange
                              : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}