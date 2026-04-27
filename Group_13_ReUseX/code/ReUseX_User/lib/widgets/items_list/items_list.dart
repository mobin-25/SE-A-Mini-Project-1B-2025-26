import 'package:flutter/material.dart';

class ItemsGrid extends StatelessWidget {
  final int itemCount;

  final String Function(int index) imagePathBuilder;
  final String Function(int index) titleBuilder;
  final String Function(int index) priceBuilder;

  final void Function(int index)? onBuy;

  const ItemsGrid({
    super.key,
    required this.itemCount,
    required this.imagePathBuilder,
    required this.titleBuilder,
    required this.priceBuilder,
    this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.72,
        ),
        itemBuilder: (context, index) {
          return _ItemCard(
            imagePath: imagePathBuilder(index),
            title: titleBuilder(index),
            price: priceBuilder(index),
            onBuy: onBuy == null ? null : () => onBuy!(index),
          );
        },
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final String price;
  final VoidCallback? onBuy;

  const _ItemCard({
    required this.imagePath,
    required this.title,
    required this.price,
    this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF4CAF50),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Image.asset(
              imagePath,
              fit: BoxFit.contain,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            price,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF4CAF50),
            ),
          ),

          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            height: 36,
            child: ElevatedButton(
              onPressed: onBuy,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: const Text(
                "Buy",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
