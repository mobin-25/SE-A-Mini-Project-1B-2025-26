import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../../models/product_model.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../utils/cloudinary_service.dart';

class ProductEdit extends StatefulWidget {
  final Product? product;

  const ProductEdit({
    super.key,
    this.product,
  });

  @override
  State<ProductEdit> createState() => _ProductEditState();
}

class _ProductEditState extends State<ProductEdit> {
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();
  final gradeController = TextEditingController();
  final inspectionController = TextEditingController();

  String? selectedCategory;
  bool isSaving = false;
  List<String> categories = [];

  File? selectedImage;
  Uint8List? webImage;

  @override
  void initState() {
    super.initState();

    if (widget.product != null) {
      nameController.text = widget.product!.title;
      descriptionController.text = widget.product!.description;
      priceController.text = widget.product!.price;
      gradeController.text = widget.product!.gradeLevel;
      inspectionController.text = widget.product!.inspectionHistory;
      selectedCategory = widget.product!.category;
    }

    loadCategories();
  }

  Future<void> pickImage() async {
    final picked =
    await ImagePicker().pickImage(source: ImageSource.gallery);

    if (picked != null) {
      if (kIsWeb) {
        webImage = await picked.readAsBytes();
      } else {
        selectedImage = File(picked.path);
      }
      setState(() {});
    }
  }

  Future<void> loadCategories() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection("categories")
          .where("isActive", isEqualTo: true)
          .get();

      final loadedCategories = snapshot.docs.map((doc) {
        final data = doc.data();
        return (data["name"] ?? "").toString();
      }).where((name) => name.isNotEmpty).toList();

      setState(() {
        categories = loadedCategories;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load categories")),
      );
    }
  }

  Future<void> saveProduct() async {
    final title = nameController.text.trim();
    final description = descriptionController.text.trim();
    final price = priceController.text.trim();
    final gradeLevel = gradeController.text.trim();
    final inspectionHistory = inspectionController.text.trim();

    if (title.isEmpty ||
        description.isEmpty ||
        price.isEmpty ||
        selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    try {
      setState(() {
        isSaving = true;
      });

      String imageUrl = widget.product?.imageUrl ?? "";

      // ✅ WEB + MOBILE UPLOAD FIX
      if (kIsWeb && webImage != null) {
        final uploaded =
        await CloudinaryService.uploadImage(webImage);
        if (uploaded != null) imageUrl = uploaded;
      } else if (!kIsWeb && selectedImage != null) {
        final uploaded =
        await CloudinaryService.uploadImage(selectedImage);
        if (uploaded != null) imageUrl = uploaded;
      }

      final data = {
        "title": title,
        "description": description,
        "price": price,
        "category": selectedCategory,
        "gradeLevel": gradeLevel,
        "inspectionHistory": inspectionHistory,
        "imageUrl": imageUrl,
        "isActive": true,
        "updatedAt": FieldValue.serverTimestamp(),
      };

      if (widget.product == null) {
        await FirebaseFirestore.instance.collection("products").add({
          ...data,
          "createdAt": FieldValue.serverTimestamp(),
        });
      } else {
        await FirebaseFirestore.instance
            .collection("products")
            .doc(widget.product!.id)
            .update(data);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.product == null
                ? "Product added successfully"
                : "Product updated successfully",
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to save product")),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    gradeController.dispose();
    inspectionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD6D9F7),
      appBar: AppBar(
        title: Text(widget.product == null ? "Add Product" : "Edit Product"),
        backgroundColor: const Color(0xFF8F7AE5),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: pickImage,
              child: CircleAvatar(
                radius: 55,
                backgroundColor: Colors.white,
                backgroundImage: kIsWeb
                    ? (webImage != null ? MemoryImage(webImage!) : null)
                    : (selectedImage != null
                    ? FileImage(selectedImage!)
                    : null),
                child: (webImage == null && selectedImage == null)
                    ? const Icon(
                  Icons.image,
                  size: 35,
                  color: Color(0xFF8F7AE5),
                )
                    : null,
              ),
            ),

            const SizedBox(height: 10),
            const Text(
              "Tap to select image",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 30),

            // 🔽 YOUR ORIGINAL UI BELOW (UNCHANGED)

            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                hintText: "Product Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),

            TextFormField(
              controller: descriptionController,
              minLines: 4,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: "Description",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),

            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: "Price",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),

            DropdownButtonFormField<String>(
              value: categories.contains(selectedCategory)
                  ? selectedCategory
                  : null,
              items: categories.map((category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedCategory = value;
                });
              },
              decoration: const InputDecoration(
                hintText: "Select Category",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),

            TextField(
              controller: gradeController,
              decoration: const InputDecoration(
                hintText: "Grade Level",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),

            TextFormField(
              controller: inspectionController,
              minLines: 4,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: "Inspection History",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: isSaving
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: saveProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8F7AE5),
                  padding: const EdgeInsets.symmetric(
                    vertical: 22,
                    horizontal: 20,
                  ),
                ),
                child: Text(
                  widget.product == null
                      ? "Save Product"
                      : "Update Product",
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}