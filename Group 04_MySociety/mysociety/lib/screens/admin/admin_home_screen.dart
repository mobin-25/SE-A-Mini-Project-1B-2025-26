import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1E3A5F), Color(0xFF0D1B2A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.adminAccent.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                  Icons.admin_panel_settings_rounded,
                                  color: AppColors.adminAccent,
                                  size: 28),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Admin Dashboard',
                                      style: GoogleFonts.poppins(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white)),
                                  Text('Sunrise Heights Society',
                                      style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.white70)),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () =>
                                  FirebaseAuth.instance.signOut(),
                              icon: const Icon(Icons.logout_rounded,
                                  color: Colors.white70),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            backgroundColor: const Color(0xFF1E3A5F),
            title: Text('Admin Panel',
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.w600)),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Stats Row
                _StatsRow(),
                const SizedBox(height: 20),

                Text('Recent Activity',
                    style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 12),
                _RecentComplaints(),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('status', isEqualTo: 'approved')
                .where('role', isEqualTo: 'resident')
                .snapshots(),
            label: 'Residents',
            icon: Icons.people_rounded,
            color: const Color(0xFF6C63FF),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            stream: FirebaseFirestore.instance
                .collection('complaints')
                .where('status', isEqualTo: 'open')
                .snapshots(),
            label: 'Open Issues',
            icon: Icons.report_problem_rounded,
            color: const Color(0xFFE53935),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            stream: FirebaseFirestore.instance
                .collection('amenity_bookings')
                .where('status', isEqualTo: 'pending')
                .snapshots(),
            label: 'Bookings',
            icon: Icons.event_rounded,
            color: const Color(0xFFFF9800),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final Stream<QuerySnapshot> stream;
  final String label;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.stream,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snap) {
        final count = snap.data?.docs.length ?? 0;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: color.withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 6),
              Text('$count',
                  style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: color)),
              Text(label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        );
      },
    );
  }
}

class _RecentComplaints extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('complaints')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text('No recent complaints.',
                style: GoogleFonts.poppins(
                    color: AppColors.textSecondary, fontSize: 13)),
          );
        }
        return Column(
          children: snap.data!.docs.map((doc) {
            final d = doc.data() as Map<String, dynamic>;
            final isOpen = d['status'] == 'open';
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2)),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.report_problem_rounded,
                      color:
                          isOpen ? AppColors.warning : AppColors.success,
                      size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${d['residentName']} • Flat ${d['flatNo']}',
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: AppColors.textPrimary)),
                        Text(
                          '${d['category']}: ${(d['description'] as String).substring(0, (d['description'] as String).length > 40 ? 40 : (d['description'] as String).length)}...',
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (isOpen ? AppColors.warning : AppColors.success)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isOpen ? 'Open' : 'Done',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isOpen
                            ? AppColors.warning
                            : AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
