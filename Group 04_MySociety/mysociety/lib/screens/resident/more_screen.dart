import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';
import 'visitor_pass_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('More'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton.icon(
            onPressed: () async => await FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 18),
            label: Text('Logout',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 13)),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream:
            FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }
          final user = UserModel.fromDoc(snap.data!);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Profile card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF3B35C9)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white.withOpacity(0.25),
                      child: Text(
                        user.name.isNotEmpty
                            ? user.name[0].toUpperCase()
                            : 'R',
                        style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.name,
                              style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                          Text('Flat ${user.flatNo}',
                              style: GoogleFonts.poppins(
                                  fontSize: 13, color: Colors.white70)),
                          Text(user.email,
                              style: GoogleFonts.poppins(
                                  fontSize: 11, color: Colors.white60)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Quick links
              _MenuItem(
                icon: Icons.qr_code_2_rounded,
                color: const Color(0xFF00BCD4),
                title: 'Visitor Pass',
                subtitle: 'Generate QR code for guests',
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => VisitorPassScreen(user: user))),
              ),

              const SizedBox(height: 16),
              Text('Emergency Services',
                  style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 10),
              _EmergencyButton(
                icon: Icons.security_rounded,
                label: 'Security',
                number: '+91-0000000001',
                color: const Color(0xFF1E3A5F),
              ),
              _EmergencyButton(
                icon: Icons.local_fire_department_rounded,
                label: 'Fire Brigade',
                number: '101',
                color: const Color(0xFFE53935),
              ),
              _EmergencyButton(
                icon: Icons.local_hospital_rounded,
                label: 'Ambulance',
                number: '108',
                color: const Color(0xFF4CAF50),
              ),
              _EmergencyButton(
                icon: Icons.person_rounded,
                label: 'Society Manager',
                number: '+91-0000000002',
                color: const Color(0xFF9C27B0),
              ),
              _EmergencyButton(
                icon: Icons.local_police_rounded,
                label: 'Police',
                number: '100',
                color: const Color(0xFF3949AB),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(title,
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppColors.textPrimary)),
        subtitle: Text(subtitle,
            style: GoogleFonts.poppins(
                fontSize: 12, color: AppColors.textSecondary)),
        trailing: const Icon(Icons.chevron_right_rounded,
            color: AppColors.textSecondary),
        onTap: onTap,
      ),
    );
  }
}

class _EmergencyButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String number;
  final Color color;

  const _EmergencyButton({
    required this.icon,
    required this.label,
    required this.number,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(label,
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppColors.textPrimary)),
        subtitle: Text(number,
            style: GoogleFonts.poppins(
                fontSize: 12, color: AppColors.textSecondary)),
        trailing: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.call_rounded, color: Colors.white, size: 18),
        ),
        onTap: () async {
          final uri = Uri(scheme: 'tel', path: number.replaceAll(' ', ''));
          if (await canLaunchUrl(uri)) await launchUrl(uri);
        },
      ),
    );
  }
}
