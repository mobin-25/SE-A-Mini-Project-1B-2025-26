import 'package:cloud_firestore/cloud_firestore.dart';

/// Single source of truth for all Firestore operations.
/// Collection structure:
///   users/{uid}/profile        — health profile + emergency contact
///   users/{uid}/checkins/{date} — daily check-in records
///   users/{uid}/medications/{id} — medication logs
class FirebaseService {
  static final _db = FirebaseFirestore.instance;

  // ── Shortcuts ──────────────────────────────────────────────────────────────
  static DocumentReference _userDoc(String uid) =>
      _db.collection('users').doc(uid);

  static CollectionReference _checkinsCol(String uid) =>
      _userDoc(uid).collection('checkins');

  static CollectionReference _medicationsCol(String uid) =>
      _userDoc(uid).collection('medications');

  // ═══════════════════════════════════════════════════════════════════════════
  // PROFILE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Save or update health profile fields
  static Future<void> updateProfile(String uid, Map<String, dynamic> data) async {
    try {
      print('🔥 Saving profile for UID: $uid with data: $data');
      await _userDoc(uid).set(
        {...data, 'updatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
      print('✅ Profile saved successfully');
    } catch (e) {
      print('❌ ERROR saving profile: $e');
      rethrow; // Re-throw so caller knows about the error
    }
  }
   /// Check if user profile exists in Firebase
  static Future<bool> userProfileExists(String uid) async {
    try {
      final doc = await _userDoc(uid).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Get user profile with detailed info
  static Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final doc = await _userDoc(uid).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Load full profile document
  static Future<Map<String, dynamic>?> getProfile(String uid) async {
    try {
      final doc = await _userDoc(uid).get();
      return doc.exists ? doc.data() as Map<String, dynamic> : null;
    } catch (e) {
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EMERGENCY CONTACT
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<void> saveEmergencyContact(String uid, String contact) async {
    await updateProfile(uid, {'emergencyContact': contact});
  }

  static Future<String?> getEmergencyContact(String uid) async {
    final profile = await getProfile(uid);
    return profile?['emergencyContact'] as String?;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DAILY CHECK-INS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Save today's check-in
  static Future<void> saveCheckIn(String uid, String date) async {
    try {
      await _checkinsCol(uid).doc(date).set({
        'date':      date,
        'checkedIn': true,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {}
  }

  /// Get all check-in history as {date: bool}
  static Future<Map<String, bool>> getCheckInHistory(String uid) async {
    try {
      final snap = await _checkinsCol(uid)
          .orderBy('date', descending: true)
          .limit(90) // last 90 days
          .get();
      return {
        for (var doc in snap.docs)
          doc.id: (doc.data() as Map)['checkedIn'] == true
      };
    } catch (e) {
      return {};
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MEDICATION LOGS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Save a medication log entry
  static Future<void> saveMedicationLog(
      String uid, bool taken, String note) async {
    try {
      await _medicationsCol(uid).add({
        'taken':     taken,
        'note':      note,
        'timestamp': FieldValue.serverTimestamp(),
        'date':      DateTime.now().toString().substring(0, 10),
      });
    } catch (e) {}
  }

  /// Get medication logs (last 30 days)
  static Future<List<Map<String, dynamic>>> getMedicationLogs(
      String uid) async {
    try {
      final snap = await _medicationsCol(uid)
          .orderBy('timestamp', descending: true)
          .limit(60)
          .get();
      return snap.docs
          .map((d) => d.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ═══════════════════════════════════════════════════════════════════════════
  // FAMILY VIEW — real-time stream
  // ═══════════════════════════════════════════════════════════════════════════

  /// Stream the user document for real-time family view updates
  static Stream<DocumentSnapshot> userStream(String uid) =>
      _userDoc(uid).snapshots();

  /// Stream latest check-ins for family view
  static Stream<QuerySnapshot> checkinsStream(String uid) =>
      _checkinsCol(uid)
          .orderBy('date', descending: true)
          .limit(7)
          .snapshots();

  /// Get last 30 days check-in history
  static Future<Map<String, bool>> getLast30DaysCheckIns(String uid) async {
    try {
      final snap = await _checkinsCol(uid)
          .orderBy('date', descending: true)
          .limit(30)
          .get();
      return {
        for (var doc in snap.docs)
          doc.id: (doc.data() as Map)['checkedIn'] == true
      };
    } catch (e) {
      return {};
    }
  }

  /// Calculate check-in streak (consecutive days)
  static Future<int> getCheckInStreak(String uid) async {
    try {
      final history = await getLast30DaysCheckIns(uid);
      int streak = 0;
      final today = DateTime.now();
      
      for (int i = 0; i < 30; i++) {
        final date = today.subtract(Duration(days: i));
        final dateStr = date.toString().substring(0, 10);
        if (history[dateStr] == true) {
          streak++;
        } else if (i > 0) {
          break;
        }
      }
      return streak;
    } catch (e) {
      return 0;
    }
  }

  /// Get wellness score (0-100) based on check-in frequency
  static Future<int> getWellnessScore(String uid) async {
    try {
      final history = await getLast30DaysCheckIns(uid);
      final checkedInDays = history.values.where((v) => v).length;
      return ((checkedInDays / 30) * 100).toInt();
    } catch (e) {
      return 0;
    }
  }

  /// Get last check-in timestamp
  static Future<DateTime?> getLastCheckInTime(String uid) async {
    try {
      final snap = await _checkinsCol(uid)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        final timestamp = snap.docs.first['timestamp'] as Timestamp?;
        return timestamp?.toDate();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Add family note
  static Future<void> addFamilyNote(String uid, String name, String message) async {
    try {
      await _userDoc(uid).collection('familyNotes').add({
        'author': name,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding family note: $e');
    }
  }

  /// Get family notes stream
  static Stream<QuerySnapshot> familyNotesStream(String uid) =>
      _userDoc(uid)
          .collection('familyNotes')
          .orderBy('timestamp', descending: true)
          .limit(10)
          .snapshots();

  /// Send alert
  static Future<void> sendAlert(String uid, String authorName, String message) async {
    try {
      await _userDoc(uid).collection('alerts').add({
        'author': authorName,
        'message': message,
        'read': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error sending alert: $e');
    }
  }

  /// Stream recent alerts (live)
  static Stream<QuerySnapshot> alertsStream(String uid) =>
      _userDoc(uid)
          .collection('alerts')
          .orderBy('timestamp', descending: true)
          .limit(5)
          .snapshots();
}