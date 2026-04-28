import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'pet_details_screen.dart';
import 'experience_section.dart';

class PetsScreen extends StatefulWidget {
  const PetsScreen({super.key});

  @override
  State<PetsScreen> createState() => _PetsScreenState();
}

class _PetsScreenState extends State<PetsScreen> {
  String selectedCategory = "all";

  Future<void> adoptPet(
      BuildContext context, String petId, String petName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    var existing = await FirebaseFirestore.instance
        .collection('adoption_requests')
        .where('userId', isEqualTo: user.uid)
        .where('petId', isEqualTo: petId)
        .get();

    if (existing.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Already requested")),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('adoption_requests').add({
      'userId': user.uid,
      'userEmail': user.email,
      'petId': petId,
      'petName': petName,
      'status': 'pending',
      'timestamp': Timestamp.now(),
    });

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("Pets 🐶")),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('pets').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var pets = snapshot.data!.docs;

          // 🔍 FILTER CATEGORY
          if (selectedCategory != "all") {
            pets = pets.where((doc) {
              var data = doc.data() as Map<String, dynamic>;
              return data['category'] == selectedCategory;
            }).toList();
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                // 🐶 CATEGORY FILTER
                SizedBox(
                  height: 50,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      filterChip("all"),
                      filterChip("dog"),
                      filterChip("cat"),
                      filterChip("bird"),
                    ],
                  ),
                ),

                // ❤️ EXPERIENCE SECTION (ONLY FOR ALL)
                if (selectedCategory == "all")
                  const ExperienceSection(),

                // 🐾 PET GRID
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(10),
                  itemCount: pets.length,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemBuilder: (context, index) {
                    var doc = pets[index];
                    var pet = doc.data() as Map<String, dynamic>;

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PetDetailsScreen(
                              petId: doc.id,
                              petData: pet,
                            ),
                          ),
                        );
                      },
                      child: Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 🖼 IMAGE + ADOPTED RIBBON
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(12)),
                                  child: Image.network(
                                    pet['image'] ?? "",
                                    height: 120,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),

                                if (pet['isAdopted'] == true)
                                  Positioned(
                                    top: 8,
                                    left: -30,
                                    child: Transform.rotate(
                                      angle: -0.5,
                                      child: Container(
                                        padding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 30, vertical: 5),
                                        color: Colors.red,
                                        child: const Text(
                                          "ADOPTED",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),

                            // 📄 DETAILS
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      pet['name'] ?? "",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(pet['age'] ?? ""),

                                    const Spacer(),

                                    // ❌ REMOVE BUTTON IF ADOPTED
                                    if (pet['isAdopted'] != true)
                                      FutureBuilder<QuerySnapshot>(
                                        future: FirebaseFirestore.instance
                                            .collection('adoption_requests')
                                            .where('userId',
                                                isEqualTo: user?.uid)
                                            .where('petId',
                                                isEqualTo: doc.id)
                                            .get(),
                                        builder: (context, snap) {
                                          if (!snap.hasData) {
                                            return const SizedBox();
                                          }

                                          String status = "";

                                          if (snap.data!.docs.isNotEmpty) {
                                            var requestData =
                                                snap.data!.docs.first.data()
                                                    as Map<String, dynamic>;
                                            status = requestData['status'];
                                          }

                                          return SizedBox(
                                            width: double.infinity,
                                            height: 36,
                                            child: ElevatedButton(
                                              onPressed:
                                                  (status == "pending")
                                                      ? null
                                                      : () => adoptPet(
                                                          context,
                                                          doc.id,
                                                          pet['name']),
                                              child: Text(
                                                status == "pending"
                                                    ? "Pending"
                                                    : status == "rejected"
                                                        ? "Rejected"
                                                        : "Adopt",
                                              ),
                                            ),
                                          );
                                        },
                                      )
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // 🧠 FILTER CHIP
  Widget filterChip(String category) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: ChoiceChip(
        label: Text(category.toUpperCase()),
        selected: selectedCategory == category,
        onSelected: (_) {
          setState(() {
            selectedCategory = category;
          });
        },
      ),
    );
  }
}