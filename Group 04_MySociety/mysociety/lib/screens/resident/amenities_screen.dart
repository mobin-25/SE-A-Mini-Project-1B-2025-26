import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';

class AmenitiesScreen extends StatefulWidget {
  const AmenitiesScreen({super.key});

  @override
  State<AmenitiesScreen> createState() => _AmenitiesScreenState();
}

class _AmenitiesScreenState extends State<AmenitiesScreen> {
  final _amenities = [
    {'name': 'Swimming Pool', 'icon': Icons.pool_rounded, 'color': const Color(0xFF00BCD4), 'image': 'https://images.unsplash.com/photo-1576013551627-0cc20b96c2a7?q=80&w=600&auto=format&fit=crop'},
    {'name': 'Gym', 'icon': Icons.fitness_center_rounded, 'color': const Color(0xFFE91E63), 'image': 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?q=80&w=600&auto=format&fit=crop'},
    {'name': 'Clubhouse', 'icon': Icons.groups_rounded, 'color': const Color(0xFFFF9800), 'image': 'https://images.unsplash.com/photo-1517245386807-bb43f82c33c4?q=80&w=600&auto=format&fit=crop'},
    {'name': 'Garden / Park', 'icon': Icons.park_rounded, 'color': const Color(0xFF4CAF50), 'image': 'https://images.unsplash.com/photo-1519331379826-f10be5486c6f?q=80&w=600&auto=format&fit=crop'},
    {'name': 'Tennis Court', 'icon': Icons.sports_tennis_rounded, 'color': const Color(0xFF9C27B0), 'image': 'https://images.unsplash.com/photo-1595435934249-5df7ed86e1c0?q=80&w=600&auto=format&fit=crop'},
    {'name': 'Banquet Hall', 'icon': Icons.celebration_rounded, 'color': const Color(0xFFFF5722), 'image': 'https://images.unsplash.com/photo-1519167758481-83f550bb49b3?q=80&w=600&auto=format&fit=crop'},
  ];

  final _timeCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedAmenity = 'Swimming Pool';
  bool _submitting = false;

  Future<void> _bookAmenity() async {
    if (_timeCtrl.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a preferred time'), backgroundColor: AppColors.error),
        );
      }
      return;
    }
    final uid = FirebaseAuth.instance.currentUser!.uid;
    setState(() => _submitting = true);
    try {
      DocumentSnapshot userDoc;
      try {
        userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      } catch (e) {
        throw Exception('User Read Error: $e');
      }

      if (!userDoc.exists) {
        throw Exception('User profile not found.');
      }
      final user = UserModel.fromDoc(userDoc);
      
      try {
        await FirebaseFirestore.instance.collection('amenity_bookings').add({
          'uid': uid,
          'residentName': user.name,
          'flatNo': user.flatNo,
          'amenity': _selectedAmenity,
          'date': Timestamp.fromDate(_selectedDate),
          'time': _timeCtrl.text.trim(),
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        throw Exception('Save Booking Error: $e');
      }

      _timeCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Booking request sent! Awaiting admin approval.'),
              backgroundColor: AppColors.success),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to book: $e'),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showBookingSheet(String amenity) {
    setState(() => _selectedAmenity = amenity);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          margin: const EdgeInsets.all(16),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 24,
            right: 24,
            top: 24,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Book $amenity',
                  style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 20),

              // Date Picker
              InkWell(
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                  );
                  if (d != null) setS(() => _selectedDate = d);
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          color: AppColors.primary, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('dd MMMM yyyy').format(_selectedDate),
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              TextField(
                controller: _timeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Preferred Time (e.g. 6:00 AM - 8:00 AM)',
                  prefixIcon:
                      Icon(Icons.access_time_rounded, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _submitting ? null : _bookAmenity,
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Send Booking Request'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Amenities'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Book an Amenity',
              style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            itemCount: _amenities.length,
            itemBuilder: (_, i) {
              final a = _amenities[i];
              return GestureDetector(
                onTap: () => _showBookingSheet(a['name'] as String),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(color: (a['color'] as Color).withOpacity(0.9)),
                      Image.network(
                        a['image'] as String,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox(),
                      ),
                      Container(color: Colors.black.withOpacity(0.4)),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(a['icon'] as IconData,
                            color: Colors.white, size: 30),
                      ),
                      const SizedBox(height: 10),
                      Text(a['name'] as String,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ],
                  ),
                ],
              ),
            ),
          );
            },
          ),
          const SizedBox(height: 24),
          Text('My Bookings',
              style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('amenity_bookings')
                .where('uid', isEqualTo: uid)
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData || snap.data!.docs.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text('No bookings yet.',
                      style: GoogleFonts.poppins(
                          color: AppColors.textSecondary, fontSize: 13)),
                );
              }
              final bookings = snap.data!.docs
                  .map((d) => BookingModel.fromDoc(d))
                  .toList();
                  
              // In-memory sort to bypass Firestore composite index requirement
              bookings.sort((a, b) => b.date.compareTo(a.date));
              
              return Column(
                children: bookings
                    .map((b) => _BookingCard(booking: b))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timeCtrl.dispose();
    super.dispose();
  }
}

class _BookingCard extends StatelessWidget {
  final BookingModel booking;
  const _BookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (booking.status) {
      'approved' => AppColors.success,
      'rejected' => AppColors.error,
      _ => AppColors.warning,
    };
    final statusIcon = switch (booking.status) {
      'approved' => Icons.check_circle_rounded,
      'rejected' => Icons.cancel_rounded,
      _ => Icons.hourglass_top_rounded,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(booking.amenity,
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.textPrimary)),
                Text(
                    '${DateFormat('dd MMM yyyy').format(booking.date)} • ${booking.time}',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              booking.status.capitalize(),
              style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: statusColor),
            ),
          ),
        ],
      ),
    );
  }
}

extension StringExt on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
