/// Repository for doctor-side prescription management.
library;

import '../models/models.dart';
import '../services/firestore_service.dart';

class PrescriptionsRepository {
  final FirestoreService _firestore = FirestoreService();

  List<Prescription> _prescriptions = [];

  /// Load all prescriptions created by this doctor.
  Future<void> loadAll() async {
    final doctorId = _firestore.uid;
    final snapshot =
        await _firestore.prescriptionsCollection
            .where('doctorId', isEqualTo: doctorId)
            .get();
    _prescriptions =
        snapshot.docs.map((doc) => Prescription.fromMap(doc.data())).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<Prescription> getAll() => List.unmodifiable(_prescriptions);

  List<Prescription> getByPatientId(String patientId) =>
      _prescriptions.where((p) => p.patientId == patientId).toList();

  Future<void> add(Prescription prescription) async {
    await _firestore.prescriptionsCollection
        .doc(prescription.id)
        .set(prescription.toMap());
    _prescriptions.insert(0, prescription);
  }

  Future<void> update(Prescription prescription) async {
    await _firestore.prescriptionsCollection
        .doc(prescription.id)
        .update(prescription.toMap());
    final index = _prescriptions.indexWhere((p) => p.id == prescription.id);
    if (index != -1) _prescriptions[index] = prescription;
  }

  Future<void> delete(String id) async {
    await _firestore.prescriptionsCollection.doc(id).delete();
    _prescriptions.removeWhere((p) => p.id == id);
  }
}
