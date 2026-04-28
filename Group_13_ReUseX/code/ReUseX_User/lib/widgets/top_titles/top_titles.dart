import 'package:flutter/material.dart';
import 'package:reusex/screens/login/login.dart';

class TopTitles extends StatelessWidget {
  final String title, subtitle;
  const TopTitles({super.key, required this.subtitle, required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        if (title == "Create Account")
        const SizedBox(height: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 35,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 25,
          ),
        ),
      ],
    );
  }
}