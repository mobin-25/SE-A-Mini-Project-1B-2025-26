import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

import '../models/models.dart';
import 'dart:async';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isIOS() => defaultTargetPlatform == TargetPlatform.iOS;

  Future<void> init() async {
    if (kIsWeb) return; // Notifications not supported on web
    // Initialize timezone
    tz.initializeTimeZones();

    // Android Initialization
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS Initialization
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        if (response.actionId == 'snooze') {
          // Re-fire the same notification in 10 minutes
          final snoozeTime = tz.TZDateTime.now(
            tz.local,
          ).add(const Duration(minutes: 10));
          await flutterLocalNotificationsPlugin.zonedSchedule(
            id: response.id ?? 0,
            title: response.payload ?? 'Reminder (snoozed)',
            body: 'Snoozed reminder — take action now!',
            scheduledDate: snoozeTime,
            notificationDetails: const NotificationDetails(
              android: AndroidNotificationDetails(
                'med_alarm_v2',
                'Medicine Alarms',
                channelDescription:
                    'Alarm-style notifications for medicine reminders',
                importance: Importance.max,
                priority: Priority.high,
                fullScreenIntent: true,
                ongoing: true,
                autoCancel: false,
                playSound: true,
                enableVibration: true,
                category: AndroidNotificationCategory.alarm,
                visibility: NotificationVisibility.public,
                audioAttributesUsage: AudioAttributesUsage.alarm,
                timeoutAfter: 120000,
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          );
        }
        // 'dismiss' action auto-cancels via cancelNotification: true
      },
    );
  }

  Future<void> requestPermissions() async {
    if (kIsWeb) return;
    if (!kIsWeb && _isIOS()) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } else if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
        await androidImplementation.requestExactAlarmsPermission();
      }
    }
  }

  Future<void> scheduleMedicineNotification({
    required Medicine medicine,
    required String userName,
    required String timeString,
  }) async {
    if (kIsWeb) return;
    // Determine a unique ID. We can hash the medicine ID + time string
    final int notificationId = (medicine.id + timeString).hashCode;

    // Parse the timeString (e.g., "8:00 AM" or "08:00")
    final now = DateTime.now();
    DateTime scheduleTime;

    try {
      // Attempt to parse simple AM/PM format manually as intl parsing isn't always robust without explicit format
      String timeToParse = timeString.trim().toUpperCase();
      int hour = 0;
      int minute = 0;

      if (timeToParse.contains('AM') || timeToParse.contains('PM')) {
        bool isPM = timeToParse.contains('PM');
        timeToParse =
            timeToParse.replaceAll('AM', '').replaceAll('PM', '').trim();
        var parts = timeToParse.split(':');
        hour = int.parse(parts[0]);
        minute = int.parse(parts[1]);
        if (isPM && hour < 12) hour += 12;
        if (!isPM && hour == 12) hour = 0;
      } else {
        var parts = timeToParse.split(':');
        hour = int.parse(parts[0]);
        minute = int.parse(parts[1]);
      }

      scheduleTime = DateTime(now.year, now.month, now.day, hour, minute);

      // If the time has already passed today, schedule for tomorrow
      if (scheduleTime.isBefore(now)) {
        scheduleTime = scheduleTime.add(const Duration(days: 1));
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error parsing time: $e');
      return;
    }

    final tz.TZDateTime tzScheduleTime = tz.TZDateTime.from(
      scheduleTime,
      tz.local,
    );

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'med_alarm_v2',
          'Medicine Alarms',
          channelDescription:
              'Alarm-style notifications for medicine reminders',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'Take your medicine!',
          fullScreenIntent: true,
          ongoing: true,
          autoCancel: false,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,
          audioAttributesUsage: AudioAttributesUsage.alarm,
          timeoutAfter: 120000, // auto-dismiss after 2 minutes
          actions: <AndroidNotificationAction>[
            AndroidNotificationAction(
              'dismiss',
              'Dismiss',
              showsUserInterface: true,
              cancelNotification: true,
            ),
            AndroidNotificationAction(
              'snooze',
              'Snooze 10 min',
              showsUserInterface: true,
            ),
          ],
        );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: DarwinNotificationDetails(
        presentSound: true,
        presentAlert: true,
        presentBanner: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: notificationId,
      title: 'Time for your ${medicine.name}, $userName!',
      body: 'Dosage: ${medicine.dosage}. Form: ${medicine.form}',
      payload: 'Time for your ${medicine.name}, $userName!',
      scheduledDate: tzScheduleTime,
      notificationDetails: platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents:
          DateTimeComponents.time, // Repeat at the same time every day
    );
  }

  Future<void> cancelMedicineNotifications(Medicine medicine) async {
    if (kIsWeb) return;
    for (String timeString in medicine.reminderTimes) {
      final int notificationId = (medicine.id + timeString).hashCode;
      await flutterLocalNotificationsPlugin.cancel(id: notificationId);
    }
  }

  /// Schedule a notification for an appointment (fires 30 minutes before).
  Future<void> scheduleAppointmentNotification({
    required Appointment appointment,
  }) async {
    if (kIsWeb) return;
    final notifyTime = appointment.dateTime.subtract(
      const Duration(minutes: 30),
    );
    if (notifyTime.isBefore(DateTime.now())) return; // Already past

    final int notificationId = ('appt_${appointment.id}').hashCode;
    final tz.TZDateTime tzScheduleTime = tz.TZDateTime.from(
      notifyTime,
      tz.local,
    );

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'appt_alarm_v2',
          'Appointment Alarms',
          channelDescription:
              'Alarm-style notifications for upcoming appointments',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'Appointment reminder!',
          fullScreenIntent: true,
          ongoing: true,
          autoCancel: false,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,
          audioAttributesUsage: AudioAttributesUsage.alarm,
          timeoutAfter: 120000, // auto-dismiss after 2 minutes
          actions: <AndroidNotificationAction>[
            AndroidNotificationAction(
              'dismiss',
              'Dismiss',
              showsUserInterface: true,
              cancelNotification: true,
            ),
            AndroidNotificationAction(
              'snooze',
              'Snooze 10 min',
              showsUserInterface: true,
            ),
          ],
        );
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentSound: true,
        presentAlert: true,
        presentBanner: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: notificationId,
      title: 'Appointment in 30 minutes!',
      body:
          '${appointment.doctorName} — ${appointment.specialty} at ${appointment.location}',
      payload:
          'Appointment: ${appointment.doctorName} — ${appointment.specialty}',
      scheduledDate: tzScheduleTime,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  /// Cancel notification for an appointment.
  Future<void> cancelAppointmentNotification(Appointment appointment) async {
    if (kIsWeb) return;
    final int notificationId = ('appt_${appointment.id}').hashCode;
    await flutterLocalNotificationsPlugin.cancel(id: notificationId);
  }
}
