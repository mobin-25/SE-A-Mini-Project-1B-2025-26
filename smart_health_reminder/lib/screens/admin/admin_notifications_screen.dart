// Admin Notifications — central view of all admin notifications.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';
import '../../providers/admin_providers.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/nebula_background.dart';
import '../../widgets/accent_bar.dart';

class AdminNotificationsScreen extends ConsumerWidget {
  const AdminNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifAsync = ref.watch(adminNotificationsStreamProvider);

    return NebulaBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    const Icon(
                      Icons.notifications_rounded,
                      color: AppTheme.vividOrange,
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Notifications',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        ref
                            .read(adminNotificationsProvider.notifier)
                            .markAllAsRead();
                      },
                      child: const Text(
                        'Mark all read',
                        style: TextStyle(
                          color: AppTheme.electricBlue,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: notifAsync.when(
                  data: (notifications) {
                    if (notifications.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.notifications_none_rounded,
                              color: AppTheme.textSecondary.withValues(
                                alpha: 0.5,
                              ),
                              size: 64,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'No notifications yet',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: notifications.length,
                      itemBuilder:
                          (_, i) => _NotificationTile(
                            notification: notifications[i],
                            onTap: () {
                              if (!notifications[i].isRead) {
                                ref
                                    .read(adminNotificationsProvider.notifier)
                                    .markAsRead(notifications[i].id);
                              }
                            },
                          ),
                    );
                  },
                  loading:
                      () => const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.electricBlue,
                        ),
                      ),
                  error:
                      (e, _) => Center(
                        child: Text(
                          'Error: $e',
                          style: const TextStyle(color: AppTheme.radiantPink),
                        ),
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AdminNotification notification;
  final VoidCallback onTap;

  const _NotificationTile({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    Color accentColor;
    IconData icon;
    switch (notification.type) {
      case 'appointment':
        accentColor = AppTheme.electricBlue;
        icon = Icons.calendar_today_rounded;
        break;
      case 'chat':
        accentColor = AppTheme.neonGreen;
        icon = Icons.chat_bubble_rounded;
        break;
      case 'prescription':
        accentColor = AppTheme.vividOrange;
        icon = Icons.receipt_long_rounded;
        break;
      default:
        accentColor = AppTheme.textSecondary;
        icon = Icons.notifications_rounded;
    }

    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        borderColor:
            notification.isRead ? null : accentColor.withValues(alpha: 0.3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AccentBar(color: accentColor, height: 42),
            const SizedBox(width: 12),
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor.withValues(alpha: 0.15),
              ),
              child: Icon(icon, color: accentColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight:
                          notification.isRead
                              ? FontWeight.w500
                              : FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notification.body,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTimestamp(notification.timestamp),
                    style: TextStyle(
                      color: AppTheme.textSecondary.withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM dd').format(dt);
  }
}
