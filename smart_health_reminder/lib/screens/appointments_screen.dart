/// Appointments screen — glassmorphic cards, gradient segmented control,
/// accent-colored specialty icons, nebula background.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../providers/providers.dart';
import '../models/models.dart';
import '../widgets/nebula_background.dart';
import '../widgets/user_avatar.dart';
import '../repositories/chat_repository.dart';
import '../services/firestore_service.dart';
import 'patient_chat_screen.dart';

class AppointmentsScreen extends ConsumerStatefulWidget {
  const AppointmentsScreen({super.key});
  @override
  ConsumerState<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends ConsumerState<AppointmentsScreen> {
  bool _showUpcoming = true;
  String _search = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  static const _specAccents = {
    'dent': AppTheme.neonGreen,
    'cardio': AppTheme.radiantPink,
    'heart': AppTheme.radiantPink,
    'eye': AppTheme.vividOrange,
    'opto': AppTheme.vividOrange,
  };

  Color _accentFor(String specialty) {
    final low = specialty.toLowerCase();
    for (final e in _specAccents.entries) {
      if (low.contains(e.key)) return e.value;
    }
    return AppTheme.electricBlue;
  }

  IconData _iconFor(String specialty) {
    final low = specialty.toLowerCase();
    if (low.contains('dent')) return Icons.health_and_safety_rounded;
    if (low.contains('cardio') || low.contains('heart')) {
      return Icons.favorite_rounded;
    }
    if (low.contains('eye') || low.contains('opto')) {
      return Icons.visibility_rounded;
    }
    return Icons.medical_services_rounded;
  }

  @override
  Widget build(BuildContext context) {
    // Use real-time stream for live appointment status updates
    final streamData = ref.watch(patientAppointmentsStreamProvider);
    final allAppointments = streamData.when(
      data: (list) => list,
      loading: () => ref.read(appointmentsProvider),
      error: (_, __) => ref.read(appointmentsProvider),
    );
    final now = DateTime.now();
    final upcoming =
        allAppointments
            .where(
              (a) =>
                  a.dateTime.isAfter(now) &&
                  (_search.isEmpty ||
                      a.doctorName.toLowerCase().contains(
                        _search.toLowerCase(),
                      )),
            )
            .toList()
          ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    final past =
        allAppointments
            .where(
              (a) =>
                  !a.dateTime.isAfter(now) &&
                  (_search.isEmpty ||
                      a.doctorName.toLowerCase().contains(
                        _search.toLowerCase(),
                      )),
            )
            .toList()
          ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

    return NebulaBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Appointments'),
          actions: [
            IconButton(
              icon: const Icon(Icons.search_rounded),
              onPressed: () {
                showDialog(
                  context: context,
                  builder:
                      (_) => AlertDialog(
                        title: const Text('Search Appointments'),
                        content: TextField(
                          controller: _searchCtrl,
                          decoration: const InputDecoration(
                            hintText: 'Doctor name...',
                          ),
                          onChanged: (v) => setState(() => _search = v),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _search = '');
                              Navigator.pop(context);
                            },
                            child: const Text('Clear'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Done'),
                          ),
                        ],
                      ),
                );
              },
            ),
          ],
        ),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Glassmorphic segmented control
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0x28FFFFFF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.glassBorder),
                  ),
                  child: Row(
                    children: [
                      _segmentButton('Upcoming', true),
                      _segmentButton('Past', false),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),

              // Section header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      width: 3,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppTheme.electricBlue,
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: AppTheme.glow(
                          AppTheme.electricBlue,
                          blur: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _showUpcoming ? 'UPCOMING' : 'PAST HISTORY',
                      style: const TextStyle(
                        color: AppTheme.electricBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_showUpcoming ? upcoming.length : past.length} Total',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // List
              Expanded(
                child:
                    _showUpcoming
                        ? (upcoming.isEmpty
                            ? _emptyState('No upcoming appointments')
                            : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                0,
                                20,
                                120,
                              ),
                              itemCount: upcoming.length,
                              itemBuilder:
                                  (_, i) => _buildCard(upcoming[i], false, i),
                            ))
                        : (past.isEmpty
                            ? _emptyState('No past appointments')
                            : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                0,
                                20,
                                120,
                              ),
                              itemCount: past.length,
                              itemBuilder:
                                  (_, i) => _buildCard(past[i], true, i),
                            )),
              ),
            ],
          ),
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 80),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: AppTheme.accentGradient,
              boxShadow: AppTheme.glow(
                AppTheme.electricBlue,
                blur: 20,
                spread: 2,
              ),
            ),
            child: FloatingActionButton(
              tooltip: 'Add Appointment',
              backgroundColor: Colors.transparent,
              elevation: 0,
              onPressed: () => _showAddForm(context),
              child: const Icon(
                Icons.add_rounded,
                size: 28,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _segmentButton(String label, bool isUpcoming) {
    final selected = _showUpcoming == isUpcoming;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _showUpcoming = isUpcoming),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: selected ? AppTheme.accentGradient : null,
            borderRadius: BorderRadius.circular(14),
            boxShadow:
                selected
                    ? AppTheme.glow(AppTheme.electricBlue, blur: 10)
                    : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyState(String msg) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.event_available_rounded,
            size: 56,
            color: AppTheme.textSecondary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          Text(msg, style: const TextStyle(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildCard(Appointment appt, bool isPast, int index) {
    final accent = _accentFor(appt.specialty);
    final icon = _iconFor(appt.specialty);
    final dateStr = DateFormat('MMM d, yyyy').format(appt.dateTime);
    final timeStr = DateFormat('h:mm a').format(appt.dateTime);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0x28FFFFFF),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: accent.withValues(alpha: isPast ? 0.1 : 0.25),
          ),
        ),
        child: Row(
          children: [
            // Accent bar
            Container(
              width: 4,
              height: isPast ? 100 : 155,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [accent, accent.withValues(alpha: 0.3)],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                ),
                boxShadow: AppTheme.glow(accent, blur: 8),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icon, color: accent, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                appt.doctorName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color:
                                      isPast
                                          ? AppTheme.textSecondary
                                          : Colors.white,
                                ),
                              ),
                              Text(
                                appt.specialty,
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Status chip — color-coded per status
                        Builder(
                          builder: (_) {
                            Color chipColor;
                            switch (appt.status) {
                              case 'accepted':
                                chipColor = AppTheme.neonGreen;
                                break;
                              case 'declined':
                                chipColor = AppTheme.radiantPink;
                                break;
                              case 'cancelled':
                                chipColor = AppTheme.vividOrange;
                                break;
                              case 'pending':
                              default:
                                chipColor =
                                    isPast ? AppTheme.textSecondary : accent;
                            }
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: chipColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: chipColor.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                appt.status[0].toUpperCase() +
                                    appt.status.substring(1),
                                style: TextStyle(
                                  color: chipColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Date & location
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          color: AppTheme.textSecondary,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$dateStr at $timeStr',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          color: AppTheme.textSecondary,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            appt.location,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    // Action buttons for upcoming
                    if (!isPast) ...[
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: LinearGradient(
                                  colors: [
                                    accent,
                                    accent.withValues(alpha: 0.7),
                                  ],
                                ),
                                boxShadow: AppTheme.glow(accent, blur: 10),
                              ),
                              child: ElevatedButton.icon(
                                onPressed: () => _reschedule(appt),
                                icon: const Icon(
                                  Icons.calendar_month_rounded,
                                  size: 16,
                                ),
                                label: const Text('Reschedule'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          if (appt.isAccepted && appt.doctorId != null)
                            Container(
                              decoration: BoxDecoration(
                                color: AppTheme.glassWhite,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.glassBorder),
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.chat_rounded,
                                  color: AppTheme.neonGreen,
                                ),
                                tooltip: 'Chat with Doctor',
                                onPressed: () => _openChatWithDoctor(appt),
                              ),
                            ),
                          const SizedBox(width: 10),
                          Container(
                            decoration: BoxDecoration(
                              color: AppTheme.glassWhite,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.glassBorder),
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.arrow_forward_rounded,
                                color: accent,
                              ),
                              onPressed: () => _showDetails(appt),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _reschedule(Appointment appt) async {
    final date = await showDatePicker(
      context: context,
      initialDate: appt.dateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(appt.dateTime),
    );
    if (time == null || !mounted) return;
    final newDt = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    ref
        .read(appointmentsProvider.notifier)
        .update(appt.copyWith(dateTime: newDt));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Appointment rescheduled'),
          backgroundColor: AppTheme.electricBlue,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _showDetails(Appointment appt) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(appt.doctorName),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Specialty: ${appt.specialty}'),
                Text(
                  'Date: ${DateFormat('MMM d, yyyy h:mm a').format(appt.dateTime)}',
                ),
                Text('Location: ${appt.location}'),
                Text('Status: ${appt.status}'),
                if (appt.notes != null) Text('Notes: ${appt.notes}'),
              ],
            ),
            actions: [
              if (appt.isAccepted && appt.doctorId != null)
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _openChatWithDoctor(appt);
                  },
                  icon: const Icon(Icons.chat_rounded, size: 18),
                  label: const Text('Chat with Doctor'),
                ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  void _openChatWithDoctor(Appointment appt) async {
    if (appt.doctorId == null || appt.doctorId!.isEmpty) return;
    try {
      final patientName = ref.read(profileProvider).name;
      final room = await ChatRepository().getOrCreateChatRoom(
        doctorId: appt.doctorId!,
        patientId: FirestoreService().uid,
        doctorName: appt.doctorName,
        patientName: patientName,
      );
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => PatientChatDetailScreen(
                  chatRoomId: room.id,
                  doctorName: room.doctorName,
                ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open chat: $e'),
            backgroundColor: AppTheme.radiantPink,
          ),
        );
      }
    }
  }

  void _showAddForm(BuildContext context) {
    final locCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));
    TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 0);
    Map<String, dynamic>? selectedDoctor; // picked doctor from Firestore

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setBS) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add Appointment',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Doctor search button
                    GestureDetector(
                      onTap: () async {
                        final doctor = await _showDoctorSearch(context);
                        if (doctor != null) {
                          setBS(() => selectedDoctor = doctor);
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.electricBlue.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                selectedDoctor != null
                                    ? AppTheme.electricBlue
                                    : AppTheme.glassBorder,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.search_rounded,
                              color:
                                  selectedDoctor != null
                                      ? AppTheme.electricBlue
                                      : AppTheme.textSecondary,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    selectedDoctor != null
                                        ? selectedDoctor!['name'] ?? 'Doctor'
                                        : 'Search for a Doctor',
                                    style: TextStyle(
                                      color:
                                          selectedDoctor != null
                                              ? AppTheme.textPrimary
                                              : AppTheme.textSecondary,
                                      fontSize: 15,
                                      fontWeight:
                                          selectedDoctor != null
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                    ),
                                  ),
                                  if (selectedDoctor != null &&
                                      selectedDoctor!['specialty'] != null &&
                                      (selectedDoctor!['specialty'] as String)
                                          .isNotEmpty)
                                    Text(
                                      '${selectedDoctor!['specialty']}${selectedDoctor!['username'] != null && (selectedDoctor!['username'] as String).isNotEmpty ? ' • @${selectedDoctor!['username']}' : ''}',
                                      style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (selectedDoctor != null)
                              const Icon(
                                Icons.check_circle,
                                color: AppTheme.neonGreen,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final d = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365),
                                ),
                              );
                              if (d != null) {
                                setBS(() => selectedDate = d);
                              }
                            },
                            icon: const Icon(
                              Icons.calendar_today_rounded,
                              size: 16,
                            ),
                            label: Text(
                              DateFormat('MMM d, yyyy').format(selectedDate),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.electricBlue,
                              side: const BorderSide(
                                color: AppTheme.electricBlue,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final t = await showTimePicker(
                                context: context,
                                initialTime: selectedTime,
                              );
                              if (t != null) {
                                setBS(() => selectedTime = t);
                              }
                            },
                            icon: const Icon(
                              Icons.access_time_rounded,
                              size: 16,
                            ),
                            label: Text(selectedTime.format(context)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.electricBlue,
                              side: const BorderSide(
                                color: AppTheme.electricBlue,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: locCtrl,
                      decoration: const InputDecoration(hintText: 'Location'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: notesCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Notes (optional)',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: AppTheme.accentGradient,
                        ),
                        child: ElevatedButton(
                          onPressed: () async {
                            if (selectedDoctor == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please select a doctor first'),
                                ),
                              );
                              return;
                            }
                            try {
                              await ref
                                  .read(appointmentsProvider.notifier)
                                  .add(
                                    Appointment(
                                      doctorName:
                                          selectedDoctor!['name'] ?? 'Doctor',
                                      specialty:
                                          selectedDoctor!['specialty'] ?? '',
                                      doctorId: selectedDoctor!['id'] as String,
                                      dateTime: DateTime(
                                        selectedDate.year,
                                        selectedDate.month,
                                        selectedDate.day,
                                        selectedTime.hour,
                                        selectedTime.minute,
                                      ),
                                      location:
                                          locCtrl.text.trim().isNotEmpty
                                              ? locCtrl.text.trim()
                                              : 'TBD',
                                      notes:
                                          notesCtrl.text.trim().isNotEmpty
                                              ? notesCtrl.text.trim()
                                              : null,
                                    ),
                                  );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Appointment booked successfully!',
                                    ),
                                    backgroundColor: AppTheme.neonGreen,
                                  ),
                                );
                                Navigator.pop(context);
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Failed to save appointment: $e',
                                    ),
                                    backgroundColor: AppTheme.radiantPink,
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Save Appointment'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Show full doctor profile with bio, contact, availability and "Book" button.
  Future<bool> _showDoctorDetail(
    BuildContext context,
    Map<String, dynamic> doc,
  ) async {
    final name = doc['name'] as String? ?? 'Doctor';
    final specialty = doc['specialty'] as String? ?? '';
    final username = doc['username'] as String? ?? '';
    final bio = doc['bio'] as String? ?? '';
    final phone = doc['phone'] as String? ?? '';
    final email = doc['email'] as String? ?? '';
    final availability = doc['availability'] as List<dynamic>? ?? [];
    final doctorPic = doc['profilePicture'] as String?;
    final accent = _accentFor(specialty);

    final result = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => Dialog(
            backgroundColor: AppTheme.bgPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Doctor avatar
                  UserAvatar(imageUrl: doctorPic, name: name, radius: 36),
                  const SizedBox(height: 12),
                  Text(
                    name,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (username.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      '@$username',
                      style: const TextStyle(
                        color: AppTheme.electricBlue,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  if (specialty.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        specialty,
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],

                  // Bio
                  if (bio.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'About',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        bio,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],

                  // Contact info
                  if (phone.isNotEmpty || email.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Contact',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (phone.isNotEmpty) _infoRow(Icons.phone_rounded, phone),
                    if (email.isNotEmpty) _infoRow(Icons.email_rounded, email),
                  ],

                  // Availability
                  const SizedBox(height: 16),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Availability',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (availability.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children:
                          availability.map((slot) {
                            final day = slot['dayOfWeek'] ?? '';
                            final start = slot['startTime'] ?? '';
                            final end = slot['endTime'] ?? '';
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.neonGreen.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppTheme.neonGreen.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: Text(
                                '$day  $start – $end',
                                style: const TextStyle(
                                  color: AppTheme.neonGreen,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }).toList(),
                    )
                  else
                    const Text(
                      'No availability set yet',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.textSecondary,
                            side: const BorderSide(color: AppTheme.glassBorder),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Back'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: AppTheme.accentGradient,
                          ),
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Book Appointment'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
    return result == true;
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.electricBlue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  /// Show a browse/search dialog where patient can pick a doctor.
  /// All registered doctors are shown by default with specialty + availability.
  Future<Map<String, dynamic>?> _showDoctorSearch(BuildContext context) async {
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) {
        String searchQuery = '';
        List<Map<String, dynamic>> results = [];
        bool loading = true;

        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            // Load doctors on first build
            if (loading) {
              FirebaseFirestore.instance
                  .collection('doctorProfiles')
                  .get()
                  .then((snapshot) {
                    if (ctx.mounted) {
                      setDialogState(() {
                        results =
                            snapshot.docs
                                .map((doc) => {'id': doc.id, ...doc.data()})
                                .toList();
                        loading = false;
                      });
                    }
                  })
                  .catchError((e) {
                    if (ctx.mounted) {
                      setDialogState(() {
                        loading = false;
                      });
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: Text('Failed to load doctors: $e'),
                          backgroundColor: AppTheme.radiantPink,
                        ),
                      );
                    }
                  });
            }

            final filtered =
                searchQuery.isEmpty
                    ? results
                    : results.where((doc) {
                      final name = (doc['name'] as String? ?? '').toLowerCase();
                      final specialty =
                          (doc['specialty'] as String? ?? '').toLowerCase();
                      final uname =
                          (doc['username'] as String? ?? '').toLowerCase();
                      final q = searchQuery.toLowerCase();
                      return name.contains(q) ||
                          specialty.contains(q) ||
                          uname.contains(q);
                    }).toList();

            return AlertDialog(
              backgroundColor: AppTheme.bgPrimary,
              title: const Text(
                'Browse Doctors',
                style: TextStyle(color: AppTheme.textPrimary),
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 450,
                child: Column(
                  children: [
                    TextField(
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Search by name, username, or specialty...',
                        hintStyle: const TextStyle(
                          color: AppTheme.textSecondary,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppTheme.textSecondary,
                        ),
                        filled: true,
                        fillColor: AppTheme.glassWhite,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppTheme.glassBorder,
                          ),
                        ),
                      ),
                      onChanged: (v) => setDialogState(() => searchQuery = v),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child:
                          loading
                              ? const Center(
                                child: CircularProgressIndicator(
                                  color: AppTheme.electricBlue,
                                ),
                              )
                              : filtered.isEmpty
                              ? Center(
                                child: Text(
                                  searchQuery.isEmpty
                                      ? 'No doctors registered yet'
                                      : 'No doctors match "$searchQuery"',
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              )
                              : ListView.builder(
                                itemCount: filtered.length,
                                itemBuilder: (_, i) {
                                  final doc = filtered[i];
                                  final availability =
                                      doc['availability'] as List<dynamic>? ??
                                      [];
                                  final specialty =
                                      doc['specialty'] as String? ?? '';
                                  final username =
                                      doc['username'] as String? ?? '';

                                  return Card(
                                    color: AppTheme.glassWhite,
                                    margin: const EdgeInsets.only(bottom: 10),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      side: const BorderSide(
                                        color: AppTheme.glassBorder,
                                      ),
                                    ),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(14),
                                      onTap: () async {
                                        final selected =
                                            await _showDoctorDetail(ctx, doc);
                                        if (selected && ctx.mounted) {
                                          Navigator.pop(ctx, doc);
                                        }
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                UserAvatar(
                                                  imageUrl:
                                                      doc['profilePicture']
                                                          as String?,
                                                  name: doc['name'] ?? 'D',
                                                  radius: 20,
                                                  showGlow: false,
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        doc['name'] ?? 'Doctor',
                                                        style: const TextStyle(
                                                          color:
                                                              AppTheme
                                                                  .textPrimary,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontSize: 15,
                                                        ),
                                                      ),
                                                      if (username.isNotEmpty)
                                                        Text(
                                                          '@$username',
                                                          style: const TextStyle(
                                                            color:
                                                                AppTheme
                                                                    .electricBlue,
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                                if (specialty.isNotEmpty)
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 4,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: _accentFor(
                                                        specialty,
                                                      ).withValues(alpha: 0.15),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      specialty,
                                                      style: TextStyle(
                                                        color: _accentFor(
                                                          specialty,
                                                        ),
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            // Bio preview
                                            if ((doc['bio'] as String? ?? '')
                                                .isNotEmpty) ...[
                                              const SizedBox(height: 6),
                                              Text(
                                                doc['bio'] as String,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: AppTheme.textSecondary,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                            // Availability slots
                                            if (availability.isNotEmpty) ...[
                                              const SizedBox(height: 8),
                                              const Divider(
                                                color: AppTheme.glassBorder,
                                                height: 1,
                                              ),
                                              const SizedBox(height: 8),
                                              Wrap(
                                                spacing: 6,
                                                runSpacing: 4,
                                                children:
                                                    availability.map((slot) {
                                                      final day =
                                                          slot['dayOfWeek'] ??
                                                          '';
                                                      final start =
                                                          slot['startTime'] ??
                                                          '';
                                                      final end =
                                                          slot['endTime'] ?? '';
                                                      return Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                              vertical: 4,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: AppTheme
                                                              .neonGreen
                                                              .withValues(
                                                                alpha: 0.12,
                                                              ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                6,
                                                              ),
                                                          border: Border.all(
                                                            color: AppTheme
                                                                .neonGreen
                                                                .withValues(
                                                                  alpha: 0.3,
                                                                ),
                                                          ),
                                                        ),
                                                        child: Text(
                                                          '${day.length > 3 ? day.substring(0, 3) : day} $start–$end',
                                                          style: const TextStyle(
                                                            color:
                                                                AppTheme
                                                                    .neonGreen,
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                      );
                                                    }).toList(),
                                              ),
                                            ],
                                            if (availability.isEmpty)
                                              const Padding(
                                                padding: EdgeInsets.only(
                                                  top: 6,
                                                ),
                                                child: Text(
                                                  'No availability set yet',
                                                  style: TextStyle(
                                                    color:
                                                        AppTheme.textSecondary,
                                                    fontSize: 11,
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                              ),
                                            // Tap for details hint
                                            const Padding(
                                              padding: EdgeInsets.only(top: 6),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    'Tap for details',
                                                    style: TextStyle(
                                                      color:
                                                          AppTheme.electricBlue,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                  SizedBox(width: 4),
                                                  Icon(
                                                    Icons
                                                        .arrow_forward_ios_rounded,
                                                    color:
                                                        AppTheme.electricBlue,
                                                    size: 10,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                    ),
                  ],
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
              ],
            );
          },
        );
      },
    );
  }
}
