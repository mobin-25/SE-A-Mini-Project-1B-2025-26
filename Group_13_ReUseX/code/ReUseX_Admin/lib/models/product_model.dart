class Product {
  final String? id;
  final String title;
  final String description;
  final String price;
  final String category;
  final String gradeLevel;
  final String inspectionHistory;
  final String imageUrl;
  final bool isActive;

  Product({
    this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    required this.gradeLevel,
    required this.inspectionHistory,
    required this.imageUrl,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      "title": title,
      "description": description,
      "price": price,
      "category": category,
      "gradeLevel": gradeLevel,
      "inspectionHistory": inspectionHistory,
      "imageUrl": imageUrl,
      "isActive": isActive,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map, String docId) {
    return Product(
      id: docId,
      title: (map["title"] ?? "").toString(),
      description: (map["description"] ?? "").toString(),
      price: (map["price"] ?? "").toString(),
      category: (map["category"] ?? "").toString(),
      gradeLevel: (map["gradeLevel"] ?? "").toString(),
      inspectionHistory: (map["inspectionHistory"] ?? "").toString(),
      imageUrl: (map["imageUrl"] ?? "").toString(),
      isActive: map["isActive"] ?? true,
    );
  }
}