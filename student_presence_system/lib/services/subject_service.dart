import 'package:cloud_firestore/cloud_firestore.dart';

class SubjectService {
  static final _db = FirebaseFirestore.instance;

  // ── Collection path per division ─────────────────────────
  static CollectionReference _subjectsRef(String division) {
    return _db
        .collection('subjects')
        .doc(division.toUpperCase())
        .collection('list');
  }

  // ── Stream all subjects for a division ───────────────────
  static Stream<QuerySnapshot> streamSubjects(String division) {
    return _subjectsRef(division).orderBy('createdAt').snapshots();
  }

  // ── Add subject ──────────────────────────────────────────
  static Future<void> addSubject({
    required String division,
    required String name,
    required String code,
    required String semester, // 'Semester I' or 'Semester II'
    required String type, // 'Core' or 'Elective'
    required int credits,
    required int weeklyHours,
  }) async {
    await _subjectsRef(division).add({
      'name': name.trim(),
      'code': code.trim().toUpperCase(),
      'semester': semester,
      'type': type,
      'credits': credits,
      'weeklyHours': weeklyHours,
      'division': division.toUpperCase(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Update subject ───────────────────────────────────────
  static Future<void> updateSubject({
    required String division,
    required String docId,
    required String name,
    required String code,
    required String semester,
    required String type,
    required int credits,
    required int weeklyHours,
  }) async {
    await _subjectsRef(division).doc(docId).update({
      'name': name.trim(),
      'code': code.trim().toUpperCase(),
      'semester': semester,
      'type': type,
      'credits': credits,
      'weeklyHours': weeklyHours,
    });
  }

  // ── Delete subject ───────────────────────────────────────
  static Future<void> deleteSubject({
    required String division,
    required String docId,
  }) async {
    await _subjectsRef(division).doc(docId).delete();
  }

  // ── Get subjects once (for student profile) ───────────────
  static Future<List<Map<String, dynamic>>> getSubjects(
      String division) async {
    final snap = await _subjectsRef(division).orderBy('createdAt').get();
    return snap.docs
        .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
        .toList();
  }
}