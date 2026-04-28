// lib/widgets/scorer_card.dart
import 'package:flutter/material.dart';

class ScorerCard extends StatelessWidget {
  final String name;
  final String score;

  const ScorerCard({super.key, required this.name, required this.score});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.shade100,
          child: const Icon(Icons.person, color: Colors.green),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Text(
          '$score pts',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
        ),
      ),
    );
  }
}