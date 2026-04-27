import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  final String? imagePath;

  const ProfileAvatar({super.key, this.imagePath});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 50,
      backgroundColor: Colors.green.shade100,
      backgroundImage:
          imagePath != null ? AssetImage(imagePath!) : null,
      child: imagePath == null
          ? const Icon(Icons.person, size: 50, color: Colors.green)
          : null,
    );
  }
}