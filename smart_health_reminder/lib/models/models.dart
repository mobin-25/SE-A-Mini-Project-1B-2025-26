// Data models for the MEDITOUCH app.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Represents a user profile with personal and health information.
class UserProfile {
  final String id;
  String name;
  String? username; // unique handle chosen by user (like Instagram)
  String? uniqueId; // legacy auto-generated ID
  int? age;
  String? gender;
  String? phone;
  String? email;
  String? bloodGroup;
  String? emergencyContactName;
  String? emergencyContactPhone;
  List<String> healthConditions; // e.g. ["Diabetes", "Hypertension"]
  List<String> allergies; // e.g. ["Penicillin", "Peanuts"]
  double? height; // in cm
  double? weight; // in kg
  bool onboardingComplete;
  String role; // 'user' or 'doctor'
  String? profilePicture; // DiceBear avatar URL

  UserProfile({
    String? id,
    required this.name,
    this.username,
    this.uniqueId,
    this.age,
    this.gender,
    this.phone,
    this.email,
    this.bloodGroup,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.healthConditions = const [],
    this.allergies = const [],
    this.height,
    this.weight,
    this.onboardingComplete = false,
    this.role = 'user',
    this.profilePicture,
  }) : id = id ?? _uuid.v4();

  UserProfile copyWith({
    String? name,
    String? username,
    String? uniqueId,
    int? age,
    String? gender,
    String? phone,
    String? email,
    String? bloodGroup,
    String? emergencyContactName,
    String? emergencyContactPhone,
    List<String>? healthConditions,
    List<String>? allergies,
    double? height,
    double? weight,
    bool? onboardingComplete,
    String? role,
    String? profilePicture,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      username: username ?? this.username,
      uniqueId: uniqueId ?? this.uniqueId,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone:
          emergencyContactPhone ?? this.emergencyContactPhone,
      healthConditions: healthConditions ?? this.healthConditions,
      allergies: allergies ?? this.allergies,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      role: role ?? this.role,
      profilePicture: profilePicture ?? this.profilePicture,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'uniqueId': uniqueId,
      'age': age,
      'gender': gender,
      'phone': phone,
      'email': email,
      'bloodGroup': bloodGroup,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
      'healthConditions': healthConditions,
      'allergies': allergies,
      'height': height,
      'weight': weight,
      'onboardingComplete': onboardingComplete,
      'role': role,
      'profilePicture': profilePicture,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      name: map['name'] as String,
      username: map['username'] as String?,
      uniqueId: map['uniqueId'] as String?,
      age: map['age'] as int?,
      gender: map['gender'] as String?,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      bloodGroup: map['bloodGroup'] as String?,
      emergencyContactName: map['emergencyContactName'] as String?,
      emergencyContactPhone: map['emergencyContactPhone'] as String?,
      healthConditions: List<String>.from(map['healthConditions'] ?? []),
      allergies: List<String>.from(map['allergies'] ?? []),
      height: (map['height'] as num?)?.toDouble(),
      weight: (map['weight'] as num?)?.toDouble(),
      onboardingComplete: map['onboardingComplete'] as bool? ?? false,
      role: map['role'] as String? ?? 'user',
      profilePicture: map['profilePicture'] as String?,
    );
  }

  bool get isDoctor => role == 'doctor';

  /// BMI calculation
  double? get bmi {
    if (height != null && weight != null && height! > 0) {
      final h = height! / 100;
      return weight! / (h * h);
    }
    return null;
  }

  String get bmiCategory {
    final b = bmi;
    if (b == null) return 'N/A';
    if (b < 18.5) return 'Underweight';
    if (b < 25) return 'Normal';
    if (b < 30) return 'Overweight';
    return 'Obese';
  }
}

/// Represents a medicine with dosage, schedule, and reminder settings.
class Medicine {
  final String id;
  String name;
  String dosage;
  String form;
  List<String> reminderTimes;
  String frequency;
  bool withFood;
  String? notes;
  bool isCompleted;
  bool isReminderOn;
  List<String> takenTimes;

  Medicine({
    String? id,
    required this.name,
    required this.dosage,
    this.form = 'Tablet',
    this.reminderTimes = const [],
    this.frequency = 'Once a day',
    this.withFood = false,
    this.notes,
    this.isCompleted = false,
    this.isReminderOn = true,
    this.takenTimes = const [],
  }) : id = id ?? _uuid.v4();

  Medicine copyWith({
    String? name,
    String? dosage,
    String? form,
    List<String>? reminderTimes,
    String? frequency,
    bool? withFood,
    String? notes,
    bool? isCompleted,
    bool? isReminderOn,
    List<String>? takenTimes,
  }) {
    return Medicine(
      id: id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      form: form ?? this.form,
      reminderTimes: reminderTimes ?? this.reminderTimes,
      frequency: frequency ?? this.frequency,
      withFood: withFood ?? this.withFood,
      notes: notes ?? this.notes,
      isCompleted: isCompleted ?? this.isCompleted,
      isReminderOn: isReminderOn ?? this.isReminderOn,
      takenTimes: takenTimes ?? this.takenTimes,
    );
  }

  int get takenCount => takenTimes.length;
  int get totalDoses => reminderTimes.length;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'form': form,
      'reminderTimes': reminderTimes,
      'frequency': frequency,
      'withFood': withFood,
      'notes': notes,
      'isCompleted': isCompleted,
      'isReminderOn': isReminderOn,
      'takenTimes': takenTimes,
    };
  }

  factory Medicine.fromMap(Map<String, dynamic> map) {
    return Medicine(
      id: map['id'] as String,
      name: map['name'] as String,
      dosage: map['dosage'] as String,
      form: map['form'] as String? ?? 'Tablet',
      reminderTimes: List<String>.from(map['reminderTimes'] ?? []),
      frequency: map['frequency'] as String? ?? 'Once a day',
      withFood: map['withFood'] as bool? ?? false,
      notes: map['notes'] as String?,
      isCompleted: map['isCompleted'] as bool? ?? false,
      isReminderOn: map['isReminderOn'] as bool? ?? true,
      takenTimes: List<String>.from(map['takenTimes'] ?? []),
    );
  }
}

/// Represents a medical appointment.
class Appointment {
  final String id;
  String doctorName;
  String specialty;
  DateTime dateTime;
  String location;
  String status; // pending, accepted, declined, confirmed, cancelled
  String? notes;
  String? patientId;
  String? patientName;
  String? doctorId;
  String? cancelReason;

  Appointment({
    String? id,
    required this.doctorName,
    required this.specialty,
    required this.dateTime,
    required this.location,
    this.status = 'pending',
    this.notes,
    this.patientId,
    this.patientName,
    this.doctorId,
    this.cancelReason,
  }) : id = id ?? _uuid.v4();

  Appointment copyWith({
    String? doctorName,
    String? specialty,
    DateTime? dateTime,
    String? location,
    String? status,
    String? notes,
    String? patientId,
    String? patientName,
    String? doctorId,
    String? cancelReason,
  }) {
    return Appointment(
      id: id,
      doctorName: doctorName ?? this.doctorName,
      specialty: specialty ?? this.specialty,
      dateTime: dateTime ?? this.dateTime,
      location: location ?? this.location,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      doctorId: doctorId ?? this.doctorId,
      cancelReason: cancelReason ?? this.cancelReason,
    );
  }

  bool get isUpcoming => dateTime.isAfter(DateTime.now());
  bool get isPast => !isUpcoming;

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isDeclined => status == 'declined';
  bool get isCancelled => status == 'cancelled';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'doctorName': doctorName,
      'specialty': specialty,
      'dateTime': dateTime.toIso8601String(),
      'location': location,
      'status': status,
      'notes': notes,
      'patientId': patientId,
      'patientName': patientName,
      'doctorId': doctorId,
      'cancelReason': cancelReason,
    };
  }

  factory Appointment.fromMap(Map<String, dynamic> map) {
    return Appointment(
      id: map['id'] as String,
      doctorName: map['doctorName'] as String,
      specialty: map['specialty'] as String,
      dateTime: DateTime.parse(map['dateTime'] as String),
      location: map['location'] as String,
      status: map['status'] as String? ?? 'pending',
      notes: map['notes'] as String?,
      patientId: map['patientId'] as String?,
      patientName: map['patientName'] as String?,
      doctorId: map['doctorId'] as String?,
      cancelReason: map['cancelReason'] as String?,
    );
  }
}

/// Represents a daily mood check-in.
class DailyCheckIn {
  final String id;
  final DateTime date;
  int mood;
  String? note;

  DailyCheckIn({String? id, required this.date, required this.mood, this.note})
    : id = id ?? _uuid.v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'mood': mood,
      'note': note,
    };
  }

  factory DailyCheckIn.fromMap(Map<String, dynamic> map) {
    return DailyCheckIn(
      id: map['id'] as String,
      date: DateTime.parse(map['date'] as String),
      mood: map['mood'] as int,
      note: map['note'] as String?,
    );
  }
}

/// Tracks water intake for the day.
class WaterIntake {
  final DateTime date;
  int glassCount;
  int goal;

  WaterIntake({required this.date, this.glassCount = 0, this.goal = 8});

  double get percentage => (glassCount / goal).clamp(0.0, 1.0);
}

/// Tracks a health vital recording.
class VitalRecord {
  final String id;
  final String type; // bp, heartRate, weight, bloodSugar
  final double value;
  final double? value2; // for BP: diastolic
  final DateTime recordedAt;
  final String? unit;

  VitalRecord({
    String? id,
    required this.type,
    required this.value,
    this.value2,
    required this.recordedAt,
    this.unit,
  }) : id = id ?? _uuid.v4();
}

/// A health tip shown on the home screen.
class HealthTip {
  final String title;
  final String body;
  final String icon; // emoji

  const HealthTip({
    required this.title,
    required this.body,
    required this.icon,
  });
}

/// Predefined list of common health conditions.
const kCommonConditions = [
  'Diabetes Type 1',
  'Diabetes Type 2',
  'Hypertension',
  'Asthma',
  'Heart Disease',
  'Arthritis',
  'Thyroid Disorder',
  'High Cholesterol',
  'COPD',
  'Kidney Disease',
  'Liver Disease',
  'Anemia',
  'Depression',
  'Anxiety',
  'Epilepsy',
  'Migraine',
  'Cancer',
  'HIV/AIDS',
  'Tuberculosis',
  'Allergic Rhinitis',
];

/// Predefined common allergies.
const kCommonAllergies = [
  'Penicillin',
  'Aspirin',
  'Ibuprofen',
  'Sulfa Drugs',
  'Peanuts',
  'Tree Nuts',
  'Shellfish',
  'Eggs',
  'Milk',
  'Latex',
  'Bee Stings',
  'Dust Mites',
  'Pollen',
  'Mold',
  'Pet Dander',
];

/// Blood group options.
const kBloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

/// Daily health tips rotation.
const kHealthTips = [
  HealthTip(
    title: 'Stay Hydrated',
    body:
        'Drink at least 8 glasses of water daily to keep your body functioning optimally.',
    icon: '💧',
  ),
  HealthTip(
    title: 'Move Your Body',
    body:
        '30 minutes of moderate exercise daily reduces risk of chronic disease by 50%.',
    icon: '🏃',
  ),
  HealthTip(
    title: 'Sleep Well',
    body: 'Aim for 7-9 hours of quality sleep each night for optimal recovery.',
    icon: '😴',
  ),
  HealthTip(
    title: 'Eat Colorfully',
    body:
        'Include fruits and vegetables of different colors for a wider range of nutrients.',
    icon: '🥗',
  ),
  HealthTip(
    title: 'Manage Stress',
    body: 'Practice deep breathing or meditation for 10 minutes daily.',
    icon: '🧘',
  ),
  HealthTip(
    title: 'Take Medicines on Time',
    body:
        'Consistent timing improves medication effectiveness and reduces side effects.',
    icon: '💊',
  ),
  HealthTip(
    title: 'Regular Check-ups',
    body:
        'Annual health screenings catch problems early when they are most treatable.',
    icon: '🏥',
  ),
];

// ─── Admin Portal Models ─────────────────────────────────────────────

/// A chat message between a doctor and patient.
class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;

  ChatMessage({
    String? id,
    required this.senderId,
    required this.text,
    required this.timestamp,
  }) : id = id ?? _uuid.v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] as String,
      senderId: map['senderId'] as String,
      text: map['text'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }
}

/// A chat room between a doctor and patient.
class ChatRoom {
  final String id;
  final String doctorId;
  final String patientId;
  final String doctorName;
  final String patientName;
  String? lastMessage;
  DateTime? lastMessageTime;

  ChatRoom({
    String? id,
    required this.doctorId,
    required this.patientId,
    required this.doctorName,
    required this.patientName,
    this.lastMessage,
    this.lastMessageTime,
  }) : id = id ?? _uuid.v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'doctorId': doctorId,
      'patientId': patientId,
      'doctorName': doctorName,
      'patientName': patientName,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime?.toIso8601String(),
    };
  }

  factory ChatRoom.fromMap(Map<String, dynamic> map) {
    return ChatRoom(
      id: map['id'] as String,
      doctorId: map['doctorId'] as String,
      patientId: map['patientId'] as String,
      doctorName: map['doctorName'] as String,
      patientName: map['patientName'] as String,
      lastMessage: map['lastMessage'] as String?,
      lastMessageTime:
          map['lastMessageTime'] != null
              ? DateTime.parse(map['lastMessageTime'] as String)
              : null,
    );
  }
}

/// A prescription created by a doctor for a patient.
class Prescription {
  final String id;
  final String doctorId;
  final String patientId;
  final String patientName;
  final String doctorName;
  final List<PrescriptionItem> medicines;
  final String? diagnosis;
  final String? notes;
  final DateTime createdAt;

  Prescription({
    String? id,
    required this.doctorId,
    required this.patientId,
    required this.patientName,
    required this.doctorName,
    required this.medicines,
    this.diagnosis,
    this.notes,
    DateTime? createdAt,
  }) : id = id ?? _uuid.v4(),
       createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'doctorId': doctorId,
      'patientId': patientId,
      'patientName': patientName,
      'doctorName': doctorName,
      'medicines': medicines.map((m) => m.toMap()).toList(),
      'diagnosis': diagnosis,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Prescription.fromMap(Map<String, dynamic> map) {
    return Prescription(
      id: map['id'] as String,
      doctorId: map['doctorId'] as String,
      patientId: map['patientId'] as String,
      patientName: map['patientName'] as String,
      doctorName: map['doctorName'] as String,
      medicines:
          (map['medicines'] as List)
              .map((m) => PrescriptionItem.fromMap(m as Map<String, dynamic>))
              .toList(),
      diagnosis: map['diagnosis'] as String?,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}

/// A single medicine entry within a prescription.
class PrescriptionItem {
  String name;
  String dosage;
  String frequency;
  String duration;
  String? instructions;

  PrescriptionItem({
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.duration,
    this.instructions,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'duration': duration,
      'instructions': instructions,
    };
  }

  factory PrescriptionItem.fromMap(Map<String, dynamic> map) {
    return PrescriptionItem(
      name: map['name'] as String,
      dosage: map['dosage'] as String,
      frequency: map['frequency'] as String,
      duration: map['duration'] as String,
      instructions: map['instructions'] as String?,
    );
  }
}

/// Doctor availability time slots.
class DoctorAvailability {
  final String dayOfWeek; // Monday, Tuesday, etc.
  final String startTime;
  final String endTime;
  final int slotDurationMinutes;

  DoctorAvailability({
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.slotDurationMinutes = 30,
  });

  Map<String, dynamic> toMap() {
    return {
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'endTime': endTime,
      'slotDurationMinutes': slotDurationMinutes,
    };
  }

  factory DoctorAvailability.fromMap(Map<String, dynamic> map) {
    return DoctorAvailability(
      dayOfWeek: map['dayOfWeek'] as String,
      startTime: map['startTime'] as String,
      endTime: map['endTime'] as String,
      slotDurationMinutes: map['slotDurationMinutes'] as int? ?? 30,
    );
  }
}

/// Doctor profile with specialty and availability info.
class DoctorProfile {
  final String id;
  String name;
  String? username;
  String? specialty;
  String? phone;
  String? email;
  String? bio;
  String? profilePicture;
  List<DoctorAvailability> availability;

  DoctorProfile({
    required this.id,
    required this.name,
    this.username,
    this.specialty,
    this.phone,
    this.email,
    this.bio,
    this.profilePicture,
    this.availability = const [],
  });

  DoctorProfile copyWith({
    String? name,
    String? username,
    String? specialty,
    String? phone,
    String? email,
    String? bio,
    String? profilePicture,
    List<DoctorAvailability>? availability,
  }) {
    return DoctorProfile(
      id: id,
      name: name ?? this.name,
      username: username ?? this.username,
      specialty: specialty ?? this.specialty,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      bio: bio ?? this.bio,
      profilePicture: profilePicture ?? this.profilePicture,
      availability: availability ?? this.availability,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'specialty': specialty,
      'phone': phone,
      'email': email,
      'bio': bio,
      'profilePicture': profilePicture,
      'availability': availability.map((a) => a.toMap()).toList(),
    };
  }

  factory DoctorProfile.fromMap(Map<String, dynamic> map) {
    return DoctorProfile(
      id: map['id'] as String,
      name: map['name'] as String,
      username: map['username'] as String?,
      specialty: map['specialty'] as String?,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      bio: map['bio'] as String?,
      profilePicture: map['profilePicture'] as String?,
      availability:
          (map['availability'] as List?)
              ?.map(
                (a) => DoctorAvailability.fromMap(a as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }
}

/// Admin notification entry.
class AdminNotification {
  final String id;
  final String type; // 'new_appointment', 'cancellation', 'message'
  final String title;
  final String body;
  final DateTime timestamp;
  bool isRead;
  final String? referenceId;

  AdminNotification({
    String? id,
    required this.type,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
    this.referenceId,
  }) : id = id ?? _uuid.v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'body': body,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'referenceId': referenceId,
    };
  }

  factory AdminNotification.fromMap(Map<String, dynamic> map) {
    final ts = map['timestamp'];
    DateTime parsedTimestamp;
    if (ts is Timestamp) {
      parsedTimestamp = ts.toDate();
    } else if (ts is String) {
      parsedTimestamp = DateTime.parse(ts);
    } else {
      parsedTimestamp = DateTime.now();
    }
    return AdminNotification(
      id: map['id'] as String,
      type: map['type'] as String,
      title: map['title'] as String,
      body: map['body'] as String,
      timestamp: parsedTimestamp,
      isRead: map['isRead'] as bool? ?? false,
      referenceId: map['referenceId'] as String?,
    );
  }
}

/// Common medical specialties for doctor registration.
const kSpecialties = [
  'General Medicine',
  'Cardiology',
  'Dermatology',
  'Dentistry',
  'Ophthalmology',
  'Orthopedics',
  'Pediatrics',
  'Neurology',
  'Psychiatry',
  'Gynecology',
  'ENT',
  'Urology',
  'Pulmonology',
  'Endocrinology',
  'Oncology',
];
