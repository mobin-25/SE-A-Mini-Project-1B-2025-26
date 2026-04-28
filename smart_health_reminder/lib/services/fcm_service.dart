/// Firebase Cloud Messaging service — handles FCM token management,
/// foreground notification display, and background message handling.
library;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;

/// Top-level background message handler (must be a top-level function).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialized by the time this runs.
  debugPrint('FCM background message: ${message.messageId}');
}

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Android notification channel for FCM push notifications.
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'appointment_notifications',
    'Appointment Notifications',
    description: 'Push notifications for appointment updates',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  /// Initialize FCM: request permission, save token, listen for messages.
  Future<void> init() async {
    if (kIsWeb) return;

    // Request notification permission
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint('FCM permission: ${settings.authorizationStatus}');

    // Register the background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Create the Android notification channel
    final localNotifications = FlutterLocalNotificationsPlugin();
    await localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);

    // Tell FCM to show foreground notifications on iOS
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Listen for foreground messages and display them as local notifications
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Save the FCM token to Firestore
    await saveTokenToFirestore();

    // Listen for token refreshes
    _messaging.onTokenRefresh.listen((newToken) {
      _saveToken(newToken);
    });
  }

  /// Get the current FCM token and save it to Firestore.
  Future<void> saveTokenToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final token = await _messaging.getToken();
    if (token != null) {
      await _saveToken(token);
    }
  }

  /// Write the FCM token to the user's document in Firestore.
  Future<void> _saveToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await _db.collection('users').doc(user.uid).set({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('FCM token save failed: $e');
    }
  }

  /// Remove the FCM token on sign-out so the user stops receiving pushes.
  Future<void> clearToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await _db.collection('users').doc(user.uid).update({
        'fcmToken': FieldValue.delete(),
      });
    } catch (_) {}
  }

  /// Display a foreground FCM message as a local notification.
  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    final localNotifications = FlutterLocalNotificationsPlugin();
    localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }
}
