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

class UploadLaptop extends StatefulWidget {
  const UploadLaptop({super.key});

  @override
  State<UploadLaptop> createState() => _UploadLaptopState();
}

class _UploadLaptopState extends State<UploadLaptop> {
  _UploadLaptopState() {
    _selectedVal1 = _questionlist1[0];
    _selectedVal2 = _questionlist2[0];
    _selectedVal3 = _questionlist3[0];
    _selectedVal4 = _questionlist4[0];
    _selectedVal5 = _questionlist5[0];
    _selectedVal6 = _questionlist6[0];
    _selectedVal7 = _questionlist7[0];
  }

  final _questionlist1 = [
    "No Scratches",
    "1-2 scratches on screen",
    "More than 2 scratches",
    "Screen Cracked or Broken",
  ];

  final _questionlist2 = [
    "No Discolouration",
    "Minor Discolouration",
    "Major Discolouration",
  ];

  final _questionlist3 = [
    "No Lines",
    "Visible lines on Screen",
    "Display Flickering",
    "Black Dots on Screen",
  ];

  final _questionlist4 = [
    "No Scratches",
    "Minor Scratch on Body",
    "Major Scratch on Body",
  ];

  final _questionlist5 = [
    "No Dents on top panel",
    "Upto 2 Minor Dents",
    "More than 2 Minor Dents",
    "1 or more Major Dents",
  ];

  final _questionlist6 = [
    "No - Loose Hinges",
    "Yes - Loose Hinges",
  ];

  final _questionlist7 = [
    "No Cracked or Loose Panel",
    "Loose Panel",
    "Crack/Damage Panel",
  ];

  String? q1;
  String? q2;

  String? _selectedVal1 = "";
  String? _selectedVal2 = "";
  String? _selectedVal3 = "";
  String? _selectedVal4 = "";
  String? _selectedVal5 = "";
  String? _selectedVal6 = "";
  String? _selectedVal7 = "";

  bool defect1 = false;
  bool defect2 = false;
  bool defect3 = false;

  bool isLoading = false;

  final TextEditingController processorController = TextEditingController();
  final TextEditingController ramController = TextEditingController();
  final TextEditingController hardDiskController = TextEditingController();
  final TextEditingController graphicsController = TextEditingController();
  final TextEditingController screenSizeController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  File? selectedImage;
  Uint8List? webImage;

  @override
  void dispose() {
    processorController.dispose();
    ramController.dispose();
    hardDiskController.dispose();
    graphicsController.dispose();
    screenSizeController.dispose();
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

  Future<void> submitLaptopRequest() async {
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
        "deviceType": "laptop",
        "title": "Laptop Sell Request",
        "imageUrl": imageUrl,
        "status": "pending",
        "additionalNotes": notesController.text.trim(),
        "createdAt": FieldValue.serverTimestamp(),
        "answers": {
          "switchesOn": q1 ?? "",
          "deviceAge": q2 ?? "",
          "processor": processorController.text.trim(),
          "ram": ramController.text.trim(),
          "hardDisk": hardDiskController.text.trim(),
          "graphicsCard": graphicsController.text.trim(),
          "screenSize": screenSizeController.text.trim(),
          "functionalProblems": {
            "keyboardIssue": defect1,
            "touchpadIssue": defect2,
            "batteryIssue": defect3,
          },
          "physicalCondition": {
            "screenScratchCondition": _selectedVal1 ?? "",
            "screenDiscolouration": _selectedVal2 ?? "",
            "screenLines": _selectedVal3 ?? "",
            "bodyScratchCondition": _selectedVal4 ?? "",
            "topPanelDentCondition": _selectedVal5 ?? "",
            "looseHinges": _selectedVal6 ?? "",
            "crackedOrLoosePanel": _selectedVal7 ?? "",
          },
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
                        "1. Does the Laptop Switch On?",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Column(
                        children: [
                          _radioBox(
                            "Yes",
                            "yes",
                            q1,
                                (val) => setState(() => q1 = val),
                          ),
                          _radioBox(
                            "No",
                            "no",
                            q1,
                                (val) => setState(() => q1 = val),
                          ),
                        ],
                      ),

                      const SizedBox(height: 25),

                      const Text(
                        "2. System Configuration Details",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Tell us your Laptop's processor, memory(RAM), Storage ,Graphic card & Screen Size",
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),

                      const SizedBox(height: 10),
                      const Text(
                        "Processor",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: processorController,
                        decoration: const InputDecoration(
                          hintText: "Intel Core i3 13th Gen",
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 10),
                      const Text(
                        "RAM",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: ramController,
                        decoration: const InputDecoration(
                          hintText: "4 GB",
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 10),
                      const Text(
                        "Hard Disk",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: hardDiskController,
                        decoration: const InputDecoration(
                          hintText: "1 TB HDD + 128 GB SSD",
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 10),
                      const Text(
                        "Graphics Card (NVIDIA/ AMD)",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: graphicsController,
                        decoration: const InputDecoration(
                          hintText: "AMD Radeon(TM) RX 6500M",
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 10),
                      const Text(
                        "Screen Size",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: screenSizeController,
                        decoration: const InputDecoration(
                          hintText: "15'6 inch",
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 25),

                      const Text(
                        "3. Does your device function properly?",
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
                        value: defect1,
                        title: const Text(
                          "Keyboard not working/missing or not working key(s)",
                          style: TextStyle(fontSize: 16),
                        ),
                        activeColor: Colors.green,
                        onChanged: (val) =>
                            setState(() => defect1 = val ?? false),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      const SizedBox(height: 10),
                      CheckboxListTile(
                        value: defect2,
                        title: const Text(
                          "Touchpad not working; Left/Right click faulty",
                          style: TextStyle(fontSize: 16),
                        ),
                        activeColor: Colors.green,
                        onChanged: (val) =>
                            setState(() => defect2 = val ?? false),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      const SizedBox(height: 10),
                      CheckboxListTile(
                        value: defect3,
                        title: const Text(
                          "Battery dead, backup < 60 mins or health < 80%",
                          style: TextStyle(fontSize: 16),
                        ),
                        activeColor: Colors.green,
                        onChanged: (val) =>
                            setState(() => defect3 = val ?? false),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),

                      const SizedBox(height: 25),

                      const Text(
                        "4. Select Physical Condition",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Select the screen scratch or broken condition",
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      _dropdown(
                        _selectedVal1,
                        _questionlist1,
                            (val) => setState(() => _selectedVal1 = val),
                      ),

                      const SizedBox(height: 25),
                      const Text(
                        "5. Discolouration on Screen",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Select the screen discolouration condition",
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      _dropdown(
                        _selectedVal2,
                        _questionlist2,
                            (val) => setState(() => _selectedVal2 = val),
                      ),

                      const SizedBox(height: 25),
                      const Text(
                        "6. Line on Screen",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Select the screen visible lines/flickering and dots condition",
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      _dropdown(
                        _selectedVal3,
                        _questionlist3,
                            (val) => setState(() => _selectedVal3 = val),
                      ),

                      const SizedBox(height: 25),
                      const Text(
                        "7. Scratch on Body",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Select the device body scratch condition",
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      _dropdown(
                        _selectedVal4,
                        _questionlist4,
                            (val) => setState(() => _selectedVal4 = val),
                      ),

                      const SizedBox(height: 25),
                      const Text(
                        "8. Dent on Top Panel",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Select the device top panel dent condition",
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      _dropdown(
                        _selectedVal5,
                        _questionlist5,
                            (val) => setState(() => _selectedVal5 = val),
                      ),

                      const SizedBox(height: 25),
                      const Text(
                        "9. Loose Hinges",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Select the device loose hinges condition",
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      _dropdown(
                        _selectedVal6,
                        _questionlist6,
                            (val) => setState(() => _selectedVal6 = val),
                      ),

                      const SizedBox(height: 25),
                      const Text(
                        "10. Cracked or Loose Panel",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Select the device cracked or loose panel condition",
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      _dropdown(
                        _selectedVal7,
                        _questionlist7,
                            (val) => setState(() => _selectedVal7 = val),
                      ),

                      const SizedBox(height: 25),

                      const Text(
                        "Age of your device",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Let us know how old is your device. Valid bill is needed for devices less than 3 years.",
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      Column(
                        children: [
                          _radioBox(
                            "Less than 1 year (in warranty)",
                            "less_1",
                            q2,
                                (val) => setState(() => q2 = val),
                          ),
                          _radioBox(
                            "Between 1 and 3 years",
                            "between_1_3",
                            q2,
                                (val) => setState(() => q2 = val),
                          ),
                          _radioBox(
                            "More than 3 years",
                            "more_3",
                            q2,
                                (val) => setState(() => q2 = val),
                          ),
                        ],
                      ),

                      const SizedBox(height: 25),

                      const Text(
                        "Is there anything else you would like to mention about your Laptop’s condition?",
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
                          onPressed: isLoading ? null : submitLaptopRequest,
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
                                  style: WidgetSupporter.whitetextstyle(
                                    20.0,
                                  ),
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

  Widget _dropdown(String? value, List<String> items, Function(String) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items
          .map((e) => DropdownMenuItem<String>(value: e, child: Text(e)))
          .toList(),
      onChanged: (val) {
        if (val != null) onChanged(val);
      },
      icon: const Icon(Icons.arrow_drop_down_circle, color: Colors.green),
      dropdownColor: Colors.white,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
      ),
    );
  }
}