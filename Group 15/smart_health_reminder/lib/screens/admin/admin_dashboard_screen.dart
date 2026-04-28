// Admin Dashboard — overview with stats, pending appointments, and quick actions.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../providers/admin_providers.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/nebula_background.dart';
import 'admin_notifications_screen.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsAsync = ref.watch(adminAppointmentsStreamProvider);

    return NebulaBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: appointmentsAsync.when(
            data: (appointments) => _buildDashboard(context, ref, appointments),
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
      ),
    );
  }

  Widget _buildDashboard(
    BuildContext context,
    WidgetRef ref,
    List appointments,
  ) {
    final pending = appointments.where((a) => a.status == 'pending').length;
    final accepted = appointments.where((a) => a.status == 'accepted').length;
    final total = appointments.length;
    final todayAppts =
        appointments.where((a) {
          final now = DateTime.now();
          return a.dateTime.year == now.year &&
              a.dateTime.month == now.month &&
              a.dateTime.day == now.day;
        }).toList();

    final doctorProfile = ref.watch(doctorProfileProvider);
    final greeting = _getGreeting();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.accentGradient,
                  boxShadow: AppTheme.glow(AppTheme.electricBlue, blur: 16),
                ),
                child: const Icon(
                  Icons.medical_services_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Dr. ${doctorProfile?.name ?? 'Doctor'}',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              // Notification bell with badge
              _NotificationBell(ref: ref),
            ],
          ),
          const SizedBox(height: 24),

          // Stats Row
          Row(
            children: [
              _StatCard(
                label: 'Pending',
                value: '$pending',
                color: AppTheme.vividOrange,
                icon: Icons.pending_actions_rounded,
              ),
              const SizedBox(width: 12),
              _StatCard(
                label: 'Accepted',
                value: '$accepted',
                color: AppTheme.neonGreen,
                icon: Icons.check_circle_outline_rounded,
              ),
              const SizedBox(width: 12),
              _StatCard(
                label: 'Total',
                value: '$total',
                color: AppTheme.electricBlue,
                icon: Icons.calendar_month_rounded,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Today's Appointments
          const Text(
            "Today's Appointments",
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          if (todayAppts.isEmpty)
            GlassCard(
              child: const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'No appointments scheduled for today',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
              ),
            )
          else
            ...todayAppts.map((a) => _AppointmentTile(appointment: a)),

          const SizedBox(height: 24),

          // Pending Actions
          if (pending > 0) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.vividOrange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.notification_important_rounded,
                    color: AppTheme.vividOrange,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$pending Pending Appointment${pending > 1 ? 's' : ''}',
                  style: const TextStyle(
                    color: AppTheme.vividOrange,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...appointments
                .where((a) => a.status == 'pending')
                .take(3)
                .map((a) => _PendingCard(appointment: a, ref: ref)),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        borderColor: color.withValues(alpha: 0.3),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppointmentTile extends StatelessWidget {
  final dynamic appointment;
  const _AppointmentTile({required this.appointment});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(appointment.status);
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 44,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(2),
              boxShadow: AppTheme.glow(statusColor, blur: 8),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.patientName ?? 'Patient',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('hh:mm a').format(appointment.dateTime),
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withValues(alpha: 0.4)),
            ),
            child: Text(
              appointment.status.toString().toUpperCase(),
              style: TextStyle(
                color: statusColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return AppTheme.vividOrange;
      case 'accepted':
        return AppTheme.neonGreen;
      case 'declined':
      case 'cancelled':
        return AppTheme.radiantPink;
      default:
        return AppTheme.electricBlue;
    }
  }
}

class _PendingCard extends StatelessWidget {
  final dynamic appointment;
  final WidgetRef ref;

  const _PendingCard({required this.appointment, required this.ref});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      borderColor: AppTheme.vividOrange.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.person_rounded,
                color: AppTheme.electricBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                appointment.patientName ?? 'Unknown Patient',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                color: AppTheme.textSecondary,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                DateFormat(
                  'MMM dd, yyyy – hh:mm a',
                ).format(appointment.dateTime),
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          if (appointment.notes != null && appointment.notes!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              appointment.notes!,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: 'Accept',
                  color: AppTheme.neonGreen,
                  icon: Icons.check_rounded,
                  onTap:
                      () => ref
                          .read(adminAppointmentsProvider.notifier)
                          .acceptAppointment(appointment.id),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  label: 'Decline',
                  color: AppTheme.radiantPink,
                  icon: Icons.close_rounded,
                  onTap: () => _showDeclineDialog(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDeclineDialog(BuildContext context) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: AppTheme.bgSecondary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppTheme.glassBorder),
            ),
            title: const Text(
              'Decline Appointment',
              style: TextStyle(color: AppTheme.textPrimary),
            ),
            content: TextField(
              controller: reasonCtrl,
              style: const TextStyle(color: AppTheme.textPrimary),
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Reason for declining (optional)',
                hintStyle: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
              TextButton(
                onPressed: () {
                  ref
                      .read(adminAppointmentsProvider.notifier)
                      .declineAppointment(
                        appointment.id,
                        reason:
                            reasonCtrl.text.isNotEmpty ? reasonCtrl.text : null,
                      );
                  Navigator.pop(ctx);
                },
                child: const Text(
                  'Decline',
                  style: TextStyle(color: AppTheme.radiantPink),
                ),
              ),
            ],
          ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  final WidgetRef ref;
  const _NotificationBell({required this.ref});

  @override
  Widget build(BuildContext context) {
    final notifAsync = ref.watch(adminNotificationsStreamProvider);
    final unreadCount = notifAsync.when(
      data: (list) => list.where((n) => !n.isRead).length,
      loading: () => 0,
      error: (_, __) => 0,
    );

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminNotificationsScreen()),
        );
      },
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.glassWhite,
              border: Border.all(color: AppTheme.glassBorder),
            ),
            child: const Icon(
              Icons.notifications_rounded,
              color: AppTheme.textPrimary,
              size: 24,
            ),
          ),
          if (unreadCount > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.radiantPink,
                ),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                child: Text(
                  '$unreadCount',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
