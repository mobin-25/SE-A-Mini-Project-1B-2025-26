import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/time_utils.dart';
import 'priority_badge.dart';
import 'status_chip.dart';

class AlertCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback? onTap;

  const AlertCard({super.key, required this.data, this.onTap});

  @override
  Widget build(BuildContext context) {
    final message = data['message']?.toString() ?? '';
    final priority = data['priority']?.toString() ?? 'Medium';
    final status = data['status']?.toString() ?? 'Open';
    final userEmail = data['user_email']?.toString() ?? 'Unknown';
    final createdAt = data['created_at']?.toString();
    final imageUrl = data['image_url']?.toString();

    final priorityColor = AppTheme.priorityColor(priority);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          gradient: AppTheme.cardGradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: priorityColor.withOpacity(0.25),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: priorityColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.crisis_alert,
                      color: priorityColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _shortEmail(userEmail),
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          TimeUtils.relative(createdAt),
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  StatusChip(status: status, small: true),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Text(
                message,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Row(
                children: [
                  PriorityBadge(priority: priority, small: true),
                  const Spacer(),
                  if (imageUrl != null) ...[
                    const Icon(
                      Icons.image_outlined,
                      size: 14,
                      color: AppTheme.textMuted,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Photo',
                      style: TextStyle(
                          color: AppTheme.textMuted, fontSize: 12),
                    ),
                    const SizedBox(width: 10),
                  ],
                  const Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: AppTheme.textMuted,
                  ),
                ],
              ),
            ),
            Container(
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    priorityColor.withOpacity(0.7),
                    priorityColor.withOpacity(0.1),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _shortEmail(String email) {
    if (email.length <= 28) return email;
    final parts = email.split('@');
    if (parts.length == 2) {
      final name = parts[0];
      return '${name.substring(0, name.length > 10 ? 10 : name.length)}…@${parts[1]}';
    }
    return '${email.substring(0, 25)}…';
  }
}