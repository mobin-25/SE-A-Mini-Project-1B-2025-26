import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PetDetailsScreen extends StatelessWidget {
  final String petId;
  final Map<String, dynamic> petData;

  const PetDetailsScreen({
    super.key,
    required this.petId,
    required this.petData,
  });

  Future<void> adoptPet(BuildContext context) async {
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
      'petName': petData['name'],
      'status': 'pending',
      'timestamp': Timestamp.now(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Adoption request sent")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    bool isAdopted = petData['isAdopted'] == true;

    return Scaffold(
      appBar: AppBar(title: Text(petData['name'] ?? "Pet")),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              petData['image'] ?? "",
              height: 250,
              width: double.infinity,
              fit: BoxFit.cover,
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    petData['name'] ?? "",
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Text("Breed: ${petData['breed']}"),
                  Text("Age: ${petData['age']}"),

                  const SizedBox(height: 10),

                  Text(petData['description'] ?? ""),

                  const SizedBox(height: 20),

                  // ❌ REMOVE BUTTON IF ADOPTED
                  if (!isAdopted)
                    FutureBuilder<QuerySnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('adoption_requests')
                          .where('userId', isEqualTo: user?.uid)
                          .where('petId', isEqualTo: petId)
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
                          child: ElevatedButton(
                            onPressed: (status == "pending")
                                ? null
                                : () => adoptPet(context),
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
                    ),

                  // ✅ OPTIONAL: show text if adopted
                  if (isAdopted)
                    const Text(
                      "This pet has been adopted 🐾",
                      style: TextStyle(
                          color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}