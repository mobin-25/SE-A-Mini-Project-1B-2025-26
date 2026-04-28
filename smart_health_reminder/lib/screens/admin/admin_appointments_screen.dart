// Admin Appointments — view, filter, accept/decline, reschedule, cancel.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../providers/admin_providers.dart';
import '../../models/models.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/nebula_background.dart';
import '../../widgets/accent_bar.dart';
import '../../repositories/chat_repository.dart';
import '../../services/firestore_service.dart';
import 'admin_chat_screen.dart';

class AdminAppointmentsScreen extends ConsumerStatefulWidget {
  const AdminAppointmentsScreen({super.key});
  @override
  ConsumerState<AdminAppointmentsScreen> createState() =>
      _AdminAppointmentsScreenState();
}

class _AdminAppointmentsScreenState
    extends ConsumerState<AdminAppointmentsScreen> {
  String _filter = 'all'; // all, pending, accepted, declined, cancelled
  String _search = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appointmentsAsync = ref.watch(adminAppointmentsStreamProvider);

    return NebulaBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_month_rounded,
                      color: AppTheme.electricBlue,
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Appointments',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Search
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  onChanged: (v) => setState(() => _search = v.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Search by patient name...',
                    hintStyle: const TextStyle(color: AppTheme.textSecondary),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppTheme.textSecondary,
                    ),
                    suffixIcon:
                        _search.isNotEmpty
                            ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: AppTheme.textSecondary,
                              ),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _search = '');
                              },
                            )
                            : null,
                    filled: true,
                    fillColor: AppTheme.glassWhite,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppTheme.glassBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppTheme.glassBorder),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Filter chips
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _FilterChip(
                      label: 'All',
                      color: AppTheme.electricBlue,
                      selected: _filter == 'all',
                      onTap: () => setState(() => _filter = 'all'),
                    ),
                    _FilterChip(
                      label: 'Pending',
                      color: AppTheme.vividOrange,
                      selected: _filter == 'pending',
                      onTap: () => setState(() => _filter = 'pending'),
                    ),
                    _FilterChip(
                      label: 'Accepted',
                      color: AppTheme.neonGreen,
                      selected: _filter == 'accepted',
                      onTap: () => setState(() => _filter = 'accepted'),
                    ),
                    _FilterChip(
                      label: 'Declined',
                      color: AppTheme.radiantPink,
                      selected: _filter == 'declined',
                      onTap: () => setState(() => _filter = 'declined'),
                    ),
                    _FilterChip(
                      label: 'Cancelled',
                      color: AppTheme.textSecondary,
                      selected: _filter == 'cancelled',
                      onTap: () => setState(() => _filter = 'cancelled'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // List
              Expanded(
                child: appointmentsAsync.when(
                  data: (appointments) {
                    var filtered = appointments;
                    if (_filter != 'all') {
                      filtered =
                          filtered.where((a) => a.status == _filter).toList();
                    }
                    if (_search.isNotEmpty) {
                      filtered =
                          filtered
                              .where(
                                (a) => (a.patientName ?? '')
                                    .toLowerCase()
                                    .contains(_search),
                              )
                              .toList();
                    }

                    if (filtered.isEmpty) {
                      return const Center(
                        child: Text(
                          'No appointments found',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        return _AdminAppointmentCard(
                          appointment: filtered[index],
                          ref: ref,
                        );
                      },
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

class _FilterChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color:
                selected ? color.withValues(alpha: 0.2) : AppTheme.glassWhite,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color:
                  selected
                      ? color.withValues(alpha: 0.6)
                      : AppTheme.glassBorder,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? color : AppTheme.textSecondary,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminAppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final WidgetRef ref;

  const _AdminAppointmentCard({required this.appointment, required this.ref});

  Color get _statusColor {
    switch (appointment.status) {
      case 'pending':
        return AppTheme.vividOrange;
      case 'accepted':
        return AppTheme.neonGreen;
      case 'declined':
        return AppTheme.radiantPink;
      case 'cancelled':
        return AppTheme.textSecondary;
      default:
        return AppTheme.electricBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AccentBar(color: _statusColor, height: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.patientName ?? 'Unknown Patient',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${appointment.specialty} • ${appointment.location}',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _statusColor.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  appointment.status.toUpperCase(),
                  style: TextStyle(
                    color: _statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
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
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (appointment.cancelReason != null) ...[
            const SizedBox(height: 6),
            Text(
              'Reason: ${appointment.cancelReason}',
              style: const TextStyle(color: AppTheme.radiantPink, fontSize: 12),
            ),
          ],
          // Actions
          if (appointment.isPending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ActionBtn(
                    label: 'Accept',
                    color: AppTheme.neonGreen,
                    icon: Icons.check_rounded,
                    onTap:
                        () => ref
                            .read(adminAppointmentsProvider.notifier)
                            .acceptAppointment(appointment.id),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionBtn(
                    label: 'Decline',
                    color: AppTheme.radiantPink,
                    icon: Icons.close_rounded,
                    onTap: () => _showDeclineDialog(context),
                  ),
                ),
              ],
            ),
          ] else if (appointment.isAccepted && appointment.isUpcoming) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ActionBtn(
                    label: 'Chat',
                    color: AppTheme.neonGreen,
                    icon: Icons.chat_rounded,
                    onTap: () => _openChatWithPatient(context),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionBtn(
                    label: 'Reschedule',
                    color: AppTheme.electricBlue,
                    icon: Icons.schedule_rounded,
                    onTap: () => _showRescheduleDialog(context),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionBtn(
                    label: 'Cancel',
                    color: AppTheme.radiantPink,
                    icon: Icons.cancel_outlined,
                    onTap: () => _showCancelDialog(context),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _openChatWithPatient(BuildContext context) async {
    if (appointment.patientId == null || appointment.patientId!.isEmpty) return;
    try {
      final room = await ChatRepository().getOrCreateChatRoom(
        doctorId: FirestoreService().uid,
        patientId: appointment.patientId!,
        doctorName: appointment.doctorName,
        patientName: appointment.patientName ?? 'Patient',
      );
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => AdminChatDetailScreen(
                  chatRoomId: room.id,
                  patientName: room.patientName,
                ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open chat: $e'),
            backgroundColor: AppTheme.radiantPink,
          ),
        );
      }
    }
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

  void _showRescheduleDialog(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: appointment.dateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(appointment.dateTime),
    );
    if (time == null) return;
    final newDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    ref
        .read(adminAppointmentsProvider.notifier)
        .rescheduleAppointment(appointment.id, newDateTime);
  }

  void _showCancelDialog(BuildContext context) {
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
              'Cancel Appointment',
              style: TextStyle(color: AppTheme.textPrimary),
            ),
            content: TextField(
              controller: reasonCtrl,
              style: const TextStyle(color: AppTheme.textPrimary),
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Reason for cancellation',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Back',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
              TextButton(
                onPressed: () {
                  if (reasonCtrl.text.isNotEmpty) {
                    ref
                        .read(adminAppointmentsProvider.notifier)
                        .cancelAppointment(appointment.id, reasonCtrl.text);
                    Navigator.pop(ctx);
                  }
                },
                child: const Text(
                  'Confirm Cancel',
                  style: TextStyle(color: AppTheme.radiantPink),
                ),
              ),
            ],
          ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionBtn({
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
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
