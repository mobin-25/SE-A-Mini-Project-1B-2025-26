import 'item_dto.dart';

class CartItemDto {
  final int cartItemId;
  final double cartItemPrice;
  final int quantity;
  final ItemDto menuItem;

  const CartItemDto({
    required this.cartItemId,
    required this.cartItemPrice,
    required this.quantity,
    required this.menuItem,
  });

  factory CartItemDto.fromJson(Map<String, dynamic> json) {
    return CartItemDto(
      cartItemId: json['cartItemId'] as int,
      cartItemPrice: (json['cartItemPrice'] as num).toDouble(),
      quantity: json['quantity'] as int,
      menuItem: ItemDto.fromJson(json['menuItem'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cartItemId': cartItemId,
      'cartItemPrice': cartItemPrice,
      'quantity': quantity,
      'menuItem': menuItem.toJson(),
    };
  }

  CartItemDto copyWith({
    int? cartItemId,
    double? cartItemPrice,
    int? quantity,
    ItemDto? menuItem,
  }) {
    return CartItemDto(
      cartItemId: cartItemId ?? this.cartItemId,
      cartItemPrice: cartItemPrice ?? this.cartItemPrice,
      quantity: quantity ?? this.quantity,
      menuItem: menuItem ?? this.menuItem,
    );
  }
}
