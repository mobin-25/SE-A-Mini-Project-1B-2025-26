import 'package:flutter/material.dart';
import 'package:my_first_app/screens/profile_page/profile_page.dart';
import 'package:my_first_app/screens/settings_page/setting_page.dart';
import 'package:my_first_app/screens/vault_page/vault_page.dart';

class MainAppScreen extends StatefulWidget {
  const MainAppScreen({super.key});

  @override
  State<MainAppScreen> createState() =>
      _MainAppScreenState();
}

class _MainAppScreenState
    extends State<MainAppScreen> {
  int index = 0;

  final List<Widget> screens = [
  const VaultScreen(),
  const ProfileScreen(),
SettingsScreen(),
];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[index],
      bottomNavigationBar:
          BottomNavigationBar(
        currentIndex: index,
        onTap: (i) =>
            setState(() => index = i),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.lock),
              label: "Vault"),
          BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: "Profile"),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: "Settings"),
        ],
      ),
    );
  }
}
