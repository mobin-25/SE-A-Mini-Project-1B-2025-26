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

class UploadPhone extends StatefulWidget {
  const UploadPhone({super.key});

  @override
  State<UploadPhone> createState() => _UploadPhoneState();
}

class _UploadPhoneState extends State<UploadPhone> {
  _UploadPhoneState() {
    _selectedVal = _questionlist1[0];
  }

  final _questionlist1 = [
    "No Scratches",
    "Screen cracked/glass broken",
    "Chipped/cracked outside display",
    "More than 2 scratches",
    "1-2 scratches on screen",
  ];

  String? q1;
  String? q2;
  String? q3;
  String? _selectedVal = "";

  bool defect1 = false;
  bool defect2 = false;
  bool defect3 = false;
  bool defect4 = false;
  bool defect5 = false;
  bool defect6 = false;
  bool defect7 = false;
  bool have1 = false;
  bool have2 = false;

  bool isLoading = false;

  final TextEditingController notesController = TextEditingController();

  File? selectedImage;
  Uint8List? webImage;

  @override
  void dispose() {
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

  Future<void> submitPhoneRequest() async {
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

    setState(() {
      isLoading = true;
    });

    try {
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
        "userName": user.displayName ?? user.email ?? "",
        "mobile": user.phoneNumber ?? "",
        "address": "",
        "requestType": "sell",
        "deviceType": "phone",
        "title": "Phone Sell Request",
        "imageUrl": imageUrl,
        "status": "pending",
        "additionalNotes": notesController.text.trim(),
        "answers": {
          "canMakeCalls": q1 ?? "",
          "touchWorking": q2 ?? "",
          "screenOriginal": q3 ?? "",
          "physicalCondition": _selectedVal ?? "",
          "screenBodyDefects": {
            "deadSpotVisibleLineDiscoloration": defect1,
            "scratchDentOnBody": defect2,
            "panelMissingBroken": defect3,
          },
          "functionalPhysicalProblems": {
            "frontCamNotWorking": defect4,
            "backCamNotWorking": defect5,
            "volumeButtonNotWorking": defect6,
            "fingerTouchNotWorking": defect7,
          },
          "accessories": {
            "originalCharger": have1,
            "originalBoxSameImei": have2,
          },
        },
        "createdAt": FieldValue.serverTimestamp(),
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
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
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
                                clipBehavior: Clip.antiAlias,
                                child: (kIsWeb && webImage != null)
                                    ? Image.memory(
                                  webImage!,
                                  fit: BoxFit.cover,
                                )
                                    : (selectedImage != null)
                                    ? Image.file(
                                  selectedImage!,
                                  fit: BoxFit.cover,
                                )
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
                        "Tell us more about your device?",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Please answer a few questions about your device.",
                        style: TextStyle(color: Colors.grey, fontSize: 15),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "1. Are you able to make and receive calls?",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Check your device for cellular network connectivity issues.",
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      Column(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: RadioListTile<String>(
                              activeColor: Colors.green,
                              title: const Text("Yes"),
                              value: "yes",
                              groupValue: q1,
                              onChanged: (val) {
                                setState(() {
                                  q1 = val;
                                });
                              },
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: RadioListTile<String>(
                              activeColor: Colors.green,
                              title: const Text("No"),
                              value: "no",
                              groupValue: q1,
                              onChanged: (val) {
                                setState(() {
                                  q1 = val;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),
                      const Text(
                        "2. Is your device's touch screen working properly?",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Check the touch screen functionality of your phone.",
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      Column(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: RadioListTile<String>(
                              activeColor: Colors.green,
                              title: const Text("Yes"),
                              value: "yes",
                              groupValue: q2,
                              onChanged: (val) {
                                setState(() {
                                  q2 = val;
                                });
                              },
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: RadioListTile<String>(
                              activeColor: Colors.green,
                              title: const Text("No"),
                              value: "no",
                              groupValue: q2,
                              onChanged: (val) {
                                setState(() {
                                  q2 = val;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),
                      const Text(
                        "3. Is your phone's screen original ?",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Pick 'Yes' if screen never changed or if the screen was changed pick 'No'",
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      Column(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: RadioListTile<String>(
                              activeColor: Colors.green,
                              title: const Text("Yes"),
                              value: "yes",
                              groupValue: q3,
                              onChanged: (val) {
                                setState(() {
                                  q3 = val;
                                });
                              },
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: RadioListTile<String>(
                              activeColor: Colors.green,
                              title: const Text("No"),
                              value: "no",
                              groupValue: q3,
                              onChanged: (val) {
                                setState(() {
                                  q3 = val;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),
                      const Text(
                        "4. Select Physical Condition ",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField(
                        value: _selectedVal,
                        items: _questionlist1
                            .map(
                              (e) => DropdownMenuItem(
                            value: e,
                            child: Text(e),
                          ),
                        )
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedVal = val as String;
                          });
                        },
                        icon: const Icon(
                          Icons.arrow_drop_down_circle,
                          color: Colors.green,
                        ),
                        dropdownColor: Colors.white,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 25),
                      const Text(
                        "5. Select Screen/Body Defects that are applicable! ",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 10),
                      CheckboxListTile(
                        value: defect1,
                        title: const Text(
                          "Dead Spot/Visible line & Discoloration on screen",
                          style: TextStyle(fontSize: 16),
                        ),
                        activeColor: Colors.green,
                        onChanged: (val) {
                          setState(() {
                            defect1 = val ?? false;
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      const SizedBox(height: 10),
                      CheckboxListTile(
                        value: defect2,
                        title: const Text(
                          "Scratch/Dent on device body",
                          style: TextStyle(fontSize: 16),
                        ),
                        activeColor: Colors.green,
                        onChanged: (val) {
                          setState(() {
                            defect2 = val ?? false;
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      const SizedBox(height: 10),
                      CheckboxListTile(
                        value: defect3,
                        title: const Text(
                          "Device panel missing/broken",
                          style: TextStyle(fontSize: 16),
                        ),
                        activeColor: Colors.green,
                        onChanged: (val) {
                          setState(() {
                            defect3 = val ?? false;
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      const SizedBox(height: 25),
                      const Text(
                        "6. Functional or Physical Problems ",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Please choose appropriate condition to get accurate quote",
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      CheckboxListTile(
                        value: defect4,
                        title: const Text(
                          "Front Cam not working",
                          style: TextStyle(fontSize: 16),
                        ),
                        activeColor: Colors.green,
                        onChanged: (val) {
                          setState(() {
                            defect4 = val ?? false;
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      const SizedBox(height: 10),
                      CheckboxListTile(
                        value: defect5,
                        title: const Text(
                          "Back Cam not working",
                          style: TextStyle(fontSize: 16),
                        ),
                        activeColor: Colors.green,
                        onChanged: (val) {
                          setState(() {
                            defect5 = val ?? false;
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      const SizedBox(height: 10),
                      CheckboxListTile(
                        value: defect6,
                        title: const Text(
                          "Volume Button not working",
                          style: TextStyle(fontSize: 16),
                        ),
                        activeColor: Colors.green,
                        onChanged: (val) {
                          setState(() {
                            defect6 = val ?? false;
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      const SizedBox(height: 10),
                      CheckboxListTile(
                        value: defect7,
                        title: const Text(
                          "Finger Touch not working",
                          style: TextStyle(fontSize: 16),
                        ),
                        activeColor: Colors.green,
                        onChanged: (val) {
                          setState(() {
                            defect7 = val ?? false;
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      const SizedBox(height: 25),
                      const Text(
                        "Do you have the following",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Please select accessories which are available ",
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      CheckboxListTile(
                        value: have1,
                        title: const Text(
                          "Original Charger of Device",
                          style: TextStyle(fontSize: 16),
                        ),
                        activeColor: Colors.green,
                        onChanged: (val) {
                          setState(() {
                            have1 = val ?? false;
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      const SizedBox(height: 10),
                      CheckboxListTile(
                        value: have2,
                        title: const Text(
                          "Original box with same IMEI",
                          style: TextStyle(fontSize: 16),
                        ),
                        activeColor: Colors.green,
                        onChanged: (val) {
                          setState(() {
                            have2 = val ?? false;
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      const SizedBox(height: 25),
                      const Text(
                        "Is there anything else you would like to mention about your phone’s condition?",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 10),
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
                          onPressed: isLoading
                              ? null
                              : () async {
                            await submitPhoneRequest();
                          },
                          child: Material(
                            elevation: 5.0,
                            borderRadius: BorderRadius.circular(30),
                            child: Container(
                              height: 60,
                              width: MediaQuery.of(context).size.width / 1.0,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Center(
                                child: isLoading
                                    ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                                    : Text(
                                  "Submit",
                                  style: WidgetSupporter.whitetextstyle(20.0),
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