import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import 'home_screen.dart';
import 'complaints_screen.dart';
import 'notices_screen.dart';
import 'payments_screen.dart';
import 'amenities_screen.dart';
import 'more_screen.dart';

class ResidentNav extends StatefulWidget {
  const ResidentNav({super.key});

  @override
  State<ResidentNav> createState() => _ResidentNavState();
}

class _ResidentNavState extends State<ResidentNav> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      ResidentHomeScreen(onNavigate: (i) => setState(() => _currentIndex = i)),
      const ComplaintsScreen(),
      const NoticesScreen(),
      const PaymentsScreen(),
      const AmenitiesScreen(),
      const MoreScreen(),
    ];

    return Scaffold(
      body: screens[_currentIndex],
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
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          selectedLabelStyle:
              GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle:
              GoogleFonts.poppins(fontSize: 10),
          backgroundColor: Colors.white,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home_rounded),
                label: 'Home'),
            BottomNavigationBarItem(
                icon: Icon(Icons.report_problem_outlined),
                activeIcon: Icon(Icons.report_problem_rounded),
                label: 'Complaints'),
            BottomNavigationBarItem(
                icon: Icon(Icons.campaign_outlined),
                activeIcon: Icon(Icons.campaign_rounded),
                label: 'Notices'),
            BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long_outlined),
                activeIcon: Icon(Icons.receipt_long_rounded),
                label: 'Payments'),
            BottomNavigationBarItem(
                icon: Icon(Icons.sports_tennis_outlined),
                activeIcon: Icon(Icons.sports_tennis_rounded),
                label: 'Amenities'),
            BottomNavigationBarItem(
                icon: Icon(Icons.more_horiz_rounded),
                activeIcon: Icon(Icons.more_horiz_rounded),
                label: 'More'),
          ],
        ),
      ),
    );
  }
}
