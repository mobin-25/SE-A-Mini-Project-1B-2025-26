import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../db/database_helper.dart';
import '../models/dosage_schedule.dart';

class ReminderService {
  static final ReminderService instance = ReminderService._internal();
  ReminderService._internal();

  final _db = DatabaseHelper.instance;
  final _notifications = FlutterLocalNotificationsPlugin();
  Timer? _timer;

  // ── Init notifications ────────────────────────────────────────────────────
  Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _notifications.initialize(settings);
    _startPeriodicCheck();
  }

  // ── Check every minute ────────────────────────────────────────────────────
  void _startPeriodicCheck() {
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => checkDoses());
  }

  Future<void> checkDoses() async {
    final now = DateTime.now();
    final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final rows = await _db.rawQuery('''
      SELECT ds.*, m.name AS medicine_name
      FROM dosage_schedule ds
      JOIN medicines m ON ds.medicine_id = m.medicine_id
      WHERE ds.status = 'pending'
    ''');

    for (final row in rows) {
      final schedule = DosageSchedule.fromMap(row);
      final medicineName = row['medicine_name'] as String;

      if (schedule.time == currentTime) {
        await _sendNotification(
          schedule.id!,
          'Time for ${medicineName}!',
          'Scheduled at ${schedule.time}',
        );
      }
    }
  }

  // ── Mark dose as taken ────────────────────────────────────────────────────
  Future<void> markTaken(int scheduleId) async {
    await _db.update(
      'dosage_schedule',
      {'status': 'taken'},
      'schedule_id = ?',
      [scheduleId],
    );
  }

  // ── Mark dose as missed + increment counter ───────────────────────────────
  Future<void> markMissed(int scheduleId) async {
    final rows = await _db.rawQuery(
      'SELECT missed_count FROM dosage_schedule WHERE schedule_id = ?',
      [scheduleId],
    );
    if (rows.isEmpty) return;

    final missedCount = (rows.first['missed_count'] as int) + 1;
    await _db.update(
      'dosage_schedule',
      {'status': 'missed', 'missed_count': missedCount},
      'schedule_id = ?',
      [scheduleId],
    );

    // Trigger alert if missed 2+ times
    if (missedCount >= 2) {
      await _sendNotification(
        scheduleId + 1000,
        '⚠️ Missed Dose Alert',
        'You have missed this dose $missedCount times. Please consult your doctor.',
      );
    }
  }

  // ── Add a new schedule ────────────────────────────────────────────────────
  Future<int> addSchedule(DosageSchedule schedule) async {
    return await _db.insert('dosage_schedule', schedule.toMap());
  }

  // ── Get all schedules for a user ──────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getSchedulesForUser(int userId) async {
    return await _db.rawQuery('''
      SELECT ds.*, m.name AS medicine_name
      FROM dosage_schedule ds
      JOIN medicines m ON ds.medicine_id = m.medicine_id
      WHERE ds.user_id = ?
      ORDER BY ds.time ASC
    ''', [userId]);
  }

  Future<void> _sendNotification(int id, String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'medly_channel',
      'Dosage Reminders',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);
    await _notifications.show(id, title, body, details);
  }

  void dispose() => _timer?.cancel();
}