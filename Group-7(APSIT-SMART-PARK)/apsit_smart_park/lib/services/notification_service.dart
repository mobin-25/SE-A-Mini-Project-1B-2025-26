import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Top-level handler required by FCM for background messages.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM background message: ${message.notification?.title}');
}

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static const _channel = AndroidNotificationChannel(
    'apsit_park_channel',
    'APSIT Smart Park',
    description: 'Slot booking and campus alerts',
    importance: Importance.high,
  );

  /// Call once in main() after Firebase.initializeApp().
  static Future<void> initialize() async {
    // ── FCM setup ───────────────────────────────────────────────────────────
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final token = await _messaging.getToken();
    debugPrint('FCM Token: $token');

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final n = message.notification;
      if (n != null) {
        showLocalNotification(
          title: n.title ?? 'APSIT Smart Park',
          body: n.body ?? '',
        );
      }
    });

    // ── Local notifications setup ────────────────────────────────────────────
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _local.initialize(initSettings);

    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  /// Show an immediate local notification on the device.
  static Future<void> showLocalNotification({
    required String title,
    required String body,
    int id = 0,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    final details = NotificationDetails(android: androidDetails);
    await _local.show(id, title, body, details);
  }

  /// Notify the current user that their slot was booked.
  static Future<void> notifySlotBooked(String slotId) async {
    await showLocalNotification(
      title: '🅿️ Slot Reserved!',
      body: 'Slot $slotId has been successfully reserved for you.',
      id: slotId.hashCode,
    );
  }

  /// Get the current device FCM token.
  static Future<String?> getToken() => _messaging.getToken();
}
