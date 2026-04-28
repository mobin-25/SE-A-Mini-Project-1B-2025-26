/// Firestore-backed repository for daily check-ins.
library;

import '../models/models.dart';
import '../services/firestore_service.dart';

class CheckInRepository {
  final FirestoreService _firestore = FirestoreService();

  List<DailyCheckIn> _checkIns = [];

  /// Load all check-ins from Firestore.
  Future<void> loadAll() async {
    final snapshot = await _firestore.checkInsCollection.get();
    _checkIns =
        snapshot.docs.map((doc) => DailyCheckIn.fromMap(doc.data())).toList();
  }

  List<DailyCheckIn> getAll() => List.unmodifiable(_checkIns);

  /// Get today's check-in, if any.
  DailyCheckIn? getToday() {
    final now = DateTime.now();
    try {
      return _checkIns.firstWhere(
        (c) =>
            c.date.year == now.year &&
            c.date.month == now.month &&
            c.date.day == now.day,
      );
    } catch (_) {
      return null;
    }
  }

  /// Save or update today's mood.
  Future<void> saveMood(int mood, {String? note}) async {
    final today = getToday();
    if (today != null) {
      today.mood = mood;
      today.note = note;
      await _firestore.checkInsCollection.doc(today.id).update(today.toMap());
    } else {
      final checkIn = DailyCheckIn(
        date: DateTime.now(),
        mood: mood,
        note: note,
      );
      await _firestore.checkInsCollection.doc(checkIn.id).set(checkIn.toMap());
      _checkIns.add(checkIn);
    }
  }
}
