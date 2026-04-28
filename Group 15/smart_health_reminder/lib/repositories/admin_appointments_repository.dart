/// Firestore-backed repository for admin appointment management.
/// Reads/writes to the shared top-level 'appointments' collection.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../services/firestore_service.dart';
import 'chat_repository.dart';

class AdminAppointmentsRepository {
  final FirestoreService _firestore = FirestoreService();

  List<Appointment> _appointments = [];

  /// Load all appointments for this doctor from the shared collection.
  Future<void> loadAll() async {
    final doctorId = _firestore.uid;
    // First try loading appointments assigned to this doctor
    var snapshot =
        await _firestore.sharedAppointmentsCollection
            .where('doctorId', isEqualTo: doctorId)
            .get();
    // If none found, also load appointments with no doctorId assigned
    if (snapshot.docs.isEmpty) {
      snapshot = await _firestore.sharedAppointmentsCollection.get();
    }
    _appointments =
        snapshot.docs.map((doc) => Appointment.fromMap(doc.data())).toList()
          ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  List<Appointment> getAll() => List.unmodifiable(_appointments);

  List<Appointment> getPending() =>
      _appointments.where((a) => a.isPending).toList();

  List<Appointment> getUpcoming() =>
      _appointments.where((a) => a.isUpcoming && a.isAccepted).toList()
        ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

  List<Appointment> getPast() =>
      _appointments.where((a) => a.isPast).toList()
        ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

  List<Appointment> getByStatus(String status) =>
      _appointments.where((a) => a.status == status).toList();

  List<Appointment> getByPatientId(String patientId) =>
      _appointments.where((a) => a.patientId == patientId).toList();

  Appointment? getById(String id) {
    try {
      return _appointments.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Accept an appointment.
  Future<void> acceptAppointment(String id) async {
    final appt = getById(id);
    if (appt == null) return;
    appt.status = 'accepted';
    await _firestore.sharedAppointmentsCollection.doc(id).update({
      'status': 'accepted',
    });
    // Also update in patient's personal appointments
    if (appt.patientId != null) {
      try {
        await _firestore.usersCollection
            .doc(appt.patientId)
            .collection('appointments')
            .doc(id)
            .update({'status': 'accepted'});
      } catch (e) {
        debugPrint('Failed to update patient appointment: $e');
      }
    }
    // Notify the patient
    await _notifyPatient(
      appt,
      'Appointment Accepted',
      'Your appointment with ${appt.doctorName} has been accepted.',
    );
    // Auto-create a chat room between doctor and patient
    if (appt.patientId != null && appt.patientId!.isNotEmpty) {
      try {
        await ChatRepository().getOrCreateChatRoom(
          doctorId: _firestore.uid,
          patientId: appt.patientId!,
          doctorName: appt.doctorName,
          patientName: appt.patientName ?? 'Patient',
        );
      } catch (_) {
        // Don't block accept if chat room creation fails
      }
    }
  }

  /// Decline an appointment.
  Future<void> declineAppointment(String id, {String? reason}) async {
    final appt = getById(id);
    if (appt == null) return;
    appt.status = 'declined';
    appt.cancelReason = reason;
    final data = <String, dynamic>{'status': 'declined'};
    if (reason != null) data['cancelReason'] = reason;
    await _firestore.sharedAppointmentsCollection.doc(id).update(data);
    if (appt.patientId != null) {
      try {
        await _firestore.usersCollection
            .doc(appt.patientId)
            .collection('appointments')
            .doc(id)
            .update(data);
      } catch (e) {
        debugPrint('Failed to update patient appointment: $e');
      }
    }
    // Notify the patient
    final body =
        reason != null
            ? 'Your appointment with ${appt.doctorName} was declined. Reason: $reason'
            : 'Your appointment with ${appt.doctorName} was declined.';
    await _notifyPatient(appt, 'Appointment Declined', body);
  }

  /// Reschedule an appointment.
  Future<void> rescheduleAppointment(String id, DateTime newDateTime) async {
    final appt = getById(id);
    if (appt == null) return;
    appt.dateTime = newDateTime;
    appt.status = 'accepted';
    final data = {
      'dateTime': newDateTime.toIso8601String(),
      'status': 'accepted',
    };
    await _firestore.sharedAppointmentsCollection.doc(id).update(data);
    if (appt.patientId != null) {
      try {
        await _firestore.usersCollection
            .doc(appt.patientId)
            .collection('appointments')
            .doc(id)
            .update(data);
      } catch (e) {
        debugPrint('Failed to update patient appointment: $e');
      }
    }
  }

  /// Cancel an appointment with a reason.
  Future<void> cancelAppointment(String id, String reason) async {
    final appt = getById(id);
    if (appt == null) return;
    appt.status = 'cancelled';
    appt.cancelReason = reason;
    final data = {'status': 'cancelled', 'cancelReason': reason};
    await _firestore.sharedAppointmentsCollection.doc(id).update(data);
    if (appt.patientId != null) {
      try {
        await _firestore.usersCollection
            .doc(appt.patientId)
            .collection('appointments')
            .doc(id)
            .update(data);
      } catch (e) {
        debugPrint('Failed to update patient appointment: $e');
      }
    }
    await _notifyPatient(
      appt,
      'Appointment Cancelled',
      'Your appointment with ${appt.doctorName} was cancelled. Reason: $reason',
    );
  }

  /// Send a notification to the patient's personal notification sub-collection.
  Future<void> _notifyPatient(
    Appointment appt,
    String title,
    String body,
  ) async {
    if (appt.patientId == null) return;
    final notification = AdminNotification(
      id: const Uuid().v4(),
      type: 'appointment',
      title: title,
      body: body,
      timestamp: DateTime.now(),
      referenceId: appt.id,
    );
    // Write to patient's adminNotifications sub-collection
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(appt.patientId)
          .collection('adminNotifications')
          .doc(notification.id)
          .set(notification.toMap());
    } catch (_) {
      // Don't let notification write failure crash the flow
    }
  }

  /// Stream of real-time appointment updates for this doctor.
  Stream<List<Appointment>> watchAppointments() {
    final doctorId = _firestore.uid;
    return _firestore.sharedAppointmentsCollection.snapshots().map((snapshot) {
      final all =
          snapshot.docs.map((doc) => Appointment.fromMap(doc.data())).toList();
      // Show appointments assigned to this doctor, or unassigned ones
      _appointments =
          all
              .where((a) => a.doctorId == doctorId || a.doctorId == null)
              .toList()
            ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
      return _appointments;
    });
  }
}
