import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:reusex/screens/home/phone_buy_button/checkout_page/Orderplaced_page/Orderplaced_page.dart';
import '../../../../widgets/widget_supporter/widget_supporter.dart';

class CheckoutPage extends StatefulWidget {
  final String productName;
  final String productImage;
  final double price;
  final double? oldPrice;
  final String category;
  final String gradeLevel;

  const CheckoutPage({
    super.key,
    required this.productName,
    required this.productImage,
    required this.price,
    this.oldPrice,
    required this.category,
    required this.gradeLevel,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  bool codSelected = true;
  bool _isPlacingOrder = false;

  String addressLabel = "Home or Office";
  String fullName = "Name";
  String phoneNumber = "Phone Number";
  String addressLine1 = "Address";
  String city = "City";
  String pincode = "Pincode";

  final double shipping = 200.00;
  final double tax = 448.49;

  final TextEditingController _couponController = TextEditingController();
  bool _isValidatingCoupon = false;
  double _couponDiscount = 0.0;
  String? _appliedCouponCode;
  String? _couponDocId;
  String? _couponError;

  double get total {
    final calculated = widget.price + shipping + tax - _couponDiscount;
    return calculated < 0 ? 0 : calculated;
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  String formatIndianPrice(double price) {
    final formatter = NumberFormat('#,##,##0.00', 'en_IN');
    return "₹${formatter.format(price)}";
  }

  bool get _isAddressValid {
    return addressLabel.trim().isNotEmpty &&
        addressLabel != "Home or Office" &&
        fullName.trim().isNotEmpty &&
        fullName != "Name" &&
        phoneNumber.trim().isNotEmpty &&
        phoneNumber != "Phone Number" &&
        addressLine1.trim().isNotEmpty &&
        addressLine1 != "Address" &&
        city.trim().isNotEmpty &&
        city != "City" &&
        pincode.trim().isNotEmpty &&
        pincode != "Pincode";
  }

  Future<void> _applyCoupon() async {
    final code = _couponController.text.trim().toUpperCase();

    if (code.isEmpty) {
      setState(() => _couponError = "Please enter a coupon code.");
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _couponError = "Please login to apply coupons.");
      return;
    }

    setState(() {
      _isValidatingCoupon = true;
      _couponError = null;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('reward_coupons')
          .where('code', isEqualTo: code)
          .where('userId', isEqualTo: user.uid)
          .where('isUsed', isEqualTo: false)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        setState(() {
          _couponError = "Invalid or already used coupon code.";
          _couponDiscount = 0.0;
          _appliedCouponCode = null;
          _couponDocId = null;
        });
        return;
      }

      final doc = snapshot.docs.first;
      final data = doc.data();
      final discount = ((data['discount'] ?? 0) as num).toDouble();

      if (discount <= 0) {
        setState(() {
          _couponError = "This coupon is not valid.";
          _couponDiscount = 0.0;
          _appliedCouponCode = null;
          _couponDocId = null;
        });
        return;
      }

      final safeDiscount = discount > (widget.price + shipping + tax)
          ? (widget.price + shipping + tax)
          : discount;

      setState(() {
        _couponDiscount = safeDiscount;
        _appliedCouponCode = code;
        _couponDocId = doc.id;
        _couponError = null;
        _couponController.text = code;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Coupon applied! You save ${formatIndianPrice(safeDiscount)}",
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _couponError = "Something went wrong. Please try again.";
        _couponDiscount = 0.0;
        _appliedCouponCode = null;
        _couponDocId = null;
      });
    } finally {
      if (mounted) {
        setState(() => _isValidatingCoupon = false);
      }
    }
  }

  void _removeCoupon() {
    setState(() {
      _couponDiscount = 0.0;
      _appliedCouponCode = null;
      _couponDocId = null;
      _couponError = null;
      _couponController.clear();
    });
  }

  Future<void> _editAddress() async {
    final nameController = TextEditingController(
      text: fullName == "Name" ? "" : fullName,
    );
    final phoneController = TextEditingController(
      text: phoneNumber == "Phone Number" ? "" : phoneNumber,
    );
    final labelController = TextEditingController(
      text: addressLabel == "Home or Office" ? "" : addressLabel,
    );
    final line1Controller = TextEditingController(
      text: addressLine1 == "Address" ? "" : addressLine1,
    );
    final cityController = TextEditingController(
      text: city == "City" ? "" : city,
    );
    final pincodeController = TextEditingController(
      text: pincode == "Pincode" ? "" : pincode,
    );

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 18,
            right: 18,
            top: 18,
            bottom: MediaQuery.of(context).viewInsets.bottom + 18,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 45,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  "Edit Address",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Lora',
                  ),
                ),
                const SizedBox(height: 18),
                _buildTextField("Address Label", labelController),
                const SizedBox(height: 12),
                _buildTextField("Full Name", nameController),
                const SizedBox(height: 12),
                _buildTextField(
                  "Phone Number",
                  phoneController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                ),
                const SizedBox(height: 12),
                _buildTextField("Address Line", line1Controller, maxLines: 2),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField("City", cityController),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        "Pincode",
                        pincodeController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      if (labelController.text.trim().isEmpty ||
                          nameController.text.trim().isEmpty ||
                          phoneController.text.trim().isEmpty ||
                          line1Controller.text.trim().isEmpty ||
                          cityController.text.trim().isEmpty ||
                          pincodeController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Please fill all address fields"),
                          ),
                        );
                        return;
                      }

                      setState(() {
                        addressLabel = labelController.text.trim();
                        fullName = nameController.text.trim();
                        phoneNumber = phoneController.text.trim();
                        addressLine1 = line1Controller.text.trim();
                        city = cityController.text.trim();
                        pincode = pincodeController.text.trim();
                      });

                      Navigator.pop(context);
                    },
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          "Save Address",
                          style: WidgetSupporter.whitetextstyle(18.0),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField(
      String hint,
      TextEditingController controller, {
        TextInputType keyboardType = TextInputType.text,
        int maxLines = 1,
        List<TextInputFormatter>? inputFormatters,
      }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xfff5f5f5),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget sectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xfffafafa),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }

  Widget amountRow(
      String title,
      double value, {
        bool totalRow = false,
        bool isDiscount = false,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: totalRow ? 18 : 16,
              fontWeight: totalRow ? FontWeight.w700 : FontWeight.w500,
              color: isDiscount
                  ? Colors.green
                  : totalRow
                  ? Colors.green
                  : Colors.black87,
            ),
          ),
          Text(
            isDiscount
                ? "- ${formatIndianPrice(value)}"
                : formatIndianPrice(value),
            style: TextStyle(
              fontSize: totalRow ? 18 : 16,
              fontWeight: totalRow ? FontWeight.w700 : FontWeight.w500,
              color: isDiscount
                  ? Colors.green
                  : totalRow
                  ? Colors.green
                  : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildProductImage() {
    if (widget.productImage.startsWith("http")) {
      return Image.network(
        widget.productImage,
        height: 85,
        width: 85,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 85,
            width: 85,
            color: Colors.grey.shade200,
            child: const Icon(Icons.image_not_supported),
          );
        },
      );
    }

    return Image.asset(
      widget.productImage,
      height: 85,
      width: 85,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          height: 85,
          width: 85,
          color: Colors.grey.shade200,
          child: const Icon(Icons.image_not_supported),
        );
      },
    );
  }

  Widget _buildCouponSection() {
    return sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.card_giftcard_rounded,
                  color: Colors.green,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                "Apply Coupon",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Lora',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_appliedCouponCode != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _appliedCouponCode!,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: Colors.green,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          "You save ${formatIndianPrice(_couponDiscount)}!",
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _removeCoupon,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: const Text(
                        "Remove",
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _couponController,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                    decoration: InputDecoration(
                      hintText: "Enter coupon code",
                      hintStyle: const TextStyle(
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF5F5F5),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      errorText: _couponError,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isValidatingCoupon ? null : _applyCoupon,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      elevation: 0,
                    ),
                    child: _isValidatingCoupon
                        ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                        : const Text(
                      "Apply",
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 14,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(width: 6),
                Text(
                  "Use your ReuseX reward coupon to save ₹500",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _placeOrder() async {
    if (_isPlacingOrder) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please login first.")),
      );
      return;
    }

    if (!_isAddressValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill your shipping address first.")),
      );
      return;
    }

    setState(() {
      _isPlacingOrder = true;
    });

    try {
      await FirebaseFirestore.instance.collection("orders").add({
        "userId": user.uid,
        "productName": widget.productName,
        "productImage": widget.productImage,
        "price": widget.price,
        "category": widget.category,
        "gradeLevel": widget.gradeLevel,
        "addressLabel": addressLabel,
        "fullName": fullName,
        "phoneNumber": phoneNumber,
        "addressLine1": addressLine1,
        "city": city,
        "pincode": pincode,
        "couponCode": _appliedCouponCode,
        "couponDiscount": _couponDiscount > 0 ? _couponDiscount : 0,
        "totalAfterDiscount": total < 0 ? 0 : total,
        "status": "Pending",
        "createdAt": FieldValue.serverTimestamp(),
      });

      if (_couponDocId != null) {
        await FirebaseFirestore.instance
            .collection('reward_coupons')
            .doc(_couponDocId)
            .update({'isUsed': true});
      }

      if (!mounted) return;
      Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (context) => OrderplacedPage(),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Order failed: $e")),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPlacingOrder = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.green,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Checkout",
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Lora',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    sectionCard(
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: buildProductImage(),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.productName,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "Category: ${widget.category}",
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Grade: ${widget.gradeLevel}",
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  formatIndianPrice(widget.price),
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    sectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Shipping Address",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Lora',
                                ),
                              ),
                              IconButton(
                                onPressed: _editAddress,
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.green,
                                  size: 22,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              addressLabel,
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            fullName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            phoneNumber,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "$addressLine1\n$city, $pincode",
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _buildCouponSection(),
                    const SizedBox(height: 18),
                    sectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Payment Method",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Lora',
                            ),
                          ),
                          const SizedBox(height: 10),
                          InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              setState(() {
                                codSelected = true;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: codSelected
                                      ? Colors.green
                                      : Colors.grey.shade300,
                                ),
                                color: codSelected
                                    ? Colors.green.withOpacity(0.06)
                                    : Colors.white,
                              ),
                              child: Row(
                                children: [
                                  Radio<bool>(
                                    value: true,
                                    groupValue: codSelected,
                                    activeColor: Colors.green,
                                    onChanged: (value) {
                                      setState(() {
                                        codSelected = value ?? true;
                                      });
                                    },
                                  ),
                                  const Expanded(
                                    child: Text(
                                      "Cash On Delivery",
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.local_shipping_outlined,
                                    color: Colors.green,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    sectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Order Summary",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Lora',
                            ),
                          ),
                          const SizedBox(height: 12),
                          amountRow("Subtotal", widget.price),
                          amountRow("Shipping", shipping),
                          amountRow("Tax", tax),
                          if (_couponDiscount > 0)
                            amountRow(
                              "Coupon Discount ($_appliedCouponCode)",
                              _couponDiscount,
                              isDiscount: true,
                            ),
                          const SizedBox(height: 6),
                          Divider(color: Colors.grey.shade300),
                          amountRow("Total", total, totalRow: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _isPlacingOrder ? null : _placeOrder,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    height: 60,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: _isPlacingOrder
                          ? Colors.green.shade300
                          : Colors.green,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Center(
                      child: _isPlacingOrder
                          ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                          : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "Place Order",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_couponDiscount > 0)
                            Text(
                              "Total: ${formatIndianPrice(total)}",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                        ],
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