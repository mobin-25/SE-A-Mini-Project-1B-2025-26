import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class MedicationNotificationService {
  static final FlutterLocalNotificationsPlugin notifications =
      FlutterLocalNotificationsPlugin();

  static Future init() async {
    const AndroidInitializationSettings android =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings =
        InitializationSettings(android: android);

    await notifications.initialize(settings);
  }

  static Future showReminder() async {
    await notifications.show(
      0,
      "Medication Reminder 💊",
      "Did you take your medicine?",
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'med_channel',
          'Medication',
          importance: Importance.max,
        ),
      ),
    );
  }
}