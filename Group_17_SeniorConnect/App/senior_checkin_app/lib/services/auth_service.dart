import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;

  static String? get uid       => _auth.currentUser?.uid;
  static User?   get user      => _auth.currentUser;
  static bool    get isSignedIn => _auth.currentUser != null;

  // Sign in anonymously — called on first launch
  static Future<String?> signInAnonymously() async {
    try {
      final result = await _auth.signInAnonymously();
      return result.user?.uid;
    } catch (e) {
      return null;
    }
  }

  // Sign in with name: anonymous auth + save name locally + mark onboarding done
  static Future<String?> signInWithName(String name) async {
    try {
      final uid = await signInAnonymously();
      if (uid == null) return null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', name);
      await prefs.setBool('onboarding_done', true);
      return uid;
    } catch (e) {
      return null;
    }
  }

  static Future<String> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_name') ?? 'Friend';
  }

  static Future<void> signOut() async {
    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('onboarding_done');
  }

  static Stream<User?> get authStateChanges => _auth.authStateChanges();
}