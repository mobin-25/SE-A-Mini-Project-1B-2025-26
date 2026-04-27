import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:reusex/screens/home/home.dart';
import 'package:reusex/screens/sell/approval_page/approval_page.dart';

import '../../../widgets/widget_supporter/widget_supporter.dart';

String? q1;
String? q2;
String? q3;

class UploadSsd extends StatefulWidget {
  const UploadSsd({super.key});

  @override
  State<UploadSsd> createState() => _UploadSsdState();
}

class _UploadSsdState extends State<UploadSsd> {
  _UploadSsdState() {
    _selectedVal1 = _questionlist1[0];
    _selectedVal2 = _questionlist2[0];
  }

  final _questionlist1 = [
    "SATA SSD",
    "NVMe (M.2)",
  ];

  final _questionlist2 = [
    "1 SSD",
    "2 SSDs",
  ];

  String? _selectedVal1 = "";
  String? _selectedVal2 = "";

  bool defect1 = false;
  bool defect2 = false;
  bool defect3 = false;
  bool defect4 = false;

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
          style: TextStyle(color: Colors.white, fontFamily: 'Lora',fontWeight: FontWeight.w600),
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
                  // for scrolling
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            Container(
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
                              child: const Icon(
                                Icons.camera_alt_outlined,
                                size: 35,
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
                        "Tell us more about your SSD?",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 4),

                      const Text(
                        "Please answer a few questions about your ssd.",
                        style: TextStyle(color: Colors.grey,fontSize: 15),
                      ),

                      const SizedBox(height: 20),

                      // -------- Question 1 --------
                      const Text(
                        "1. What is the SSD capacity?",
                        style: TextStyle(fontWeight: FontWeight.bold,fontSize: 18),
                      ),

                      const SizedBox(height: 10),

                      TextFormField(
                        minLines: 1,   // starting height
                        maxLines: 1,   // how much it can grow
                        decoration: const InputDecoration(
                          hintText: "512 GB",
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 25),

                      // -------- Question 2 --------
                      const Text(
                        "2. Which type of SSD is installed?",
                        style: TextStyle(fontWeight: FontWeight.bold,fontSize: 18),
                      ),

                      const SizedBox(height: 10),

                      DropdownButtonFormField(
                        value: _selectedVal1,
                        items: _questionlist1
                            .map(
                              (e) => DropdownMenuItem(child: Text(e), value: e),
                        )
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedVal1 = val as String;
                          });
                        },
                        icon: const Icon(
                          Icons.arrow_drop_down_circle,
                          color: Colors.green,
                        ),
                        dropdownColor: Colors.white,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 25),

                      // -------- Question 3 --------
                      const Text(
                        "3. Is this SSD the main system drive?",
                        style: TextStyle(fontWeight: FontWeight.bold,fontSize: 18),
                      ),

                      const SizedBox(height: 4),

                      const Text(
                        "Is Windows installed on this SSD?",
                        style: TextStyle(color: Colors.grey,fontSize: 16),
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

                      // -------- Question 4 --------
                      const Text(
                        "4. How many SSDs are installed?",
                        style: TextStyle(fontWeight: FontWeight.bold,fontSize: 18),
                      ),

                      const SizedBox(height: 10),

                      DropdownButtonFormField(
                        value: _selectedVal2,
                        items: _questionlist2
                            .map(
                              (e) => DropdownMenuItem(child: Text(e), value: e),
                        )
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedVal2 = val as String;
                          });
                        },
                        icon: const Icon(
                          Icons.arrow_drop_down_circle,
                          color: Colors.green,
                        ),
                        dropdownColor: Colors.white,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 25),

                      // -------- Question 5 --------
                      const Text(
                        "5. Is the SSD detected properly in the system?",
                        style: TextStyle(fontWeight: FontWeight.bold,fontSize: 18),
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
                                  q2= val;
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

                      // -------- Question 6 --------
                      const Text(
                        "6. Has this SSD ever been repaired or replaced?",
                        style: TextStyle(fontWeight: FontWeight.bold,fontSize: 18),
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
                                  q3= val;
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

                      // -------- Question 7 --------
                      const Text(
                        "7. Are you facing any of these issues with the SSD?",
                        style: TextStyle(fontWeight: FontWeight.bold,fontSize: 18),
                      ),

                      const SizedBox(height: 10),

                      CheckboxListTile(
                        value: defect1,
                        title: Text(
                          "Slow boot or app loading",
                          style: TextStyle(fontSize: 16 ),
                        ),
                        activeColor: Colors.green,
                        onChanged: (val) {
                          setState(() {
                            defect1 = val!;
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                      ),

                      const SizedBox(height: 10),

                      CheckboxListTile(
                        value: defect2,
                        title: Text("Files take very long to open",style: TextStyle(fontSize: 16 )),
                        activeColor: Colors.green,
                        onChanged: (val) {
                          setState(() {
                            defect2 = val!;
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                      ),

                      const SizedBox(height: 10),

                      CheckboxListTile(
                        value: defect3,
                        title: Text("Frequent freezing while accessing files",style: TextStyle(fontSize: 16 )),
                        activeColor: Colors.green,
                        onChanged: (val) {
                          setState(() {
                            defect3 = val!;
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                      ),

                      CheckboxListTile(
                        value: defect4,
                        title: Text("Drive sometimes disappears",style: TextStyle(fontSize: 16 )),
                        activeColor: Colors.green,
                        onChanged: (val) {
                          setState(() {
                            defect4 = val!;
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                      ),

                      const SizedBox(height: 25),

                      const Text(
                        "Is there anything else you would like to mention about your SSD’s condition?",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),

                      const SizedBox(height: 10),

                      TextFormField(
                        minLines: 4,   // starting height
                        maxLines: 6,   // how much it can grow
                        decoration: const InputDecoration(
                          hintText: "Describe",
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 25),

                      Center(
                        child: CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            Navigator.push(
                              context,
                              CupertinoPageRoute(builder: (context) => ApprovalPage()),
                            );
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
                                child: Text(
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
