import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings =
        InitializationSettings(android: androidInit);

    await _notifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
      },
    );

    tz.initializeTimeZones(); // 🔥 IMPORTANT
  }

  // 🔔 NORMAL REMINDER
  static Future<void> showReminder() async {
    await _notifications.show(
      id: 0,
      title: 'Medication Reminder 💊',
      body: 'Did you take your medicine?',
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'med_channel',
          'Medication',
          importance: Importance.max,
        ),
      ),
    );
  }

  // ⏰ DAILY SCHEDULE
  static Future<void> scheduleDaily(int hour, int minute) async {
    await _notifications.zonedSchedule(
      id: 0,
      title: 'Medication Reminder 💊',
      body: 'Time to take your medicine',
      scheduledDate: _nextInstance(hour, minute),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'med_channel',
          'Medication',
          importance: Importance.max,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static tz.TZDateTime _nextInstance(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);

    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }
}