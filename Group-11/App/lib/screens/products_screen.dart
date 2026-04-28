import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/product_service.dart';
import '../services/cart_service.dart';
import '../models/product_model.dart';
import '../models/cart_item.dart';

class ProductsScreen extends StatelessWidget {
  ProductsScreen({super.key});

  final ProductService productService = ProductService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("🐾 Pet Store"),
        backgroundColor: const Color.fromARGB(255, 243, 150, 237),
      ),

      body: StreamBuilder<List<Product>>(
        stream: productService.getProducts(),
        builder: (context, snapshot) {

          // 🔴 ERROR HANDLING (important)
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          // ⏳ LOADING
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final products = snapshot.data!;

          if (products.isEmpty) {
            return const Center(child: Text("No products found"));
          }

          // ✅ MATCH YOUR CATEGORY NAMES EXACTLY
          final food =
              products.where((p) => p.category == 'food').toList();

          final accessories =
              products.where((p) => p.category == 'Accessory').toList();

          final bowls =
              products.where((p) => p.category == 'bowls').toList();

          return SingleChildScrollView(
            child: Column(
              children: [
                if (food.isNotEmpty)
                  _buildSection("🍖 Food", food, context),

                if (accessories.isNotEmpty)
                  _buildSection("🦴 Accessories", accessories, context),

                if (bowls.isNotEmpty)
                  _buildSection("🥣 Bowls", bowls, context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection(
      String title, List<Product> products, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔥 SECTION TITLE
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              title,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

          const SizedBox(height: 10),

          SizedBox(
            height: 270,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];

                return Container(
                  width: 170,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 5)
                    ],
                  ),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🖼 IMAGE
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(14)),
                        child: Image.network(
                          product.image,
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,

                          errorBuilder: (context, error, stackTrace) {
                            return const SizedBox(
                              height: 120,
                              child: Center(
                                  child: Icon(Icons.image_not_supported)),
                            );
                          },
                        ),
                      ),

                      // 📦 DETAILS
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(product.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),

                            const SizedBox(height: 4),

                            Text("₹${product.price}",
                                style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold)),

                            const SizedBox(height: 8),

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color.fromARGB(255, 170, 143, 216),
                                ),
                                onPressed: () {
                                  final cart =
                                      Provider.of<CartService>(context,
                                          listen: false);

                                  cart.addToCart(
                                    CartItem(
                                      id: product.id,
                                      name: product.name,
                                      image: product.image,
                                      price: product.price,
                                    ),
                                  );

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          "${product.name} added to cart"),
                                    ),
                                  );
                                },
                                child: const Text("Add"),
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}