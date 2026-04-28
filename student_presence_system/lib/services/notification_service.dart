import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

// ✅ Conditional import: web vs mobile
import 'notification_service_web.dart'
if (dart.library.io) 'notification_service_stub.dart' as web_notify;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'general_notifications',
    'General Notifications',
    description: 'App notifications',
    importance: Importance.high,
  );

  /// INITIALIZE NOTIFICATIONS
  static Future<String?> initialize() async {
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (kIsWeb) {
      // 🌐 Request browser notification permission
      await web_notify.requestWebPermission();
    } else {
      const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings =
      DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(settings);

      await _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      await _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);
    }

    // Foreground Firebase push handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        final title = message.notification!.title ?? "Notification";
        final body = message.notification!.body ?? "";
        if (kIsWeb) {
          web_notify.showWebNotification(title: title, body: body);
        } else {
          showNotification(title: title, body: body);
        }
      }
    });

    try {
      String? token = await _fcm.getToken();
      debugPrint('📱 FCM Token: $token');
      return token;
    } catch (e) {
      debugPrint("⚠️ Could not get FCM token: $e");
      return null;
    }
  }

  /// CHECK ATTENDANCE & NOTIFY
  static Future<void> checkAttendanceAndNotify(
      String studentId,
      String rollNo,
      ) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('attendance')
          .where('roll_no', isEqualTo: rollNo)
          .get();

      if (snapshot.docs.isEmpty) {
        debugPrint('ℹ️ No attendance records found for roll_no: $rollNo');
        // Still send a welcome notification if no records
        await _showAttendanceNotification(
            'Welcome!',
            'You currently have no attendance records logged.'
        );
        return;
      }

      int total = snapshot.docs.length;
      int present = snapshot.docs
          .where((doc) => (doc.data() as Map)['status'] == 'Present')
          .length;

      double percentage = (present / total) * 100;
      debugPrint('📊 Attendance: $present/$total (${percentage.toStringAsFixed(1)}%)');

      // 🔥 ALWAYS send a notification upon login
      String title = percentage < 75 ? '⚠️ Low Attendance Alert!' : '📊 Attendance Status';
      String body = 'Your overall attendance is ${percentage.toStringAsFixed(1)}% ($present/$total).';
      if (percentage < 75) {
        body += ' Please maintain a minimum of 75%.';
      } else {
        body += ' Great job keeping it up!';
      }

      await _showAttendanceNotification(title, body);
    } catch (e) {
      debugPrint('❌ Error checking attendance: $e');
    }
  }

  /// SHOW ATTENDANCE NOTIFICATION
  static Future<void> _showAttendanceNotification(String title, String body) async {
    if (kIsWeb) {
      // ✅ Use browser Notification API
      web_notify.showWebNotification(title: title, body: body);
      return;
    }

    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'attendance_alerts',
      'Attendance Alerts',
      channelDescription: 'Attendance status notifications',
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(''),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(0, title, body, details);
    debugPrint('🔔 Low attendance notification sent!');
  }

  /// MANUAL / FOREGROUND PUSH NOTIFICATION
  static Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    if (kIsWeb) {
      web_notify.showWebNotification(title: title, body: body);
      return;
    }

    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'general_notifications',
      'General Notifications',
      channelDescription: 'General app notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _notifications.show(
      DateTime.now().millisecond,
      title,
      body,
      details,
    );
  }
}