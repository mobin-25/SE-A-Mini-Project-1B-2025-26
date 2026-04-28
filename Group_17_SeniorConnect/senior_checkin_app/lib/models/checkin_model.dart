class CheckInRecord {
  final String date; // "2026-03-27"
  final bool checkedIn;
  final DateTime? timestamp;
  final String? note;

  const CheckInRecord({
    required this.date,
    required this.checkedIn,
    this.timestamp,
    this.note,
  });

  Map<String, dynamic> toMap() => {
        'date': date,
        'checkedIn': checkedIn,
        'timestamp': timestamp?.toIso8601String(),
        'note': note,
      };

  factory CheckInRecord.fromMap(Map<String, dynamic> map) => CheckInRecord(
        date: map['date'] as String,
        checkedIn: map['checkedIn'] as bool? ?? false,
        timestamp: map['timestamp'] != null
            ? DateTime.tryParse(map['timestamp'] as String)
            : null,
        note: map['note'] as String?,
      );
}
