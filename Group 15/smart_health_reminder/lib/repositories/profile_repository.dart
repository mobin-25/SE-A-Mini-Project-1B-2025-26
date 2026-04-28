// Firestore-backed repository for user profile.
import '../models/models.dart';
import '../services/firestore_service.dart';

class ProfileRepository {
  final FirestoreService _firestore = FirestoreService();
  static const String _profileDocId = 'default_user';

  UserProfile _profile = UserProfile(name: 'User', onboardingComplete: false);

  /// Load profile from Firestore.
  Future<void> load() async {
    final doc = await _firestore.profileCollection.doc(_profileDocId).get();
    if (doc.exists && doc.data() != null) {
      _profile = UserProfile.fromMap(doc.data()!);
    }
  }

  UserProfile get() => _profile;

  Future<void> update(UserProfile profile) async {
    _profile = profile;
    await _firestore.profileCollection.doc(_profileDocId).set(profile.toMap());
  }

  bool get isOnboardingComplete => _profile.onboardingComplete;
}
