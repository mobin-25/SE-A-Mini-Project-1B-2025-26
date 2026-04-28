import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static RealtimeChannel? _channel;

  static const String _channelId = 'wildlife_alerts';
  static const String _channelName = 'Wildlife Alerts';
  static const String _channelDesc =
      'Notifications for new wildlife alerts';

  // ── Initialise plugin ─────────────────────────────────────────────────────
  static Future<void> initialize() async {
    if (_initialized) return;

    const androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings =
        InitializationSettings(android: androidInit, iOS: darwinInit);

    await _plugin.initialize(initSettings);

    // Create Android notification channel (no-op on iOS).
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Request permission on Android 13+.
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  // ── Listen for new alerts from OTHER users ────────────────────────────────
  static void startListening(String currentUserId) {
    stopListening();

    _channel = Supabase.instance.client
        .channel('public:alerts:inserts')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'alerts',
          callback: (payload) {
            final record = payload.newRecord;
            final insertedBy = record['user_id']?.toString() ?? '';
            if (insertedBy == currentUserId) return;

            final message =
                record['message']?.toString() ?? 'Wild animal sighted!';
            showNotification(
              title: 'New Wildlife Alert',
              body: message,
            );
          },
        )
        .subscribe();
  }

  static void stopListening() {
    _channel?.unsubscribe();
    _channel = null;
  }

  // ── Fire a local notification ─────────────────────────────────────────────
  static Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    if (!_initialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
    );
  }
}