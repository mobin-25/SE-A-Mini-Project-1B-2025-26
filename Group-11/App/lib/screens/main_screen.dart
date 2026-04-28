import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'pets_screen.dart';
import 'vet_screen.dart';
import 'products_screen.dart';
import 'cart_screen.dart';


class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    HomeScreen(),
    PetsScreen(),
    VetScreen(),
    ProductsScreen(), // 🛒 Store
    CartScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,

        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(Icons.pets), label: "Pets"),
          BottomNavigationBarItem(
              icon: Icon(Icons.local_hospital), label: "Vet"),
          BottomNavigationBarItem(
              icon: Icon(Icons.store), label: "Store"), // 🛒
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart), label: "Cart"),
         
        ],
      ),
    );
  }
}