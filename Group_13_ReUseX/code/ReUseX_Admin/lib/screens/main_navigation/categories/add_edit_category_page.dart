import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/categories_model.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/cloudinary_service.dart';

class AddEditCategoryPage extends StatefulWidget {
  final Function(CategoryProduct) onSave;
  final CategoryProduct? product;

  const AddEditCategoryPage({
    super.key,
    required this.onSave,
    this.product,
  });

  @override
  State<AddEditCategoryPage> createState() => _AddEditCategoryPageState();
}

class _AddEditCategoryPageState extends State<AddEditCategoryPage> {
  final nameController = TextEditingController();
  final descController = TextEditingController();

  File? image;
  Uint8List? webImage;

  @override
  void initState() {
    super.initState();

    if (widget.product != null) {
      nameController.text = widget.product!.name;
      descController.text = widget.product!.description;
    }
  }

  Future<void> pickImage() async {
    final picked =
    await ImagePicker().pickImage(source: ImageSource.gallery);

    if (picked != null) {
      if (kIsWeb) {
        webImage = await picked.readAsBytes();
      } else {
        image = File(picked.path);
      }
      setState(() {});
    }
  }

  Future<void> saveCategory() async {
    final name = nameController.text.trim();
    final description = descController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter category name")),
      );
      return;
    }

    String imageUrl = widget.product?.imagePath ?? "";

    // 🔥 Upload logic
    if (kIsWeb && webImage != null) {
      final uploaded =
      await CloudinaryService.uploadImage(webImage);
      if (uploaded != null) imageUrl = uploaded;
    } else if (!kIsWeb && image != null) {
      final uploaded =
      await CloudinaryService.uploadImage(image);
      if (uploaded != null) imageUrl = uploaded;
    }

    final category = CategoryProduct(
      id: widget.product?.id,
      name: name,
      description: description,
      imagePath: imageUrl, // 🔥 NOW URL
      isActive: true,
    );

    widget.onSave(category);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD6D9F7),
      appBar: AppBar(
        title: Text(widget.product == null ? "Add Category" : "Edit Category"),
        backgroundColor: AppColors.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            GestureDetector(
              onTap: pickImage,
              child: CircleAvatar(
                radius: 55,
                backgroundColor: AppColors.secondary,
                backgroundImage: kIsWeb
                    ? (webImage != null ? MemoryImage(webImage!) : null)
                    : (image != null ? FileImage(image!) : null),
                child: (webImage == null && image == null)
                    ? CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  child: const Icon(
                    Icons.camera_alt,
                    color: Color(0xFFC3C6F2),
                    size: 22,
                  ),
                )
                    : null,
              ),
            ),
            const SizedBox(height: 10),
            const Center(
              child: Text(
                "Tap to select image",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 20),

            // 🔽 SAME UI
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Category Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),

            TextField(
              controller: descController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Description",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: saveCategory,
                child: Text(
                  widget.product == null ? "Save Category" : "Update Category",
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}