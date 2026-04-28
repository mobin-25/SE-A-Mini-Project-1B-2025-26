import 'package:firebase_auth/firebase_auth.dart';

import '../services/fcm_service.dart';
import '../services/push_notification_listener.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Current user (null if not signed in).
  User? get currentUser => _auth.currentUser;

  /// UID of the current user.
  String? get uid => _auth.currentUser?.uid;

  /// Stream of auth state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign up with email and password.
  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Sign in with email and password.
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Sign out.
  Future<void> signOut() async {
    PushNotificationListener().stopListening();
    await FcmService().clearToken();
    await _auth.signOut();
  }

  /// Send password reset email.
  Future<void> resetPassword({required String email}) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}
