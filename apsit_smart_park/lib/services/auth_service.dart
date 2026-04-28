import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Stream of auth state changes (User? → null when signed out)
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Currently signed-in Firebase user
  static User? get currentUser => _auth.currentUser;

  /// Sign in with Moodle ID or email.
  /// If user enters a plain Moodle ID (e.g. 24107019), it is converted to
  /// 24107019@apsit.edu.in automatically.
  static Future<UserCredential> signIn(
      String moodleIdOrEmail, String password) async {
    final email = moodleIdOrEmail.contains('@')
        ? moodleIdOrEmail
        : '$moodleIdOrEmail@apsit.edu.in';
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  /// Sign out the current user.
  static Future<void> signOut() => _auth.signOut();

  /// Send a password reset email.
  static Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  /// Register a new user and create their Firestore profile document.
  static Future<UserCredential> register({
    required String moodleId,
    required String password,
    required String name,
    required String role,
  }) async {
    final email = moodleId.contains('@') ? moodleId : '$moodleId@apsit.edu.in';
    final cred = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    // Update Firebase display name
    await cred.user!.updateDisplayName(name);
    // Create profile in Firestore
    await _db.collection('users').doc(cred.user!.uid).set({
      'name': name,
      'role': role,
      'email': email,
      'moodleId': moodleId.contains('@') ? moodleId.split('@').first : moodleId,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return cred;
  }

  /// Fetch a UserModel for the given uid.
  static Future<UserModel?> getProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(uid, doc.data()!);
  }

  /// Create a profile document if one does not already exist (called on first login).
  static Future<void> ensureProfile(User user) async {
    final ref = _db.collection('users').doc(user.uid);
    final doc = await ref.get();
    if (!doc.exists) {
      await ref.set({
        'name': user.displayName ?? 'APSIT User',
        'role': 'Student',
        'email': user.email ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Save or update the FCM token for a user in Firestore.
  static Future<void> saveFcmToken(String uid, String token) async {
    await _db.collection('users').doc(uid).update({
      'fcmToken': token,
      'tokenUpdatedAt': FieldValue.serverTimestamp(),
    });
  }
}
