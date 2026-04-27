import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:reusex/screens/home/home.dart';
import 'package:reusex/screens/sell/approval_page/approval_page.dart';

import '../../../widgets/widget_supporter/widget_supporter.dart';

String? q1;
String? q2;

class UploadRam extends StatefulWidget {
  const UploadRam({super.key});

  @override
  State<UploadRam> createState() => _UploadRamState();
}

class _UploadRamState extends State<UploadRam> {
  _UploadRamState() {
    _selectedVal = _questionlist1[0];
  }

  final _questionlist1 = [
    "DDR3",
    "DDR4",
    "DDR5",
  ];
  String? _selectedVal = "";

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
                        "Tell us more about your ram?",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 4),

                      const Text(
                        "Please answer a few questions about your ram.",
                        style: TextStyle(color: Colors.grey,fontSize: 15),
                      ),

                      const SizedBox(height: 20),

                      // -------- Question 1 --------
                      const Text(
                        "1. Installed RAM size",
                        style: TextStyle(fontWeight: FontWeight.bold,fontSize: 18),
                      ),

                      const SizedBox(height: 10),

                      TextFormField(
                        minLines: 1,   // starting height
                        maxLines: 1,   // how much it can grow
                        decoration: const InputDecoration(
                          hintText: "4 GB",
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 25),

                      // -------- Question 2 --------
                      const Text(
                        "2. RAM type",
                        style: TextStyle(fontWeight: FontWeight.bold,fontSize: 18),
                      ),

                      const SizedBox(height: 10),

                      DropdownButtonFormField(
                        value: _selectedVal,
                        items: _questionlist1
                            .map(
                              (e) => DropdownMenuItem(child: Text(e), value: e),
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
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 25),

                      // -------- Question 3 --------
                      const Text(
                        "3. RAM speed (MHz)",
                        style: TextStyle(fontWeight: FontWeight.bold,fontSize: 18),
                      ),

                      const SizedBox(height: 10),

                      TextFormField(
                        minLines: 1,   // starting height
                        maxLines: 1,   // how much it can grow
                        decoration: const InputDecoration(
                          hintText: "3200 Mhz",
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 25),

                      // -------- Question 4 --------
                      const Text(
                        "4. Is the RAM upgraded or original?",
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
                              title: const Text("Original RAM"),
                              value: "original",
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
                              title: const Text("Upgraded RAM"),
                              value: "upgraded",
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

                      // -------- Question 5 --------
                      const Text(
                        "5. Does your laptop show any RAM related error or crash? ",
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
                        "Is there anything else you would like to mention about your RAM’s condition?",
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
