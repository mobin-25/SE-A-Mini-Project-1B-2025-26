import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PriorityBadge extends StatelessWidget {
  final String priority;
  final bool small;

  const PriorityBadge({
    super.key,
    required this.priority,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.priorityColor(priority);
    final icon = _icon(priority);
    final fontSize = small ? 10.0 : 11.0;
    final pad = small
        ? const EdgeInsets.symmetric(horizontal: 7, vertical: 3)
        : const EdgeInsets.symmetric(horizontal: 9, vertical: 4);

    return Container(
      padding: pad,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: small ? 10 : 12, color: color),
          const SizedBox(width: 4),
          Text(
            priority,
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  IconData _icon(String p) {
    switch (p) {
      case 'Critical':
        return Icons.local_fire_department;
      case 'High':
        return Icons.arrow_upward;
      case 'Low':
        return Icons.arrow_downward;
      default:
        return Icons.remove;
    }
  }
}
