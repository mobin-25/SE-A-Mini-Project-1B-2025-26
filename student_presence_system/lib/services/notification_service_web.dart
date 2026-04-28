// lib/services/notification_service_web.dart
import 'dart:js_interop';                  // ✅ needed for .toDart on JSPromise
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

/// Request browser notification permission
Future<void> requestWebPermission() async {
  try {
    final permission = web.Notification.permission;
    debugPrint('🌐 Current browser notification permission: $permission');

    if (permission != 'granted') {
      await web.Notification.requestPermission().toDart; // ✅ now works
      debugPrint('🌐 Permission dialog triggered');
    }
  } catch (e) {
    debugPrint('❌ Web permission error: $e');
  }
}

/// Show a native browser notification
void showWebNotification({required String title, required String body}) {
  try {
    final permission = web.Notification.permission;

    if (permission == 'granted') {
      web.Notification(
        title,
        web.NotificationOptions(
          body: body,
          icon: '/favicon.png',
        ),
      );
      debugPrint('🔔 Web notification shown: $title');
    } else {
      debugPrint('⚠️ Web notification permission not granted: $permission');
    }
  } catch (e) {
    debugPrint('❌ Web notification error: $e');
  }
}