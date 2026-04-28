// Riverpod providers for all repositories and state.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/models.dart';
import '../repositories/medicines_repository.dart';
import '../repositories/appointments_repository.dart';
import '../repositories/profile_repository.dart';
import '../repositories/checkin_repository.dart';
import '../repositories/admin_notifications_repository.dart';
import '../repositories/chat_repository.dart';
import '../widgets/avatar_picker.dart';

import '../services/notification_service.dart';

// --- Auth ---
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// --- Repositories (singletons) ---
final medicinesRepoProvider = Provider<MedicinesRepository>(
  (ref) => MedicinesRepository(),
);
final appointmentsRepoProvider = Provider<AppointmentsRepository>(
  (ref) => AppointmentsRepository(),
);
final profileRepoProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(),
);
final checkInRepoProvider = Provider<CheckInRepository>(
  (ref) => CheckInRepository(),
);

// --- Medicines ---
class MedicinesNotifier extends StateNotifier<List<Medicine>> {
  final MedicinesRepository _repo;
  final Ref _ref;
  final NotificationService _notificationService = NotificationService();

  MedicinesNotifier(this._repo, this._ref) : super(_repo.getAll());

  String get _userName {
    return _ref.read(profileProvider).name;
  }

  void refresh() => state = _repo.getAll();

  Future<void> loadFromFirestore() async {
    await _repo.loadAll();
    refresh();
  }

  Future<void> add(Medicine m) async {
    await _repo.add(m);
    _scheduleNotifications(m);
    refresh();
  }

  Future<void> update(Medicine m) async {
    await _repo.update(m);
    await _notificationService.cancelMedicineNotifications(m);
    _scheduleNotifications(m);
    refresh();
  }

  Future<void> delete(String id) async {
    final medicine = _repo.getById(id);
    if (medicine != null) {
      await _notificationService.cancelMedicineNotifications(medicine);
    }
    await _repo.delete(id);
    refresh();
  }

  void _scheduleNotifications(Medicine m) {
    if (!m.isReminderOn) return;
    for (String timeString in m.reminderTimes) {
      _notificationService.scheduleMedicineNotification(
        medicine: m,
        userName: _userName,
        timeString: timeString,
      );
    }
  }

  Future<void> markTimeTaken(String id, String time) async {
    await _repo.markTimeTaken(id, time);
    refresh();
  }

  Future<void> markAllTaken(String id) async {
    await _repo.markAllTaken(id);
    refresh();
  }

  /// Adherence streak: consecutive days with all meds taken (simplified).
  int get adherenceStreak {
    // For now, return count of fully-completed meds as a proxy streak
    return state.where((m) => m.isCompleted).length;
  }
}

final medicinesProvider =
    StateNotifierProvider<MedicinesNotifier, List<Medicine>>((ref) {
      return MedicinesNotifier(ref.read(medicinesRepoProvider), ref);
    });

// --- Appointments ---
class AppointmentsNotifier extends StateNotifier<List<Appointment>> {
  final AppointmentsRepository _repo;
  final NotificationService _notificationService = NotificationService();
  final Ref _ref;
  AppointmentsNotifier(this._repo, this._ref) : super(_repo.getAll());

  void refresh() => state = _repo.getAll();

  Future<void> loadFromFirestore() async {
    await _repo.loadAll();
    refresh();
    // Schedule notifications for all existing upcoming appointments
    for (final a in _repo.getUpcoming()) {
      _notificationService.scheduleAppointmentNotification(appointment: a);
    }
  }

  Future<void> add(Appointment a) async {
    final patientName = _ref.read(profileProvider).name;
    try {
      await _repo.add(a, patientName: patientName);
      _notificationService.scheduleAppointmentNotification(appointment: a);
      refresh();
    } catch (e) {
      refresh();
      rethrow;
    }
  }

  Future<void> update(Appointment a) async {
    await _notificationService.cancelAppointmentNotification(a);
    _notificationService.scheduleAppointmentNotification(appointment: a);
    await _repo.update(a);
    refresh();
  }

  Future<void> delete(String id) async {
    final appt = _repo.getById(id);
    if (appt != null) {
      await _notificationService.cancelAppointmentNotification(appt);
    }
    await _repo.delete(id);
    refresh();
  }

  List<Appointment> get upcoming => _repo.getUpcoming();
  List<Appointment> get past => _repo.getPast();
  Appointment? get nextUpcoming => _repo.getNextUpcoming();
}

final appointmentsProvider =
    StateNotifierProvider<AppointmentsNotifier, List<Appointment>>((ref) {
      return AppointmentsNotifier(ref.read(appointmentsRepoProvider), ref);
    });

/// Real-time stream of patient appointments — reflects doctor accept/decline instantly.
final patientAppointmentsStreamProvider = StreamProvider<List<Appointment>>((
  ref,
) {
  return ref.read(appointmentsRepoProvider).watchAppointments();
});

// --- Profile ---
class ProfileNotifier extends StateNotifier<UserProfile> {
  final ProfileRepository _repo;
  ProfileNotifier(this._repo) : super(_repo.get());

  Future<void> loadFromFirestore() async {
    await _repo.load();
    var profile = _repo.get();
    // Auto-assign avatar for existing profiles that don't have one
    if (profile.profilePicture == null || profile.profilePicture!.isEmpty) {
      final seed = profile.username ?? profile.name;
      if (seed.isNotEmpty && profile.onboardingComplete) {
        final url = kAvatarThemes[0].generateUrl(seed);
        profile = profile.copyWith(profilePicture: url);
        await _repo.update(profile);
      }
    }
    state = profile;
  }

  Future<void> updateProfile(UserProfile p) async {
    await _repo.update(p);
    state = _repo.get();
  }

  bool get isOnboardingComplete => _repo.isOnboardingComplete;
}

final profileProvider = StateNotifierProvider<ProfileNotifier, UserProfile>((
  ref,
) {
  return ProfileNotifier(ref.read(profileRepoProvider));
});

// --- Check-in ---
class CheckInNotifier extends StateNotifier<DailyCheckIn?> {
  final CheckInRepository _repo;
  CheckInNotifier(this._repo) : super(_repo.getToday());

  Future<void> loadFromFirestore() async {
    await _repo.loadAll();
    state = _repo.getToday();
  }

  Future<void> saveMood(int mood, {String? note}) async {
    await _repo.saveMood(mood, note: note);
    state = _repo.getToday();
  }
}

final checkInProvider = StateNotifierProvider<CheckInNotifier, DailyCheckIn?>((
  ref,
) {
  return CheckInNotifier(ref.read(checkInRepoProvider));
});

// --- Water Intake ---
class WaterIntakeNotifier extends StateNotifier<WaterIntake> {
  WaterIntakeNotifier()
    : super(WaterIntake(date: DateTime.now(), glassCount: 0, goal: 8));

  void addGlass() {
    if (state.glassCount < state.goal) {
      state = WaterIntake(
        date: state.date,
        glassCount: state.glassCount + 1,
        goal: state.goal,
      );
    }
  }

  void removeGlass() {
    if (state.glassCount > 0) {
      state = WaterIntake(
        date: state.date,
        glassCount: state.glassCount - 1,
        goal: state.goal,
      );
    }
  }

  void setGoal(int goal) {
    state = WaterIntake(
      date: state.date,
      glassCount: state.glassCount,
      goal: goal,
    );
  }
}

final waterIntakeProvider =
    StateNotifierProvider<WaterIntakeNotifier, WaterIntake>((ref) {
      return WaterIntakeNotifier();
    });

// --- Vitals ---
class VitalsNotifier extends StateNotifier<List<VitalRecord>> {
  VitalsNotifier()
    : super([
        // Sample data
        VitalRecord(
          type: 'heartRate',
          value: 72,
          recordedAt: DateTime.now().subtract(const Duration(hours: 2)),
          unit: 'bpm',
        ),
        VitalRecord(
          type: 'bp',
          value: 120,
          value2: 80,
          recordedAt: DateTime.now().subtract(const Duration(hours: 3)),
          unit: 'mmHg',
        ),
        VitalRecord(
          type: 'bloodSugar',
          value: 95,
          recordedAt: DateTime.now().subtract(const Duration(hours: 5)),
          unit: 'mg/dL',
        ),
      ]);

  void add(VitalRecord r) {
    state = [...state, r];
  }

  List<VitalRecord> getByType(String type) =>
      state.where((r) => r.type == type).toList()
        ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));

  VitalRecord? latestOfType(String type) {
    final list = getByType(type);
    return list.isEmpty ? null : list.first;
  }
}

final vitalsProvider = StateNotifierProvider<VitalsNotifier, List<VitalRecord>>(
  (ref) {
    return VitalsNotifier();
  },
);

/// Current bottom nav tab index.
final currentTabProvider = StateProvider<int>((ref) => 0);

// --- Patient Notifications (reuses AdminNotificationsRepository for the patient's own sub-collection) ---
final patientNotificationsRepoProvider = Provider<AdminNotificationsRepository>(
  (ref) => AdminNotificationsRepository(),
);

/// Stream provider for real-time patient notification updates.
final patientNotificationsStreamProvider =
    StreamProvider<List<AdminNotification>>((ref) {
      return ref.read(patientNotificationsRepoProvider).watchNotifications();
    });

// --- Patient Chat ---
final patientChatRepoProvider = Provider<ChatRepository>(
  (ref) => ChatRepository(),
);

/// Stream provider for real-time patient chat room updates.
final patientChatRoomsStreamProvider = StreamProvider<List<ChatRoom>>((ref) {
  return ref.read(patientChatRepoProvider).watchPatientChatRooms();
});

/// Stream provider for real-time chat messages (shared by both patient and doctor).
final patientChatMessagesStreamProvider =
    StreamProvider.family<List<ChatMessage>, String>((ref, chatRoomId) {
      return ref.read(patientChatRepoProvider).watchMessages(chatRoomId);
    });
