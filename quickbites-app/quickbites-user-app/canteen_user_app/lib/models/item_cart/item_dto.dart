class ItemDto {
  final int itemId;
  final String itemName;
  final int price;
  final String imageUrl;
  final String category;
  final bool isAvailable;
  final int readyIn;

  const ItemDto({
    required this.itemId,
    required this.itemName,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.isAvailable,
    required this.readyIn,
  });

  factory ItemDto.fromJson(Map<String, dynamic> json) {
    final availabilityRaw = json['isAvailable'] ?? json['available'];
    final parsedAvailability = switch (availabilityRaw) {
      bool b => b,
      num n => n != 0,
      String s => s.toLowerCase() == 'true' || s == '1',
      _ => false,
    };

    return ItemDto(
      itemId: (json['itemId'] as num).toInt(),
      itemName: json['itemName'] as String,
      price: (json['price'] as num).toInt(),
      imageUrl: json['imageUrl'] as String,
      category: (json['category'] ?? '').toString(),
      isAvailable: parsedAvailability,
      readyIn: (json['readyIn'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'itemName': itemName,
      'price': price,
      'imageUrl': imageUrl,
      'category': category,
      'isAvailable': isAvailable,
      'readyIn': readyIn,
    };
  }
}
