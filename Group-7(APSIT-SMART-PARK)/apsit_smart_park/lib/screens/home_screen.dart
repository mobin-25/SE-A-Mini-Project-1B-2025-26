import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../main.dart';
import '../models/parking_slot_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'bookings_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  int _availableCount(List<ParkingSlotModel> all) =>
      all.where((s) => s.status == SlotStatus.available).length;

  @override
  void dispose() {
    super.dispose();
  }

  bool get _isDark => themeNotifier.value == ThemeMode.dark;
  Color get _bg => _isDark ? AppColors.background : Colors.white;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, __) {
        return StreamBuilder<List<ParkingSlotModel>>(
          stream: FirestoreService.getParkingSlots(),
          builder: (context, snapshot) {
            final allSlots = snapshot.data ?? [];
            return Scaffold(
              backgroundColor: _bg,
              body: IndexedStack(
                index: _currentIndex,
                children: [
                  _buildMainContent(allSlots),
                  const BookingsScreen(embedded: true),
                  const HistoryScreen(embedded: true),
                  const SettingsScreen(embedded: true),
                ],
              ),
              bottomNavigationBar: _buildNavBar(),
            );
          },
        );
      },
    );
  }

  Widget _buildMainContent(List<ParkingSlotModel> allSlots) {
    return SafeArea(
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildParkingGrid(allSlots),
                  const SizedBox(height: 12),
                  _buildLegend(),
                  const SizedBox(height: 20),
                  _buildBottomInfo(allSlots, allSlots),
                  const SizedBox(height: 10),
                  _buildInfoCards(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pushNamed('/profile'),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 22),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'APSIT Parking',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'LIVE',
                    style: GoogleFonts.inter(
                      color: AppColors.green,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.of(context).pushNamed('/parking-map'),
            child: Container(
              width: 44,
              height: 44,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.inputBorder),
              ),
              child:
                  const Icon(Icons.map_outlined, color: Colors.white, size: 22),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).pushNamed('/alerts'),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.inputBorder),
              ),
              child: Stack(
                children: [
                  const Center(
                    child: Icon(Icons.notifications_outlined,
                        color: Colors.white, size: 22),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                          color: AppColors.red, shape: BoxShape.circle),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildParkingGrid(List<ParkingSlotModel> allSlots) {
    // Zone slot counts
    final staffCarSlots =
        allSlots.where((s) => s.zone == ParkingZone.staffCar).toList();
    final studentBikeSlots =
        allSlots.where((s) => s.zone == ParkingZone.studentBike).toList();
    final staffBikeSlots =
        allSlots.where((s) => s.zone == ParkingZone.staffBike).toList();
    final commonSlots =
        allSlots.where((s) => s.zone == ParkingZone.common).toList();

    int avail(List<ParkingSlotModel> z) =>
        z.where((s) => s.status == SlotStatus.available).length;

    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed('/parking-map'),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D1B35), Color(0xFF0A0E1A)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withOpacity(0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(19)),
                border: Border(
                  bottom:
                      BorderSide(color: AppColors.primary.withOpacity(0.2)),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_parking,
                      color: AppColors.primaryLight, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'APSIT CAMPUS PARKING MAP',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.map_outlined,
                            size: 12, color: AppColors.primaryLight),
                        const SizedBox(width: 4),
                        Text(
                          'View Map',
                          style: GoogleFonts.inter(
                            color: AppColors.primaryLight,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Visual campus layout preview
            Padding(
              padding: const EdgeInsets.all(12),
              child: allSlots.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        // TOP SECTION: Left car + Right bikes
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Staff Car (Left)
                              Expanded(
                                flex: 4,
                                child: _buildMapZonePreview(
                                  label: 'STAFF CARS',
                                  icon: Icons.directions_car,
                                  color: AppColors.amber,
                                  available: avail(staffCarSlots),
                                  total: 30,
                                  slots: staffCarSlots,
                                  crossAxisCount: 3,
                                ),
                              ),
                              // Divider lane
                              Container(
                                width: 16,
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A2540),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: List.generate(
                                    4,
                                    (_) => Container(
                                      height: 8,
                                      width: 3,
                                      color:
                                          AppColors.amber.withOpacity(0.4),
                                    ),
                                  ),
                                ),
                              ),
                              // Bikes Column (Right)
                              Expanded(
                                flex: 6,
                                child: Column(
                                  children: [
                                    _buildMapZonePreview(
                                      label: 'STUDENT BIKES',
                                      icon: Icons.two_wheeler,
                                      color: AppColors.primaryLight,
                                      available: avail(studentBikeSlots),
                                      total: 100,
                                      slots: studentBikeSlots.take(30).toList(),
                                      crossAxisCount: 6,
                                    ),
                                    const SizedBox(height: 4),
                                    _buildMapZonePreview(
                                      label: 'STAFF BIKES',
                                      icon: Icons.two_wheeler,
                                      color: AppColors.purple,
                                      available: avail(staffBikeSlots),
                                      total: 25,
                                      slots: staffBikeSlots,
                                      crossAxisCount: 5,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Drive road
                        Container(
                          height: 14,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A2540),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(
                              10,
                              (_) => Container(
                                width: 12,
                                height: 2,
                                color: AppColors.amber.withOpacity(0.4),
                              ),
                            ),
                          ),
                        ),
                        // COMMON PARKING (Bottom)
                        _buildMapZonePreview(
                          label: 'COMMON PARKING · STUDENTS & STAFF',
                          icon: Icons.local_parking,
                          color: AppColors.green,
                          available: avail(commonSlots),
                          total: 100,
                          slots: commonSlots.take(48).toList(),
                          crossAxisCount: 8,
                        ),
                      ],
                    ),
            ),

            // "Tap to book" CTA footer
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(19)),
                border: Border(
                  top: BorderSide(
                      color: AppColors.primary.withOpacity(0.15)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.touch_app_outlined,
                      color: AppColors.primaryLight, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Tap any slot on the map to Book',
                    style: GoogleFonts.inter(
                      color: AppColors.primaryLight,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_ios,
                      color: AppColors.primaryLight, size: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapZonePreview({
    required String label,
    required IconData icon,
    required Color color,
    required int available,
    required int total,
    required List<ParkingSlotModel> slots,
    required int crossAxisCount,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(7, 6, 7, 4),
            child: Row(
              children: [
                Icon(icon, color: color, size: 10),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.inter(
                      color: color,
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '$available/$total',
                  style: GoogleFonts.inter(
                    color: color,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(5, 0, 5, 5),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
                childAspectRatio: 1.3,
              ),
              itemCount: slots.length,
              itemBuilder: (_, i) {
                final s = slots[i];
                final c = _slotBorderColor(s.status);
                return Container(
                  decoration: BoxDecoration(
                    color: _slotBgColor(s.status),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: c, width: 0.8),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _slotBgColor(SlotStatus status) {
    switch (status) {
      case SlotStatus.available:
        return AppColors.slotAvailable;
      case SlotStatus.occupied:
        return AppColors.slotOccupied;
      case SlotStatus.reserved:
        return AppColors.slotReserved;
      case SlotStatus.faculty:
        return AppColors.slotFaculty;
    }
  }

  Color _slotBorderColor(SlotStatus status) {
    switch (status) {
      case SlotStatus.available:
        return AppColors.slotAvailableBorder;
      case SlotStatus.occupied:
        return AppColors.slotOccupiedBorder;
      case SlotStatus.reserved:
        return AppColors.slotReservedBorder;
      case SlotStatus.faculty:
        return AppColors.slotFacultyBorder;
    }
  }


  Widget _buildBottomInfo(
      List<ParkingSlotModel> allSlots, List<ParkingSlotModel> filteredSlots) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_availableCount(allSlots)} Slots Available',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'Nearby APSIT Wing-C Entrance',
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const Spacer(),
        ElevatedButton(
          onPressed: () {
            final available = filteredSlots
                .where((s) => s.status == SlotStatus.available)
                .toList();
            if (available.isNotEmpty) {
              Navigator.of(context).pushNamed('/parking-map');
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'No slots available!',
                    style: GoogleFonts.inter(color: Colors.white),
                  ),
                  backgroundColor: AppColors.red,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
          child: Text(
            'Reserve\nNow',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCards() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.inputBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.timer_outlined,
                      color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TIME LIMIT',
                        style: GoogleFonts.inter(
                          color: AppColors.textMuted,
                          fontSize: 10,
                          letterSpacing: 0.8,
                        )),
                    Text('4 Hours',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        )),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.inputBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.money_off,
                      color: AppColors.green, size: 22),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('STAFF COST',
                        style: GoogleFonts.inter(
                          color: AppColors.textMuted,
                          fontSize: 10,
                          letterSpacing: 0.8,
                        )),
                    Text('Free',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        )),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavBar() {
    final items = [
      {'icon': Icons.home_outlined, 'activeIcon': Icons.home, 'label': 'Home'},
      {
        'icon': Icons.confirmation_number_outlined,
        'activeIcon': Icons.confirmation_number,
        'label': 'Bookings',
      },
      {
        'icon': Icons.history,
        'activeIcon': Icons.history,
        'label': 'History',
      },
      {
        'icon': Icons.settings_outlined,
        'activeIcon': Icons.settings,
        'label': 'Settings',
      },
    ];

    final navBg = _isDark ? AppColors.navBarBg : Colors.white;
    final navBorder = _isDark ? AppColors.divider : const Color(0xFFE2E8F0);
    final inactiveColor = _isDark ? AppColors.textMuted : const Color(0xFF94A3B8);

    return Container(
      decoration: BoxDecoration(
        color: navBg,
        border: Border(top: BorderSide(color: navBorder)),
      ),
      child: Row(
        children: List.generate(items.length, (i) {
          final isActive = _currentIndex == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _currentIndex = i),
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
                      color: isActive ? AppColors.primary : inactiveColor,
                      size: 26,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      items[i]['label'] as String,
                      style: GoogleFonts.inter(
                        color: isActive ? AppColors.primary : inactiveColor,
                        fontSize: 11,
                        fontWeight:
                            isActive ? FontWeight.w700 : FontWeight.w400,
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

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SLOT STATUS MEANING',
            style: GoogleFonts.inter(
              color: AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _legendItem(AppColors.slotAvailableBorder, 'Available'),
              _legendItem(AppColors.slotOccupiedBorder, 'Occupied'),
              _legendItem(AppColors.slotReservedBorder, 'Reserved'),
              _legendItem(AppColors.slotFacultyBorder, 'Faculty'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

// Needs to be imported in slot_detail_sheet
class SlotDetailSheet extends StatefulWidget {
  final ParkingSlotModel slot;
  const SlotDetailSheet({super.key, required this.slot});

  @override
  State<SlotDetailSheet> createState() => _SlotDetailSheetState();
}

class _SlotDetailSheetState extends State<SlotDetailSheet> {
  int _selectedDuration = 0;
  final List<String> _durations = ['1h', '2h', '4h', 'Max'];

  bool get _isFacultySlot => widget.slot.status == SlotStatus.faculty;
  bool get _isAvailable => widget.slot.status == SlotStatus.available;

  Color get _borderColor {
    switch (widget.slot.status) {
      case SlotStatus.available:
        return AppColors.slotAvailableBorder;
      case SlotStatus.occupied:
        return AppColors.slotOccupiedBorder;
      case SlotStatus.reserved:
        return AppColors.slotReservedBorder;
      case SlotStatus.faculty:
        return AppColors.slotFacultyBorder;
    }
  }

  String get _statusText {
    switch (widget.slot.status) {
      case SlotStatus.available:
        return 'Available';
      case SlotStatus.occupied:
        return 'Occupied';
      case SlotStatus.reserved:
        return 'Reserved';
      case SlotStatus.faculty:
        return 'Faculty Only';
    }
  }

  void _reserve() async {
    if (!_isAvailable && !_isFacultySlot) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('This slot is not available!',
            style: GoogleFonts.inter(color: Colors.white)),
        backgroundColor: AppColors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }

    // Write to Firestore
    final uid = AuthService.currentUser?.uid;
    if (uid != null) {
      try {
        await FirestoreService.reserveSlot(widget.slot.id, uid);
      } catch (_) {}
    }

    if (context.mounted) {
      Navigator.pop(context);
      Navigator.of(context).pushNamed(
        '/reservation',
        arguments: {
          'slotId': widget.slot.id,
          'duration': _durations[_selectedDuration],
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      builder: (ctx, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: CustomScrollView(
            controller: scrollCtrl,
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 20),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.inputBorder,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Slot ${widget.slot.id}',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on_outlined,
                                      color: AppColors.textSecondary,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'APSIT ${_isFacultySlot ? "East" : "North"} Wing • Campus ${widget.slot.vehicleType == VehicleType.car ? "A" : "B"}',
                                      style: GoogleFonts.inter(
                                        color: AppColors.textSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: AppColors.primary
                                  .withAlpha((0.15 * 255).round()),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primary
                                    .withAlpha((0.4 * 255).round()),
                              ),
                            ),
                            child: Icon(
                              widget.slot.vehicleType == VehicleType.car
                                  ? Icons.directions_car
                                  : Icons.two_wheeler,
                              color: AppColors.primaryLight,
                              size: 26,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _borderColor.withAlpha((0.12 * 255).round()),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _borderColor.withAlpha((0.5 * 255).round()),
                          ),
                        ),
                        child: Text(
                          _statusText,
                          style: GoogleFonts.inter(
                            color: _borderColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(height: 1, color: AppColors.divider),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          _buildDetailRow(Icons.grid_view, 'Zone',
                              _isFacultySlot ? 'East Wing' : 'North Wing'),
                          const SizedBox(height: 16),
                          _buildDetailRow(
                            Icons.category_outlined,
                            'Vehicle Type',
                            widget.slot.vehicleType == VehicleType.car
                                ? 'Car (LVM)'
                                : 'Bike',
                          ),
                        ],
                      ),
                    ),
                    if (_isFacultySlot) ...[
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color:
                                AppColors.purple.withAlpha((0.1 * 255).round()),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.purple
                                  .withAlpha((0.4 * 255).round()),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.lock_outline,
                                      color: AppColors.purple, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Faculty Only Area',
                                    style: GoogleFonts.inter(
                                      color: AppColors.purple,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'This zone is restricted to APSIT staff during 08:00 AM - 04:00 PM.',
                                style: GoogleFonts.inter(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Text(
                            'Reservation Duration',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Valid for 4 hours',
                            style: GoogleFonts.inter(
                              color: AppColors.primaryLight,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: List.generate(
                          _durations.length,
                          (i) => Padding(
                            padding: EdgeInsets.only(
                              right: i < _durations.length - 1 ? 10 : 0,
                            ),
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedDuration = i),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 65,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: _selectedDuration == i
                                      ? Colors.transparent
                                      : AppColors.surfaceLight,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _selectedDuration == i
                                        ? AppColors.primary
                                        : AppColors.inputBorder,
                                    width: _selectedDuration == i ? 2 : 1,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    _durations[i],
                                    style: GoogleFonts.inter(
                                      color: _selectedDuration == i
                                          ? AppColors.primaryLight
                                          : AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed:
                                  widget.slot.status == SlotStatus.occupied
                                      ? null
                                      : _reserve,
                              icon: const Icon(
                                Icons.check_circle_outline,
                                color: Colors.white,
                                size: 20,
                              ),
                              label: Text(
                                'Reserve Now',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    widget.slot.status == SlotStatus.occupied
                                        ? AppColors.inputBorder
                                        : AppColors.primary,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 6,
                                shadowColor: AppColors.primary
                                    .withAlpha((0.4 * 255).round()),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.inputBorder),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.share_outlined,
                                  color: Colors.white, size: 20),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Slot ${widget.slot.id} link copied!',
                                      style: GoogleFonts.inter(
                                          color: Colors.white),
                                    ),
                                    backgroundColor: AppColors.surfaceLight,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.textSecondary, size: 18),
        ),
        const SizedBox(width: 14),
        Text(label,
            style: GoogleFonts.inter(
                color: AppColors.textSecondary, fontSize: 15)),
        const Spacer(),
        Text(value,
            style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15)),
      ],
    );
  }
}
