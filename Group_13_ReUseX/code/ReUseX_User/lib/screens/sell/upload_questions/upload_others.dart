import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:reusex/screens/sell/approval_page/approval_page.dart';

import '../../../utils/cloudinary_service.dart';
import '../../../widgets/widget_supporter/widget_supporter.dart';

class UploadOthers extends StatefulWidget {
  const UploadOthers({super.key});

  @override
  State<UploadOthers> createState() => _UploadOthersState();
}

class _UploadOthersState extends State<UploadOthers> {
  String? q1;
  String? q2;

  bool isLoading = false;

  final TextEditingController itemNameController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  File? selectedImage;
  Uint8List? webImage;

  @override
  void dispose() {
    itemNameController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (picked != null) {
      if (kIsWeb) {
        webImage = await picked.readAsBytes();
      } else {
        selectedImage = File(picked.path);
      }
      setState(() {});
    }
  }

  Future<void> submitOthersRequest() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("User not logged in"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final userData = userDoc.data() ?? {};

      String imageUrl = "";

      if (kIsWeb && webImage != null) {
        String? uploaded;

        if (kIsWeb) {
          uploaded = await CloudinaryService.uploadWebImage(webImage!);
        } else {
          uploaded = await CloudinaryService.uploadImage(selectedImage!);
        }
        if (uploaded != null) imageUrl = uploaded;
      } else if (!kIsWeb && selectedImage != null) {
        final uploaded = await CloudinaryService.uploadImage(selectedImage!);
        if (uploaded != null) imageUrl = uploaded;
      }

      await FirebaseFirestore.instance.collection('approval_requests').add({
        "userId": user.uid,
        "userName": (userData['name'] ?? user.displayName ?? user.email ?? "")
            .toString(),
        "mobile": (userData['mobile'] ?? "").toString(),
        "address": (userData['address'] ?? "").toString(),
        "requestType": "sell",
        "deviceType": "others",
        "title": itemNameController.text.trim().isEmpty
            ? "Other Item Sell Request"
            : itemNameController.text.trim(),
        "imageUrl": imageUrl,
        "status": "pending",
        "additionalNotes": notesController.text.trim(),
        "createdAt": FieldValue.serverTimestamp(),
        "answers": {
          "itemModelName": itemNameController.text.trim(),
          "workingProperly": q1 ?? "",
          "hasPhysicalDamage": q2 ?? "",
        },
      });

      if (!mounted) return;

      Navigator.push(
        context,
        CupertinoPageRoute(builder: (context) => const ApprovalPage()),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to submit request: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Widget _radioBox(
      String title,
      String value,
      String? groupValue,
      Function(String?) onChanged,
      ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: RadioListTile<String>(
        activeColor: Colors.green,
        title: Text(title),
        value: value,
        groupValue: groupValue,
        onChanged: onChanged,
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
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Device Details",
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Lora',
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          const SizedBox(height: 30),
          Expanded(
            child: Container(
              width: MediaQuery.of(context).size.width,
              decoration: const BoxDecoration(color: Colors.white),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: pickImage,
                              child: Container(
                                height: 160,
                                width: 160,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFBDBDBD),
                                  border: Border.all(
                                    color: Colors.black45,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: (kIsWeb && webImage != null)
                                    ? Image.memory(webImage!, fit: BoxFit.cover)
                                    : (selectedImage != null)
                                    ? Image.file(selectedImage!,
                                    fit: BoxFit.cover)
                                    : const Icon(
                                  Icons.camera_alt_outlined,
                                  size: 35,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              "Upload the image",
                              style: TextStyle(
                                color: Colors.grey,
                                fontFamily: 'Lora',
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      const Text(
                        "Tell us more about your item?",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Please answer a few questions about your item.",
                        style: TextStyle(color: Colors.grey, fontSize: 15),
                      ),
                      const SizedBox(height: 20),

                      const Text(
                        "1. What is the item and its model name?",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: itemNameController,
                        minLines: 2,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText: "Eg. Keyboard – Logitech K120",
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 25),

                      const Text(
                        "2. Is the item working properly?",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 10),
                      Column(
                        children: [
                          _radioBox("Yes", "yes", q1,
                                  (val) => setState(() => q1 = val)),
                          _radioBox("No", "no", q1,
                                  (val) => setState(() => q1 = val)),
                        ],
                      ),

                      const SizedBox(height: 25),

                      const Text(
                        "3. Are there any physical damages or issues?",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 10),
                      Column(
                        children: [
                          _radioBox("Yes", "yes", q2,
                                  (val) => setState(() => q2 = val)),
                          _radioBox("No", "no", q2,
                                  (val) => setState(() => q2 = val)),
                        ],
                      ),

                      const SizedBox(height: 25),

                      TextFormField(
                        controller: notesController,
                        minLines: 4,
                        maxLines: 6,
                        decoration: const InputDecoration(
                          hintText: "Describe",
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 25),

                      Center(
                        child: CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed:
                          isLoading ? null : submitOthersRequest,
                          child: Material(
                            elevation: 5.0,
                            borderRadius: BorderRadius.circular(30),
                            child: Container(
                              height: 60,
                              width:
                              MediaQuery.of(context).size.width / 1.0,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Center(
                                child: isLoading
                                    ? const CircularProgressIndicator(
                                    color: Colors.white)
                                    : Text(
                                  "Submit",
                                  style: WidgetSupporter
                                      .whitetextstyle(20.0),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 25),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}