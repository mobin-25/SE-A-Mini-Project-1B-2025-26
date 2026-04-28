import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

Future<void> addDummyStudents() async {
  final users = FirebaseFirestore.instance.collection('Users');
  final Random random = Random();

  // 🔹 Random Indian-style phone number
  String randomPhone() {
    return '9${random.nextInt(900000000) + 100000000}';
  }

  // 🔵 DIVISION A (Foreign + Girls)
  final List<String> namesA = [
    'Alex Johnson', 'Emma Wilson', 'Liam Carter', 'Olivia Brown',
    'Noah Anderson', 'Sophia Miller', 'Ethan Davis', 'Ava Thompson',
    'Lucas Martin', 'Mia Taylor', 'Daniel Moore', 'Isabella White'
  ];

  // 🟢 DIVISION B
  final List<String> namesB = [
    'James Walker', 'Emily Harris', 'Benjamin Lewis', 'Charlotte Clark',
    'Henry Young', 'Amelia Hall', 'Michael King', 'Harper Scott',
    'Samuel Green', 'Ella Adams', 'Andrew Baker', 'Grace Nelson'
  ];

  // 🟡 DIVISION C
  final List<String> namesC = [
    'William Turner', 'Sofia Ramirez', 'Jack Collins', 'Victoria Lopez',
    'Oliver Wright', 'Natalie Perez', 'Leo Martinez', 'Hannah Robinson',
    'Ryan Mitchell', 'Zoe Carter', 'Aaron Phillips', 'Lucy Campbell'
  ];

  // 🔴 DIVISION D
  final List<String> namesD = [
    'David Foster', 'Anna Morgan', 'Joseph Reed', 'Chloe Bennett',
    'Matthew Brooks', 'Lily Cooper', 'Christopher Ward', 'Nora Hughes',
    'Anthony Price', 'Sarah Coleman', 'Jonathan Evans', 'Paige Stewart'
  ];

  final List<Map<String, dynamic>> students = [];

  for (int i = 0; i < 12; i++) {
    students.add({
      'name': namesA[i],
      'roll_no': 'CSA${i + 1}',
      'email': 'csa${i + 1}@apsit.edu.in',
      'phone': randomPhone(),
      'dept': 'CSE',
      'division': 'A',
      'role': 'student',
    });

    students.add({
      'name': namesB[i],
      'roll_no': 'CSB${i + 1}',
      'email': 'csb${i + 1}@apsit.edu.in',
      'phone': randomPhone(),
      'dept': 'CSE',
      'division': 'B',
      'role': 'student',
    });

    students.add({
      'name': namesC[i],
      'roll_no': 'CSC${i + 1}',
      'email': 'csc${i + 1}@apsit.edu.in',
      'phone': randomPhone(),
      'dept': 'CSE',
      'division': 'C',
      'role': 'student',
    });

    students.add({
      'name': namesD[i],
      'roll_no': 'CSD${i + 1}',
      'email': 'csd${i + 1}@apsit.edu.in',
      'phone': randomPhone(),
      'dept': 'CSE',
      'division': 'D',
      'role': 'student',
    });
  }

  // 🔥 Add all students to Firestore
  for (final student in students) {
    await users.add(student);
  }
}
