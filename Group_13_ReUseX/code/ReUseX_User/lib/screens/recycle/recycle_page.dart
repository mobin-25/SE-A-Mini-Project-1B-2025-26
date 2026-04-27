import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../utils/cloudinary_service.dart';
import '../../widgets/widget_supporter/widget_supporter.dart';
import '../main_navigation.dart';

class RecyclePage extends StatefulWidget {
  const RecyclePage({super.key});

  @override
  State<RecyclePage> createState() => _RecyclePageState();
}

class _RecyclePageState extends State<RecyclePage> {
  File? image;
  Uint8List? webImage;
  XFile? pickedImageFile;
  bool isLoading = false;

  final nameController = TextEditingController();
  final mobileController = TextEditingController();
  final addressController = TextEditingController();
  final productController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    mobileController.dispose();
    addressController.dispose();
    productController.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (picked == null) return;

      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        if (!mounted) return;
        setState(() {
          pickedImageFile = picked;
          webImage = bytes;
          image = null;
        });
      } else {
        if (!mounted) return;
        setState(() {
          pickedImageFile = picked;
          image = File(picked.path);
          webImage = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to pick image: $e")),
      );
    }
  }

  Future<void> submitRecycleRequest() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please login first")),
      );
      return;
    }

    if (nameController.text.trim().isEmpty ||
        mobileController.text.trim().isEmpty ||
        addressController.text.trim().isEmpty ||
        productController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    if (mobileController.text.trim().length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter valid 10-digit mobile number")),
      );
      return;
    }

    if (pickedImageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an image")),
      );
      return;
    }

    try {
      setState(() => isLoading = true);

      String imageUrl = '';

      if (kIsWeb) {
        if (webImage == null) {
          throw Exception("Please select an image");
        }

        final uploaded = await CloudinaryService.uploadWebImage(webImage!);
        if (uploaded == null || uploaded.isEmpty) {
          throw Exception("Image upload failed");
        }
        imageUrl = uploaded;
      } else {
        if (image == null) {
          throw Exception("Please select an image");
        }

        final uploaded = await CloudinaryService.uploadImage(image!);
        if (uploaded == null || uploaded.isEmpty) {
          throw Exception("Image upload failed");
        }
        imageUrl = uploaded;
      }

      await FirebaseFirestore.instance.collection('recycle_requests').add({
        'fullName': nameController.text.trim(),
        'mobile': mobileController.text.trim(),
        'address': addressController.text.trim(),
        'productDetails': productController.text.trim(),
        'imageUrl': imageUrl,
        'status': 'pending',
        'userId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Recycle request submitted successfully")),
      );

      nameController.clear();
      mobileController.clear();
      addressController.clear();
      productController.clear();

      setState(() {
        image = null;
        webImage = null;
        pickedImageFile = null;
      });

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigation()),
            (route) => false,
      );
    } catch (e) {
      debugPrint("Recycle submit error: $e");

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Submission failed: $e")),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Widget _buildImagePreview() {
    if (kIsWeb && webImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          webImage!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: 160,
        ),
      );
    }

    if (!kIsWeb && image != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          image!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: 160,
        ),
      );
    }

    return const Center(
      child: Text(
        "Tap to select image",
        style: TextStyle(color: Colors.green),
        textAlign: TextAlign.center,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const MainNavigation()),
                  (route) => false,
            );
          },
        ),
        title: const Text(
          "Recycle",
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Lora',
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "About Us",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "ReuseX focuses on reuse before recycling. Reusable products are redirected for reuse, while non-reusable products are sent to scrap or regeneration industries. All earnings generated are donated to trusted charitable organizations.",
              style: TextStyle(fontSize: 15, height: 1.6),
            ),
            const SizedBox(height: 30),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.favorite, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        "Charity & Donation",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "ReuseX ensures that all earnings generated from reusable and recycled products are donated to trusted charitable organizations. These funds support education, healthcare, food drives, and environmental protection initiatives.",
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    "Small actions today can create meaningful change tomorrow.",
                    style: TextStyle(
                      fontSize: 14.5,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Why Your Contribution Matters",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "• Reduces landfill waste\n"
                        "• Supports underprivileged communities\n"
                        "• Promotes sustainable living\n"
                        "• Creates positive social impact\n",
                    style: TextStyle(fontSize: 14, height: 1.6),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      "“Your waste can be someone’s worth.”",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              "Add Product for Recycling",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: pickImage,
              child: Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.green),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _buildImagePreview(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Full Name",
                prefixIcon: Icon(Icons.person),
                floatingLabelStyle: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: mobileController,
              keyboardType: TextInputType.number,
              maxLength: 10,
              decoration: const InputDecoration(
                labelText: "Mobile Number",
                prefixIcon: Icon(Icons.phone),
                counterText: "",
                floatingLabelStyle: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: addressController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Address",
                prefixIcon: Icon(Icons.location_on),
                floatingLabelStyle: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: productController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Product Details",
                prefixIcon: Icon(Icons.inventory),
                floatingLabelStyle: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: isLoading ? null : submitRecycleRequest,
                child: Material(
                  elevation: 5.0,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 60,
                    width: MediaQuery.of(context).size.width / 1.0,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                        "Submit",
                        style: WidgetSupporter.whitetextstyle(16.0),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}