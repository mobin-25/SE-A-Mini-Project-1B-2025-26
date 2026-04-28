// Riverpod providers for the admin (doctor) portal.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../repositories/admin_appointments_repository.dart';
import '../repositories/chat_repository.dart';
import '../repositories/prescriptions_repository.dart';
import '../repositories/doctor_profile_repository.dart';
import '../repositories/admin_notifications_repository.dart';
import '../widgets/avatar_picker.dart';

// ─── Repository Providers ────────────────────────────────────────────
final adminAppointmentsRepoProvider = Provider<AdminAppointmentsRepository>(
  (ref) => AdminAppointmentsRepository(),
);
final chatRepoProvider = Provider<ChatRepository>((ref) => ChatRepository());
final prescriptionsRepoProvider = Provider<PrescriptionsRepository>(
  (ref) => PrescriptionsRepository(),
);
final doctorProfileRepoProvider = Provider<DoctorProfileRepository>(
  (ref) => DoctorProfileRepository(),
);
final adminNotificationsRepoProvider = Provider<AdminNotificationsRepository>(
  (ref) => AdminNotificationsRepository(),
);

// ─── Admin Appointments ──────────────────────────────────────────────
class AdminAppointmentsNotifier extends StateNotifier<List<Appointment>> {
  final AdminAppointmentsRepository _repo;

  AdminAppointmentsNotifier(this._repo) : super([]);

  Future<void> loadFromFirestore() async {
    await _repo.loadAll();
    state = _repo.getAll();
  }

  void refresh() => state = _repo.getAll();

  List<Appointment> get pending => _repo.getPending();
  List<Appointment> get upcoming => _repo.getUpcoming();
  List<Appointment> get past => _repo.getPast();

  List<Appointment> filterByStatus(String status) => _repo.getByStatus(status);
  List<Appointment> filterByPatient(String patientId) =>
      _repo.getByPatientId(patientId);

  Future<void> acceptAppointment(String id) async {
    await _repo.acceptAppointment(id);
    refresh();
  }

  Future<void> declineAppointment(String id, {String? reason}) async {
    await _repo.declineAppointment(id, reason: reason);
    refresh();
  }

  Future<void> rescheduleAppointment(String id, DateTime newDateTime) async {
    await _repo.rescheduleAppointment(id, newDateTime);
    refresh();
  }

  Future<void> cancelAppointment(String id, String reason) async {
    await _repo.cancelAppointment(id, reason);
    refresh();
  }

  /// Start listening to real-time updates.
  Stream<List<Appointment>> watchAppointments() => _repo.watchAppointments();
}

final adminAppointmentsProvider =
    StateNotifierProvider<AdminAppointmentsNotifier, List<Appointment>>((ref) {
      return AdminAppointmentsNotifier(ref.read(adminAppointmentsRepoProvider));
    });

/// Stream provider for real-time appointment updates.
final adminAppointmentsStreamProvider = StreamProvider<List<Appointment>>((
  ref,
) {
  return ref.read(adminAppointmentsRepoProvider).watchAppointments();
});

// ─── Chat ────────────────────────────────────────────────────────────
final chatRoomsStreamProvider = StreamProvider<List<ChatRoom>>((ref) {
  return ref.read(chatRepoProvider).watchDoctorChatRooms();
});

final chatMessagesStreamProvider =
    StreamProvider.family<List<ChatMessage>, String>((ref, chatRoomId) {
      return ref.read(chatRepoProvider).watchMessages(chatRoomId);
    });

// ─── Prescriptions ──────────────────────────────────────────────────
class PrescriptionsNotifier extends StateNotifier<List<Prescription>> {
  final PrescriptionsRepository _repo;

  PrescriptionsNotifier(this._repo) : super([]);

  Future<void> loadFromFirestore() async {
    await _repo.loadAll();
    state = _repo.getAll();
  }

  void refresh() => state = _repo.getAll();

  List<Prescription> getByPatient(String patientId) =>
      _repo.getByPatientId(patientId);

  Future<void> add(Prescription prescription) async {
    await _repo.add(prescription);
    refresh();
  }

  Future<void> update(Prescription prescription) async {
    await _repo.update(prescription);
    refresh();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    refresh();
  }
}

final prescriptionsProvider =
    StateNotifierProvider<PrescriptionsNotifier, List<Prescription>>((ref) {
      return PrescriptionsNotifier(ref.read(prescriptionsRepoProvider));
    });

// ─── Doctor Profile ─────────────────────────────────────────────────
class DoctorProfileNotifier extends StateNotifier<DoctorProfile?> {
  final DoctorProfileRepository _repo;

  DoctorProfileNotifier(this._repo) : super(null);

  Future<void> loadFromFirestore() async {
    await _repo.load();
    var profile = _repo.get();
    // Auto-assign avatar for existing doctor profiles that don't have one
    if (profile != null &&
        (profile.profilePicture == null || profile.profilePicture!.isEmpty)) {
      final seed = profile.username ?? profile.name;
      final url = kAvatarThemes[0].generateUrl(seed);
      profile = profile.copyWith(profilePicture: url);
      await _repo.save(profile);
    }
    state = profile;
  }

  Future<void> save(DoctorProfile profile) async {
    await _repo.save(profile);
    state = profile;
  }
}

final doctorProfileProvider =
    StateNotifierProvider<DoctorProfileNotifier, DoctorProfile?>((ref) {
      return DoctorProfileNotifier(ref.read(doctorProfileRepoProvider));
    });

// ─── Admin Notifications ────────────────────────────────────────────
class AdminNotificationsNotifier
    extends StateNotifier<List<AdminNotification>> {
  final AdminNotificationsRepository _repo;

  AdminNotificationsNotifier(this._repo) : super([]);

  Future<void> loadFromFirestore() async {
    await _repo.loadAll();
    state = _repo.getAll();
  }

  void refresh() => state = _repo.getAll();

  int get unreadCount => _repo.unreadCount;

  Future<void> add(AdminNotification notification) async {
    await _repo.add(notification);
    refresh();
  }

  Future<void> markAsRead(String id) async {
    await _repo.markAsRead(id);
    refresh();
  }

  Future<void> markAllAsRead() async {
    await _repo.markAllAsRead();
    refresh();
  }
}

final adminNotificationsProvider = StateNotifierProvider<
  AdminNotificationsNotifier,
  List<AdminNotification>
>((ref) {
  return AdminNotificationsNotifier(ref.read(adminNotificationsRepoProvider));
});

/// Stream provider for real-time notification updates.
final adminNotificationsStreamProvider =
    StreamProvider<List<AdminNotification>>((ref) {
      return ref.read(adminNotificationsRepoProvider).watchNotifications();
    });

/// Current admin tab index.
final adminTabProvider = StateProvider<int>((ref) => 0);
