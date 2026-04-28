import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

/// Handles all local notification scheduling for the app.
/// Uses flutter_local_notifications v21 — ALL methods use named parameters.
class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const _channelId   = 'med_channel';
  static const _channelName = 'Medication Reminders';

  static Future<void> init() async {
    // 1. Initialize timezone database
    tz.initializeTimeZones();

    // 2. Set the device's local timezone robustly
    _setLocalTimezone();

    // 3. Android initialisation settings
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // 4. initialize() — v21 uses NAMED parameter `settings:`
    await _notifications.initialize(
      settings: const InitializationSettings(android: androidInit),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('🔔 Notification tapped: ${response.payload}');
      },
    );

    // 4. Create Android notification channels (required Android 8+)
    await _createChannel();
    await _createAlertChannel();

    // 6. Request POST_NOTIFICATIONS permission (required Android 13+)
    await requestNotificationsPermission();
  }

  /// Sets tz.local to the device's timezone.
  /// Tries multiple strategies to handle abbreviations like "IST" that are
  /// ambiguous in the tz database.
  static void _setLocalTimezone() {
    // Strategy 1: Try the raw timezone name (works for "America/New_York" etc.)
    final String tzName = DateTime.now().timeZoneName;
    debugPrint('📍 Device timezone name: $tzName');

    try {
      tz.setLocalLocation(tz.getLocation(tzName));
      debugPrint('✅ Timezone set via name: $tzName');
      return;
    } catch (_) {
      debugPrint('⚠️  Timezone name "$tzName" not found in tz db, using offset fallback');
    }

    // Strategy 2: Match by UTC offset (handles "IST", "CST" ambiguities)
    final int offsetMs = DateTime.now().timeZoneOffset.inMilliseconds;
    debugPrint('📍 Device UTC offset: ${DateTime.now().timeZoneOffset}');

    // Known common timezone mappings by offset for fallback
    const Map<int, String> offsetToTz = {
      19800000: 'Asia/Kolkata',       // IST +5:30
      -18000000: 'America/New_York',  // EST -5
      -21600000: 'America/Chicago',   // CST -6
      -25200000: 'America/Denver',    // MST -7
      -28800000: 'America/Los_Angeles', // PST -8
      0: 'Europe/London',             // GMT
      3600000: 'Europe/Paris',        // CET +1
      7200000: 'Europe/Athens',       // EET +2
      19800000 - 1800000: 'Asia/Karachi', // PKT +5
      28800000: 'Asia/Shanghai',      // CST +8
      32400000: 'Asia/Tokyo',         // JST +9
      36000000: 'Australia/Sydney',   // AEST +10
    };

    final knownTz = offsetToTz[offsetMs];
    if (knownTz != null) {
      try {
        tz.setLocalLocation(tz.getLocation(knownTz));
        debugPrint('✅ Timezone set via offset map: $knownTz (offset: $offsetMs ms)');
        return;
      } catch (_) {}
    }

    // Strategy 3: Scan all tz locations by offset
    try {
      final candidates = tz.timeZoneDatabase.locations.values
          .where((loc) => loc.currentTimeZone.offset == offsetMs)
          .toList();
      if (candidates.isNotEmpty) {
        tz.setLocalLocation(candidates.first);
        debugPrint('✅ Timezone set via scan: ${candidates.first.name}');
        return;
      }
    } catch (_) {}

    debugPrint('❌ Could not determine timezone, falling back to UTC');
  }

  /// Creates the Android notification channel (required Android 8+).
  static Future<void> _createChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Daily medication reminder alerts',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
    debugPrint('✅ Notification channel created: $_channelId');
  }

  /// Creates the Family Alerts notification channel.
  static Future<void> _createAlertChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'alert_channel',
      'Family Alerts',
      description: 'Alerts sent from the family section',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
    debugPrint('✅ Alert channel created: alert_channel');
  }

  /// Requests POST_NOTIFICATIONS permission on Android 13+.
  static Future<bool> requestNotificationsPermission() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return true;
    final granted = await androidPlugin.requestNotificationsPermission();
    debugPrint('🔔 Notification permission granted: $granted');
    return granted ?? false;
  }

  /// Checks if exact alarm permission is granted (Android 12+).
  /// Returns true if granted or not needed (< Android 12).
  static Future<bool> checkExactAlarmPermission() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return true;
    final canSchedule = await androidPlugin.canScheduleExactNotifications();
    debugPrint('⏰ Can schedule exact notifications: $canSchedule');
    return canSchedule ?? false;
  }

  /// Opens the system Alarms & Reminders settings page so user can grant
  /// exact alarm permission (required Android 12+).
  static Future<void> openExactAlarmSettings() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestExactAlarmsPermission();
  }

  // ─── Shared notification details ──────────────────────────────────────
  static const NotificationDetails _details = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Daily medication reminder alerts',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    ),
  );

  // 🔔 Show an INSTANT notification (good for testing)
  static Future<void> showReminder() async {
    debugPrint('🔔 Showing instant notification...');
    await _notifications.show(
      id: 0,
      title: 'Medication Reminder 💊',
      body: 'Did you take your medicine?',
      notificationDetails: _details,
    );
  }

  // 🚨 Show a custom alert notification (used by Family → Send Alert)
  static Future<void> showCustomAlert({
    required String title,
    required String body,
  }) async {
    debugPrint('🚨 Firing custom alert: $title — $body');
    await _notifications.show(
      id: 1,   // different id from medication reminder
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'alert_channel',
          'Family Alerts',
          channelDescription: 'Alerts sent from the family section',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          enableVibration: true,
          playSound: true,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFFE74C3C),
        ),
      ),
    );
  }

  // ⏰ Schedule a daily repeating notification at [hour]:[minute]
  static Future<void> scheduleDaily(int hour, int minute) async {
    // First check if exact alarm permission is granted
    final hasExactAlarm = await checkExactAlarmPermission();
    if (!hasExactAlarm) {
      debugPrint('⚠️  No exact alarm permission — requesting...');
      await openExactAlarmSettings();
      return;
    }

    // Cancel previous medication reminder
    await _notifications.cancel(id: 0);

    final scheduled = _nextInstance(hour, minute);
    debugPrint('⏰ Scheduling daily reminder at $hour:$minute');
    debugPrint('   → Next fire time: $scheduled (local: ${DateTime.now()})');
    debugPrint('   → tz.local = ${tz.local.name}');

    await _notifications.zonedSchedule(
      id: 0,
      title: 'Medication Reminder 💊',
      body: 'Time to take your medicine. Tap to confirm.',
      scheduledDate: scheduled,
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
    debugPrint('✅ Reminder scheduled successfully');
  }

  /// Cancel the daily medication reminder.
  static Future<void> cancelReminder() async {
    await _notifications.cancel(id: 0);
    debugPrint('🗑 Reminder cancelled');
  }

  static tz.TZDateTime _nextInstance(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, hour, minute);

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}