import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:reusex/screens/sell/upload_questions/upload_laptop.dart';
import 'package:reusex/screens/sell/upload_questions/upload_others.dart';
import 'package:reusex/screens/sell/upload_questions/upload_phone.dart';

class SellPage extends StatelessWidget {
  const SellPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "What are you offering?",
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Lora',
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('categories').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final allDocs = snapshot.data?.docs ?? [];
          final List<Map<String, String>> items = [];

          bool othersAlreadyExists = false;

          for (final doc in allDocs) {
            final data = doc.data() as Map<String, dynamic>;

            final title = (data['name'] ?? '').toString().trim();

            // supports both imageUrl and imagePath
            final imageUrl = ((data['imageUrl'] ?? data['imagePath']) ?? '')
                .toString()
                .trim();

            if (title.isEmpty) continue;

            final lower = title.toLowerCase();

            if (lower.contains('other')) {
              othersAlreadyExists = true;
            }

            items.add({
              "title": title,
              "imageUrl": imageUrl,
            });
          }

          if (!othersAlreadyExists) {
            items.add({
              "title": "Others",
              "imageUrl": "",
            });
          }

          if (items.isEmpty) {
            return const Center(child: Text("No categories available"));
          }

          return Padding(
            padding: const EdgeInsets.all(12),
            child: GridView.builder(
              itemCount: items.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.9,
              ),
              itemBuilder: (context, index) {
                return CategoryTile(
                  title: items[index]["title"]!,
                  imageUrl: items[index]["imageUrl"]!,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class CategoryTile extends StatelessWidget {
  final String title;
  final String imageUrl;

  const CategoryTile({
    super.key,
    required this.title,
    required this.imageUrl,
  });

  void _openCategoryPage(BuildContext context) {
    final t = title.toLowerCase().trim();

    if (t.contains("phone")) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const UploadPhone()),
      );
    } else if (t.contains("laptop")) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const UploadLaptop()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const UploadOthers()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lowerTitle = title.toLowerCase().trim();
    final isOthers = lowerTitle.contains("other");
    final shouldShowNetworkImage =
        !isOthers && imageUrl.isNotEmpty && imageUrl.startsWith("http");

    return InkWell(
      onTap: () => _openCategoryPage(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (shouldShowNetworkImage)
              Image.network(
                imageUrl,
                height: 90,
                width: 90,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.category,
                  size: 60,
                  color: Colors.green,
                ),
              )
            else
              const Icon(
                Icons.category,
                size: 60,
                color: Colors.green,
              ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontFamily: 'Lora',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}