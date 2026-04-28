/// Repository for managing the doctor's profile and availability.
library;

import '../models/models.dart';
import '../services/firestore_service.dart';

class DoctorProfileRepository {
  final FirestoreService _firestore = FirestoreService();

  DoctorProfile? _profile;

  /// Load doctor profile from Firestore.
  Future<void> load() async {
    final doc =
        await _firestore.doctorProfilesCollection.doc(_firestore.uid).get();
    if (doc.exists && doc.data() != null) {
      _profile = DoctorProfile.fromMap(doc.data()!);
    }
  }

  DoctorProfile? get() => _profile;

  /// Save or update the doctor profile.
  Future<void> save(DoctorProfile profile) async {
    _profile = profile;
    await _firestore.doctorProfilesCollection
        .doc(_firestore.uid)
        .set(profile.toMap());
  }
}
