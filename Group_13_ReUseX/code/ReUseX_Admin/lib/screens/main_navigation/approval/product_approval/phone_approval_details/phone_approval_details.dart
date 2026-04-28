import 'package:flutter/material.dart';

import '../../../../../utils/app_colors.dart';
import '../price_predicting_page.dart';

class PhoneDetailPage extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> requestData;

  const PhoneDetailPage({
    super.key,
    required this.docId,
    required this.requestData,
  });

  Map<String, dynamic> _safeMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return {};
  }

  String _getImageUrl() {
    final possibleFields = [
      requestData['imageUrl'],
      requestData['productImage'],
      requestData['photoUrl'],
      requestData['photo'],
      requestData['image'],
    ];

    for (final value in possibleFields) {
      final url = (value ?? '').toString().trim();
      if (url.isNotEmpty) return url;
    }

    return '';
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> answers = _safeMap(requestData['answers']);

    final Map<String, dynamic> defects =
    _safeMap(answers['screenBodyDefects']);

    final Map<String, dynamic> problems =
    _safeMap(answers['functionalPhysicalProblems']);

    final Map<String, dynamic> accessories =
    _safeMap(answers['accessories']);

    final Map<String, dynamic> laptopPhysical =
    _safeMap(answers['physicalCondition']);

    final Map<String, dynamic> laptopProblems =
    _safeMap(answers['functionalProblems']);

    final String mobile = ((requestData['mobile'] ??
        requestData['phone'] ??
        requestData['phoneNumber'] ??
        '')
        .toString())
        .trim();

    final String deviceType =
    (requestData['deviceType'] ?? '').toString().toLowerCase().trim();

    final String imageUrl = _getImageUrl();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F4FF),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          "Request Details",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _sectionCard(
              icon: Icons.image_rounded,
              title: "Product Image",
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                    imageUrl,
                    width: double.infinity,
                    height: 220,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: double.infinity,
                        height: 220,
                        color: const Color(0xFFF3F2FF),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.broken_image_rounded,
                              size: 42,
                              color: AppColors.primary,
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Image not available",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF555555),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  )
                      : Container(
                    width: double.infinity,
                    height: 220,
                    color: const Color(0xFFF3F2FF),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_not_supported_rounded,
                          size: 42,
                          color: AppColors.primary,
                        ),
                        SizedBox(height: 8),
                        Text(
                          "No image uploaded",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF555555),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            _sectionCard(
              icon: Icons.person_rounded,
              title: "User Info",
              children: [
                _infoRow(
                  "Name",
                  (requestData['userName'] ??
                      requestData['fullName'] ??
                      "Not provided")
                      .toString(),
                ),
                _infoRow(
                  "Mobile",
                  mobile.isEmpty ? "Not provided" : mobile,
                ),
              ],
            ),

            const SizedBox(height: 14),

            _sectionCard(
              icon: Icons.devices_other_rounded,
              title: "Device Info",
              children: [
                _infoRow(
                  "Type",
                  _capitalize((requestData['deviceType'] ?? "").toString()),
                ),
                _infoRow(
                  "Title",
                  (requestData['title'] ?? "").toString(),
                ),
              ],
            ),

            const SizedBox(height: 14),

            if (deviceType == "phone") ...[
              _sectionCard(
                icon: Icons.quiz_rounded,
                title: "General Answers",
                children: [
                  _infoRow(
                    "Can make calls",
                    (answers['canMakeCalls'] ?? "").toString(),
                  ),
                  _infoRow(
                    "Touch working",
                    (answers['touchWorking'] ?? "").toString(),
                  ),
                  _infoRow(
                    "Screen original",
                    (answers['screenOriginal'] ?? "").toString(),
                  ),
                  _infoRow(
                    "Physical condition",
                    (answers['physicalCondition'] ?? "").toString(),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              _sectionCard(
                icon: Icons.broken_image_rounded,
                title: "Screen & Body Defects",
                children: [
                  _boolRow(
                    "Dead Spot / Discoloration",
                    defects['deadSpotVisibleLineDiscoloration'] == true,
                  ),
                  _boolRow(
                    "Scratch / Dent on Body",
                    defects['scratchDentOnBody'] == true,
                  ),
                  _boolRow(
                    "Panel Missing / Broken",
                    defects['panelMissingBroken'] == true,
                  ),
                ],
              ),

              const SizedBox(height: 14),

              _sectionCard(
                icon: Icons.build_rounded,
                title: "Functional Problems",
                children: [
                  _boolRow(
                    "Front Camera",
                    problems['frontCamNotWorking'] == true,
                  ),
                  _boolRow(
                    "Back Camera",
                    problems['backCamNotWorking'] == true,
                  ),
                  _boolRow(
                    "Volume Button",
                    problems['volumeButtonNotWorking'] == true,
                  ),
                  _boolRow(
                    "Fingerprint / Touch",
                    problems['fingerTouchNotWorking'] == true,
                  ),
                ],
              ),

              const SizedBox(height: 14),

              _sectionCard(
                icon: Icons.inventory_2_rounded,
                title: "Accessories",
                children: [
                  _boolRow(
                    "Original Charger",
                    accessories['originalCharger'] == true,
                  ),
                  _boolRow(
                    "Original Box (Same IMEI)",
                    accessories['originalBoxSameImei'] == true,
                  ),
                ],
              ),
            ],

            if (deviceType == "laptop") ...[
              _sectionCard(
                icon: Icons.memory_rounded,
                title: "Laptop Specs",
                children: [
                  _infoRow(
                    "Switches On",
                    (answers['switchesOn'] ?? "").toString(),
                  ),
                  _infoRow(
                    "Processor",
                    (answers['processor'] ?? "").toString(),
                  ),
                  _infoRow(
                    "RAM",
                    (answers['ram'] ?? "").toString(),
                  ),
                  _infoRow(
                    "Storage",
                    (answers['hardDisk'] ?? "").toString(),
                  ),
                  _infoRow(
                    "Graphics Card",
                    (answers['graphicsCard'] ?? "").toString(),
                  ),
                  _infoRow(
                    "Screen Size",
                    (answers['screenSize'] ?? "").toString(),
                  ),
                  _infoRow(
                    "Device Age",
                    (answers['deviceAge'] ?? "").toString(),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              _sectionCard(
                icon: Icons.build_circle_rounded,
                title: "Functional Problems",
                children: [
                  _boolRow(
                    "Keyboard Issue",
                    laptopProblems['keyboardIssue'] == true,
                  ),
                  _boolRow(
                    "Touchpad Issue",
                    laptopProblems['touchpadIssue'] == true,
                  ),
                  _boolRow(
                    "Battery Issue",
                    laptopProblems['batteryIssue'] == true,
                  ),
                ],
              ),

              const SizedBox(height: 14),

              _sectionCard(
                icon: Icons.laptop_chromebook_rounded,
                title: "Physical Condition",
                children: [
                  _infoRow(
                    "Screen Scratch Condition",
                    (laptopPhysical['screenScratchCondition'] ?? "").toString(),
                  ),
                  _infoRow(
                    "Screen Discolouration",
                    (laptopPhysical['screenDiscolouration'] ?? "").toString(),
                  ),
                  _infoRow(
                    "Screen Lines",
                    (laptopPhysical['screenLines'] ?? "").toString(),
                  ),
                  _infoRow(
                    "Body Scratch Condition",
                    (laptopPhysical['bodyScratchCondition'] ?? "").toString(),
                  ),
                  _infoRow(
                    "Top Panel Dent Condition",
                    (laptopPhysical['topPanelDentCondition'] ?? "").toString(),
                  ),
                  _infoRow(
                    "Loose Hinges",
                    (laptopPhysical['looseHinges'] ?? "").toString(),
                  ),
                  _infoRow(
                    "Cracked or Loose Panel",
                    (laptopPhysical['crackedOrLoosePanel'] ?? "").toString(),
                  ),
                ],
              ),
            ],

            if (deviceType == "others") ...[
              _sectionCard(
                icon: Icons.category_rounded,
                title: "Other Item Details",
                children: [
                  _infoRow(
                    "Item / Model Name",
                    (answers['itemModelName'] ?? "").toString(),
                  ),
                  _infoRow(
                    "Working Properly",
                    (answers['workingProperly'] ?? "").toString(),
                  ),
                  _infoRow(
                    "Physical Damage",
                    (answers['hasPhysicalDamage'] ?? "").toString(),
                  ),
                ],
              ),
            ],

            if ((requestData['additionalNotes'] ?? "").toString().trim().isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.notes_rounded,
                            color: AppColors.primary,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          "Additional Notes",
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Color(0xFF2D2D2D),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      requestData['additionalNotes'].toString(),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PriceQuotePage(docId: docId),
                  ),
                );
              },
              child: Container(
                height: 58,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFAB9FF2), AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    SizedBox(width: 10),
                    Text(
                      "Approve Request",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _capitalize(String value) {
    if (value.trim().isEmpty) return "Not provided";
    return value[0].toUpperCase() + value.substring(1);
  }

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: Color(0xFF2D2D2D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.secondary),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    final displayValue = value.trim().isEmpty ? "Not provided" : value;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Color(0xFF555555),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              displayValue,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF888888),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _boolRow(String label, bool value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Color(0xFF555555),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: value
                  ? const Color(0xFFDCFCE7)
                  : const Color(0xFFFFEBEB),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(
                  value ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  size: 13,
                  color: value
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFDC2626),
                ),
                const SizedBox(width: 4),
                Text(
                  value ? "Yes" : "No",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: value
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFDC2626),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}