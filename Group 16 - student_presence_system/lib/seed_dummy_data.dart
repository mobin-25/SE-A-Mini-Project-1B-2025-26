import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const SeedDataApp());
}

class SeedDataApp extends StatelessWidget {
  const SeedDataApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SeedDataScreen(),
    );
  }
}

class SeedDataScreen extends StatefulWidget {
  const SeedDataScreen({super.key});
  @override
  State<SeedDataScreen> createState() => _SeedDataScreenState();
}

class _SeedDataScreenState extends State<SeedDataScreen> {
  bool _isSeeding = false;
  String _status = 'Ready to seed dummy data';
  final List<String> _logs = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seed Dummy Data'),
        backgroundColor: Colors.indigo,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '⚠️ WARNING',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('This will add:'),
                    const SizedBox(height: 4),
                    const Text('• 30 days of attendance (4 subjects/day)'),
                    const Text('• Marks for 4 subjects per student'),
                    const SizedBox(height: 8),
                    const Text(
                      'Run this ONLY ONCE!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _status,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _isSeeding ? Colors.blue : Colors.green,
              ),
            ),
            const SizedBox(height: 20),
            if (!_isSeeding)
              ElevatedButton.icon(
                onPressed: _seedAllData,
                icon: const Icon(Icons.upload, color: Colors.white),
                label: const Text(
                  'SEED DUMMY DATA',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              )
            else
              const Center(
                child: CircularProgressIndicator(),
              ),
            const SizedBox(height: 20),
            const Text(
              'Logs:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        _logs[index],
                        style: const TextStyle(fontSize: 13),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _seedAllData() async {
    setState(() {
      _isSeeding = true;
      _status = 'Seeding data...';
      _logs.clear();
    });

    try {
      // Seed Attendance
      _addLog('🔄 Starting attendance seeding...');
      await seedDummyAttendance();
      _addLog('✅ Attendance seeded successfully!');

      // Seed Marks
      _addLog('🔄 Starting marks seeding...');
      await seedDummyMarks();
      _addLog('✅ Marks seeded successfully!');

      setState(() {
        _status = '🎉 All data seeded successfully!';
        _isSeeding = false;
      });

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('✅ Success!'),
          content: const Text(
            'Dummy attendance and marks have been added to all students.\n\nYou can now close this app and run your main app.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      _addLog('❌ Error: $e');
      setState(() {
        _status = 'Error occurred';
        _isSeeding = false;
      });
    }
  }

  void _addLog(String message) {
    setState(() {
      _logs.add(message);
    });
  }

  Future<void> seedDummyAttendance() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final Random random = Random();

    final List<String> subjects = [
      'Data Science',
      'Python Programming',
      'Artificial Intelligence',
      'PowerBI & Analytics',
    ];

    final studentsSnapshot = await firestore
        .collection('Users')
        .where('role', isEqualTo: 'student')
        .get();

    if (studentsSnapshot.docs.isEmpty) {
      _addLog('❌ No students found');
      return;
    }

    _addLog('📊 Found ${studentsSnapshot.docs.length} students');

    final DateTime today = DateTime.now();
    final DateTime startDate = today.subtract(const Duration(days: 30));

    WriteBatch batch = firestore.batch();
    int batchCount = 0;
    int totalRecords = 0;

    for (var student in studentsSnapshot.docs) {
      final studentData = student.data();
      final String studentId = student.id;

      DateTime currentDate = startDate;

      while (currentDate.isBefore(today)) {
        for (int lec = 0; lec < 4; lec++) {
          final attendanceRef = firestore.collection('attendance').doc();

          batch.set(attendanceRef, {
            'studentId': studentId,
            'name': studentData['name'],
            'roll_no': studentData['roll_no'],
            'division': studentData['division'],
            'subject': subjects[lec],
            'status': random.nextInt(100) < 80 ? 'Present' : 'Absent',
            'date': Timestamp.fromDate(currentDate),
            'dateString': '${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}',
            'markedAt': Timestamp.now(),
          });

          batchCount++;
          totalRecords++;

          if (batchCount == 400) {
            await batch.commit();
            _addLog('💾 Committed 400 records (Total: $totalRecords)');
            batch = firestore.batch();
            batchCount = 0;
          }
        }

        currentDate = currentDate.add(const Duration(days: 1));
      }
    }

    if (batchCount > 0) {
      await batch.commit();
      _addLog('💾 Committed remaining $batchCount records');
    }

    _addLog('✅ Total attendance records created: $totalRecords');
  }

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

    _addLog('📊 Found ${studentsSnapshot.docs.length} students for marks');

    WriteBatch batch = firestore.batch();
    int batchCount = 0;
    int totalMarks = 0;

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
          'mid_term': 45 + random.nextInt(26),
          'end_term': 60 + random.nextInt(36),
          'createdAt': Timestamp.now(),
        });

        batchCount++;
        totalMarks++;

        if (batchCount == 450) {
          await batch.commit();
          _addLog('💾 Committed marks batch (Total: $totalMarks)');
          batch = firestore.batch();
          batchCount = 0;
        }
      }
    }

    if (batchCount > 0) {
      await batch.commit();
    }

    _addLog('✅ Total marks records created: $totalMarks');
  }
}