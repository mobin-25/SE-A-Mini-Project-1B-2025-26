class DosageSchedule {
  final int? id;
  final int userId;
  final int medicineId;
  final String time; // HH:mm format
  final String status; // taken, missed, pending
  int missedCount;

  DosageSchedule({
    this.id,
    required this.userId,
    required this.medicineId,
    required this.time,
    this.status = 'pending',
    this.missedCount = 0,
  });

  Map<String, dynamic> toMap() => {
    'schedule_id': id,
    'user_id': userId,
    'medicine_id': medicineId,
    'time': time,
    'status': status,
    'missed_count': missedCount,
  };

  factory DosageSchedule.fromMap(Map<String, dynamic> map) => DosageSchedule(
    id: map['schedule_id'],
    userId: map['user_id'],
    medicineId: map['medicine_id'],
    time: map['time'],
    status: map['status'],
    missedCount: map['missed_count'] ?? 0,
  );
}