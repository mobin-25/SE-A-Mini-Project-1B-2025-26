import 'package:flutter/material.dart';

class ApprovalCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const ApprovalCard({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 5,
              offset: Offset(0, 3),
            )
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 40,
              color: Color(0xFF7B61FF),
            ),
            const SizedBox(width: 20),
            Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}