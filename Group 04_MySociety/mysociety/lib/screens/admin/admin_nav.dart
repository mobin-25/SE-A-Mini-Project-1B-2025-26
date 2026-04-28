import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import 'admin_home_screen.dart';
import 'notices_admin_screen.dart';
import 'complaints_admin_screen.dart';
import 'payments_admin_screen.dart';
import 'residents_admin_screen.dart';
import 'amenities_admin_screen.dart';

class AdminNav extends StatefulWidget {
  const AdminNav({super.key});

  @override
  State<AdminNav> createState() => _AdminNavState();
}

class _AdminNavState extends State<AdminNav> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const AdminHomeScreen(),
    const NoticesAdminScreen(),
    const ComplaintsAdminScreen(),
    const AmenitiesAdminScreen(),
    const PaymentsAdminScreen(),
    const ResidentsAdminScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.adminAccent,
          unselectedItemColor: AppColors.textSecondary,
          selectedLabelStyle:
              GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.poppins(fontSize: 10),
          backgroundColor: Colors.white,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                activeIcon: Icon(Icons.dashboard_rounded),
                label: 'Dashboard'),
            BottomNavigationBarItem(
                icon: Icon(Icons.campaign_outlined),
                activeIcon: Icon(Icons.campaign_rounded),
                label: 'Notices'),
            BottomNavigationBarItem(
                icon: Icon(Icons.report_problem_outlined),
                activeIcon: Icon(Icons.report_problem_rounded),
                label: 'Complaints'),
            BottomNavigationBarItem(
                icon: Icon(Icons.event_available_outlined),
                activeIcon: Icon(Icons.event_available_rounded),
                label: 'Bookings'),
            BottomNavigationBarItem(
                icon: Icon(Icons.account_balance_wallet_outlined),
                activeIcon: Icon(Icons.account_balance_wallet_rounded),
                label: 'Finance'),
            BottomNavigationBarItem(
                icon: Icon(Icons.people_outline_rounded),
                activeIcon: Icon(Icons.people_rounded),
                label: 'Residents'),
          ],
        ),
      ),
    );
  }
}
