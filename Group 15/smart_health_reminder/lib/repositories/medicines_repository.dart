/// Firestore-backed repository for medicines.
library;

import '../models/models.dart';
import '../services/firestore_service.dart';

class MedicinesRepository {
  final FirestoreService _firestore = FirestoreService();

  /// In-memory cache synced from Firestore.
  List<Medicine> _medicines = [];

  /// Load all medicines from Firestore into memory.
  Future<void> loadAll() async {
    final snapshot = await _firestore.medicinesCollection.get();
    _medicines =
        snapshot.docs.map((doc) => Medicine.fromMap(doc.data())).toList();
  }

  List<Medicine> getAll() => List.unmodifiable(_medicines);

  Future<void> add(Medicine medicine) async {
    await _firestore.medicinesCollection.doc(medicine.id).set(medicine.toMap());
    _medicines.add(medicine);
  }

  Future<void> update(Medicine medicine) async {
    await _firestore.medicinesCollection
        .doc(medicine.id)
        .update(medicine.toMap());
    final index = _medicines.indexWhere((m) => m.id == medicine.id);
    if (index != -1) _medicines[index] = medicine;
  }

  Future<void> delete(String id) async {
    await _firestore.medicinesCollection.doc(id).delete();
    _medicines.removeWhere((m) => m.id == id);
  }

  Medicine? getById(String id) {
    try {
      return _medicines.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Mark a specific dose time as taken for a medicine.
  Future<void> markTimeTaken(String medicineId, String time) async {
    final med = getById(medicineId);
    if (med != null && !med.takenTimes.contains(time)) {
      med.takenTimes = [...med.takenTimes, time];
      if (med.takenTimes.length >= med.reminderTimes.length) {
        med.isCompleted = true;
      }
      await _firestore.medicinesCollection.doc(medicineId).update(med.toMap());
    }
  }

  /// Mark all doses as taken.
  Future<void> markAllTaken(String medicineId) async {
    final med = getById(medicineId);
    if (med != null) {
      med.takenTimes = List.from(med.reminderTimes);
      med.isCompleted = true;
      await _firestore.medicinesCollection.doc(medicineId).update(med.toMap());
    }
  }
}
