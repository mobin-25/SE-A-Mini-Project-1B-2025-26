/// Repository for admin/doctor notifications.
library;

import '../models/models.dart';
import '../services/firestore_service.dart';

class AdminNotificationsRepository {
  final FirestoreService _firestore = FirestoreService();

  List<AdminNotification> _notifications = [];

  /// Load all notifications for this doctor.
  Future<void> loadAll() async {
    final snapshot =
        await _firestore.adminNotificationsCollection
            .orderBy('timestamp', descending: true)
            .get();
    _notifications =
        snapshot.docs
            .map((doc) => AdminNotification.fromMap(doc.data()))
            .toList();
  }

  List<AdminNotification> getAll() => List.unmodifiable(_notifications);

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  /// Add a notification.
  Future<void> add(AdminNotification notification) async {
    await _firestore.adminNotificationsCollection
        .doc(notification.id)
        .set(notification.toMap());
    _notifications.insert(0, notification);
  }

  /// Mark a notification as read.
  Future<void> markAsRead(String id) async {
    await _firestore.adminNotificationsCollection.doc(id).update({
      'isRead': true,
    });
    final n = _notifications.firstWhere((n) => n.id == id);
    n.isRead = true;
  }

  /// Mark all as read.
  Future<void> markAllAsRead() async {
    final unread = _notifications.where((n) => !n.isRead).toList();
    for (final n in unread) {
      await _firestore.adminNotificationsCollection.doc(n.id).update({
        'isRead': true,
      });
      n.isRead = true;
    }
  }

  /// Stream notifications in real-time.
  Stream<List<AdminNotification>> watchNotifications() {
    return _firestore.adminNotificationsCollection
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          _notifications =
              snapshot.docs
                  .map((doc) => AdminNotification.fromMap(doc.data()))
                  .toList();
          return _notifications;
        });
  }
}
