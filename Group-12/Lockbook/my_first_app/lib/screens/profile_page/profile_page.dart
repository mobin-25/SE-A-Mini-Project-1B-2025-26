import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final emergencyController = TextEditingController();

  bool isEditing = false;
  File? profileImage;
  String? profileImageUrl;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<String?> uploadToCloudinary(File imageFile) async {
    final url = Uri.parse(
      "https://api.cloudinary.com/v1_1/db9pfo2uu/image/upload",
    );

    var request = http.MultipartRequest("POST", url);

    request.fields['upload_preset'] = 'lockbook_profile';
    request.files.add(
      await http.MultipartFile.fromPath('file', imageFile.path),
    );

    var response = await request.send();

    if (response.statusCode == 200) {
      var responseData = await response.stream.bytesToString();
      var jsonData = json.decode(responseData);
      return jsonData['secure_url'];
    } else {
      return null;
    }
  }

  void loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;

    setState(() {
      nameController.text = prefs.getString("username") ?? "";
      emailController.text = prefs.getString("email") ?? "";
      phoneController.text = prefs.getString("phone") ?? "";
      emergencyController.text =
          prefs.getString("emergency_phone") ?? "";

      String? imagePath = prefs.getString("profile_image");
      if (imagePath != null && imagePath.isNotEmpty) {
        profileImage = File(imagePath);
      }

      profileImageUrl = prefs.getString("profile_image_url");
    });

    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      if (doc.exists) {
        setState(() {
          nameController.text =
              doc.data()?["username"] ??
              doc.data()?["name"] ??
              nameController.text;

          emailController.text =
              doc.data()?["email"] ?? emailController.text;

          phoneController.text =
              doc.data()?["phone"] ?? phoneController.text;

          emergencyController.text =
              doc.data()?["emergency_phone"] ??
              doc.data()?["emergency"] ??
              emergencyController.text;

          profileImageUrl =
              doc.data()?["profile_image_url"] ?? profileImageUrl;
        });

        await prefs.setString("username", nameController.text);
        await prefs.setString("email", emailController.text);
        await prefs.setString("phone", phoneController.text);
        await prefs.setString(
          "emergency_phone",
          emergencyController.text,
        );

        if (profileImageUrl != null && profileImageUrl!.isNotEmpty) {
          await prefs.setString("profile_image_url", profileImageUrl!);
        }
      }
    }
  }

  void saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .set({
        "username": nameController.text.trim(),
        "email": emailController.text.trim(),
        "phone": phoneController.text.trim(),
        "emergency_phone": emergencyController.text.trim(),
        "profile_image_url": profileImageUrl ?? "",
      }, SetOptions(merge: true));
    }

    await prefs.setString("username", nameController.text.trim());
    await prefs.setString("email", emailController.text.trim());
    await prefs.setString("phone", phoneController.text.trim());
    await prefs.setString(
      "emergency_phone",
      emergencyController.text.trim(),
    );

    if (profileImage != null) {
      await prefs.setString("profile_image", profileImage!.path);
    }

    if (profileImageUrl != null) {
      await prefs.setString("profile_image_url", profileImageUrl!);
    }

    setState(() {
      isEditing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Profile Updated Successfully ✅"),
      ),
    );
  }

  Future<void> pickImage() async {
    if (!isEditing) return;

    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      File file = File(picked.path);

      setState(() {
        profileImage = file;
      });

      final imageUrl = await uploadToCloudinary(file);
      final user = FirebaseAuth.instance.currentUser;

      if (imageUrl != null && user != null) {
        await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .set({
          "profile_image_url": imageUrl,
        }, SetOptions(merge: true));

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("profile_image_url", imageUrl);
        await prefs.setString("profile_image", file.path);

        setState(() {
          profileImageUrl = imageUrl;
        });
      }
    }
  }

  Widget buildField(
      String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        enabled: isEditing,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? imageProvider;

    if (profileImage != null) {
      imageProvider = FileImage(profileImage!);
    } else if (profileImageUrl != null &&
        profileImageUrl!.isNotEmpty) {
      imageProvider = NetworkImage(profileImageUrl!);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 30),

          Center(
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Colors.purple,
                        Colors.deepPurple,
                      ],
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 55,
                    backgroundColor: Colors.white,
                    backgroundImage: imageProvider,
                    child: imageProvider == null
                        ? const Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.purple,
                          )
                        : null,
                  ),
                ),

                if (isEditing)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () async {
                        await pickImage();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.purple,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          Card(
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  buildField("Full Name", nameController),
                  buildField("Email", emailController),
                  buildField("Phone Number", phoneController),
                  buildField("Emergency Contact", emergencyController),
                ],
              ),
            ),
          ),

          const SizedBox(height: 25),

          isEditing
              ? ElevatedButton.icon(
                  onPressed: saveProfile,
                  icon: const Icon(Icons.save),
                  label: const Text("Save Changes"),
                )
              : ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      isEditing = true;
                    });
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text("Edit Profile"),
                ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    emergencyController.dispose();
    super.dispose();
  }
}