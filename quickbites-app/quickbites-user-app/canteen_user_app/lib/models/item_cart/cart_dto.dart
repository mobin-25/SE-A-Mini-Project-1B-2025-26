import 'cart_item_dto.dart';

class CartDto {
  final int cartId;
  final List<CartItemDto> cartItems;
  final double totalCartPrice;
  final int estPrepTime;

  const CartDto({
    required this.cartId,
    required this.cartItems,
    required this.totalCartPrice,
    required this.estPrepTime,
  });

  factory CartDto.fromJson(Map<String, dynamic> json) {
    final items = (json['cartItems'] as List<dynamic>)
        .map((item) => CartItemDto.fromJson(item as Map<String, dynamic>))
        .toList();

    return CartDto(
      cartId: json['cartId'] as int,
      cartItems: items,
      totalCartPrice: (json['totalCartPrice'] as num?)?.toDouble() ?? 0,
      estPrepTime: (json['estPrepTime'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cartId': cartId,
      'cartItems': cartItems.map((item) => item.toJson()).toList(),
      'totalCartPrice': totalCartPrice,
      'estPrepTime': estPrepTime,
    };
  }

  CartDto copyWith({
    int? cartId,
    List<CartItemDto>? cartItems,
    double? totalCartPrice,
    int? estPrepTime,
  }) {
    return CartDto(
      cartId: cartId ?? this.cartId,
      cartItems: cartItems ?? this.cartItems,
      totalCartPrice: totalCartPrice ?? this.totalCartPrice,
      estPrepTime: estPrepTime ?? this.estPrepTime,
    );
  }
}
