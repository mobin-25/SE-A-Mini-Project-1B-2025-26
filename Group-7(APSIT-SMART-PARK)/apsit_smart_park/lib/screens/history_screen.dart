import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../models/booking_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class HistoryScreen extends StatelessWidget {
  final bool embedded;
  const HistoryScreen({super.key, this.embedded = false});

  // ─── Helpers ────────────────────────────────────────────────────────────────

  int _parseDurationMin(String? d) {
    if (d == null || d.isEmpty) return 0;
    if (d.contains('30')) return 30;
    if (d.contains('1 Hour') || d.contains('1 hour')) return 60;
    if (d.contains('2')) return 120;
    if (d.contains('4')) return 240;
    return 0;
  }

  String _totalDuration(List<BookingModel> bookings) {
    int totalMin = 0;
    for (final b in bookings) {
      totalMin += _parseDurationMin(b.duration);
    }
    if (totalMin == 0) return '—';
    final h = totalMin ~/ 60;
    final m = totalMin % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  Color _dotColor(String slotId) {
    if (slotId.startsWith('SC')) return AppColors.amber;
    if (slotId.startsWith('SB')) return AppColors.primaryLight;
    if (slotId.startsWith('FB')) return AppColors.purple;
    return AppColors.green;
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour12 =
        dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day} · $hour12:$min $ampm';
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.currentUser?.uid;

    if (uid == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text(
            'Please log in to see your history.',
            style: GoogleFonts.inter(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: StreamBuilder<List<BookingModel>>(
          stream: FirestoreService.getUserBookings(uid),
          builder: (context, snapshot) {
            // Loading
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2,
                ),
              );
            }

            // Error
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error loading history',
                  style:
                      GoogleFonts.inter(color: AppColors.textSecondary),
                ),
              );
            }

            final all = snapshot.data ?? [];
            // History = only completed bookings
            final history =
                all.where((b) => b.status == 'completed').toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Text(
                    'Parking History',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    '${history.length} completed session${history.length == 1 ? '' : 's'}',
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Stats row ────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _buildStatCard(
                        'Total Sessions',
                        '${history.length}',
                        Icons.history,
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        'Total Time',
                        _totalDuration(history),
                        Icons.timer_outlined,
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard('Total Cost', '₹0', Icons.money),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── List or Empty state ─────────────────────────────────
                if (history.isEmpty)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: const BoxDecoration(
                              color: AppColors.surfaceLight,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.history,
                              color: AppColors.textMuted,
                              size: 38,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No history yet',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Completed parking sessions\nwill appear here.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: history.length,
                      itemBuilder: (ctx, i) =>
                          _buildHistoryItem(history[i]),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ─── Widgets ────────────────────────────────────────────────────────────────

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primaryLight, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style:
                  GoogleFonts.inter(color: AppColors.textMuted, fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(BookingModel booking) {
    final dotColor = _dotColor(booking.slotId);
    final dur =
        booking.duration.isNotEmpty ? booking.duration : '—';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: dotColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.local_parking, color: dotColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Slot ${booking.slotId}',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                Text(
                  _formatDate(booking.startTime),
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                dur,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                '₹0',
                style: GoogleFonts.inter(
                  color: AppColors.green,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
