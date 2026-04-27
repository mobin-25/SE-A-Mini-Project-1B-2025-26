import 'package:firebase_auth/firebase_auth.dart';

class AuthHelper {
  AuthHelper._();

  static final AuthHelper instance = AuthHelper._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<UserCredential> signUp(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthError(e));
    } catch (e) {
      throw Exception("Something went wrong");
    }
  }

  Future<UserCredential> login(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthError(e));
    } catch (e) {
      throw Exception("Something went wrong");
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }

  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return "Email is already registered";
      case 'invalid-email':
        return "Invalid email address";
      case 'weak-password':
        return "Password should be at least 6 characters";
      case 'user-not-found':
        return "No user found with this email";
      case 'wrong-password':
      case 'invalid-credential':
        return "Incorrect email or password";
      default:
        return e.message ?? "Authentication error";
    }
  }
}