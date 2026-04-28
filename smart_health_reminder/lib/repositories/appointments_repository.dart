/// Firestore-backed repository for appointments.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../services/firestore_service.dart';

class AppointmentsRepository {
  final FirestoreService _firestore = FirestoreService();

  List<Appointment> _appointments = [];

  /// Load all appointments from Firestore into memory.
  Future<void> loadAll() async {
    final snapshot = await _firestore.appointmentsCollection.get();
    _appointments =
        snapshot.docs.map((doc) => Appointment.fromMap(doc.data())).toList();
  }

  List<Appointment> getAll() => List.unmodifiable(_appointments);

  List<Appointment> getUpcoming() =>
      _appointments.where((a) => a.isUpcoming).toList()
        ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

  List<Appointment> getPast() =>
      _appointments.where((a) => a.isPast).toList()
        ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

  Appointment? getNextUpcoming() {
    final upcoming = getUpcoming();
    return upcoming.isEmpty ? null : upcoming.first;
  }

  Appointment? getById(String id) {
    try {
      return _appointments.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> add(Appointment appointment, {String patientName = ''}) async {
    // Use doctorId from the appointment if already provided (from doctor search)
    final doctorId = appointment.doctorId;

    // Enrich appointment with patient info
    final enriched = Appointment(
      id: appointment.id,
      doctorName: appointment.doctorName,
      specialty: appointment.specialty,
      dateTime: appointment.dateTime,
      location: appointment.location,
      notes: appointment.notes,
      status: 'pending',
      patientId: _firestore.uid,
      patientName: patientName,
      doctorId: doctorId,
    );

    // Save to user's personal appointments collection
    await _firestore.appointmentsCollection
        .doc(enriched.id)
        .set(enriched.toMap());

    // Also save to the shared appointments collection for the admin/doctor
    await _firestore.sharedAppointmentsCollection
        .doc(enriched.id)
        .set(enriched.toMap());

    // Create an admin notification for the doctor
    final notification = AdminNotification(
      id: const Uuid().v4(),
      type: 'appointment',
      title: 'New Appointment Request',
      body: '$patientName booked an appointment for ${appointment.specialty}',
      timestamp: DateTime.now(),
      referenceId: enriched.id,
    );

    if (doctorId != null && doctorId.isNotEmpty) {
      // Write to the doctor's personal notifications sub-collection
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(doctorId)
            .collection('adminNotifications')
            .doc(notification.id)
            .set(notification.toMap());
      } catch (_) {
        // Don't let notification failure block appointment creation
      }
    }

    _appointments.add(enriched);
  }

  Future<void> update(Appointment appointment) async {
    await _firestore.appointmentsCollection
        .doc(appointment.id)
        .update(appointment.toMap());
    // Also update shared collection
    await _firestore.sharedAppointmentsCollection
        .doc(appointment.id)
        .set(appointment.toMap());
    final index = _appointments.indexWhere((a) => a.id == appointment.id);
    if (index != -1) _appointments[index] = appointment;
  }

  Future<void> delete(String id) async {
    await _firestore.appointmentsCollection.doc(id).delete();
    // Also delete from shared collection
    await _firestore.sharedAppointmentsCollection.doc(id).delete();
    _appointments.removeWhere((a) => a.id == id);
  }

  /// Real-time stream of patient's appointments from the **shared** collection.
  /// The doctor reliably updates the shared collection, so watching it here
  /// ensures the patient sees status changes (accepted / declined) instantly.
  Stream<List<Appointment>> watchAppointments() {
    return _firestore.sharedAppointmentsCollection
        .where('patientId', isEqualTo: _firestore.uid)
        .snapshots()
        .map((snapshot) {
          _appointments =
              snapshot.docs
                  .map((doc) => Appointment.fromMap(doc.data()))
                  .toList()
                ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
          return _appointments;
        });
  }
}
