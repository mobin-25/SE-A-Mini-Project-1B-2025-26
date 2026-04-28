import '../item_cart/item_dto.dart';

class OrderItemDto {
  final ItemDto menuItem;
  final int quantity;
  final double historicalPrice;

  const OrderItemDto({
    required this.menuItem,
    required this.quantity,
    required this.historicalPrice,
  });

  factory OrderItemDto.fromJson(Map<String, dynamic> json) {
    return OrderItemDto(
      menuItem: ItemDto.fromJson(json['menuItem'] as Map<String, dynamic>),
      quantity: json['quantity'] as int,
      historicalPrice: (json['historicalPrice'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'menuItem': menuItem.toJson(),
      'quantity': quantity,
      'historicalPrice': historicalPrice,
    };
  }
}
