import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/parking_slot_model.dart';
import '../models/booking_model.dart';
import 'notification_service.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── User profile ─────────────────────────────────────────────────────────

  static Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(uid, doc.data()!);
  }

  static Future<void> updateUserProfile(
      String uid, String name, String role) async {
    await _db.collection('users').doc(uid).update({
      'name': name,
      'role': role,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ─── Vehicle (one per user login) ──────────────────────────────────────────

  static Future<Map<String, dynamic>?> getVehicle(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    if (data['vehicle'] == null) return null;
    return Map<String, dynamic>.from(data['vehicle'] as Map);
  }

  static Future<void> setVehicle(
    String uid, {
    required String plate,
    required String type,
    required String model,
  }) async {
    await _db.collection('users').doc(uid).update({
      'vehicle': {'plate': plate, 'type': type, 'model': model},
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ─── Parking slots ────────────────────────────────────────────────────────

  /// Real-time stream of all parking slots
  static Stream<List<ParkingSlotModel>> getParkingSlots() {
    return _db.collection('parking_slots').snapshots().map((snap) {
      return snap.docs
          .map((d) => ParkingSlotModel.fromMap(d.id, d.data()))
          .toList()
        ..sort((a, b) => a.id.compareTo(b.id));
    });
  }

  /// Reserve a slot for a user (sets status='reserved', stores uid + duration)
  static Future<void> reserveSlot(
    String slotId,
    String userId, {
    String duration = '1 Hour',
  }) async {
    final batch = _db.batch();
    final slotRef = _db.collection('parking_slots').doc(slotId);
    batch.update(slotRef, {
      'status': 'reserved',
      'reservedBy': userId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    final bookingRef = _db.collection('bookings').doc();
    batch.set(bookingRef, {
      'slotId': slotId,
      'userId': userId,
      'startTime': FieldValue.serverTimestamp(),
      'status': 'active',
      'duration': duration,
    });
    await batch.commit();
    await NotificationService.notifySlotBooked(slotId);
  }

  /// Release a slot (sets status='available', clears uid)
  static Future<void> releaseSlot(String slotId) async {
    await _db.collection('parking_slots').doc(slotId).update({
      'status': 'available',
      'reservedBy': null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    final bookings = await _db
        .collection('bookings')
        .where('slotId', isEqualTo: slotId)
        .where('status', isEqualTo: 'active')
        .get();
    for (final doc in bookings.docs) {
      await doc.reference.update({'status': 'completed'});
    }
  }

  // ─── Bookings ─────────────────────────────────────────────────────────────

  static Stream<List<BookingModel>> getUserBookings(String userId) {
    return _db
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((d) => BookingModel.fromMap(d.id, d.data()))
              .toList();
          // Sort in Dart so no composite Firestore index is required
          list.sort((a, b) => b.startTime.compareTo(a.startTime));
          return list;
        });
  }

  // ─── Seed data ────────────────────────────────────────────────────────────

  /// Seeds the full APSIT parking layout into Firestore.
  /// Layout:
  ///   SC-01..SC-30   → Staff Car Parking      (left, 30 slots)
  ///   SB-001..SB-100 → Student Bike Parking   (right-top, 100 slots)
  ///   FB-01..FB-25   → Staff/Faculty Bikes    (right-bottom, 25 slots)
  ///   CP-001..CP-100 → Common Parking (both)  (behind, 100 slots)
  ///
  /// Runs only if the new-format slots are missing (SC-, SB-, FB-, CP- IDs).
  static Future<void> seedParkingSlotsIfEmpty() async {
    // Check for the specific anchor doc; fast single-doc lookup
    final check =
        await _db.collection('parking_slots').doc('SC-01').get();
    if (check.exists) return; // already seeded

    // Write in batches of 500 (Firestore limit)
    final allSlots = <Map<String, dynamic>>[];

    // ── Staff Car Parking: SC-01 to SC-30 ─────────────────────────────────
    for (int i = 1; i <= 30; i++) {
      allSlots.add({
        'id': 'SC-${i.toString().padLeft(2, '0')}',
        'status': i <= 4 ? 'occupied' : (i <= 6 ? 'reserved' : 'available'),
        'vehicleType': 'car',
        'zone': 'staff_car',
        'reservedBy': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    // ── Student Bike Parking: SB-001 to SB-100 ────────────────────────────
    for (int i = 1; i <= 100; i++) {
      allSlots.add({
        'id': 'SB-${i.toString().padLeft(3, '0')}',
        'status': i <= 12
            ? 'occupied'
            : (i <= 18 ? 'reserved' : 'available'),
        'vehicleType': 'bike',
        'zone': 'student_bike',
        'reservedBy': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    // ── Staff/Faculty Bike Parking: FB-01 to FB-25 ───────────────────────
    for (int i = 1; i <= 25; i++) {
      allSlots.add({
        'id': 'FB-${i.toString().padLeft(2, '0')}',
        'status': i <= 3 ? 'occupied' : 'available',
        'vehicleType': 'bike',
        'zone': 'staff_bike',
        'reservedBy': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    // ── Common Parking: CP-001 to CP-100 ─────────────────────────────────
    for (int i = 1; i <= 100; i++) {
      allSlots.add({
        'id': 'CP-${i.toString().padLeft(3, '0')}',
        'status': i <= 20
            ? 'occupied'
            : (i <= 30 ? 'reserved' : 'available'),
        'vehicleType': i % 3 == 0 ? 'bike' : 'car',
        'zone': 'common',
        'reservedBy': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    // Write in batches of 500
    const batchSize = 499;
    for (int start = 0; start < allSlots.length; start += batchSize) {
      final batch = _db.batch();
      final end = (start + batchSize).clamp(0, allSlots.length);
      for (final s in allSlots.sublist(start, end)) {
        final ref = _db.collection('parking_slots').doc(s['id'] as String);
        batch.set(ref, s);
      }
      await batch.commit();
    }
  }
}
