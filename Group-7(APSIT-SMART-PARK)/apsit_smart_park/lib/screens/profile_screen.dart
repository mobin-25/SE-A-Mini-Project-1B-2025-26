import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../main.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class ProfileScreen extends StatefulWidget {
  final bool embedded;
  const ProfileScreen({super.key, this.embedded = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsEnabled = true;
  String _userName = 'APSIT User';
  String _userRole = 'Student';
  Map<String, dynamic>? _vehicle;
  bool _loadingProfile = true;

  bool get _isDark => themeNotifier.value == ThemeMode.dark;
  Color get _bg => _isDark ? AppColors.background : Colors.white;
  Color get _cardBg =>
      _isDark ? AppColors.surfaceLight : const Color(0xFFF3F4F6);
  Color get _textColor => _isDark ? Colors.white : const Color(0xFF0F172A);
  Color get _subtitleColor =>
      _isDark ? AppColors.textMuted : const Color(0xFF64748B);
  Color get _borderColor =>
      _isDark ? AppColors.inputBorder : const Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = AuthService.currentUser;
    if (user == null) {
      setState(() => _loadingProfile = false);
      return;
    }
    final profile = await FirestoreService.getUser(user.uid);
    final vehicle = await FirestoreService.getVehicle(user.uid);
    if (mounted) {
      setState(() {
        if (profile != null) {
          _userName = profile.name;
          _userRole = profile.role;
        }
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

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, __) {
        return Scaffold(
          backgroundColor: _bg,
          appBar: AppBar(
            backgroundColor: _bg,
            elevation: 0,
            leading: widget.embedded
                ? null
                : IconButton(
                    icon: Icon(Icons.arrow_back_ios_new,
                        color: _textColor, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
            title: Text(
              'Profile',
              style: GoogleFonts.inter(
                color: _textColor,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(Icons.settings_outlined, color: _textColor, size: 22),
                onPressed: () => Navigator.of(context).pushNamed('/settings'),
              ),
            ],
          ),
          body: _loadingProfile
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary))
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      // Avatar + name
                      Center(
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: AppColors.primary, width: 3),
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF1E3A8A),
                                        Color(0xFF1D4ED8)
                                      ],
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      _initials(_userName),
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 36,
                                          fontWeight: FontWeight.w900),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 2,
                                  right: 2,
                                  child: GestureDetector(
                                    onTap: () =>
                                        _showEditNameDialog(context),
                                    child: Container(
                                      width: 30,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: _bg, width: 2),
                                      ),
                                      child: const Icon(Icons.edit,
                                          color: Colors.white, size: 14),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            GestureDetector(
                              onTap: () => _showEditNameDialog(context),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _userName,
                                    style: GoogleFonts.inter(
                                      color: _textColor,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(Icons.edit_outlined,
                                      color: _subtitleColor, size: 16),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _userRole,
                              style: GoogleFonts.inter(
                                  color: _subtitleColor, fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              AuthService.currentUser?.email ??
                                  'smartpark@apsit.edu.in',
                              style: GoogleFonts.inter(
                                  color: _subtitleColor, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),

                      // My Vehicle (one per account)
                      Row(
                        children: [
                          Text(
                            'My Vehicle',
                            style: GoogleFonts.inter(
                              color: _textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => _showVehicleSheet(context),
                            child: Row(
                              children: [
                                const Icon(Icons.edit_outlined,
                                    color: AppColors.primaryLight, size: 17),
                                const SizedBox(width: 4),
                                Text(
                                  _vehicle == null ? 'Add Vehicle' : 'Edit',
                                  style: GoogleFonts.inter(
                                    color: AppColors.primaryLight,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildVehicleSection(),
                      const SizedBox(height: 28),

                      // Account Settings
                      Text(
                        'Account Settings',
                        style: GoogleFonts.inter(
                          color: _textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: _cardBg,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: _borderColor),
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              child: Row(
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: _isDark
                                          ? AppColors.surfaceLight
                                          : const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(Icons.notifications_outlined,
                                        color: _subtitleColor, size: 20),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text('Notifications',
                                        style: GoogleFonts.inter(
                                            color: _textColor,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15)),
                                  ),
                                  Switch(
                                    value: _notificationsEnabled,
                                    onChanged: (v) => setState(
                                        () => _notificationsEnabled = v),
                                    activeThumbColor: Colors.white,
                                    activeTrackColor: AppColors.primary,
                                  ),
                                ],
                              ),
                            ),
                            Divider(height: 1, color: _borderColor),
                            // Night Mode toggle — wired to global themeNotifier
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              child: Row(
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: _isDark
                                          ? AppColors.surfaceLight
                                          : const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(Icons.dark_mode_outlined,
                                        color: _subtitleColor, size: 20),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text('Night Mode',
                                        style: GoogleFonts.inter(
                                            color: _textColor,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15)),
                                  ),
                                  ValueListenableBuilder<ThemeMode>(
                                    valueListenable: themeNotifier,
                                    builder: (context, m, _) {
                                      return Switch(
                                        value: m == ThemeMode.dark,
                                        onChanged: (v) {
                                          themeNotifier.value = v
                                              ? ThemeMode.dark
                                              : ThemeMode.light;
                                        },
                                        activeThumbColor: Colors.white,
                                        activeTrackColor: AppColors.primary,
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            Divider(height: 1, color: _borderColor),
                            _buildNavRow(
                              context,
                              Icons.history,
                              'Parking History',
                              () => Navigator.of(context).pushNamed('/history'),
                            ),
                            Divider(height: 1, color: _borderColor),
                            _buildNavRow(
                              context,
                              Icons.credit_card_outlined,
                              'Payment Methods',
                              () => _showPaymentMethods(context),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Logout
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
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: AppColors.red.withOpacity(0.08),
                            side: BorderSide(
                                color: AppColors.red.withOpacity(0.35)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          'APSIT Smart Park v1.0.0',
                          style: GoogleFonts.inter(
                              color: _subtitleColor, fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
          bottomNavigationBar:
              widget.embedded ? null : _buildBottomNav(context),
        );
      },
    );
  }

  Widget _buildVehicleSection() {
    if (_vehicle == null) {
      return GestureDetector(
        onTap: () => _showVehicleSheet(context),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _borderColor, style: BorderStyle.solid),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_outline,
                  color: AppColors.primaryLight, size: 22),
              const SizedBox(width: 10),
              Text(
                'Add your vehicle',
                style: GoogleFonts.inter(
                  color: AppColors.primaryLight,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final typeIcon = _vehicle!['type'] == 'bike'
        ? Icons.two_wheeler
        : Icons.directions_car;
    final plate = _vehicle!['plate'] ?? '';
    final model = _vehicle!['model'] ?? '';
    final type = (_vehicle!['type'] ?? 'car') == 'bike' ? 'Bike' : 'Car';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(typeIcon, color: AppColors.primaryLight, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(plate,
                    style: GoogleFonts.inter(
                        color: _textColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
                Text('$model • $type',
                    style: GoogleFonts.inter(
                        color: _subtitleColor, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit_outlined, color: _subtitleColor, size: 20),
            onPressed: () => _showVehicleSheet(context),
          ),
        ],
      ),
    );
  }

  Widget _buildNavRow(
      BuildContext context, IconData icon, String label, VoidCallback onTap) {
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
                color: _isDark
                    ? AppColors.background
                    : const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: _subtitleColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: GoogleFonts.inter(
                      color: _textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 15)),
            ),
            Icon(Icons.chevron_right, color: _subtitleColor, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    final items = [
      {'icon': Icons.map_outlined, 'label': 'Map'},
      {'icon': Icons.search, 'label': 'Find Space'},
      {'icon': Icons.confirmation_number_outlined, 'label': 'Tickets'},
      {'icon': Icons.person, 'label': 'Profile'},
    ];
    return Container(
      decoration: BoxDecoration(
        color: _isDark ? AppColors.navBarBg : Colors.white,
        border: Border(
            top: BorderSide(
                color: _borderColor)),
      ),
      child: Row(
        children: List.generate(items.length, (i) {
          final isActive = i == 3;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (i == 0) Navigator.of(context).pushNamed('/parking-map');
                if (i == 1) Navigator.of(context).pushNamed('/parking-map');
                if (i == 2) Navigator.of(context).pushNamed('/bookings');
              },
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(items[i]['icon'] as IconData,
                        color: isActive
                            ? AppColors.primary
                            : _subtitleColor,
                        size: 26),
                    const SizedBox(height: 4),
                    Text(items[i]['label'] as String,
                        style: GoogleFonts.inter(
                          color: isActive ? AppColors.primary : _subtitleColor,
                          fontSize: 11,
                          fontWeight:
                              isActive ? FontWeight.w700 : FontWeight.w400,
                        )),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ─── Vehicle Sheet ─────────────────────────────────────────────────────────

  void _showVehicleSheet(BuildContext context) {
    final plateCtrl =
        TextEditingController(text: _vehicle?['plate'] ?? '');
    final modelCtrl =
        TextEditingController(text: _vehicle?['model'] ?? '');
    String vehicleType = _vehicle?['type'] ?? 'car';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _isDark ? AppColors.surface : Colors.white,
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
                    color: _textColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 18),
              ),
              const SizedBox(height: 6),
              Text(
                'One vehicle per account. Updates are saved to your profile.',
                style: GoogleFonts.inter(
                    color: _subtitleColor, fontSize: 12),
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
                              : _cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : _borderColor,
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
                                  : _subtitleColor,
                              size: 20,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              t == 'car' ? 'Car' : 'Bike',
                              style: GoogleFonts.inter(
                                  color: isSelected
                                      ? Colors.white
                                      : _subtitleColor,
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
                    final plate =
                        plateCtrl.text.trim().toUpperCase();
                    final model = modelCtrl.text.trim();
                    if (plate.isEmpty || model.isEmpty) return;
                    final uid =
                        FirebaseAuth.instance.currentUser?.uid;
                    if (uid != null) {
                      await FirestoreService.setVehicle(uid,
                          plate: plate,
                          type: vehicleType,
                          model: model);
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
                            style:
                                GoogleFonts.inter(color: Colors.white)),
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
                          color: Colors.white,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetField(
      TextEditingController ctrl, String hint, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: _isDark ? AppColors.inputBg : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
      ),
      child: TextField(
        controller: ctrl,
        style: GoogleFonts.inter(color: _textColor),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: _subtitleColor),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          prefixIcon: Icon(icon, color: _subtitleColor, size: 20),
        ),
      ),
    );
  }

  // ─── Edit Name Dialog ──────────────────────────────────────────────────────

  void _showEditNameDialog(BuildContext context) {
    final controller = TextEditingController(text: _userName);
    String selectedRole = _userRole;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: _isDark ? AppColors.surface : Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Edit Profile',
              style: GoogleFonts.inter(
                  color: _textColor, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Full Name',
                  style: GoogleFonts.inter(
                      color: _subtitleColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: _isDark
                      ? AppColors.inputBg
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _borderColor),
                ),
                child: TextField(
                  controller: controller,
                  style: GoogleFonts.inter(color: _textColor),
                  decoration: InputDecoration(
                    hintText: 'Enter your full name',
                    hintStyle: GoogleFonts.inter(color: _subtitleColor),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    prefixIcon: Icon(Icons.person_outline,
                        color: _subtitleColor, size: 20),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Role',
                  style: GoogleFonts.inter(
                      color: _subtitleColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: ['Student', 'Teacher'].map((role) {
                  final isSelected = selectedRole == role;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setDialogState(() => selectedRole = role),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: EdgeInsets.only(
                            right: role == 'Student' ? 8 : 0),
                        padding:
                            const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : _cardBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : _borderColor,
                          ),
                        ),
                        child: Text(
                          role,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            color: isSelected
                                ? Colors.white
                                : _subtitleColor,
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
                  style: GoogleFonts.inter(color: _subtitleColor)),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = controller.text.trim();
                if (newName.isNotEmpty) {
                  Navigator.pop(ctx);
                  setState(() {
                    _userName = newName;
                    _userRole = selectedRole;
                  });
                  final uid = AuthService.currentUser?.uid;
                  if (uid != null) {
                    await FirestoreService.updateUserProfile(
                        uid, newName, selectedRole);
                  }
                }
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

  void _showPaymentMethods(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _isDark ? AppColors.surface : Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Payment Methods',
                style: GoogleFonts.inter(
                    color: _textColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 18)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _borderColor),
              ),
              child: Row(
                children: [
                  const Icon(Icons.school_outlined,
                      color: AppColors.primaryLight, size: 24),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('APSIT Campus Wallet',
                          style: GoogleFonts.inter(
                              color: _textColor,
                              fontWeight: FontWeight.w700)),
                      Text('Balance: ₹0.00 (Free for students)',
                          style: GoogleFonts.inter(
                              color: AppColors.green, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
                'Parking is currently free for all APSIT students and staff.',
                style: GoogleFonts.inter(
                    color: _subtitleColor, fontSize: 13, height: 1.5)),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _isDark ? AppColors.surface : Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Logout?',
            style: GoogleFonts.inter(
                color: _textColor, fontWeight: FontWeight.bold)),
        content: Text(
            'Are you sure you want to logout from APSIT Smart Park?',
            style: GoogleFonts.inter(color: _subtitleColor)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: GoogleFonts.inter(color: _subtitleColor))),
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
              child: Text('Logout',
                  style: GoogleFonts.inter(color: Colors.white))),
        ],
      ),
    );
  }
}
