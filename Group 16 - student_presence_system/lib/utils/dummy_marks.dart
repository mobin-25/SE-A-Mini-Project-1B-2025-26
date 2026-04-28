import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

Future<void> seedDummyMarks() async {
  final firestore = FirebaseFirestore.instance;
  final random = Random();

  final subjects = [
    'Data Science',
    'Python Programming',
    'Artificial Intelligence',
    'PowerBI & Analytics',
  ];

  final studentsSnapshot = await firestore
      .collection('Users')
      .where('role', isEqualTo: 'student')
      .get();

  WriteBatch batch = firestore.batch();
  int batchCount = 0;

  for (var student in studentsSnapshot.docs) {
    final studentData = student.data();
    final studentId = student.id;

    for (var subject in subjects) {
      final marksRef = firestore.collection('marks').doc();

      batch.set(marksRef, {
        'studentId': studentId,
        'name': studentData['name'] ?? 'Unknown',
        'roll_no': studentData['roll_no'] ?? '',
        'division': studentData['division'] ?? '',
        'subject': subject,

        // 🎯 realistic marks
        'mid_term': 45 + random.nextInt(26), // 45–70
        'end_term': 60 + random.nextInt(36), // 60–95

        'createdAt': Timestamp.now(),
      });

      batchCount++;

      // 🔒 Firestore batch limit protection
      if (batchCount == 450) {
        await batch.commit();
        batch = firestore.batch();
        batchCount = 0;
      }
    }
  }

  if (batchCount > 0) {
    await batch.commit();
  }
}
