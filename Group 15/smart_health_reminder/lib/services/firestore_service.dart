import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Central Firestore service providing user-scoped and shared collection references.
class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String get uid => FirebaseAuth.instance.currentUser!.uid;

  DocumentReference<Map<String, dynamic>> get _userDoc =>
      _db.collection('users').doc(uid);

  // ─── User-scoped collections ───────────────────────────────────────
  CollectionReference<Map<String, dynamic>> get medicinesCollection =>
      _userDoc.collection('medicines');

  CollectionReference<Map<String, dynamic>> get appointmentsCollection =>
      _userDoc.collection('appointments');

  CollectionReference<Map<String, dynamic>> get profileCollection =>
      _userDoc.collection('profile');

  CollectionReference<Map<String, dynamic>> get checkInsCollection =>
      _userDoc.collection('checkIns');

  // ─── Shared top-level collections (for admin portal) ───────────────
  /// All appointments across users — doctors query this by doctorId.
  CollectionReference<Map<String, dynamic>> get sharedAppointmentsCollection =>
      _db.collection('appointments');

  /// Chat rooms between doctors and patients.
  CollectionReference<Map<String, dynamic>> get chatRoomsCollection =>
      _db.collection('chatRooms');

  /// Messages within a chat room.
  CollectionReference<Map<String, dynamic>> chatMessagesCollection(
    String chatRoomId,
  ) => _db.collection('chatRooms').doc(chatRoomId).collection('messages');

  /// Prescriptions (stored top-level, queried by doctorId or patientId).
  CollectionReference<Map<String, dynamic>> get prescriptionsCollection =>
      _db.collection('prescriptions');

  /// Doctor profiles (specialty, availability, etc.).
  CollectionReference<Map<String, dynamic>> get doctorProfilesCollection =>
      _db.collection('doctorProfiles');

  /// Admin notifications for a specific doctor.
  CollectionReference<Map<String, dynamic>> get adminNotificationsCollection =>
      _db.collection('users').doc(uid).collection('adminNotifications');

  /// Access any user's profile (for admin reading patient data).
  CollectionReference<Map<String, dynamic>> userProfileCollection(
    String userId,
  ) => _db.collection('users').doc(userId).collection('profile');

  /// Access any user's medicines (for admin reading patient prescriptions).
  CollectionReference<Map<String, dynamic>> userMedicinesCollection(
    String userId,
  ) => _db.collection('users').doc(userId).collection('medicines');

  /// Get the users collection for querying patients.
  CollectionReference<Map<String, dynamic>> get usersCollection =>
      _db.collection('users');
}
