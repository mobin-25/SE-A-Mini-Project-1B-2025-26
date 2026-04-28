import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _i = NotificationService._();
  factory NotificationService() => _i;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  int _id = 0;

  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios     = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
        const InitializationSettings(android: android, iOS: ios));
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> showFloodWarning(String username, int rate) async {
    await _plugin.show(
      _id++,
      '⚠️ Flood Detected',
      '$username is flooding the server at $rate pkt/s',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'flood_channel', 'Flood Alerts',
          channelDescription: 'Flood detection alerts',
          importance: Importance.high,
          priority: Priority.high,
          color: Colors.amber,
          enableVibration: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  Future<void> showAutoBlocked(String username, int rate, int threshold) async {
    await _plugin.show(
      _id++,
      '🔴 User Auto-Blocked',
      '$username blocked — $rate pkt/s exceeded $threshold limit',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'block_channel', 'Auto-Block Alerts',
          channelDescription: 'Auto-block alerts',
          importance: Importance.max,
          priority: Priority.max,
          color: Colors.red,
          enableVibration: true,
          fullScreenIntent: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.critical,
        ),
      ),
    );
  }
}