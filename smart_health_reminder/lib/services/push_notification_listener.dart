/// Listens to Firestore notification streams and fires local push
/// notifications — works without Firebase Cloud Functions.
library;

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;

class PushNotificationListener {
  static final PushNotificationListener _instance =
      PushNotificationListener._internal();
  factory PushNotificationListener() => _instance;
  PushNotificationListener._internal();

  final _db = FirebaseFirestore.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  StreamSubscription? _notifSub;
  StreamSubscription? _appointmentSub;

  /// Set of notification IDs we've already shown to avoid duplicates.
  final Set<String> _shownNotifIds = {};

  /// Notification channel for appointment push notifications.
  static const _channel = AndroidNotificationChannel(
    'appointment_push',
    'Appointment Updates',
    description: 'Real-time appointment status notifications',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  /// Start listening — call after the user is authenticated and data loaded.
  Future<void> startListening() async {
    if (kIsWeb) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Create the notification channel
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);

    // Pre-load existing notification IDs so we don't re-fire old ones
    await _preloadExistingIds(user.uid);

    // Listen for new notifications in user's adminNotifications subcollection
    _notifSub?.cancel();
    _notifSub = _db
        .collection('users')
        .doc(user.uid)
        .collection('adminNotifications')
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots()
        .listen(
          (snapshot) {
            for (final change in snapshot.docChanges) {
              if (change.type == DocumentChangeType.added) {
                final data = change.doc.data();
                if (data == null) continue;
                final id = data['id'] as String? ?? change.doc.id;

                // Skip if we've already shown this
                if (_shownNotifIds.contains(id)) continue;
                _shownNotifIds.add(id);

                final title = data['title'] as String? ?? 'Notification';
                final body = data['body'] as String? ?? '';

                _showLocalNotification(title, body, id);
              }
            }
          },
          onError: (e) {
            debugPrint('Notification listener error: $e');
          },
        );
  }

  /// Pre-load existing notification IDs so we only fire new ones.
  Future<void> _preloadExistingIds(String uid) async {
    try {
      final snapshot =
          await _db
              .collection('users')
              .doc(uid)
              .collection('adminNotifications')
              .orderBy('timestamp', descending: true)
              .limit(50)
              .get();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        _shownNotifIds.add(data['id'] as String? ?? doc.id);
      }
    } catch (e) {
      debugPrint('Pre-load notif IDs failed: $e');
    }
  }

  /// Show a local notification.
  void _showLocalNotification(String title, String body, String id) {
    _localNotifications.show(
      id: id.hashCode,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
        ),
      ),
    );
  }

  /// Stop all listeners (call on sign-out).
  void stopListening() {
    _notifSub?.cancel();
    _notifSub = null;
    _appointmentSub?.cancel();
    _appointmentSub = null;
    _shownNotifIds.clear();
  }
}
