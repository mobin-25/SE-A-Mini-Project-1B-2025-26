import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';

Future<void> seedDummyAttendance() async {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final Random random = Random();

  // ✅ Subjects (match exactly with app subjects)
  final List<String> subjects = [
    'Data Science',
    'Python Programming',
    'Artificial Intelligence',
    'PowerBI & Analytics',
  ];

  // ✅ Fetch all students
  final studentsSnapshot = await firestore
      .collection('Users')
      .where('role', isEqualTo: 'student')
      .get();

  if (studentsSnapshot.docs.isEmpty) {
    debugPrint('❌ No students found');
    return;
  }

  final DateTime today = DateTime.now();

  // 🔥 SAFE RANGE: last 30 days only
  final DateTime startDate = today.subtract(const Duration(days: 30));

  WriteBatch batch = firestore.batch();
  int batchCount = 0;

  for (var student in studentsSnapshot.docs) {
    final studentData = student.data();
    final String studentId = student.id;

    DateTime currentDate = startDate;

    while (currentDate.isBefore(today)) {
      // ✅ 4 lectures per day (1 per subject)
      for (int lec = 0; lec < 4; lec++) {
        final attendanceRef = firestore.collection('attendance').doc();

        batch.set(attendanceRef, {
          'studentId': studentId,
          'name': studentData['name'],
          'roll_no': studentData['roll_no'],
          'division': studentData['division'],
          'subject': subjects[lec],
          'lecture': lec + 1,
          'status': random.nextInt(100) < 80 ? 'Present' : 'Absent',
          'date': Timestamp.fromDate(currentDate),
          'markedAt': Timestamp.now(),
        });

        batchCount++;

        // 🔥 Commit every 400 writes (safe)
        if (batchCount == 400) {
          await batch.commit();
          batch = firestore.batch();
          batchCount = 0;
        }
      }

      // next day
      currentDate = currentDate.add(const Duration(days: 1));
    }
  }

  // Commit remaining writes
  if (batchCount > 0) {
    await batch.commit();
  }

  debugPrint('✅ Dummy attendance seeded successfully (30 days, 4 lectures/day)');
}
