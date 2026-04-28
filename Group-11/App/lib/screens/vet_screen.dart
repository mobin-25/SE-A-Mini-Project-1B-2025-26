import 'package:flutter/material.dart';
import '../services/vet_service.dart';
import '../widgets/vet_card.dart';
import '../models/vet_model.dart';
import 'appointments_screen.dart';

class VetScreen extends StatelessWidget {
  VetScreen({super.key});

  final VetService vetService = VetService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Find a Vet"),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AppointmentsScreen(),
                ),
              );
            },
          ),
        ],
      ),

      body: StreamBuilder<List<Vet>>(
        stream: vetService.getVets(),
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final vets = snapshot.data ?? [];

          if (vets.isEmpty) {
            return const Center(child: Text("No vets available"));
          }

          return ListView.builder(
            itemCount: vets.length,
            itemBuilder: (context, index) {
              return VetCard(vet: vets[index]);
            },
          );
        },
      ),
    );
  }
}