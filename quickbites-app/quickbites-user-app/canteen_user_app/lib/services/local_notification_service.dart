import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

typedef NotificationTapHandler = Future<void> Function(
  OrderNotificationPayload payload,
);

class OrderNotificationPayload {
  final int? orderId;
  final String status;

  const OrderNotificationPayload({
    required this.orderId,
    required this.status,
  });

  String get normalizedStatus => status.trim().toUpperCase();

  String toRawPayload() {
    return jsonEncode({
      'orderId': orderId,
      'status': normalizedStatus,
    });
  }

  static OrderNotificationPayload? tryParse(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    final rawStatus = decoded['status']?.toString();
    if (rawStatus == null || rawStatus.trim().isEmpty) {
      return null;
    }

    final rawOrderId = decoded['orderId'];
    final parsedOrderId = rawOrderId == null
        ? null
        : int.tryParse(rawOrderId.toString());

    return OrderNotificationPayload(
      orderId: parsedOrderId,
      status: rawStatus,
    );
  }
}

class LocalNotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  String? _lastHandledTapPayload;
  NotificationTapHandler? _onNotificationTap;
  final Map<int, String> _lastNotifiedStatusByOrderId = {};

  static const AndroidNotificationChannel _ordersChannel =
      AndroidNotificationChannel(
    'order_updates_channel',
    'Order Updates',
    description: 'Notifications for live order status changes',
    importance: Importance.high,
  );

  Future<void> initialize({NotificationTapHandler? onNotificationTap}) async {
    if (onNotificationTap != null) {
      _onNotificationTap = onNotificationTap;
    }

    if (_initialized) return;

    const androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidInit);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        _handleNotificationTap(response.payload);
      },
    );

    final androidPlugin = _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_ordersChannel);

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    final launchPayload = launchDetails?.notificationResponse?.payload;
    await _handleNotificationTap(launchPayload);

    _initialized = true;
  }

  Future<void> _handleNotificationTap(String? rawPayload) async {
    if (rawPayload == null || rawPayload.trim().isEmpty) return;
    if (_lastHandledTapPayload == rawPayload) return;

    final parsed = OrderNotificationPayload.tryParse(rawPayload);
    if (parsed == null) return;

    _lastHandledTapPayload = rawPayload;
    await _onNotificationTap?.call(parsed);
  }

  Future<void> requestPermissionIfNeeded() async {
    final androidPlugin = _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
  }

  Future<bool> ensurePermission() async {
    final androidPlugin = _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    final enabledBeforeRequest = await androidPlugin?.areNotificationsEnabled();
    if (enabledBeforeRequest == true) {
      return true;
    }

    await androidPlugin?.requestNotificationsPermission();
    final enabledAfterRequest = await androidPlugin?.areNotificationsEnabled();
    return enabledAfterRequest ?? false;
  }

  Future<bool> showOrderStatusUpdate({
    required int? orderId,
    required String status,
  }) async {
    await initialize();
    final permitted = await ensurePermission();
    if (!permitted) return false;

    final normalizedStatus = status.trim().toUpperCase();
    final id = orderId;

    if (id != null) {
      final last = _lastNotifiedStatusByOrderId[id];
      if (last == normalizedStatus) return false;
      _lastNotifiedStatusByOrderId[id] = normalizedStatus;
    }

    final title = _buildTitle(id, normalizedStatus);
    final body = _buildBody(id, normalizedStatus);
    final ticker = _buildTicker(normalizedStatus);
    final payload = OrderNotificationPayload(
      orderId: id,
      status: normalizedStatus,
    ).toRawPayload();

    final notificationId = DateTime.now().microsecondsSinceEpoch.remainder(2147483647);

    await _plugin.show(
      notificationId,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _ordersChannel.id,
          _ordersChannel.name,
          channelDescription: _ordersChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          ticker: ticker,
          category: AndroidNotificationCategory.status,
          playSound: true,
          enableVibration: true,
          autoCancel: true,
          visibility: NotificationVisibility.public,
          styleInformation: BigTextStyleInformation(
            body,
            contentTitle: title,
            summaryText: 'APSIT Canteen',
          ),
        ),
      ),
      payload: payload,
    );

    return true;
  }

  String _buildTitle(int? orderId, String normalizedStatus) {
    final prefix = orderId == null ? 'Your order' : 'Order #$orderId';

    switch (normalizedStatus) {
      case 'PENDING':
        return '📝 $prefix placed successfully';
      case 'IN_PROGRESS':
        return '👨‍🍳 $prefix is being prepared';
      case 'READY':
        return '✅ $prefix is ready for pickup';
      case 'DELIVERED':
        return '🎉 $prefix delivered';
      case 'CANCELLED':
        return '⚠️ $prefix was cancelled';
      default:
        return '🔔 $prefix status updated';
    }
  }

  String _buildBody(int? orderId, String normalizedStatus) {
    final orderRef = orderId == null ? 'your order' : 'order #$orderId';

    switch (normalizedStatus) {
      case 'PENDING':
        return 'We received $orderRef and it is now in queue.';
      case 'IN_PROGRESS':
        return 'Good news! Kitchen has started preparing $orderRef.';
      case 'READY':
        return 'Please head to the counter and show your QR to collect $orderRef.';
      case 'DELIVERED':
        return 'Enjoy your meal! $orderRef has been marked as delivered.';
      case 'CANCELLED':
        return 'We are sorry, $orderRef was cancelled. Please contact support if needed.';
      default:
        return '${normalizedStatus.replaceAll('_', ' ')} update received for $orderRef.';
    }
  }

  String _buildTicker(String normalizedStatus) {
    switch (normalizedStatus) {
      case 'READY':
        return 'Order ready';
      case 'IN_PROGRESS':
        return 'Order in progress';
      case 'PENDING':
        return 'Order placed';
      case 'DELIVERED':
        return 'Order delivered';
      case 'CANCELLED':
        return 'Order cancelled';
      default:
        return 'Order update';
    }
  }
}
