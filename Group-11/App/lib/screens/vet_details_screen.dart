import 'package:flutter/material.dart';
import '../models/vet_model.dart';
import 'book_appointment_screen.dart';

class VetDetailsScreen extends StatelessWidget {
  final Vet vet;

  const VetDetailsScreen({super.key, required this.vet});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(vet.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(vet.image),

            const SizedBox(height: 10),

            Text("Clinic: ${vet.clinic}",
                style: const TextStyle(fontSize: 16)),

            Text("Location: ${vet.location}"),

            Text("Experience: ${vet.experience}"),

            const SizedBox(height: 20),

            const Text(
              "About Vet",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            const Text(
              "Experienced veterinarian with expertise in pet care, surgery, and diagnostics.",
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        BookAppointmentScreen(vet: vet),
                  ),
                );
              },
              child: const Text("Book Appointment"),
            ),
          ],
        ),
      ),
    );
  }
}