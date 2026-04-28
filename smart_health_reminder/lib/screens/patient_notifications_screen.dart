/// Patient notifications screen — shows real-time notifications
/// (appointment accepted/declined/cancelled, etc.) from Firestore.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../providers/providers.dart';
import '../models/models.dart';
import '../widgets/nebula_background.dart';

class PatientNotificationsScreen extends ConsumerWidget {
  const PatientNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream = ref.watch(patientNotificationsStreamProvider);

    return NebulaBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Notifications'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: stream.when(
          loading:
              () => const Center(
                child: CircularProgressIndicator(color: AppTheme.electricBlue),
              ),
          error:
              (_, __) => const Center(
                child: Text(
                  'Unable to load notifications',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
          data: (notifications) {
            if (notifications.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.notifications_none_rounded,
                      size: 56,
                      color: AppTheme.textSecondary.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No notifications yet',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: notifications.length,
              itemBuilder:
                  (_, i) => _NotificationTile(notification: notifications[i]),
            );
          },
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AdminNotification notification;
  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;
    final timeStr = DateFormat('MMM d, h:mm a').format(notification.timestamp);

    Color accentColor;
    IconData icon;
    if (notification.title.toLowerCase().contains('accepted')) {
      accentColor = AppTheme.neonGreen;
      icon = Icons.check_circle_rounded;
    } else if (notification.title.toLowerCase().contains('declined')) {
      accentColor = AppTheme.radiantPink;
      icon = Icons.cancel_rounded;
    } else if (notification.title.toLowerCase().contains('cancelled')) {
      accentColor = AppTheme.vividOrange;
      icon = Icons.event_busy_rounded;
    } else if (notification.title.toLowerCase().contains('rescheduled')) {
      accentColor = AppTheme.electricBlue;
      icon = Icons.schedule_rounded;
    } else {
      accentColor = AppTheme.electricBlue;
      icon = Icons.notifications_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color:
            isUnread
                ? accentColor.withValues(alpha: 0.08)
                : const Color(0x18FFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color:
              isUnread
                  ? accentColor.withValues(alpha: 0.3)
                  : AppTheme.glassBorder,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: accentColor, size: 22),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: isUnread ? FontWeight.w700 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notification.body,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                timeStr,
                style: TextStyle(
                  color: AppTheme.textSecondary.withValues(alpha: 0.6),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        trailing:
            isUnread
                ? Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                    boxShadow: AppTheme.glow(accentColor, blur: 6),
                  ),
                )
                : null,
      ),
    );
  }
}
