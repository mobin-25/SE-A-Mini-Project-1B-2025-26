import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../main.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class SettingsScreen extends StatefulWidget {
  final bool embedded;
  const SettingsScreen({super.key, this.embedded = false});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;
  bool _locationAccess = true;
  bool _autoRelease = false;
  String _userName = '';
  String _userRole = '';
  Map<String, dynamic>? _vehicle;
  bool _loadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final profile = await AuthService.getProfile(uid);
    final vehicle = await FirestoreService.getVehicle(uid);
    if (mounted) {
      setState(() {
        _userName = profile?.name ?? 'APSIT User';
        _userRole = profile?.role ?? 'Student';
        _vehicle = vehicle;
        _loadingProfile = false;
      });
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts.isNotEmpty && parts[0].isNotEmpty)
      return parts[0][0].toUpperCase();
    return '?';
  }

  bool get _isDark => themeNotifier.value == ThemeMode.dark;

  Color get _bg => _isDark ? AppColors.background : Colors.white;
  Color get _cardBg =>
      _isDark ? AppColors.surfaceLight : const Color(0xFFF3F4F6);
  Color get _textColor => _isDark ? Colors.white : const Color(0xFF0F172A);
  Color get _subtitleColor =>
      _isDark ? AppColors.textMuted : const Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, __) {
        return Scaffold(
          backgroundColor: _bg,
          body: SafeArea(
            child: _loadingProfile
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        Text(
                          'Settings',
                          style: GoogleFonts.inter(
                            color: _textColor,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildProfileCard(context),
                        const SizedBox(height: 24),
                        _buildSection('Preferences', [
                          _buildToggleTile(
                            'Push Notifications',
                            'Receive alerts for slot status',
                            Icons.notifications_outlined,
                            _notifications,
                            (v) => setState(() => _notifications = v),
                          ),
                          _buildToggleTile(
                            'Location Access',
                            'Used for navigation to slot',
                            Icons.location_on_outlined,
                            _locationAccess,
                            (v) => setState(() => _locationAccess = v),
                          ),
                          _buildToggleTile(
                            'Auto Release',
                            'Auto-release slot on campus exit',
                            Icons.exit_to_app,
                            _autoRelease,
                            (v) => setState(() => _autoRelease = v),
                          ),
                          ValueListenableBuilder<ThemeMode>(
                            valueListenable: themeNotifier,
                            builder: (context, mode, _) {
                              return _buildToggleTile(
                                'Dark Mode',
                                'Switch between light and dark theme',
                                Icons.dark_mode_outlined,
                                mode == ThemeMode.dark,
                                (v) => themeNotifier.value =
                                    v ? ThemeMode.dark : ThemeMode.light,
                              );
                            },
                          ),
                        ]),
                        const SizedBox(height: 16),
                        _buildSection('Account', [
                          _buildNavTile(
                            'My Vehicle',
                            Icons.directions_car_outlined,
                            () => _showVehicleSheet(context),
                          ),
                          _buildNavTile(
                            'Change Password',
                            Icons.lock_outline,
                            () => _showPasswordDialog(context),
                          ),
                          _buildNavTile(
                            'Contact Support',
                            Icons.support_agent_outlined,
                            () => _showSupportDialog(context),
                          ),
                          _buildNavTile(
                            'About App',
                            Icons.info_outline,
                            () => _showAboutDialog(context),
                          ),
                        ]),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _confirmLogout(context),
                            icon: const Icon(Icons.logout,
                                color: AppColors.red, size: 20),
                            label: Text(
                              'Logout',
                              style: GoogleFonts.inter(
                                  color: AppColors.red,
                                  fontWeight: FontWeight.w700),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                  color: AppColors.red
                                      .withAlpha((0.3 * 255).round())),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor:
                                  AppColors.red.withAlpha((0.05 * 255).round()),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Center(
                          child: Text(
                            'APSIT Smart Park v1.0.0',
                            style: GoogleFonts.inter(
                                color: _subtitleColor, fontSize: 12),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha((0.2 * 255).round()),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _initials(_userName),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_userName,
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 17)),
                Text(_userRole,
                    style: GoogleFonts.inter(
                        color: Colors.white.withAlpha((0.7 * 255).round()),
                        fontSize: 13)),
              ],
            ),
          ),
          IconButton(
            icon:
                const Icon(Icons.edit_outlined, color: Colors.white, size: 20),
            onPressed: () => _showEditNameDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10, left: 4),
          child: Text(
            title,
            style: GoogleFonts.inter(
              color: _subtitleColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color:
                    _isDark ? AppColors.inputBorder : const Color(0xFFE2E8F0)),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildToggleTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha((0.1 * 255).round()),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primaryLight, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.inter(
                        color: _textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                Text(subtitle,
                    style:
                        GoogleFonts.inter(color: _subtitleColor, fontSize: 11)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withAlpha((0.3 * 255).round()),
            inactiveThumbColor: AppColors.textMuted,
            inactiveTrackColor: AppColors.inputBorder,
          ),
        ],
      ),
    );
  }

  Widget _buildNavTile(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha((0.1 * 255).round()),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primaryLight, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(title,
                  style: GoogleFonts.inter(
                      color: _textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
            ),
            Icon(Icons.chevron_right, color: _subtitleColor, size: 20),
          ],
        ),
      ),
    );
  }

  void _showEditNameDialog(BuildContext context) {
    final controller = TextEditingController(text: _userName);
    String selectedRole = _userRole;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Edit Profile',
              style: GoogleFonts.inter(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Full Name',
                  style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.inputBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.inputBorder),
                ),
                child: TextField(
                  controller: controller,
                  style: GoogleFonts.inter(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Enter your full name',
                    hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    prefixIcon: const Icon(Icons.person_outline,
                        color: AppColors.textMuted, size: 20),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Role',
                  style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: ['Student', 'Teacher'].map((role) {
                  final isSelected = selectedRole == role;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setDialogState(() => selectedRole = role),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin:
                            EdgeInsets.only(right: role == 'Student' ? 8 : 0),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.inputBorder,
                          ),
                        ),
                        child: Text(
                          role,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            color:
                                isSelected ? Colors.white : AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: GoogleFonts.inter(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = controller.text.trim();
                if (newName.isNotEmpty) {
                  setState(() {
                    _userName = newName;
                    _userRole = selectedRole;
                  });
                  final uid = FirebaseAuth.instance.currentUser?.uid;
                  if (uid != null) {
                    await FirestoreService.updateUserProfile(
                        uid, newName, selectedRole);
                  }
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              child:
                  Text('Save', style: GoogleFonts.inter(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showVehicleSheet(BuildContext context) {
    final plateCtrl = TextEditingController(text: _vehicle?['plate'] ?? '');
    final modelCtrl = TextEditingController(text: _vehicle?['model'] ?? '');
    String vehicleType = _vehicle?['type'] ?? 'car';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: StatefulBuilder(
          builder: (ctx, setSheet) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Vehicle',
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18),
              ),
              const SizedBox(height: 6),
              Text(
                'One vehicle per account. Updates saved to your profile.',
                style: GoogleFonts.inter(
                    color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 20),
              // Vehicle type toggle
              Row(
                children: ['car', 'bike'].map((t) {
                  final isSelected = vehicleType == t;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setSheet(() => vehicleType = t),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: EdgeInsets.only(right: t == 'car' ? 8 : 0),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.inputBorder,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              t == 'car'
                                  ? Icons.directions_car
                                  : Icons.two_wheeler,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textMuted,
                              size: 20,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              t == 'car' ? 'Car' : 'Bike',
                              style: GoogleFonts.inter(
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.textMuted,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              _sheetField(plateCtrl, 'Number Plate (e.g. MH-04-AB-1234)',
                  Icons.badge_outlined),
              const SizedBox(height: 12),
              _sheetField(
                  modelCtrl, 'Model (e.g. Honda City)', Icons.car_repair),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final plate = plateCtrl.text.trim().toUpperCase();
                    final model = modelCtrl.text.trim();
                    if (plate.isEmpty || model.isEmpty) return;
                    final uid = FirebaseAuth.instance.currentUser?.uid;
                    if (uid != null) {
                      await FirestoreService.setVehicle(uid,
                          plate: plate, type: vehicleType, model: model);
                      setState(() => _vehicle = {
                            'plate': plate,
                            'type': vehicleType,
                            'model': model
                          });
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Vehicle saved!',
                            style: GoogleFonts.inter(color: Colors.white)),
                        backgroundColor: AppColors.green,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text('Save Vehicle',
                      style: GoogleFonts.inter(
                          color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetField(TextEditingController ctrl, String hint, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.inputBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: TextField(
        controller: ctrl,
        style: GoogleFonts.inter(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
        ),
      ),
    );
  }

  void _showPasswordDialog(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Reset Password',
          style: GoogleFonts.inter(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A password reset link will be sent to:',
              style: GoogleFonts.inter(
                  color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.inputBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.primary.withAlpha(100)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.email_outlined,
                      color: AppColors.primaryLight, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      email.isNotEmpty ? email : 'No email found',
                      style: GoogleFonts.inter(
                        color: email.isNotEmpty
                            ? Colors.white
                            : AppColors.red,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Check your inbox (and spam folder) after tapping Send.',
              style: GoogleFonts.inter(
                  color: AppColors.textMuted, fontSize: 11, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: email.isEmpty
                ? null
                : () async {
                    Navigator.pop(ctx);
                    try {
                      await AuthService.sendPasswordReset(email);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Reset link sent to $email',
                              style:
                                  GoogleFonts.inter(color: Colors.white),
                            ),
                            backgroundColor: AppColors.green,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Failed to send reset email. Try again.',
                              style:
                                  GoogleFonts.inter(color: Colors.white),
                            ),
                            backgroundColor: AppColors.red,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      }
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  email.isEmpty ? AppColors.textMuted : AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Send Link',
                style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Contact Support',
            style: GoogleFonts.inter(
                color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📧 support@apsit.edu.in',
                style: GoogleFonts.inter(
                    color: AppColors.textSecondary, fontSize: 14)),
            const SizedBox(height: 8),
            Text('📞 +91 22 1234 5678',
                style: GoogleFonts.inter(
                    color: AppColors.textSecondary, fontSize: 14)),
            const SizedBox(height: 8),
            Text('🕘 Mon–Fri, 9:00 AM – 5:00 PM',
                style: GoogleFonts.inter(
                    color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close',
                style: GoogleFonts.inter(color: AppColors.primaryLight)),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'APSIT Smart Park',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2024 APSIT. All rights reserved.',
      children: [
        const SizedBox(height: 12),
        Text(
          'A smart campus parking management solution powered by APSIT.',
          style: GoogleFonts.inter(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Logout?',
            style: GoogleFonts.inter(
                color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to logout from APSIT Smart Park?',
          style: GoogleFonts.inter(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthService.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.red,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            child:
                Text('Logout', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
