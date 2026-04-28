// Admin Patients — view patient profiles, medical history, previous appointments.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';
import '../../providers/admin_providers.dart';
import '../../services/firestore_service.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/nebula_background.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/accent_bar.dart';

class AdminPatientsScreen extends ConsumerStatefulWidget {
  const AdminPatientsScreen({super.key});
  @override
  ConsumerState<AdminPatientsScreen> createState() =>
      _AdminPatientsScreenState();
}

class _AdminPatientsScreenState extends ConsumerState<AdminPatientsScreen> {
  String _search = '';
  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _patients = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPatients() async {
    final firestore = FirestoreService();
    // Get all unique patient IDs from this doctor's appointments
    final apptSnapshot =
        await firestore.sharedAppointmentsCollection
            .where('doctorId', isEqualTo: firestore.uid)
            .get();

    final patientIds = <String>{};
    for (final doc in apptSnapshot.docs) {
      final pid = doc.data()['patientId'] as String?;
      if (pid != null) patientIds.add(pid);
    }

    // Load each patient's profile
    final patients = <Map<String, dynamic>>[];
    for (final pid in patientIds) {
      final profileSnapshot =
          await firestore.userProfileCollection(pid).limit(1).get();
      if (profileSnapshot.docs.isNotEmpty) {
        final data = profileSnapshot.docs.first.data();
        data['uid'] = pid;
        patients.add(data);
      }
    }

    if (mounted) {
      setState(() {
        _patients = patients;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var filtered = _patients;
    if (_search.isNotEmpty) {
      filtered =
          filtered
              .where(
                (p) =>
                    (p['name'] as String? ?? '').toLowerCase().contains(
                      _search,
                    ) ||
                    (p['username'] as String? ?? '').toLowerCase().contains(
                      _search,
                    ),
              )
              .toList();
    }

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
                      Icons.people_rounded,
                      color: AppTheme.neonGreen,
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Patients',
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
                    hintText: 'Search patients by name or username...',
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
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Expanded(
                child:
                    _loading
                        ? const Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.electricBlue,
                          ),
                        )
                        : filtered.isEmpty
                        ? const Center(
                          child: Text(
                            'No patients found',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        )
                        : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            return _PatientCard(
                              patient: filtered[index],
                              onTap: () => _openPatientDetail(filtered[index]),
                            );
                          },
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openPatientDetail(Map<String, dynamic> patient) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _PatientDetailScreen(patient: patient)),
    );
  }
}

class _PatientCard extends StatelessWidget {
  final Map<String, dynamic> patient;
  final VoidCallback onTap;

  const _PatientCard({required this.patient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = patient['name'] as String? ?? 'Unknown';
    final username = patient['username'] as String? ?? '';
    final patientPic = patient['profilePicture'] as String?;
    final age = patient['age'] as int?;
    final gender = patient['gender'] as String?;
    final conditions = List<String>.from(patient['healthConditions'] ?? []);

    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            AccentBar(color: AppTheme.neonGreen, height: 48),
            const SizedBox(width: 12),
            UserAvatar(
              imageUrl: patientPic,
              name: name,
              radius: 20,
              showGlow: false,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  if (username.isNotEmpty)
                    Text(
                      '@$username',
                      style: const TextStyle(
                        color: AppTheme.electricBlue,
                        fontSize: 12,
                      ),
                    ),
                  if (age != null || gender != null)
                    Text(
                      [
                        if (age != null) 'Age: $age',
                        if (gender != null) gender,
                      ].join(' • '),
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  if (conditions.isNotEmpty)
                    Text(
                      conditions.take(2).join(', '),
                      style: const TextStyle(
                        color: AppTheme.vividOrange,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
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
}

/// Detail view of a patient's profile, history, and appointments.
class _PatientDetailScreen extends ConsumerWidget {
  final Map<String, dynamic> patient;
  const _PatientDetailScreen({required this.patient});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = patient['name'] as String? ?? 'Unknown';
    final username = patient['username'] as String? ?? '';
    final uid = patient['uid'] as String? ?? '';
    final profilePicture = patient['profilePicture'] as String?;
    final age = patient['age'] as int?;
    final gender = patient['gender'] as String?;
    final phone = patient['phone'] as String?;
    final email = patient['email'] as String?;
    final bloodGroup = patient['bloodGroup'] as String?;
    final conditions = List<String>.from(patient['healthConditions'] ?? []);
    final allergies = List<String>.from(patient['allergies'] ?? []);
    final height = (patient['height'] as num?)?.toDouble();
    final weight = (patient['weight'] as num?)?.toDouble();
    final emergName = patient['emergencyContactName'] as String?;
    final emergPhone = patient['emergencyContactPhone'] as String?;

    // Get this patient's appointments from the stream
    final appointmentsAsync = ref.watch(adminAppointmentsStreamProvider);

    return NebulaBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(backgroundColor: Colors.transparent, title: Text(name)),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar & Name
              Center(
                child: Column(
                  children: [
                    UserAvatar(
                      imageUrl: profilePicture,
                      name: name,
                      radius: 38,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      name,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (username.isNotEmpty)
                      Text(
                        '@$username',
                        style: const TextStyle(
                          color: AppTheme.electricBlue,
                          fontSize: 14,
                        ),
                      ),
                    if (age != null || gender != null)
                      Text(
                        [
                          if (age != null) 'Age: $age',
                          if (gender != null) gender,
                        ].join(' • '),
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Contact Info
              _InfoSection(
                title: 'Contact',
                color: AppTheme.electricBlue,
                children: [
                  if (phone != null) _InfoRow(Icons.phone, phone),
                  if (email != null) _InfoRow(Icons.email, email),
                  if (bloodGroup != null)
                    _InfoRow(Icons.bloodtype, 'Blood: $bloodGroup'),
                ],
              ),

              // Body measurements
              if (height != null || weight != null) ...[
                const SizedBox(height: 16),
                _InfoSection(
                  title: 'Body',
                  color: AppTheme.neonGreen,
                  children: [
                    if (height != null)
                      _InfoRow(Icons.height, '${height.toStringAsFixed(0)} cm'),
                    if (weight != null)
                      _InfoRow(
                        Icons.monitor_weight,
                        '${weight.toStringAsFixed(1)} kg',
                      ),
                    if (height != null && weight != null && height > 0) ...[
                      Builder(
                        builder: (_) {
                          final bmi =
                              weight / ((height / 100) * (height / 100));
                          return _InfoRow(
                            Icons.analytics,
                            'BMI: ${bmi.toStringAsFixed(1)}',
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ],

              // Health Conditions
              if (conditions.isNotEmpty) ...[
                const SizedBox(height: 16),
                _ChipSection(
                  title: 'Health Conditions',
                  color: AppTheme.vividOrange,
                  items: conditions,
                ),
              ],

              // Allergies
              if (allergies.isNotEmpty) ...[
                const SizedBox(height: 16),
                _ChipSection(
                  title: 'Allergies',
                  color: AppTheme.radiantPink,
                  items: allergies,
                ),
              ],

              // Emergency Contact
              if (emergName != null || emergPhone != null) ...[
                const SizedBox(height: 16),
                _InfoSection(
                  title: 'Emergency Contact',
                  color: AppTheme.radiantPink,
                  children: [
                    if (emergName != null) _InfoRow(Icons.person, emergName),
                    if (emergPhone != null) _InfoRow(Icons.phone, emergPhone),
                  ],
                ),
              ],

              // Appointment History
              const SizedBox(height: 24),
              const Text(
                'Appointment History',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              appointmentsAsync.when(
                data: (appts) {
                  final patientAppts =
                      appts.where((a) => a.patientId == uid).toList()
                        ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
                  if (patientAppts.isEmpty) {
                    return GlassCard(
                      child: const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'No previous appointments',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ),
                    );
                  }
                  return Column(
                    children:
                        patientAppts
                            .map((a) => _MiniApptCard(appointment: a))
                            .toList(),
                  );
                },
                loading:
                    () => const CircularProgressIndicator(
                      color: AppTheme.electricBlue,
                    ),
                error: (e, _) => Text('Error: $e'),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final Color color;
  final List<Widget> children;

  const _InfoSection({
    required this.title,
    required this.color,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderColor: color.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textSecondary, size: 18),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _ChipSection extends StatelessWidget {
  final String title;
  final Color color;
  final List<String> items;

  const _ChipSection({
    required this.title,
    required this.color,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderColor: color.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children:
                items
                    .map(
                      (item) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: color.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          item,
                          style: TextStyle(color: color, fontSize: 12),
                        ),
                      ),
                    )
                    .toList(),
          ),
        ],
      ),
    );
  }
}

class _MiniApptCard extends StatelessWidget {
  final Appointment appointment;
  const _MiniApptCard({required this.appointment});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    switch (appointment.status) {
      case 'pending':
        statusColor = AppTheme.vividOrange;
        break;
      case 'accepted':
        statusColor = AppTheme.neonGreen;
        break;
      case 'declined':
      case 'cancelled':
        statusColor = AppTheme.radiantPink;
        break;
      default:
        statusColor = AppTheme.electricBlue;
    }

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          AccentBar(color: statusColor, height: 32),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat(
                    'MMM dd, yyyy – hh:mm a',
                  ).format(appointment.dateTime),
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  appointment.specialty,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              appointment.status.toUpperCase(),
              style: TextStyle(
                color: statusColor,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
