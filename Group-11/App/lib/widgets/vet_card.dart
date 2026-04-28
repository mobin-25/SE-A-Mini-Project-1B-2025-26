import 'package:flutter/material.dart';
import '../models/vet_model.dart';
import '../screens/vet_details_screen.dart'; // ✅ IMPORTANT

class VetCard extends StatelessWidget {
  final Vet vet;

  const VetCard({super.key, required this.vet});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: NetworkImage(vet.image),
        ),
        title: Text(vet.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(vet.clinic),
            Text(vet.location),
            Text("Experience: ${vet.experience}"),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios),

        /// ✅ FIXED HERE
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VetDetailsScreen(vet: vet),
            ),
          );
        },
      ),
    );
  }
}