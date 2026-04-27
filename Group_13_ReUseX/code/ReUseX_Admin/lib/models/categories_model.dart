class CategoryProduct {
  String? id;
  String name;
  String description;
  String imagePath;
  bool isActive;

  CategoryProduct({
    this.id,
    required this.name,
    required this.description,
    required this.imagePath,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      "name": name,
      "description": description,
      "imagePath": imagePath,
      "isActive": isActive,
    };
  }

  factory CategoryProduct.fromMap(Map<String, dynamic> map, String docId) {
    return CategoryProduct(
      id: docId,
      name: map["name"] ?? "",
      description: map["description"] ?? "",
      imagePath: map["imagePath"] ?? "",
      isActive: map["isActive"] ?? true,
    );
  }
}