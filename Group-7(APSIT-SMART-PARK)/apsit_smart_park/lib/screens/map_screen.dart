import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../theme/app_colors.dart';
import '../services/firestore_service.dart';
import '../widgets/release_slot_dialog.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  String _activeFilter = 'Staff Only';
  String _selectedZone = 'Campus Parking';
  // Loaded from Firestore — null means no active booking
  String? _activeSlotId;

  final List<String> _filters = ['Staff Only', 'EV Charging', 'Block A'];

  // APSIT Campus coordinates — A.P. Shah Institute of Technology,
  // Kasarvadavali, Ghodbunder Road, Thane (W) 400615
  // Source: maps.app.goo.gl/PGMPhoBQjY5UkR5P7
  static const LatLng _apsitCenter = LatLng(19.2681361, 72.9674694);

  final MapController _mapController = MapController();

  // Parking zone markers around APSIT
  final List<_ParkingZone> _parkingZones = const [
    _ParkingZone(
        label: 'ZONE A',
        subtitle: 'Main Building',
        point: LatLng(19.2683, 72.9672),
        color: Color(0xFF2563EB)),
    _ParkingZone(
        label: 'STAFF ZONE',
        subtitle: 'East Wing',
        point: LatLng(19.2679, 72.9678),
        color: Color(0xFF8B5CF6)),
    _ParkingZone(
        label: 'ZONE B',
        subtitle: 'North Gate',
        point: LatLng(19.2686, 72.9675),
        color: Color(0xFF2563EB)),
  ];

  @override
  void initState() {
    super.initState();
    _loadActiveBooking();
  }

  Future<void> _loadActiveBooking() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: uid)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();
      if (mounted && snap.docs.isNotEmpty) {
        setState(() {
          _activeSlotId = snap.docs.first.data()['slotId'] as String?;
          if (_activeSlotId != null) _selectedZone = 'Slot $_activeSlotId';
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                // Real OpenStreetMap
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _apsitCenter,
                    initialZoom: 17.0,
                    minZoom: 10,
                    maxZoom: 20,
                  ),
                  children: [
                    // OSM tile layer
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.apsit.smartpark',
                      maxZoom: 20,
                    ),
                    // Campus marker
                    MarkerLayer(
                      markers: [
                        // Main APSIT pin
                        Marker(
                          point: _apsitCenter,
                          width: 60,
                          height: 70,
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.5),
                                      blurRadius: 8,
                                    )
                                  ],
                                ),
                                child: Text(
                                  'APSIT',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              const Icon(Icons.location_pin,
                                  color: AppColors.primary, size: 28),
                            ],
                          ),
                        ),
                        // Parking zone markers
                        ..._parkingZones.map(
                          (zone) => Marker(
                            point: zone.point,
                            width: 80,
                            height: 65,
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedZone = zone.label),
                              child: Column(
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _selectedZone == zone.label
                                          ? zone.color
                                          : zone.color.withOpacity(0.8),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: _selectedZone == zone.label
                                            ? Colors.white
                                            : Colors.transparent,
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: zone.color.withOpacity(0.5),
                                          blurRadius: 8,
                                        )
                                      ],
                                    ),
                                    child: Text(
                                      zone.label,
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 9,
                                      ),
                                    ),
                                  ),
                                  Icon(Icons.local_parking_rounded,
                                      color: zone.color, size: 22),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Attribution (required by OSM)
                    const RichAttributionWidget(
                      attributions: [
                        TextSourceAttribution('OpenStreetMap contributors'),
                      ],
                    ),
                  ],
                ),
                // Top bar overlay
                SafeArea(child: _buildTopBar()),
                // Filter chips overlay
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 130),
                    child: _buildFilterChips(),
                  ),
                ),
                // Zoom controls
                Positioned(
                  right: 16,
                  bottom: 180,
                  child: _buildZoomControls(),
                ),
                // Location button
                Positioned(
                  right: 16,
                  bottom: 130,
                  child: _buildLocationButton(),
                ),
                // Bottom card
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _buildBottomCard(),
                ),
              ],
            ),
          ),
          _buildBottomNav(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pushNamed('/profile'),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.4),
                        blurRadius: 10,
                      )
                    ],
                  ),
                  child:
                      const Icon(Icons.person, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'APSIT Campus',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 6,
                          offset: const Offset(0, 1),
                        )
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '19.2681°N  72.9675°E',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.of(context).pushNamed('/alerts'),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.black26, blurRadius: 6)
                    ],
                  ),
                  child: Stack(
                    children: [
                      const Center(
                        child: Icon(Icons.notifications_outlined,
                            color: Color(0xFF1E293B), size: 22),
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
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
          const SizedBox(height: 10),
          // Search bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
            ),
            child: TextField(
              style: GoogleFonts.inter(color: const Color(0xFF1E293B)),
              decoration: InputDecoration(
                hintText: 'Search staff zones or blocks',
                hintStyle: GoogleFonts.inter(
                    color: const Color(0xFF94A3B8), fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8)),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (ctx, i) {
          final isActive = _activeFilter == _filters[i];
          return GestureDetector(
            onTap: () => setState(() => _activeFilter = _filters[i]),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.primary
                    : Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
              ),
              child: Text(
                _filters[i],
                style: GoogleFonts.inter(
                  color: isActive ? Colors.white : const Color(0xFF1E293B),
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildZoomControls() {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            final zoom = _mapController.camera.zoom;
            _mapController.move(_mapController.camera.center, zoom + 1);
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
            ),
            child: const Icon(Icons.add, color: Color(0xFF1E293B), size: 22),
          ),
        ),
        Container(height: 1, width: 44, color: const Color(0xFFE2E8F0)),
        GestureDetector(
          onTap: () {
            final zoom = _mapController.camera.zoom;
            _mapController.move(_mapController.camera.center, zoom - 1);
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(12)),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
            ),
            child: const Icon(Icons.remove, color: Color(0xFF1E293B), size: 22),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationButton() {
    return GestureDetector(
      onTap: () {
        _mapController.move(_apsitCenter, 17.0);
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.4),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(Icons.my_location, color: Colors.white, size: 22),
      ),
    );
  }

  Widget _buildBottomCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withOpacity(0.97),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: const Border(top: BorderSide(color: AppColors.inputBorder)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.local_parking_rounded,
                color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _selectedZone,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Near Main Entrance • APSIT',
                  style: GoogleFonts.inter(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (_activeSlotId != null) {
                ReleaseSlotDialog.show(
                  context,
                  slotId: _activeSlotId!,
                  onRelease: () async {
                    try {
                      await FirestoreService.releaseSlot(_activeSlotId!);
                    } catch (_) {}
                    if (!mounted) return;
                    setState(() {
                      _activeSlotId = null;
                      _selectedZone = 'Campus Parking';
                    });
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Slot released successfully!',
                          style: GoogleFonts.inter(color: Colors.white)),
                      backgroundColor: AppColors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ));
                  },
                );
              } else {
                Navigator.of(context).pushNamed('/parking-map');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _activeSlotId != null ? AppColors.red : AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              _activeSlotId != null ? 'Release' : 'Reserve',
              style: GoogleFonts.inter(
                  color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    final items = [
      {'icon': Icons.map, 'label': 'Map'},
      {'icon': Icons.event_note_outlined, 'label': 'Reservations'},
      {'icon': Icons.person_outline, 'label': 'Profile'},
      {'icon': Icons.settings_outlined, 'label': 'Settings'},
    ];
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.navBarBg,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: List.generate(items.length, (i) {
          final isActive = i == 0;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (i == 1) Navigator.of(context).pushNamed('/bookings');
                if (i == 2) Navigator.of(context).pushNamed('/profile');
                if (i == 3) Navigator.of(context).pushNamed('/settings');
              },
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(items[i]['icon'] as IconData,
                        color:
                            isActive ? AppColors.primary : AppColors.textMuted,
                        size: 26),
                    const SizedBox(height: 4),
                    Text(items[i]['label'] as String,
                        style: GoogleFonts.inter(
                          color: isActive
                              ? AppColors.primary
                              : AppColors.textMuted,
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
}

class _ParkingZone {
  final String label;
  final String subtitle;
  final LatLng point;
  final Color color;

  const _ParkingZone({
    required this.label,
    required this.subtitle,
    required this.point,
    required this.color,
  });
}
