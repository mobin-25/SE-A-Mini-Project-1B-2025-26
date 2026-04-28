// lib/services/notification_service.dart
//
// Setup steps:
// 1. Add to pubspec.yaml:
//    flutter_local_notifications: ^17.2.2
//    timezone: ^0.9.4
//    workmanager: ^0.5.2  (for background tasks on mobile)
//
// 2. Android setup (android/app/src/main/AndroidManifest.xml) — inside <manifest>:
//    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
//    <uses-permission android:name="android.permission.VIBRATE"/>
//    <uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
//    <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
//    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
//
//    Inside <application>:
//    <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver"/>
//    <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
//      <intent-filter>
//        <action android:name="android.intent.action.BOOT_COMPLETED"/>
//        <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
//      </intent-filter>
//    </receiver>
//
// 3. iOS — add to ios/Runner/AppDelegate.swift:
//    UNUserNotificationCenter.current().delegate = self
//    And request permission on first launch.

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'dart:ui';

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    if (kIsWeb) { _initialized = true; return; } // not supported on web

    tz.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap
      },
    );

    // Request permissions
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  /// Schedule a daily notification at a specific time
  Future<void> scheduleDailyReminder({
    required int id,
    required String medicineName,
    required String time, // "HH:mm" format
    bool withFood = false,
  }) async {
    if (kIsWeb) return;
    await initialize();

    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final body = withFood
        ? 'Time to take $medicineName 🍽️ (Take with food)'
        : 'Time to take $medicineName 💊';

    await _plugin.zonedSchedule(
      id,
      '💊 Medicine Reminder',
      body,
      scheduled,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'medicine_reminders',
          'Medicine Reminders',
          channelDescription: 'Daily reminders to take your medicine',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF1A6B5A),
          playSound: true,
          enableVibration: true,
          styleInformation: BigTextStyleInformation(body),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Show a low stock alert immediately
  Future<void> showLowStockAlert({
    required String medicineName,
    required int remaining,
  }) async {
    if (kIsWeb) return;
    await initialize();

    await _plugin.show(
      medicineName.hashCode,
      '⚠️ Low Medicine Stock',
      '$medicineName is running low — only $remaining tablets left! Time to refill.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'low_stock_alerts',
          'Low Stock Alerts',
          channelDescription: 'Alerts when medicine stock is low',
          importance: Importance.high,
          priority: Priority.high,
          color: const Color(0xFFFF9800),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  /// Show expiry alert
  Future<void> showExpiryAlert({
    required String medicineName,
    required String expiryDate,
  }) async {
    if (kIsWeb) return;
    await initialize();

    await _plugin.show(
      ('exp_$medicineName').hashCode,
      '🗓️ Medicine Expiring Soon',
      '$medicineName expires on $expiryDate. Please replace it.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'expiry_alerts',
          'Expiry Alerts',
          channelDescription: 'Alerts when medicine is near expiry',
          importance: Importance.high,
          priority: Priority.high,
          color: const Color(0xFFF44336),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  /// Cancel a specific reminder
  Future<void> cancelReminder(int id) async {
    await _plugin.cancel(id);
  }

  /// Cancel all reminders
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
