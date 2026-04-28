import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart';

/// Service for admin-only operations.
/// Admin is identified by email: 24107019@apsit.edu.in
class AdminService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String adminEmail = '24107019@apsit.edu.in';

  static bool isAdmin(String? email) => email == adminEmail;

  /// Send a notification (alert) to all users. Admin-only.
  /// Also fires a local push notification on the admin's device.
  static Future<void> sendAlert({
    required String title,
    required String body,
    String type = 'info', // 'info', 'warning', 'critical'
  }) async {
    await _db.collection('alerts').add({
      'title': title,
      'body': body,
      'type': type,
      'sentAt': FieldValue.serverTimestamp(),
      'sentBy': adminEmail,
    });
    // Show a local notification on the admin's device confirming dispatch
    await NotificationService.showLocalNotification(
      title: '📢 Alert Sent',
      body: '"$title" has been broadcasted to all users.',
      id: title.hashCode,
    );
  }

  /// Real-time stream of all alerts (newest first).
  static Stream<List<Map<String, dynamic>>> alertsStream() {
    return _db
        .collection('alerts')
        .orderBy('sentAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = d.data();
              data['id'] = d.id;
              return data;
            }).toList());
  }

  /// Delete an alert by ID.
  static Future<void> deleteAlert(String id) =>
      _db.collection('alerts').doc(id).delete();
}
