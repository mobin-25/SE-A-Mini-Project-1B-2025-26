import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../models/categories_model.dart';
import '../../../utils/app_colors.dart';
import '../../../widgets/category_card.dart';
import '../main_navigation.dart';
import 'add_edit_category_page.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addCategory(CategoryProduct product) async {
    await _firestore.collection("categories").add({
      ...product.toMap(),
      "createdAt": FieldValue.serverTimestamp(),
      "updatedAt": FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateCategory(CategoryProduct product) async {
    if (product.id == null) return;

    await _firestore.collection("categories").doc(product.id).update({
      ...product.toMap(),
      "updatedAt": FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteCategory(String docId) async {
    await _firestore.collection("categories").doc(docId).delete();
  }

  void _showDeleteDialog(String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Category"),
        content: const Text("Are you sure you want to delete this category?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              await deleteCategory(docId);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD6D9F7),
      drawer: const AdminDrawer(),
      appBar: AppBar(
        title: const Text("Categories"),
        backgroundColor: AppColors.primary,
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, size: 28),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddEditCategoryPage(
                    onSave: addCategory,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection("categories")
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text("Something went wrong while loading categories"),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                "No categories added yet",
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          final categories = docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return CategoryProduct.fromMap(data, doc.id);
          }).toList();

          return GridView.builder(
            padding: const EdgeInsets.all(10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];

              return CategoryCard(
                product: category,
                onDelete: () {
                  if (category.id != null) {
                    _showDeleteDialog(category.id!);
                  }
                },
                onEdit: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddEditCategoryPage(
                        product: category,
                        onSave: updateCategory,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}