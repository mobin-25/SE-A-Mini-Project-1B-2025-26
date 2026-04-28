/// Profile screen — glassmorphic info cards, glowing avatar, accent BMI card,
/// gradient save button, nebula background.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/providers.dart';
import '../models/models.dart';
import '../widgets/nebula_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/user_avatar.dart';
import '../services/auth_service.dart';
import '../widgets/avatar_picker.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late TextEditingController _nameCtrl,
      _ageCtrl,
      _phoneCtrl,
      _emailCtrl,
      _heightCtrl,
      _weightCtrl,
      _emergNameCtrl,
      _emergPhoneCtrl;
  String _gender = 'Male';
  String? _bloodGroup;
  bool _inited = false;

  @override
  void dispose() {
    if (_inited) {
      _nameCtrl.dispose();
      _ageCtrl.dispose();
      _phoneCtrl.dispose();
      _emailCtrl.dispose();
      _heightCtrl.dispose();
      _weightCtrl.dispose();
      _emergNameCtrl.dispose();
      _emergPhoneCtrl.dispose();
    }
    super.dispose();
  }

  void _init() {
    final p = ref.read(profileProvider);
    _nameCtrl = TextEditingController(text: p.name);
    _ageCtrl = TextEditingController(text: p.age?.toString() ?? '');
    _phoneCtrl = TextEditingController(text: p.phone ?? '');
    _emailCtrl = TextEditingController(text: p.email ?? '');
    _heightCtrl = TextEditingController(text: p.height?.toString() ?? '');
    _weightCtrl = TextEditingController(text: p.weight?.toString() ?? '');
    _emergNameCtrl = TextEditingController(text: p.emergencyContactName ?? '');
    _emergPhoneCtrl = TextEditingController(
      text: p.emergencyContactPhone ?? '',
    );
    _gender = p.gender ?? 'Male';
    _bloodGroup = p.bloodGroup;
    _inited = true;
  }

  Widget _sectionLabel(String t, {Color color = AppTheme.electricBlue}) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
            boxShadow: AppTheme.glow(color, blur: 6),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          t,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_inited) _init();
    final profile = ref.watch(profileProvider);

    return NebulaBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Profile'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
          child: Column(
            children: [
              // Avatar with gradient border + glow — tap to change
              GestureDetector(
                onTap: () async {
                  final newUrl = await showAvatarPicker(
                    context: context,
                    seed: profile.username ?? profile.name,
                    currentUrl: profile.profilePicture,
                  );
                  if (newUrl != null && mounted) {
                    ref
                        .read(profileProvider.notifier)
                        .updateProfile(
                          profile.copyWith(profilePicture: newUrl),
                        );
                  }
                },
                child: Stack(
                  children: [
                    UserAvatar(
                      imageUrl: profile.profilePicture,
                      name: profile.name,
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
              const SizedBox(height: 10),
              Text(
                profile.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (profile.bloodGroup != null) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.radiantPink.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.radiantPink.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    'Blood: ${profile.bloodGroup}',
                    style: const TextStyle(
                      color: AppTheme.radiantPink,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // BMI Card
              if (profile.bmi != null) _buildBmiCard(profile),
              const SizedBox(height: 16),

              // Health Conditions
              if (profile.healthConditions.isNotEmpty) ...[
                _sectionLabel('HEALTH CONDITIONS', color: AppTheme.neonGreen),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      profile.healthConditions
                          .map(
                            (c) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.neonGreen.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppTheme.neonGreen.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: Text(
                                c,
                                style: const TextStyle(
                                  color: AppTheme.neonGreen,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                ),
                const SizedBox(height: 16),
              ],

              // Allergies
              if (profile.allergies.isNotEmpty) ...[
                _sectionLabel('ALLERGIES', color: AppTheme.vividOrange),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      profile.allergies
                          .map(
                            (a) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.vividOrange.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppTheme.vividOrange.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: Text(
                                a,
                                style: const TextStyle(
                                  color: AppTheme.vividOrange,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                ),
                const SizedBox(height: 16),
              ],

              // Emergency Contact
              if (profile.emergencyContactName != null) ...[
                _sectionLabel('EMERGENCY CONTACT', color: AppTheme.radiantPink),
                const SizedBox(height: 10),
                GlassCard(
                  borderColor: AppTheme.radiantPink.withValues(alpha: 0.3),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.radiantPink.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.emergency_rounded,
                          color: AppTheme.radiantPink,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.emergencyContactName!,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (profile.emergencyContactPhone != null)
                            Text(
                              profile.emergencyContactPhone!,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Divider
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      AppTheme.glassBorder,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Editable fields
              _sectionLabel('PERSONAL INFORMATION'),
              const SizedBox(height: 12),
              _field('Name', _nameCtrl, Icons.person_rounded),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      'Age',
                      _ageCtrl,
                      Icons.cake_rounded,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _smallLabel('Gender'),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0x28FFFFFF),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.glassBorder),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _gender,
                              isExpanded: true,
                              dropdownColor: AppTheme.bgSecondary,
                              items:
                                  [
                                        'Male',
                                        'Female',
                                        'Other',
                                        'Prefer not to say',
                                      ]
                                      .map(
                                        (g) => DropdownMenuItem(
                                          value: g,
                                          child: Text(g),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (v) => setState(() => _gender = v!),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Blood group chips
              _sectionLabel('BLOOD GROUP', color: AppTheme.radiantPink),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    kBloodGroups.map((bg) {
                      final s = _bloodGroup == bg;
                      return ChoiceChip(
                        label: Text(bg),
                        selected: s,
                        onSelected: (_) => setState(() => _bloodGroup = bg),
                        selectedColor: AppTheme.radiantPink.withValues(
                          alpha: 0.25,
                        ),
                        backgroundColor: AppTheme.glassWhite,
                        labelStyle: TextStyle(
                          color:
                              s ? AppTheme.radiantPink : AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color:
                                s ? AppTheme.radiantPink : AppTheme.glassBorder,
                          ),
                        ),
                        showCheckmark: false,
                      );
                    }).toList(),
              ),
              const SizedBox(height: 14),

              // Height / Weight
              _sectionLabel('BODY METRICS', color: AppTheme.neonGreen),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      'Height (cm)',
                      _heightCtrl,
                      Icons.height_rounded,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(
                      'Weight (kg)',
                      _weightCtrl,
                      Icons.monitor_weight_rounded,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Contact
              _sectionLabel('CONTACT', color: AppTheme.vividOrange),
              const SizedBox(height: 10),
              _field(
                'Phone',
                _phoneCtrl,
                Icons.phone_rounded,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 14),
              _field(
                'Email',
                _emailCtrl,
                Icons.email_rounded,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),

              // Emergency
              _sectionLabel('EMERGENCY', color: AppTheme.radiantPink),
              const SizedBox(height: 10),
              _field('Emergency Name', _emergNameCtrl, Icons.emergency_rounded),
              const SizedBox(height: 14),
              _field(
                'Emergency Phone',
                _emergPhoneCtrl,
                Icons.phone_callback_rounded,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 28),

              // Save button
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: AppTheme.accentGradient,
                    boxShadow: AppTheme.glow(AppTheme.electricBlue, blur: 16),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save_rounded, size: 20),
                    label: const Text('Save Profile'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Logout button
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppTheme.radiantPink.withValues(alpha: 0.5),
                    ),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder:
                            (ctx) => AlertDialog(
                              backgroundColor: AppTheme.bgSecondary,
                              title: const Text(
                                'Sign Out',
                                style: TextStyle(color: AppTheme.textPrimary),
                              ),
                              content: const Text(
                                'Are you sure you want to sign out?',
                                style: TextStyle(color: AppTheme.textSecondary),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
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
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBmiCard(UserProfile p) {
    final bmi = p.bmi!;
    final cat = p.bmiCategory;
    Color bmiColor;
    if (bmi < 18.5) {
      bmiColor = AppTheme.electricBlue;
    } else if (bmi < 25) {
      bmiColor = AppTheme.neonGreen;
    } else if (bmi < 30) {
      bmiColor = AppTheme.vividOrange;
    } else {
      bmiColor = AppTheme.radiantPink;
    }

    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(18)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0x28FFFFFF),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: bmiColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [bmiColor, bmiColor.withValues(alpha: 0.6)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: AppTheme.glow(bmiColor, blur: 12),
              ),
              child: Center(
                child: Text(
                  bmi.toStringAsFixed(1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'BMI',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
                Text(
                  cat,
                  style: TextStyle(
                    color: bmiColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${p.height?.toInt() ?? 0} cm · ${p.weight?.toInt() ?? 0} kg',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _smallLabel(String t) => Text(
    t,
    style: const TextStyle(
      color: AppTheme.electricBlue,
      fontWeight: FontWeight.w600,
      fontSize: 13,
    ),
  );

  Widget _field(
    String label,
    TextEditingController ctrl,
    IconData icon, {
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _smallLabel(label),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppTheme.textSecondary, size: 20),
            hintText: label,
          ),
        ),
      ],
    );
  }

  void _save() {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Name is required')));
      return;
    }
    final current = ref.read(profileProvider);
    ref
        .read(profileProvider.notifier)
        .updateProfile(
          current.copyWith(
            name: _nameCtrl.text.trim(),
            age: int.tryParse(_ageCtrl.text.trim()),
            gender: _gender,
            bloodGroup: _bloodGroup,
            phone:
                _phoneCtrl.text.trim().isNotEmpty
                    ? _phoneCtrl.text.trim()
                    : null,
            email:
                _emailCtrl.text.trim().isNotEmpty
                    ? _emailCtrl.text.trim()
                    : null,
            height: double.tryParse(_heightCtrl.text.trim()),
            weight: double.tryParse(_weightCtrl.text.trim()),
            emergencyContactName:
                _emergNameCtrl.text.trim().isNotEmpty
                    ? _emergNameCtrl.text.trim()
                    : null,
            emergencyContactPhone:
                _emergPhoneCtrl.text.trim().isNotEmpty
                    ? _emergPhoneCtrl.text.trim()
                    : null,
          ),
        );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Profile saved'),
        backgroundColor: AppTheme.electricBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
