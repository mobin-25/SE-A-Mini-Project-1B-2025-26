class BookingModel {
  final String id;
  final String slotId;
  final String userId;
  final DateTime startTime;
  final String status; // 'active' | 'completed'
  final String duration; // '30 min', '1 Hour', '2 Hours', '4 Hours'

  const BookingModel({
    required this.id,
    required this.slotId,
    required this.userId,
    required this.startTime,
    required this.status,
    this.duration = '',
  });

  factory BookingModel.fromMap(String id, Map<String, dynamic> map) {
    return BookingModel(
      id: id,
      slotId: map['slotId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      startTime: (map['startTime'] != null)
          ? (map['startTime'] as dynamic).toDate()
          : DateTime.now(),
      status: map['status'] as String? ?? 'active',
      duration: map['duration'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'slotId': slotId,
        'userId': userId,
        'startTime': startTime,
        'status': status,
        'duration': duration,
      };
}
