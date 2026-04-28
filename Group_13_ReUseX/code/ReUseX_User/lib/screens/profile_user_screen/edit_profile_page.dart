import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../utils/cloudinary_service.dart';
import '../../widgets/profile_user/save_button.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();

  File? profileImage;
  Uint8List? webImage;
  String profileImageUrl = '';

  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> loadUserData() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(currentUser.uid)
          .get();

      if (doc.exists) {
        final data = doc.data();
        nameController.text = (data?["name"] ?? "").toString();
        phoneController.text = (data?["phone"] ?? "").toString();
        profileImageUrl = (data?["profileImageUrl"] ?? "").toString();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load profile")),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (picked == null || !mounted) return;

      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        setState(() {
          webImage = bytes;
          profileImage = null;
        });
      } else {
        setState(() {
          profileImage = File(picked.path);
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

  Future<void> saveProfile() async {
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your name")),
      );
      return;
    }

    if (phone.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Phone number must be 10 digits")),
      );
      return;
    }

    try {
      setState(() {
        isSaving = true;
      });

      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("User not logged in")),
          );
          setState(() {
            isSaving = false;
          });
        }
        return;
      }

      String finalImageUrl = profileImageUrl;

      if (kIsWeb && webImage != null) {
        final uploadedUrl = await CloudinaryService.uploadWebImage(webImage!);
        if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
          finalImageUrl = uploadedUrl;
        }
      } else if (!kIsWeb && profileImage != null) {
        final uploadedUrl = await CloudinaryService.uploadImage(profileImage!);
        if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
          finalImageUrl = uploadedUrl;
        }
      }

      await FirebaseFirestore.instance
          .collection("users")
          .doc(currentUser.uid)
          .set({
        "name": name,
        "phone": phone,
        "profileImageUrl": finalImageUrl,
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      setState(() {
        profileImageUrl = finalImageUrl;
        isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully")),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update profile: $e")),
      );
    }
  }

  ImageProvider? _buildProfileImage() {
    if (kIsWeb && webImage != null) {
      return MemoryImage(webImage!);
    }
    if (!kIsWeb && profileImage != null) {
      return FileImage(profileImage!);
    }
    if (profileImageUrl.isNotEmpty) {
      return NetworkImage(profileImageUrl);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final imageProvider = _buildProfileImage();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Edit Profile",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: pickImage,
              child: CircleAvatar(
                radius: 55,
                backgroundColor: Colors.green.shade100,
                backgroundImage: imageProvider,
                child: imageProvider == null
                    ? const Icon(
                  Icons.camera_alt,
                  size: 35,
                  color: Colors.green,
                )
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Tap image to change profile picture",
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Full Name",
                floatingLabelStyle: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.number,
              maxLength: 10,
              decoration: const InputDecoration(
                labelText: "Phone Number",
                counterText: "",
                floatingLabelStyle: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 30),
            isSaving
                ? const CircularProgressIndicator()
                : SaveButton(
              onPressed: saveProfile,
            ),
          ],
        ),
      ),
    );
  }
}