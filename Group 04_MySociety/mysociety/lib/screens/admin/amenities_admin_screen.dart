import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';

class AmenitiesAdminScreen extends StatelessWidget {
  const AmenitiesAdminScreen({super.key});

  Future<void> _updateStatus(String id, String status) async {
    await FirebaseFirestore.instance
        .collection('amenity_bookings')
        .doc(id)
        .update({'status': status});
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Amenity Bookings'),
          automaticallyImplyLeading: false,
          bottom: TabBar(
            indicatorColor: Colors.white,
            labelStyle:
                GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
            unselectedLabelStyle: GoogleFonts.poppins(fontSize: 13),
            tabs: const [
              Tab(text: 'Pending'),
              Tab(text: 'All Bookings'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _BookingList(
                filterStatus: 'pending', onUpdateStatus: _updateStatus),
            _BookingList(filterStatus: null, onUpdateStatus: _updateStatus),
          ],
        ),
      ),
    );
  }
}

class _BookingList extends StatelessWidget {
  final String? filterStatus;
  final Future<void> Function(String id, String status) onUpdateStatus;

  const _BookingList(
      {required this.filterStatus, required this.onUpdateStatus});

  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance.collection('amenity_bookings');
    if (filterStatus != null) {
      query = query.where('status', isEqualTo: filterStatus);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                    filterStatus == 'pending'
                        ? Icons.check_circle_outline_rounded
                        : Icons.event_busy_rounded,
                    size: 72,
                    color: AppColors.textSecondary.withOpacity(0.4)),
                const SizedBox(height: 14),
                Text(
                  filterStatus == 'pending'
                      ? 'No pending bookings. 🎉'
                      : 'No booking requests yet.',
                  style: GoogleFonts.poppins(
                      color: AppColors.textSecondary, fontSize: 14),
                ),
              ],
            ),
          );
        }

        final bookings =
            snap.data!.docs.map((d) => BookingModel.fromDoc(d)).toList();

        // In-memory sort to bypass Firestore composite index requirement
        bookings.sort((a, b) => b.date.compareTo(a.date));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bookings.length,
          itemBuilder: (_, i) {
            final b = bookings[i];
            final statusColor = switch (b.status) {
              'approved' => AppColors.success,
              'rejected' => AppColors.error,
              _ => AppColors.warning,
            };

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.adminAccent.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          switch (b.amenity) {
                            'Swimming Pool' => Icons.pool_rounded,
                            'Gym' => Icons.fitness_center_rounded,
                            'Clubhouse' => Icons.groups_rounded,
                            'Garden / Park' => Icons.park_rounded,
                            'Tennis Court' => Icons.sports_tennis_rounded,
                            'Banquet Hall' => Icons.celebration_rounded,
                            _ => Icons.event_available_rounded,
                          },
                          color: AppColors.adminAccent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(b.amenity,
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: AppColors.textPrimary)),
                            Text(
                              '${b.residentName} • Flat ${b.flatNo}',
                              style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          b.status[0].toUpperCase() + b.status.substring(1),
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: statusColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(DateFormat('dd MMM yyyy').format(b.date),
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(width: 12),
                      const Icon(Icons.access_time_rounded,
                          size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(b.time,
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                  if (b.status == 'pending') ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(color: AppColors.error),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => onUpdateStatus(b.id, 'rejected'),
                            icon: const Icon(Icons.close_rounded, size: 16),
                            label: const Text('Reject'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => onUpdateStatus(b.id, 'approved'),
                            icon: const Icon(Icons.check_rounded,
                                size: 16, color: Colors.white),
                            label: const Text('Approve'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}
