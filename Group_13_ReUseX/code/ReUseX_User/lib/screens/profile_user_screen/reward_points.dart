import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RewardPointsPage extends StatefulWidget {
  const RewardPointsPage({super.key});

  @override
  State<RewardPointsPage> createState() => _RewardPointsPageState();
}

class _RewardPointsPageState extends State<RewardPointsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _progressAnim;

  int totalPoints = 0;
  bool isGenerating = false;
  List<Map<String, dynamic>> approvedProducts = [];
  List<Map<String, dynamic>> coupons = [];
  List<Map<String, dynamic>> availableProducts = [];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _progressAnim = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _fetchData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    debugPrint("Reward page logged-in UID: ${user.uid}");

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('recycle_requests')
          .where('status', isEqualTo: 'approved')
          .orderBy('updatedAt', descending: false)
          .get();

      final allApproved = snapshot.docs.map((doc) {
        final data = doc.data();
        data['docId'] = doc.id;
        return data;
      }).toList();

      final products = allApproved.where((item) => item['userId'] == user.uid).toList();

      final couponSnap = await FirebaseFirestore.instance
          .collection('reward_coupons')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      final couponList = couponSnap.docs.map((doc) {
        final data = doc.data();
        data['docId'] = doc.id;
        return data;
      }).toList();

      final usableProducts = products.where((p) => p['redeemed'] != true).toList();
      final points = usableProducts.length * 500;

      setState(() {
        approvedProducts = products;
        availableProducts = usableProducts;
        coupons = couponList;
        totalPoints = points;
      });

      final progress = (points % 1000) / 1000;
      _progressAnim = Tween<double>(begin: 0, end: progress).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
      );
      _animController.forward(from: 0);
    } catch (e) {
      debugPrint("Reward fetch error: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load rewards: $e")),
      );
    }
  }

  String _generateCouponCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random.secure();
    return 'RX-' +
        List.generate(4, (_) => chars[rand.nextInt(chars.length)]).join() +
        '-' +
        List.generate(4, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  Future<void> _redeemPoints() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (totalPoints < 1000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You need at least 1000 points to redeem."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => isGenerating = true);

    try {
      final code = _generateCouponCode();

      await FirebaseFirestore.instance.collection('reward_coupons').add({
        'userId': user.uid,
        'code': code,
        'discount': 500,
        'isUsed': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      int deducted = 0;

      for (final product in availableProducts) {
        if (deducted >= 2) break;

        final docId = product['docId'];
        if (docId != null) {
          await FirebaseFirestore.instance
              .collection('recycle_requests')
              .doc(docId)
              .update({'redeemed': true});
          deducted++;
        }
      }

      await _fetchData();

      if (!mounted) return;
      _showCouponDialog(code);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to generate coupon: $e")),
      );
    } finally {
      if (mounted) setState(() => isGenerating = false);
    }
  }

  void _showCouponDialog(String code) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSmall = constraints.maxWidth < 340;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.card_giftcard_rounded,
                      color: Colors.green,
                      size: 44,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Coupon Generated!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Lora',
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "You've earned ₹500 off on your next purchase!",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Coupon code copied!")),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmall ? 14 : 18,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FFF4),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.green.shade300,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: FittedBox(
                              alignment: Alignment.centerLeft,
                              fit: BoxFit.scaleDown,
                              child: Text(
                                code,
                                maxLines: 1,
                                style: TextStyle(
                                  fontSize: isSmall ? 18 : 22,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.green,
                                  letterSpacing: isSmall ? 1.2 : 2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(Icons.copy, color: Colors.green, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Tap to copy",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        "Done",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Coupon code copied to clipboard!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final redeemable = totalPoints ~/ 1000;
    final remainder = totalPoints % 1000;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Scaffold(
      backgroundColor: const Color(0xFFF6FBF6),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.green,
        elevation: 0,
        title: const Text(
          "Reward Points",
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Lora',
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: Colors.green,
        onRefresh: _fetchData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(isSmallScreen ? 14 : 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(isSmallScreen ? 18 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 10,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.eco,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Total Reward Points",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              "ReuseX Green Rewards",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Lora',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 340;

                        return Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.end,
                          spacing: 12,
                          runSpacing: 14,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    "$totalPoints",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: compact ? 42 : 52,
                                      fontWeight: FontWeight.w900,
                                      height: 1,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8, left: 6),
                                  child: Text(
                                    "pts",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: compact ? 17 : 20,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              constraints: BoxConstraints(
                                maxWidth: compact ? constraints.maxWidth : 180,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Text(
                                "$redeemable coupon${redeemable == 1 ? '' : 's'} available",
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final compact = constraints.maxWidth < 320;

                            if (compact) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "$remainder / 1000 pts to next coupon",
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    "= ₹500 off",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              );
                            }

                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    "$remainder / 1000 pts to next coupon",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  "= ₹500 off",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: AnimatedBuilder(
                            animation: _progressAnim,
                            builder: (context, _) {
                              return LinearProgressIndicator(
                                value: _progressAnim.value,
                                minHeight: 10,
                                backgroundColor: Colors.white.withOpacity(0.25),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (totalPoints >= 1000 && !isGenerating)
                            ? _redeemPoints
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.green,
                          disabledBackgroundColor: Colors.white.withOpacity(0.3),
                          disabledForegroundColor: Colors.white70,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: isGenerating
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.green,
                          ),
                        )
                            : FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.card_giftcard_rounded,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                totalPoints >= 1000
                                    ? "Redeem 1000 pts for ₹500 off"
                                    : "Need ${1000 - remainder} more pts to redeem",
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "How It Works",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Lora',
                      ),
                    ),
                    const SizedBox(height: 14),
                    _howItWorksStep(
                      icon: Icons.recycling,
                      color: Colors.green,
                      title: "Submit a Recycle Request",
                      subtitle: "Upload your product for recycling",
                    ),
                    _howItWorksStep(
                      icon: Icons.admin_panel_settings_outlined,
                      color: Colors.blue,
                      title: "Admin Approves It",
                      subtitle: "Our team verifies your submission",
                    ),
                    _howItWorksStep(
                      icon: Icons.star,
                      color: Colors.orange,
                      title: "Earn 500 Points",
                      subtitle: "Per approved product",
                    ),
                    _howItWorksStep(
                      icon: Icons.card_giftcard_rounded,
                      color: Colors.purple,
                      title: "Redeem at 1000 Points",
                      subtitle: "Get ₹500 off on your next purchase",
                      isLast: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (coupons.isNotEmpty) ...[
                const Text(
                  "Your Coupons",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Lora',
                  ),
                ),
                const SizedBox(height: 12),
                ...coupons.map(
                      (coupon) => _CouponCard(
                    code: coupon['code'] ?? '',
                    discount: (coupon['discount'] ?? 500).toDouble(),
                    isUsed: coupon['isUsed'] ?? false,
                    onCopy: () => _copyCode(coupon['code'] ?? ''),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      "Approved Recycles",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Lora',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "${approvedProducts.length} item${approvedProducts.length == 1 ? '' : 's'}",
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (approvedProducts.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.recycling,
                        size: 48,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "No approved recycles yet",
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Submit a product for recycling to start earning!",
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                ...approvedProducts.map(
                      (product) => _ApprovedProductCard(product: product),
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _howItWorksStep({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 28,
                color: Colors.grey.shade200,
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CouponCard extends StatelessWidget {
  final String code;
  final double discount;
  final bool isUsed;
  final VoidCallback onCopy;

  const _CouponCard({
    required this.code,
    required this.discount,
    required this.isUsed,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isUsed ? Colors.grey.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isUsed ? Colors.grey.shade200 : Colors.green.shade200,
        ),
        boxShadow: isUsed
            ? []
            : [
          BoxShadow(
            color: Colors.green.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final leftWidth = constraints.maxWidth < 340 ? 78.0 : 90.0;

          return Stack(
            children: [
              Positioned(
                left: leftWidth,
                top: 0,
                bottom: 0,
                child: VerticalDivider(
                  color: Colors.grey.shade300,
                  thickness: 1.2,
                  width: 1.2,
                  indent: 12,
                  endIndent: 12,
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: leftWidth,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 8 : 10,
                        vertical: 16,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              "₹${discount.toInt()}",
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 22 : 26,
                                fontWeight: FontWeight.w900,
                                color: isUsed ? Colors.grey : Colors.green,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "OFF",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isUsed ? Colors.grey : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isUsed)
                            Align(
                              alignment: Alignment.topRight,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  "USED",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ),
                          Text(
                            code,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 15 : 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: isSmallScreen ? 0.8 : 1.5,
                              color: isUsed ? Colors.grey : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isUsed
                                ? "Already used"
                                : "Valid on checkout • Apply to save ₹${discount.toInt()}",
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: isUsed ? Colors.grey.shade400 : Colors.black45,
                            ),
                          ),
                          if (!isUsed) ...[
                            const SizedBox(height: 10),
                            GestureDetector(
                              onTap: onCopy,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.green.shade200,
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.copy,
                                      size: 14,
                                      color: Colors.green,
                                    ),
                                    SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        "Copy Code",
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.green,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ApprovedProductCard extends StatelessWidget {
  final Map<String, dynamic> product;

  const _ApprovedProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final imageUrl = (product['imageUrl'] ?? '').toString();
    final productDetails = product['productDetails'] ?? 'Product';
    final isRedeemed = product['redeemed'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: imageUrl.isNotEmpty
                ? Image.network(
              imageUrl,
              width: 70,
              height: 70,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholder(),
            )
                : _placeholder(),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productDetails,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, size: 13, color: Colors.green),
                          SizedBox(width: 3),
                          Text(
                            "+500 pts",
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isRedeemed)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          "Redeemed",
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 70,
      height: 70,
      color: Colors.grey.shade100,
      child: const Icon(
        Icons.image_not_supported,
        size: 28,
        color: Colors.grey,
      ),
    );
  }
}