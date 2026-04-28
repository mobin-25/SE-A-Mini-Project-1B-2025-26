import 'package:flutter/material.dart';
import 'pets_screen.dart';
import 'products_screen.dart';
import 'vet_screen.dart';
import 'experience_section.dart';
import 'profile_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8F6FF),

      appBar: AppBar(
  title: const Text("PetHub 🐾"),
  backgroundColor: const Color(0xffCDB4DB),
  elevation: 0,

  actions: [
    IconButton(
      icon: const Icon(Icons.person),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const ProfileScreen(),
          ),
        );
      },
    ),
  ],
),

      body: SingleChildScrollView(
        child: Column(
          children: [

            // 🌸 HERO SECTION
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xffE6D5F7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      "Welcome back 🐶\nFind your perfect companion 💕",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xffB8C0FF),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PetsScreen(),
                        ),
                      );
                    },
                    child: const Text("Adopt"),
                  )
                ],
              ),
            ),

            // 🐾 QUICK ACTIONS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _actionCard(
                    "🐶 Pets",
                    const Color(0xffFFD6E0),
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PetsScreen()),
                    ),
                  ),
                  _actionCard(
                    "🛒 Store",
                    const Color(0xffD0F4DE),
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ProductsScreen()),
                    ),
                  ),
                  _actionCard(
                    "🏥 Vet",
                    const Color(0xffFFF3B0),
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => VetScreen()),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ❤️ EXPERIENCES (ONLY ONCE)
            const ExperienceSection(),

            const SizedBox(height: 20),

            // 🌿 INFO CARD
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xffDDF4FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: const [
                  Expanded(
                    child: Text(
                      "Care for your pet with love 💙\nShop essentials & book vets easily",
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  Icon(Icons.pets, size: 30)
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // 🌸 ACTION CARD
  Widget _actionCard(String title, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              title.split(" ")[0],
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 6),
            Text(
              title.split(" ")[1],
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}