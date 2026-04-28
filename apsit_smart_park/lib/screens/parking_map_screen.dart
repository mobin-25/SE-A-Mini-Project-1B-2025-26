import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../models/parking_slot_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class ParkingMapScreen extends StatefulWidget {
  const ParkingMapScreen({super.key});

  @override
  State<ParkingMapScreen> createState() => _ParkingMapScreenState();
}

class _ParkingMapScreenState extends State<ParkingMapScreen>
    with TickerProviderStateMixin {
  ParkingSlotModel? _selectedSlot;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  final TransformationController _transformCtrl = TransformationController();

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _transformCtrl.dispose();
    super.dispose();
  }

  Color _slotColor(ParkingSlotModel s) {
    if (_selectedSlot?.id == s.id) return AppColors.primary;
    switch (s.status) {
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

  Color _slotBorder(ParkingSlotModel s) {
    if (_selectedSlot?.id == s.id) return AppColors.primaryLight;
    switch (s.status) {
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

  void _onSlotTap(ParkingSlotModel slot) {
    setState(() => _selectedSlot = slot);
    _showSlotBottomSheet(slot);
  }

  void _showSlotBottomSheet(ParkingSlotModel slot) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SlotBookingSheet(
        slot: slot,
        onBooked: () {
          setState(() => _selectedSlot = null);
          Navigator.pop(context);
        },
        onDismiss: () {
          setState(() => _selectedSlot = null);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<List<ParkingSlotModel>>(
        stream: FirestoreService.getParkingSlots(),
        builder: (context, snapshot) {
          final allSlots = snapshot.data ?? [];

          final staffCarSlots =
              allSlots.where((s) => s.zone == ParkingZone.staffCar).toList();
          final studentBikeSlots =
              allSlots.where((s) => s.zone == ParkingZone.studentBike).toList();
          final staffBikeSlots =
              allSlots.where((s) => s.zone == ParkingZone.staffBike).toList();
          final commonSlots =
              allSlots.where((s) => s.zone == ParkingZone.common).toList();

          return Column(
            children: [
              _buildHeader(allSlots),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
                  child: Column(
                    children: [
                      _buildLegend(),
                      const SizedBox(height: 12),
                      _buildStatsBar(allSlots),
                      const SizedBox(height: 16),
                      // ── MAIN CAMPUS MAP LAYOUT ─────────────────────────
                      _buildCampusMapLayout(
                        staffCarSlots: staffCarSlots,
                        studentBikeSlots: studentBikeSlots,
                        staffBikeSlots: staffBikeSlots,
                        commonSlots: commonSlots,
                        loading: !snapshot.hasData,
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(List<ParkingSlotModel> allSlots) {
    final available =
        allSlots.where((s) => s.status == SlotStatus.available).length;
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.inputBorder),
                ),
                child: const Icon(Icons.arrow_back_ios_new,
                    color: Colors.white, size: 18),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'APSIT Campus Parking',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                  Row(
                    children: [
                      ScaleTransition(
                        scale: _pulseAnim,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: AppColors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'LIVE · $available slots free',
                        style: GoogleFonts.inter(
                          color: AppColors.green,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Compass / reset zoom
            GestureDetector(
              onTap: () => setState(() {
                _transformCtrl.value = Matrix4.identity();
              }),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.inputBorder),
                ),
                child: const Icon(Icons.explore_outlined,
                    color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    final items = [
      (AppColors.slotAvailableBorder, 'Available'),
      (AppColors.slotOccupiedBorder, 'Occupied'),
      (AppColors.slotReservedBorder, 'Reserved'),
      (AppColors.slotFacultyBorder, 'Faculty'),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: items
            .map((e) => Row(children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: e.$1,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(e.$2,
                      style: GoogleFonts.inter(
                          color: AppColors.textSecondary, fontSize: 11)),
                ]))
            .toList(),
      ),
    );
  }

  Widget _buildStatsBar(List<ParkingSlotModel> slots) {
    final zones = [
      (ParkingZone.staffCar, '🚗', 'Staff Cars', 30),
      (ParkingZone.studentBike, '🏍', 'Student Bikes', 100),
      (ParkingZone.staffBike, '🏍', 'Staff Bikes', 25),
      (ParkingZone.common, '🅿', 'Common', 100),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: zones.map((z) {
          final zSlots = slots.where((s) => s.zone == z.$1).toList();
          final avail =
              zSlots.where((s) => s.status == SlotStatus.available).length;
          final total = z.$4;
          final pct = total > 0 ? avail / total : 0.0;
          return Container(
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.inputBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(z.$2, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(z.$3,
                        style: GoogleFonts.inter(
                            color: AppColors.textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w500)),
                    Text('$avail/$total free',
                        style: GoogleFonts.inter(
                          color: pct > 0.5
                              ? AppColors.green
                              : pct > 0.2
                                  ? AppColors.amber
                                  : AppColors.red,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        )),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCampusMapLayout({
    required List<ParkingSlotModel> staffCarSlots,
    required List<ParkingSlotModel> studentBikeSlots,
    required List<ParkingSlotModel> staffBikeSlots,
    required List<ParkingSlotModel> commonSlots,
    required bool loading,
  }) {
    return Column(
      children: [
        // ── TOP ROW: Staff Cars (Left) + Student & Staff Bikes (Right) ─────
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── LEFT: STAFF CAR PARKING ──────────────────────────────────
              Expanded(
                flex: 4,
                child: _buildZonePanel(
                  zoneName: 'STAFF\nCAR PARKING',
                  slotCount: 30,
                  icon: Icons.directions_car,
                  zoneColor: AppColors.amber,
                  label: 'SC',
                  slots: staffCarSlots,
                  loading: loading,
                  crossAxisCount: 3,
                ),
              ),
              // ── DRIVE LANE ──────────────────────────────────────────────
              _buildDriveLane(vertical: true),
              // ── RIGHT: BIKE PARKINGS (Student TOP + Staff BOTTOM) ───────
              Expanded(
                flex: 6,
                child: Column(
                  children: [
                    // Student Bike Parking
                    _buildZonePanel(
                      zoneName: 'STUDENT BIKE\nPARKING',
                      slotCount: 100,
                      icon: Icons.two_wheeler,
                      zoneColor: AppColors.primaryLight,
                      label: 'SB',
                      slots: studentBikeSlots,
                      loading: loading,
                      crossAxisCount: 5,
                    ),
                    const SizedBox(height: 4),
                    // Staff Bike Parking
                    _buildZonePanel(
                      zoneName: 'STAFF BIKE\nPARKING',
                      slotCount: 25,
                      icon: Icons.two_wheeler,
                      zoneColor: AppColors.purple,
                      label: 'FB',
                      slots: staffBikeSlots,
                      loading: loading,
                      crossAxisCount: 5,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // ── DRIVE LANE (Horizontal) ──────────────────────────────────────
        _buildDriveLane(vertical: false),
        // ── BOTTOM: COMMON PARKING ──────────────────────────────────────
        _buildZonePanel(
          zoneName: 'COMMON PARKING · STUDENTS & STAFF',
          slotCount: 100,
          icon: Icons.local_parking,
          zoneColor: AppColors.green,
          label: 'CP',
          slots: commonSlots,
          loading: loading,
          crossAxisCount: 8,
          fullWidth: true,
        ),
      ],
    );
  }

  Widget _buildDriveLane({required bool vertical}) {
    if (vertical) {
      return Container(
        width: 24,
        margin: const EdgeInsets.symmetric(vertical: 0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Container(
                width: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2540),
                  border: Border.symmetric(
                    vertical: BorderSide(
                        color: AppColors.amber.withOpacity(0.4), width: 1),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    6,
                    (_) => Container(
                      height: 14,
                      width: 3,
                      color: AppColors.amber.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 0),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2540),
        border: Border.symmetric(
          horizontal: BorderSide(
              color: AppColors.amber.withOpacity(0.4), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          14,
          (_) => Container(
            width: 14,
            height: 3,
            color: AppColors.amber.withOpacity(0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildZonePanel({
    required String zoneName,
    required int slotCount,
    required IconData icon,
    required Color zoneColor,
    required String label,
    required List<ParkingSlotModel> slots,
    required bool loading,
    required int crossAxisCount,
    bool fullWidth = false,
  }) {
    final available =
        slots.where((s) => s.status == SlotStatus.available).length;
    final total = slotCount;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: zoneColor.withOpacity(0.35), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Zone header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: zoneColor.withOpacity(0.12),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
              border: Border(
                  bottom: BorderSide(color: zoneColor.withOpacity(0.2))),
            ),
            child: Row(
              children: [
                Icon(icon, color: zoneColor, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    zoneName,
                    style: GoogleFonts.inter(
                      color: zoneColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: zoneColor.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$available/$total',
                    style: GoogleFonts.inter(
                      color: zoneColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Slot grid
          Padding(
            padding: const EdgeInsets.all(6),
            child: loading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                  )
                : slots.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          'No slots loaded…',
                          style: GoogleFonts.inter(
                              color: AppColors.textMuted, fontSize: 11),
                        ),
                      )
                    : _buildSlotGrid(slots, crossAxisCount, zoneColor),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotGrid(
      List<ParkingSlotModel> slots, int crossAxisCount, Color zoneColor) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 3,
        mainAxisSpacing: 3,
        childAspectRatio: slots.length > 50 ? 0.8 : 0.9,
      ),
      itemCount: slots.length,
      itemBuilder: (_, i) => _buildMiniSlot(slots[i], zoneColor),
    );
  }

  Widget _buildMiniSlot(ParkingSlotModel slot, Color zoneColor) {
    final isSelected = _selectedSlot?.id == slot.id;
    final bg = _slotColor(slot);
    final border = _slotBorder(slot);
    final shortId = slot.id.split('-').last;

    return GestureDetector(
      onTap: () => _onSlotTap(slot),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: isSelected ? AppColors.primaryLight : border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.5),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              shortId,
              style: GoogleFonts.inter(
                color: border,
                fontSize: 7,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Slot Booking Bottom Sheet ─────────────────────────────────────────────

class _SlotBookingSheet extends StatefulWidget {
  final ParkingSlotModel slot;
  final VoidCallback onBooked;
  final VoidCallback onDismiss;
  const _SlotBookingSheet({
    required this.slot,
    required this.onBooked,
    required this.onDismiss,
  });

  @override
  State<_SlotBookingSheet> createState() => _SlotBookingSheetState();
}

class _SlotBookingSheetState extends State<_SlotBookingSheet> {
  int _selectedDuration = 1;
  bool _isBooking = false;

  static const _durations = ['30 min', '1 Hour', '2 Hours', '4 Hours'];

  bool get _canBook =>
      widget.slot.status == SlotStatus.available ||
      widget.slot.status == SlotStatus.faculty;

  Color get _statusColor {
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

  String get _statusLabel {
    switch (widget.slot.status) {
      case SlotStatus.available:
        return 'Available';
      case SlotStatus.occupied:
        return 'Occupied';
      case SlotStatus.reserved:
        return 'Reserved';
      case SlotStatus.faculty:
        return 'Faculty Reserved';
    }
  }

  String get _zoneName {
    switch (widget.slot.zone) {
      case ParkingZone.staffCar:
        return 'Staff Car Parking · Left Zone';
      case ParkingZone.studentBike:
        return 'Student Bike Parking · Right Zone';
      case ParkingZone.staffBike:
        return 'Staff Bike Parking · Right Zone';
      case ParkingZone.common:
        return 'Common Parking · Behind Block';
    }
  }

  IconData get _vehicleIcon =>
      widget.slot.vehicleType == VehicleType.bike
          ? Icons.two_wheeler
          : Icons.directions_car;

  Future<void> _book() async {
    if (!_canBook) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('This slot is not available!',
            style: GoogleFonts.inter(color: Colors.white)),
        backgroundColor: AppColors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }
    setState(() => _isBooking = true);
    final uid = AuthService.currentUser?.uid;
    if (uid != null) {
      try {
        await FirestoreService.reserveSlot(
          widget.slot.id,
          uid,
          duration: _durations[_selectedDuration],
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Booking failed: $e',
                style: GoogleFonts.inter(color: Colors.white)),
            backgroundColor: AppColors.red,
            behavior: SnackBarBehavior.floating,
          ));
        }
        setState(() => _isBooking = false);
        return;
      }
    }
    if (mounted) {
      widget.onBooked();
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
      initialChildSize: 0.58,
      minChildSize: 0.45,
      maxChildSize: 0.85,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: CustomScrollView(
          controller: ctrl,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: AppColors.inputBorder,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Slot header
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: _statusColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                            border:
                                Border.all(color: _statusColor, width: 2),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(_vehicleIcon,
                                  color: _statusColor, size: 22),
                              const SizedBox(height: 2),
                              Text(
                                widget.slot.id,
                                style: GoogleFonts.inter(
                                  color: _statusColor,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Slot ${widget.slot.id}',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _zoneName,
                                style: GoogleFonts.inter(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _statusColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _statusLabel,
                                  style: GoogleFonts.inter(
                                    color: _statusColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),
                    const Divider(color: AppColors.divider),
                    const SizedBox(height: 16),

                    // Duration selector
                    if (_canBook) ...[
                      Text(
                        'SELECT DURATION',
                        style: GoogleFonts.inter(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: List.generate(_durations.length, (i) {
                          final isActive = _selectedDuration == i;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedDuration = i),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                margin: EdgeInsets.only(
                                    right: i < _durations.length - 1 ? 8 : 0),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? AppColors.primary
                                      : AppColors.surfaceLight,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isActive
                                        ? AppColors.primary
                                        : AppColors.inputBorder,
                                  ),
                                ),
                                child: Text(
                                  _durations[i],
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    color: isActive
                                        ? Colors.white
                                        : AppColors.textMuted,
                                    fontSize: 12,
                                    fontWeight: isActive
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 24),
                      // Confirm booking button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isBooking ? null : _book,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            disabledBackgroundColor:
                                AppColors.primary.withOpacity(0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 8,
                            shadowColor:
                                AppColors.primary.withOpacity(0.4),
                          ),
                          child: _isBooking
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.check_circle_outline,
                                        color: Colors.white, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Confirm Booking · ${_durations[_selectedDuration]}',
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ] else ...[
                      // Not available banner
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.slotOccupied,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: AppColors.slotOccupiedBorder
                                  .withOpacity(0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.block,
                                color: AppColors.slotOccupiedBorder,
                                size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'This slot is currently $_statusLabel and cannot be reserved.',
                                style: GoogleFonts.inter(
                                  color: AppColors.slotOccupiedBorder,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    // Close button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: widget.onDismiss,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              color: AppColors.inputBorder, width: 1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Close',
                          style: GoogleFonts.inter(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
