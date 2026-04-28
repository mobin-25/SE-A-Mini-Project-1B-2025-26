import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/release_slot_dialog.dart';

class ReservationScreen extends StatefulWidget {
  const ReservationScreen({super.key});

  @override
  State<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> {
  Timer? _timer;
  int _minutes = 0;
  int _seconds = 0;
  int _currentIndex = 1;
  bool _timerStarted = false;
  String? _vehiclePlate;
  bool _loadingVehicle = true;

  // ─── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadVehicle();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Start timer exactly once after context/route args are available
    if (!_timerStarted) {
      _timerStarted = true;
      final args = ModalRoute.of(context)?.settings.arguments
          as Map<String, dynamic>?;
      final durationStr = args?['duration'] as String? ?? '1 Hour';
      _minutes = _parseDurationToMinutes(durationStr);
      _seconds = 0;
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  int _parseDurationToMinutes(String d) {
    if (d.contains('30')) return 30;
    if (d.contains('2 Hour')) return 120;
    if (d.contains('4 Hour')) return 240;
    return 60; // default: 1 Hour
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        if (_seconds > 0) {
          _seconds--;
        } else if (_minutes > 0) {
          _minutes--;
          _seconds = 59;
        } else {
          t.cancel();
          _showExpiredDialog();
        }
      });
    });
  }

  Future<void> _loadVehicle() async {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) {
      setState(() => _loadingVehicle = false);
      return;
    }
    try {
      final vehicle = await FirestoreService.getVehicle(uid);
      if (mounted) {
        setState(() {
          _vehiclePlate = vehicle?['plate'] as String?;
          _loadingVehicle = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingVehicle = false);
    }
  }

  String _zoneFromSlotId(String slotId) {
    if (slotId.startsWith('SC')) return 'Staff Car Zone';
    if (slotId.startsWith('SB')) return 'Student Bike Zone';
    if (slotId.startsWith('FB')) return 'Staff Bike Zone';
    if (slotId.startsWith('CP')) return 'Common Parking';
    return 'APSIT Campus';
  }

  void _showExpiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Reservation Expired',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Your parking slot reservation has expired. Please re-book a slot.',
          style: GoogleFonts.inter(color: AppColors.textSecondary),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).pushReplacementNamed('/home');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Book Again',
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _releaseSlot(String slotId) {
    ReleaseSlotDialog.show(context, slotId: slotId, onRelease: () async {
      _timer?.cancel();
      try {
        await FirestoreService.releaseSlot(slotId);
      } catch (_) {}
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/home');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Slot $slotId released successfully!',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          backgroundColor: AppColors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    });
  }

  void _navigate(String slotId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Opening navigation to Slot $slotId…',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments
        as Map<String, dynamic>?;
    final slotId = args?['slotId'] as String? ?? 'A-05';
    final plateDisplay =
        _loadingVehicle ? '…' : (_vehiclePlate ?? '—');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                // ── App bar ─────────────────────────────────────────────
                SliverAppBar(
                  backgroundColor: AppColors.background,
                  pinned: true,
                  leading: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                  title: Text(
                    'My Reservation',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  centerTitle: true,
                ),

                // ── Map preview ─────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Container(
                    height: 200,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1A3A5C), Color(0xFF0D2137)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.inputBorder),
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: CustomPaint(
                            size: const Size(double.infinity, 200),
                            painter: _MapGridPainter(),
                          ),
                        ),
                        Positioned(
                          bottom: 30,
                          left: 40,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'APSIT Campus',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 40,
                          right: 50,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF065F46),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Thane',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 14,
                          left: 14,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'ACTIVE NOW',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                        const Center(
                          child: Icon(
                            Icons.location_pin,
                            color: AppColors.red,
                            size: 48,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Details ─────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),

                        // Slot info card
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.inputBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'PARKING SLOT',
                                    style: GoogleFonts.inter(
                                      color: AppColors.textMuted,
                                      fontSize: 11,
                                      letterSpacing: 1,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary
                                          .withOpacity(0.15),
                                      borderRadius:
                                          BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.directions_car,
                                      color: AppColors.primaryLight,
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Slot $slotId',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  _buildInfoChip(
                                    'Vehicle Plate',
                                    plateDisplay,
                                  ),
                                  const SizedBox(width: 24),
                                  _buildInfoChip(
                                    'Campus Zone',
                                    _zoneFromSlotId(slotId),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Timer card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.inputBorder),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'TIME REMAINING',
                                style: GoogleFonts.inter(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                  letterSpacing: 1.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildTimerBox(
                                    _minutes.toString().padLeft(2, '0'),
                                    'MINUTES',
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    child: Text(
                                      ':',
                                      style: GoogleFonts.inter(
                                        color: AppColors.primaryLight,
                                        fontSize: 40,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  _buildTimerBox(
                                    _seconds.toString().padLeft(2, '0'),
                                    'SECONDS',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Navigate button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: () => _navigate(slotId),
                            icon: const Icon(
                              Icons.navigation,
                              color: Colors.white,
                              size: 22,
                            ),
                            label: Text(
                              'Navigate to Slot',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 6,
                              shadowColor:
                                  AppColors.primary.withOpacity(0.4),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Release button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: OutlinedButton.icon(
                            onPressed: () => _releaseSlot(slotId),
                            icon: const Icon(
                              Icons.cancel_outlined,
                              color: AppColors.red,
                              size: 22,
                            ),
                            label: Text(
                              'Release Slot',
                              style: GoogleFonts.inter(
                                color: AppColors.red,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: AppColors.red.withOpacity(0.4),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              backgroundColor:
                                  AppColors.red.withOpacity(0.05),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Info notice
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: AppColors.primaryLight,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Please release the slot before leaving the campus. Your booking expires in $_minutes minutes.',
                                  style: GoogleFonts.inter(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildBottomNav(),
        ],
      ),
    );
  }

  // ─── Sub-widgets ───────────────────────────────────────────────────────────

  Widget _buildInfoChip(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildTimerBox(String value, String label) {
    return Column(
      children: [
        Container(
          width: 90,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: Center(
            child: Text(
              value,
              style: GoogleFonts.inter(
                color: AppColors.primaryLight,
                fontSize: 40,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            color: AppColors.textMuted,
            fontSize: 10,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    final items = [
      {'icon': Icons.map_outlined, 'activeIcon': Icons.map, 'label': 'Map'},
      {
        'icon': Icons.confirmation_number_outlined,
        'activeIcon': Icons.confirmation_number,
        'label': 'Bookings',
      },
      {
        'icon': Icons.person_outline,
        'activeIcon': Icons.person,
        'label': 'Profile',
      },
      {
        'icon': Icons.settings_outlined,
        'activeIcon': Icons.settings,
        'label': 'Settings',
      },
    ];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.navBarBg,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: List.generate(items.length, (i) {
          final isActive = _currentIndex == i;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (i == 0) Navigator.of(context).pushNamed('/parking-map');
                if (i == 1) Navigator.of(context).pushNamed('/bookings');
                if (i == 2) Navigator.of(context).pushNamed('/profile');
                if (i == 3) Navigator.of(context).pushNamed('/settings');
                setState(() => _currentIndex = i);
              },
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isActive
                          ? items[i]['activeIcon'] as IconData
                          : items[i]['icon'] as IconData,
                      color: isActive
                          ? AppColors.primary
                          : AppColors.textMuted,
                      size: 26,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      items[i]['label'] as String,
                      style: GoogleFonts.inter(
                        color: isActive
                            ? AppColors.primary
                            : AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: isActive
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─── Map grid painter ──────────────────────────────────────────────────────

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1E3A5C).withOpacity(0.5)
      ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    final roadPaint = Paint()
      ..color = const Color(0xFF1E4A6E)
      ..strokeWidth = 8;
    canvas.drawLine(Offset(0, 120), Offset(size.width, 120), roadPaint);
    canvas.drawLine(
        const Offset(160, 0), const Offset(160, 200), roadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
