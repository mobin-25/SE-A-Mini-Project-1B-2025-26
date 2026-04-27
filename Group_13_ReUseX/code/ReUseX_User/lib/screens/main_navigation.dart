import 'package:flutter/material.dart';
import 'package:reusex/screens/orders/user/user_order_page.dart';
import 'package:reusex/screens/profile_user_screen/profile_page.dart';
import 'home/home.dart';
import 'sell/sell_page.dart';
import 'recycle/recycle_page.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    Home(),
    SellPage(),
    UserOrderPage(),
    RecyclePage(),
    ProfilePage(),
  ];

  void _onTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        height: 90 + MediaQuery.of(context).padding.bottom, // ✅ safe area aware
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Colors.grey,
                width: 0.3,
              ),
            ),
          ),
          child: BottomAppBar(
            padding: EdgeInsets.zero,
            color: Colors.white,
            child: Center(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _BottomNavItem(
                    icon: Icons.home,
                    label: "Buy",
                    isSelected: _selectedIndex == 0,
                    onTap: () => _onTap(0),
                  ),
                  _BottomNavItem(
                    icon: Icons.sell,
                    label: "Sell",
                    isSelected: _selectedIndex == 1,
                    onTap: () => _onTap(1),
                  ),
                  _BottomNavItem(
                    icon: Icons.shopping_cart,
                    label: "Orders",
                    isSelected: _selectedIndex == 2,
                    onTap: () => _onTap(2),
                  ),
                  _BottomNavItem(
                    icon: Icons.recycling_outlined,
                    label: "Recycle",
                    isSelected: _selectedIndex == 3,
                    onTap: () => _onTap(3),
                  ),
                  _BottomNavItem(
                    icon: Icons.person,
                    label: "Profile",
                    isSelected: _selectedIndex == 4,
                    onTap: () => _onTap(4),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 22,
            color: isSelected ? const Color(0xFF4CAF50) : Colors.grey,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12, // ✅ fixed from 16
              color: isSelected ? const Color(0xFF4CAF50) : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}