import 'package:flutter/material.dart';

class AuthService {
  static void logout(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Logged out successfully")),
    );
  }
}
