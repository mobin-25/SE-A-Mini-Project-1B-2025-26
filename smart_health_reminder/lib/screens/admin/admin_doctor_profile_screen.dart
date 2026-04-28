import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';
import '../../providers/admin_providers.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/nebula_background.dart';
import '../../widgets/accent_bar.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/avatar_picker.dart';

class AdminDoctorProfileScreen extends ConsumerStatefulWidget {
  const AdminDoctorProfileScreen({super.key});
  @override
  ConsumerState<AdminDoctorProfileScreen> createState() =>
      _AdminDoctorProfileScreenState();
}

class _AdminDoctorProfileScreenState
    extends ConsumerState<AdminDoctorProfileScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _usernameCtrl;
  late TextEditingController _specialtyCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _bioCtrl;
  bool _loaded = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _usernameCtrl = TextEditingController();
    _specialtyCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _bioCtrl = TextEditingController();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    await ref.read(doctorProfileProvider.notifier).loadFromFirestore();
    final profile = ref.read(doctorProfileProvider);
    if (profile != null) {
      _nameCtrl.text = profile.name;
      _usernameCtrl.text = profile.username ?? '';
      _specialtyCtrl.text = profile.specialty ?? '';
      _phoneCtrl.text = profile.phone ?? '';
      _emailCtrl.text = profile.email ?? '';
      _bioCtrl.text = profile.bio ?? '';
    }
    if (mounted) setState(() => _loaded = true);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _specialtyCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(doctorProfileProvider);
    final availability = profile?.availability ?? [];

    return NebulaBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child:
              !_loaded
                  ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.electricBlue,
                    ),
                  )
                  : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(
                              Icons.person_rounded,
                              color: AppTheme.electricBlue,
                              size: 28,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Doctor Profile',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Center(
                          child: GestureDetector(
                            onTap: () async {
                              final newUrl = await showAvatarPicker(
                                context: context,
                                seed:
                                    _usernameCtrl.text.isNotEmpty
                                        ? _usernameCtrl.text
                                        : _nameCtrl.text,
                                currentUrl: profile?.profilePicture,
                              );
                              if (newUrl != null && mounted) {
                                final current = ref.read(doctorProfileProvider);
                                if (current != null) {
                                  await ref
                                      .read(doctorProfileProvider.notifier)
                                      .save(
                                        current.copyWith(
                                          profilePicture: newUrl,
                                        ),
                                      );
                                }
                              }
                            },
                            child: Stack(
                              children: [
                                UserAvatar(
                                  imageUrl: profile?.profilePicture,
                                  name:
                                      _nameCtrl.text.isNotEmpty
                                          ? _nameCtrl.text
                                          : 'D',
                                  radius: 44,
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppTheme.electricBlue,
                                      border: Border.all(
                                        color: AppTheme.bgPrimary,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.edit_rounded,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const _SectionTitle('Personal Information'),
                        const SizedBox(height: 8),
                        _field('Full Name', _nameCtrl, Icons.badge),
                        // Username (read-only, set at sign-up)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: TextField(
                            controller: _usernameCtrl,
                            readOnly: true,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Username',
                              labelStyle: const TextStyle(
                                color: AppTheme.textSecondary,
                              ),
                              prefixIcon: const Icon(
                                Icons.alternate_email,
                                color: AppTheme.textSecondary,
                                size: 20,
                              ),
                              suffixIcon: const Icon(
                                Icons.lock_outline,
                                color: AppTheme.textSecondary,
                                size: 16,
                              ),
                              filled: true,
                              fillColor: AppTheme.glassWhite,
                            ),
                          ),
                        ),
                        _field(
                          'Specialty',
                          _specialtyCtrl,
                          Icons.medical_services,
                        ),
                        _field('Phone', _phoneCtrl, Icons.phone),
                        _field('Email', _emailCtrl, Icons.email),
                        _field('Bio', _bioCtrl, Icons.description, maxLines: 3),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: GradientButton(
                            onPressed: _saving ? () {} : _saveProfile,
                            label: _saving ? 'Saving...' : 'Save Profile',
                          ),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const _SectionTitle('Availability Slots'),
                            IconButton(
                              icon: const Icon(
                                Icons.add_circle_outline,
                                color: AppTheme.neonGreen,
                              ),
                              onPressed: () => _addAvailability(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (availability.isEmpty)
                          GlassCard(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Center(
                                child: Text(
                                  'No availability slots configured.\nTap + to add.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppTheme.textSecondary.withValues(
                                      alpha: 0.7,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )
                        else
                          ...availability.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final slot = entry.value;
                            return _AvailabilitySlotCard(
                              slot: slot,
                              onDelete: () => _removeAvailability(idx),
                            );
                          }),
                        const SizedBox(height: 32),

                        // Sign Out
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder:
                                    (ctx) => AlertDialog(
                                      backgroundColor: AppTheme.bgSecondary,
                                      title: const Text(
                                        'Sign Out',
                                        style: TextStyle(
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      content: const Text(
                                        'Are you sure you want to sign out?',
                                        style: TextStyle(
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () => Navigator.pop(ctx, false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed:
                                              () => Navigator.pop(ctx, true),
                                          child: const Text(
                                            'Sign Out',
                                            style: TextStyle(
                                              color: AppTheme.radiantPink,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                              );
                              if (confirmed == true) {
                                await AuthService().signOut();
                              }
                            },
                            icon: const Icon(
                              Icons.logout_rounded,
                              size: 20,
                              color: AppTheme.radiantPink,
                            ),
                            label: const Text(
                              'Sign Out',
                              style: TextStyle(color: AppTheme.radiantPink),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.radiantPink.withValues(
                                alpha: 0.1,
                              ),
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),

                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl,
    IconData icon, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        style: const TextStyle(color: AppTheme.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppTheme.textSecondary),
          prefixIcon: Icon(icon, color: AppTheme.textSecondary, size: 20),
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Name is required')));
      return;
    }
    setState(() => _saving = true);
    final current = ref.read(doctorProfileProvider);
    final updated = DoctorProfile(
      id: FirestoreService().uid,
      name: _nameCtrl.text.trim(),
      username: _usernameCtrl.text.trim(),
      specialty: _specialtyCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      bio: _bioCtrl.text.trim(),
      profilePicture: current?.profilePicture,
      availability: current?.availability ?? [],
    );
    await ref.read(doctorProfileProvider.notifier).save(updated);
    setState(() => _saving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile saved'),
          backgroundColor: Color(0xFF1B5E20),
        ),
      );
    }
  }

  void _addAvailability(BuildContext context) async {
    final slot = await _showAvailabilityDialog(context);
    if (slot != null) {
      final current = ref.read(doctorProfileProvider);
      if (current != null) {
        final updated = current.copyWith(
          availability: [...current.availability, slot],
        );
        await ref.read(doctorProfileProvider.notifier).save(updated);
      }
    }
  }

  void _removeAvailability(int index) async {
    final current = ref.read(doctorProfileProvider);
    if (current != null) {
      final newList = List<DoctorAvailability>.from(current.availability);
      newList.removeAt(index);
      final updated = current.copyWith(availability: newList);
      await ref.read(doctorProfileProvider.notifier).save(updated);
    }
  }

  Future<DoctorAvailability?> _showAvailabilityDialog(
    BuildContext context,
  ) async {
    String selectedDay = 'Monday';
    TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 17, minute: 0);
    final days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    return showDialog<DoctorAvailability>(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setDialogState) => AlertDialog(
                  backgroundColor: AppTheme.bgSecondary,
                  title: const Text(
                    'Add Availability',
                    style: TextStyle(color: AppTheme.textPrimary),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: selectedDay,
                        dropdownColor: AppTheme.bgSecondary,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        items:
                            days
                                .map(
                                  (d) => DropdownMenuItem(
                                    value: d,
                                    child: Text(d),
                                  ),
                                )
                                .toList(),
                        onChanged:
                            (v) => setDialogState(() => selectedDay = v!),
                        decoration: const InputDecoration(
                          labelText: 'Day',
                          labelStyle: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _TimePickerButton(
                              label: 'Start',
                              time: startTime,
                              onTap: () async {
                                final picked = await showTimePicker(
                                  context: ctx,
                                  initialTime: startTime,
                                );
                                if (picked != null) {
                                  setDialogState(() => startTime = picked);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _TimePickerButton(
                              label: 'End',
                              time: endTime,
                              onTap: () async {
                                final picked = await showTimePicker(
                                  context: ctx,
                                  initialTime: endTime,
                                );
                                if (picked != null) {
                                  setDialogState(() => endTime = picked);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
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
                        Navigator.pop(
                          ctx,
                          DoctorAvailability(
                            dayOfWeek: selectedDay,
                            startTime:
                                '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
                            endTime:
                                '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
                          ),
                        );
                      },
                      child: const Text(
                        'Add',
                        style: TextStyle(color: AppTheme.neonGreen),
                      ),
                    ),
                  ],
                ),
          ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppTheme.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _TimePickerButton extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;
  const _TimePickerButton({
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: AppTheme.bgPrimary.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppTheme.electricBlue.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvailabilitySlotCard extends StatelessWidget {
  final DoctorAvailability slot;
  final VoidCallback onDelete;
  const _AvailabilitySlotCard({required this.slot, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          AccentBar(color: AppTheme.neonGreen, height: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slot.dayOfWeek,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${slot.startTime} – ${slot.endTime}',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline,
              color: AppTheme.radiantPink,
              size: 20,
            ),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
