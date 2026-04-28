// Home dashboard screen — glassmorphic cards, accent color highlights,
// gradient header, animated widgets, nebula background.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../theme/app_theme.dart';
import '../providers/providers.dart';
import '../models/models.dart';
import '../services/notification_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/nebula_background.dart';
import '../widgets/user_avatar.dart';
import 'patient_notifications_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService().requestPermissions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final medicines = ref.watch(medicinesProvider);
    // Use real-time stream for appointments so status reflects instantly
    final apptStream = ref.watch(patientAppointmentsStreamProvider);
    final liveAppointments = apptStream.when(
      data: (list) => list,
      loading: () => ref.read(appointmentsProvider),
      error: (_, __) => ref.read(appointmentsProvider),
    );
    final checkIn = ref.watch(checkInProvider);
    final water = ref.watch(waterIntakeProvider);
    final vitals = ref.watch(vitalsProvider);
    final streak = ref.read(medicinesProvider.notifier).adherenceStreak;

    final totalDoses = medicines.fold<int>(0, (s, m) => s + m.totalDoses);
    final takenDoses = medicines.fold<int>(0, (s, m) => s + m.takenCount);
    final progress = totalDoses > 0 ? takenDoses / totalDoses : 0.0;

    Medicine? nextMed;
    String? nextTime;
    for (final med in medicines) {
      for (final t in med.reminderTimes) {
        if (!med.takenTimes.contains(t)) {
          nextMed = med;
          nextTime = t;
          break;
        }
      }
      if (nextMed != null) break;
    }

    final nextAppt =
        (() {
          final now = DateTime.now();
          final upcoming =
              liveAppointments.where((a) => a.dateTime.isAfter(now)).toList()
                ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
          return upcoming.isEmpty ? null : upcoming.first;
        })();
    final tipIndex =
        DateTime.now().difference(DateTime(DateTime.now().year)).inDays %
        kHealthTips.length;
    final tip = kHealthTips[tipIndex];

    return NebulaBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Greeting Header ──────────────────────
                _buildGreeting(context, profile),
                const SizedBox(height: 20),

                // ─── Streak badge ─────────────────────────
                if (streak > 0) ...[
                  _buildStreakBadge(streak),
                  const SizedBox(height: 16),
                ],

                // ─── Progress Card ────────────────────────
                _buildProgressCard(takenDoses, totalDoses, progress),
                const SizedBox(height: 20),

                // ─── Hydration ────────────────────────────
                _sectionTitle('HYDRATION', AppTheme.electricBlue),
                const SizedBox(height: 10),
                _buildWaterCard(context, ref, water),
                const SizedBox(height: 20),

                // ─── Health Tip ───────────────────────────
                _sectionTitle('HEALTH TIP', AppTheme.neonGreen),
                const SizedBox(height: 10),
                _buildTipCard(tip),
                const SizedBox(height: 20),

                // ─── Vitals ───────────────────────────────
                _sectionTitle('VITALS SNAPSHOT', AppTheme.vividOrange),
                const SizedBox(height: 10),
                _buildVitalsRow(context, ref, vitals),
                const SizedBox(height: 20),

                // ─── Next Up ──────────────────────────────
                _sectionTitle('NEXT UP', AppTheme.radiantPink),
                const SizedBox(height: 10),
                nextMed != null && nextTime != null
                    ? _buildNextUpCard(context, ref, nextMed, nextTime)
                    : _buildEmptyCard(
                      'All doses completed for today. Well done!',
                    ),
                const SizedBox(height: 20),

                // ─── Appointments ─────────────────────────
                _sectionTitle('APPOINTMENTS', AppTheme.electricBlue),
                const SizedBox(height: 10),
                nextAppt != null
                    ? _buildAppointmentCard(context, ref, nextAppt)
                    : _buildEmptyCard('No appointments scheduled.'),
                const SizedBox(height: 20),

                // ─── Mood ─────────────────────────────────
                _sectionTitle(
                  'DAILY CHECK-IN',
                  AppTheme.radiantPink,
                  trailing: _logMoodBtn(context, ref),
                ),
                const SizedBox(height: 10),
                _buildMoodRow(context, ref, checkIn),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Greeting ─────────────────────────────────────────────────────
  Widget _buildGreeting(BuildContext context, UserProfile profile) {
    final dateStr = DateFormat('EEEE, MMM d').format(DateTime.now());
    // Watch real-time notification stream for unread badge
    final notifStream = ref.watch(patientNotificationsStreamProvider);
    final unreadCount = notifStream.when(
      data: (list) => list.where((n) => !n.isRead).length,
      loading: () => 0,
      error: (_, __) => 0,
    );
    return GlassCard(
      child: Row(
        children: [
          UserAvatar(
            imageUrl: profile.profilePicture,
            name: profile.name,
            radius: 24,
            showGlow: false,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back${profile.name.isNotEmpty ? ', ${profile.name.split(' ').first}' : ''}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateStr,
                  style: const TextStyle(
                    color: AppTheme.electricBlue,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.glassWhite,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.notifications_outlined,
                    color: AppTheme.electricBlue,
                    size: 24,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PatientNotificationsScreen(),
                      ),
                    );
                  },
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppTheme.radiantPink,
                        shape: BoxShape.circle,
                        boxShadow: AppTheme.glow(AppTheme.radiantPink, blur: 6),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        unreadCount > 9 ? '9+' : '$unreadCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Streak Badge ─────────────────────────────────────────────────
  Widget _buildStreakBadge(int streak) {
    return GlassCard(
      borderColor: AppTheme.neonGreen.withValues(alpha: 0.4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: AppTheme.greenBlueGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppTheme.glow(AppTheme.neonGreen, blur: 10),
            ),
            child: const Icon(
              Icons.local_fire_department_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$streak dose${streak > 1 ? 's' : ''} taken today',
            style: const TextStyle(
              color: AppTheme.neonGreen,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.neonGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'On Track',
              style: TextStyle(
                color: AppTheme.neonGreen,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Progress Card ────────────────────────────────────────────────
  Widget _buildProgressCard(int taken, int total, double progress) {
    final pct = (progress * 100).toInt();
    return GlassCard(
      borderColor: AppTheme.electricBlue.withValues(alpha: 0.3),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Today\'s Progress',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$total doses in your regimen',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppTheme.accentGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppTheme.glow(AppTheme.electricBlue, blur: 10),
                  ),
                  child: Text(
                    '$pct% Complete',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          CircularPercentIndicator(
            radius: 44,
            lineWidth: 7,
            percent: progress.clamp(0.0, 1.0),
            center: Text(
              '$taken/$total',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            progressColor: AppTheme.electricBlue,
            backgroundColor: AppTheme.glassWhite,
            circularStrokeCap: CircularStrokeCap.round,
          ),
        ],
      ),
    );
  }

  // ─── Water Card ───────────────────────────────────────────────────
  Widget _buildWaterCard(
    BuildContext context,
    WidgetRef ref,
    WaterIntake water,
  ) {
    return GlassCard(
      borderColor: AppTheme.electricBlue.withValues(alpha: 0.2),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00B4FF), Color(0xFF6C63FF)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppTheme.glow(AppTheme.electricBlue, blur: 10),
                ),
                child: const Icon(
                  Icons.water_drop_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Water Intake',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${water.glassCount} of ${water.goal} glasses',
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
                  color: AppTheme.electricBlue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${(water.percentage * 100).toInt()}%',
                  style: const TextStyle(
                    color: AppTheme.electricBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: water.percentage,
              minHeight: 6,
              backgroundColor: AppTheme.glassWhite,
              color: AppTheme.electricBlue,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _glassBtn(
                Icons.remove_rounded,
                () => ref.read(waterIntakeProvider.notifier).removeGlass(),
              ),
              const SizedBox(width: 8),
              ...List.generate(
                water.goal,
                (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1.5),
                  child: Icon(
                    i < water.glassCount
                        ? Icons.local_drink_rounded
                        : Icons.local_drink_outlined,
                    color:
                        i < water.glassCount
                            ? AppTheme.electricBlue
                            : AppTheme.glassWhite,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _glassBtn(
                Icons.add_rounded,
                () => ref.read(waterIntakeProvider.notifier).addGlass(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _glassBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppTheme.electricBlue.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppTheme.electricBlue.withValues(alpha: 0.3),
          ),
        ),
        child: Icon(icon, color: AppTheme.electricBlue, size: 20),
      ),
    );
  }

  // ─── Health Tip ───────────────────────────────────────────────────
  Widget _buildTipCard(HealthTip tip) {
    return GlassCard(
      borderColor: AppTheme.neonGreen.withValues(alpha: 0.25),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: AppTheme.greenBlueGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppTheme.glow(AppTheme.neonGreen, blur: 10),
            ),
            child: Text(tip.icon, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tip.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tip.body,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Vitals ───────────────────────────────────────────────────────
  Widget _buildVitalsRow(
    BuildContext context,
    WidgetRef ref,
    List<VitalRecord> vitals,
  ) {
    final notifier = ref.read(vitalsProvider.notifier);
    final hr = notifier.latestOfType('heartRate');
    final bp = notifier.latestOfType('bp');
    final bs = notifier.latestOfType('bloodSugar');

    return Row(
      children: [
        _vitalMini(
          Icons.favorite_rounded,
          'Heart Rate',
          hr != null ? '${hr.value.toInt()} bpm' : '--',
          AppTheme.radiantPink,
          () => _showAddVital(context, ref, 'heartRate'),
        ),
        const SizedBox(width: 8),
        _vitalMini(
          Icons.bloodtype_rounded,
          'Blood P.',
          bp != null
              ? '${bp.value.toInt()}/${bp.value2?.toInt() ?? 0}'
              : '--/--',
          AppTheme.vividOrange,
          () => _showAddVital(context, ref, 'bp'),
        ),
        const SizedBox(width: 8),
        _vitalMini(
          Icons.monitor_heart_rounded,
          'Sugar',
          bs != null ? '${bs.value.toInt()} mg/dL' : '--',
          AppTheme.neonGreen,
          () => _showAddVital(context, ref, 'bloodSugar'),
        ),
      ],
    );
  }

  Widget _vitalMini(
    IconData icon,
    String label,
    String value,
    Color accent,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0x28FFFFFF),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: accent.withValues(alpha: 0.25)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accent, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap to log',
                style: TextStyle(
                  color: accent.withValues(alpha: 0.6),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddVital(BuildContext context, WidgetRef ref, String type) {
    final v1Ctrl = TextEditingController();
    final v2Ctrl = TextEditingController();
    final labels = {
      'heartRate': ('Heart Rate', 'bpm', false),
      'bp': ('Blood Pressure', 'mmHg', true),
      'bloodSugar': ('Blood Sugar', 'mg/dL', false),
    };
    final (title, unit, hasDual) = labels[type]!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Log $title',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (hasDual)
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: v1Ctrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Systolic',
                          suffixText: unit,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: v2Ctrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: 'Diastolic',
                        ),
                      ),
                    ),
                  ],
                )
              else
                TextField(
                  controller: v1Ctrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Value',
                    suffixText: unit,
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final v = double.tryParse(v1Ctrl.text);
                    if (v == null) return;
                    ref
                        .read(vitalsProvider.notifier)
                        .add(
                          VitalRecord(
                            type: type,
                            value: v,
                            value2: double.tryParse(v2Ctrl.text),
                            recordedAt: DateTime.now(),
                            unit: unit,
                          ),
                        );
                    Navigator.pop(ctx);
                  },
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Next Up ──────────────────────────────────────────────────────
  Widget _buildNextUpCard(
    BuildContext context,
    WidgetRef ref,
    Medicine med,
    String time,
  ) {
    return GlassCard(
      borderColor: AppTheme.radiantPink.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  gradient: AppTheme.orangePinkGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'DUE AT $time',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.glassWhite,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.access_time_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            med.name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${med.dosage} • ${med.notes ?? med.form}',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: AppTheme.accentGradient,
                boxShadow: AppTheme.glow(AppTheme.electricBlue, blur: 12),
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  ref
                      .read(medicinesProvider.notifier)
                      .markTimeTaken(med.id, time);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${med.name} marked as taken!'),
                      backgroundColor: AppTheme.neonGreen,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.check_circle_rounded, size: 20),
                label: const Text('Mark as Taken'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Appointment Card ─────────────────────────────────────────────
  Widget _buildAppointmentCard(
    BuildContext context,
    WidgetRef ref,
    Appointment appt,
  ) {
    return GestureDetector(
      onTap: () => ref.read(currentTabProvider.notifier).state = 3,
      child: GlassCard(
        borderColor: AppTheme.electricBlue.withValues(alpha: 0.2),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: AppTheme.accentGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppTheme.glow(AppTheme.electricBlue, blur: 10),
              ),
              child: const Icon(
                Icons.calendar_month_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appt.doctorName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${appt.specialty} • ${DateFormat('EEEE').format(appt.dateTime)} at ${DateFormat('h:mm a').format(appt.dateTime)}',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Section Title ────────────────────────────────────────────────
  Widget _sectionTitle(String title, Color accent, {Widget? trailing}) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(color: accent.withValues(alpha: 0.5), blurRadius: 6),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: accent,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const Spacer(),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _logMoodBtn(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _showMoodSheet(context, ref),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          gradient: AppTheme.orangePinkGradient,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Log Mood',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _showMoodSheet(BuildContext context, WidgetRef ref) {
    int sel = 3;
    final noteCtrl = TextEditingController();
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'How are you feeling today?',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(5, (i) {
                      final moods = ['😫', '😟', '😐', '🙂', '🤩'];
                      final isSel = sel == i + 1;
                      final colors = [
                        AppTheme.radiantPink,
                        AppTheme.vividOrange,
                        AppTheme.textSecondary,
                        AppTheme.electricBlue,
                        AppTheme.neonGreen,
                      ];
                      return GestureDetector(
                        onTap: () => setBS(() => sel = i + 1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:
                                isSel
                                    ? colors[i].withValues(alpha: 0.2)
                                    : AppTheme.glassWhite,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSel ? colors[i] : Colors.transparent,
                              width: 2,
                            ),
                            boxShadow:
                                isSel
                                    ? AppTheme.glow(colors[i], blur: 10)
                                    : null,
                          ),
                          child: Text(
                            moods[i],
                            style: const TextStyle(fontSize: 28),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: noteCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Add a note (optional)...',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        ref
                            .read(checkInProvider.notifier)
                            .saveMood(
                              sel,
                              note:
                                  noteCtrl.text.isNotEmpty
                                      ? noteCtrl.text
                                      : null,
                            );
                        Navigator.pop(context);
                      },
                      child: const Text('Save Mood'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ─── Mood Row ─────────────────────────────────────────────────────
  Widget _buildMoodRow(
    BuildContext context,
    WidgetRef ref,
    DailyCheckIn? checkIn,
  ) {
    final moods = ['😫', '😟', '😐', '🙂', '🤩'];
    final colors = [
      AppTheme.radiantPink,
      AppTheme.vividOrange,
      AppTheme.textSecondary,
      AppTheme.electricBlue,
      AppTheme.neonGreen,
    ];
    return GlassCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(5, (i) {
          final isSel = checkIn?.mood == i + 1;
          return GestureDetector(
            onTap: () => ref.read(checkInProvider.notifier).saveMood(i + 1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:
                    isSel
                        ? colors[i].withValues(alpha: 0.2)
                        : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSel ? colors[i] : Colors.transparent,
                  width: 2,
                ),
                boxShadow: isSel ? AppTheme.glow(colors[i], blur: 10) : null,
              ),
              child: Text(moods[i], style: const TextStyle(fontSize: 26)),
            ),
          );
        }),
      ),
    );
  }

  // ─── Empty Card ───────────────────────────────────────────────────
  Widget _buildEmptyCard(String msg) {
    return GlassCard(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            msg,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
        ),
      ),
    );
  }
}
