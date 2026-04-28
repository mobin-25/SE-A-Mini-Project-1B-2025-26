class Product {
  final String id;
  final String name;
  final String image;
  final double price;
  final String category;

  Product({
    required this.id,
    required this.name,
    required this.image,
    required this.price,
    required this.category,
  });

  factory Product.fromFirestore(Map<String, dynamic> data, String id) {
    return Product(
      id: id,
      name: data['name'] ?? '',
      image: data['image'] ?? '',
      category: data['category'] ?? '',

      // 🔥 SAFE FIX (no more crashes EVER)
      price: data['price'] != null
          ? (data['price'] as num).toDouble()
          : 0.0,
    );
  }
}