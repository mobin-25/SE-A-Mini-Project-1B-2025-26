import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppointmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> bookAppointment({
    required String vetId,
    required String vetName,
    required String date,
    required String time,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception("User not logged in");
    }

    await _firestore.collection('appointments').add({
      'userEmail': user.email, // ✅ USING EMAIL
      'userName': user.displayName ?? "User",
      'vetId': vetId,
      'vetName': vetName,
      'date': date,
      'time': time,
      'status': 'pending',
      'createdAt': Timestamp.now(),
    });
  }

  Stream<QuerySnapshot> getUserAppointments() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception("User not logged in");
    }

    return _firestore
        .collection('appointments')
        .where('userEmail', isEqualTo: user.email) // ✅ FIXED
        .snapshots();
  }

  Future<void> deleteAppointment(String id) async {
    await _firestore.collection('appointments').doc(id).delete();
  }
}