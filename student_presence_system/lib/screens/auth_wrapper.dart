import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import 'teacher/teacher_dashboard.dart';
import 'student/student_dashboard.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasData) {
          final String uid = snapshot.data!.uid;

          return FutureBuilder<DocumentSnapshot>(
            // ✅ Try fetching from 'teachers' first
            future: FirebaseFirestore.instance.collection('teachers').doc(uid).get(),
            builder: (context, teacherSnapshot) {
              if (teacherSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }

              // 1. If found in teachers collection
              if (teacherSnapshot.hasData && teacherSnapshot.data!.exists) {
                return const TeacherDashboard();
              }

              // 2. If not found in teachers, check 'students' collection
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('students').doc(uid).get(),
                builder: (context, studentSnapshot) {
                  if (studentSnapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(body: Center(child: CircularProgressIndicator()));
                  }

                  if (studentSnapshot.hasData && studentSnapshot.data!.exists) {
                    Map<String, dynamic> studentData = studentSnapshot.data!.data() as Map<String, dynamic>;

                    return StudentDashboard(
                      studentId: studentData['roll_no'] ?? 'Unknown',
                      studentName: studentData['name'] ?? 'Student',
                      division: studentData['division'] ?? 'A',
                    );
                  }

                  // 3. If found in neither, go to login
                  return const LoginScreen();
                },
              );
            },
          );
        }
        return const LoginScreen();
      },
    );
  }
}