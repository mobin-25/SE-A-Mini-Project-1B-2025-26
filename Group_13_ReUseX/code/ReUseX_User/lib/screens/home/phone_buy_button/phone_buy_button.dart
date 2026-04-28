import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../widgets/widget_supporter/widget_supporter.dart';
import 'checkout_page/checkout_page.dart';

class PhoneBuyButton extends StatefulWidget {
  final String productName;
  final String productImage;
  final String description;
  final double price;
  final double? oldPrice;
  final String gradeLevel;
  final String inspectionHistory;
  final String category;

  const PhoneBuyButton({
    super.key,
    required this.productName,
    required this.productImage,
    required this.description,
    required this.price,
    this.oldPrice,
    required this.gradeLevel,
    required this.inspectionHistory,
    required this.category,
  });

  @override
  State<PhoneBuyButton> createState() => _PhoneBuyButtonState();
}

class _PhoneBuyButtonState extends State<PhoneBuyButton> {
  String formatIndianPrice(double price) {
    final formatter = NumberFormat('#,##,##0', 'en_IN');
    return "₹${formatter.format(price)}";
  }

  double get discountPercentage {
    if (widget.oldPrice == null || widget.oldPrice == 0) return 0;
    return ((widget.oldPrice! - widget.price) / widget.oldPrice!) * 100;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: widget.productImage.startsWith("http")
                        ? Image.network(
                      widget.productImage,
                      height: 220,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 220,
                          width: 220,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.image_not_supported,
                            size: 50,
                            color: Colors.grey,
                          ),
                        );
                      },
                    )
                        : Image.asset(
                      widget.productImage,
                      height: 220,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 220,
                          width: 220,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.image_not_supported,
                            size: 50,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.productName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Lora',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.description,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Category : ${widget.category}",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),
                  RichText(
                    text: TextSpan(
                      children: [
                        if (widget.oldPrice != null &&
                            widget.oldPrice! > widget.price)
                          TextSpan(
                            text:
                            '-${discountPercentage.toStringAsFixed(0)}% ',
                            style: const TextStyle(
                              color: Color(0xFFFF5A5A),
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Lora',
                            ),
                          ),
                        TextSpan(
                          text: '${formatIndianPrice(widget.price)} ',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Lora',
                          ),
                        ),
                        if (widget.oldPrice != null &&
                            widget.oldPrice! > widget.price)
                          TextSpan(
                            text: formatIndianPrice(widget.oldPrice!),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 18,
                              decoration: TextDecoration.lineThrough,
                              decorationThickness: 2,
                              fontFamily: 'Lora',
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "Grade Level : ${widget.gradeLevel}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Inspection History",
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      fontFamily: 'Lora',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.inspectionHistory,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 15,
                      fontFamily: 'Lora',
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (context) => CheckoutPage(
                        productName: widget.productName,
                        productImage: widget.productImage,
                        price: widget.price,
                        oldPrice: widget.oldPrice,
                        category: widget.category,
                        gradeLevel: widget.gradeLevel,
                      ),
                    ),
                  );
                },
                child: Material(
                  elevation: 5.0,
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    height: 60,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Center(
                      child: Text(
                        "Buy Now",
                        style: WidgetSupporter.whitetextstyle(21.0),
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