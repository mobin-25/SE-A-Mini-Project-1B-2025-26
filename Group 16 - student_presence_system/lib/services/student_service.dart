import 'package:cloud_firestore/cloud_firestore.dart';

class StudentService {
  final CollectionReference usersCollection =
  FirebaseFirestore.instance.collection('Users');

  // ➕ ADD STUDENT
  Future<void> addStudent({
    required String name,
    required String rollNo,
    required String email,
    required String dept,
    required String division,
    required String phone,
  }) async {
    await usersCollection.add({
      'name': name,
      'roll_no': rollNo,
      'email': email,
      'dept': dept,
      'division': division,
      'phone': phone,
      'role': 'student',
      // We keep joinedAt as it is necessary for correct attendance logic
      'joinedAt': FieldValue.serverTimestamp(),
    });
  }

  // ✏️ UPDATE STUDENT
  Future<void> updateStudent({
    required String docId,
    required String name,
    required String rollNo,
    required String phone,
    required String dept,
    required String division,
  }) async {
    await usersCollection.doc(docId).update({
      'name': name,
      'roll_no': rollNo,
      'phone': phone,
      'dept': dept,
      'division': division,
    });
  }

  // 🗑️ DELETE STUDENT
  Future<void> deleteStudent(String docId) async {
    await usersCollection.doc(docId).delete();
  }
}