import 'package:flutter/material.dart';

class PrimaryButtons extends StatelessWidget {
  final void Function()? onPressed;
  final String title;
  const PrimaryButtons({super.key, this.onPressed, required this.title});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      width: double.infinity,
      child: ElevatedButton(
          onPressed: onPressed,
          child: Text(title),
      ),
    );
  }
}
