import 'package:flutter/material.dart';
import '../models/categories_model.dart';

class CategoryCard extends StatelessWidget {
  final CategoryProduct product;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const CategoryCard({
    super.key,
    required this.product,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: onDelete,
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Color(0xFF7B61FF)),
                  onPressed: onEdit,
                ),
              ],
            ),
            Expanded(
              child: product.imagePath.isEmpty
                  ? const Icon(Icons.category, size: 70, color: Colors.grey)
                  : Image.network(
                product.imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.category,
                    size: 70,
                    color: Colors.grey,
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Text(
              product.name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              product.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}