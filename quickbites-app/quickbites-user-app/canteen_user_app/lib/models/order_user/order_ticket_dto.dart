import 'order_item_dto.dart';

class OrderTicketDto {
  final int? orderId;
  final String username;
  final List<OrderItemDto> orderItems;
  final double totalAmount;
  final String orderStatus;
  final int estPrepTime;
  final String createdAt;
  final String? completedAt;
  final String? updatedAt;
  final String? orderUuid;

  const OrderTicketDto({
    this.orderId,
    required this.username,
    required this.orderItems,
    required this.totalAmount,
    required this.orderStatus,
    required this.estPrepTime,
    required this.createdAt,
    this.completedAt,
    this.updatedAt,
    this.orderUuid,
  });

  factory OrderTicketDto.fromJson(Map<String, dynamic> json) {
    final items = (json['orderItems'] as List<dynamic>)
        .map((item) => OrderItemDto.fromJson(item as Map<String, dynamic>))
        .toList();

    return OrderTicketDto(
      orderId: (json['orderId'] ?? json['id']) == null
          ? null
          : int.tryParse((json['orderId'] ?? json['id']).toString()),
      username: json['username'] as String,
      orderItems: items,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      orderStatus: json['orderStatus'] as String,
        estPrepTime: (json['estPrepTime'] as num?)?.toInt() ??
          (json['estimatedWaitTime'] as num?)?.toInt() ??
          0,
      createdAt: json['createdAt'] as String,
      completedAt: json['completedAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      orderUuid: (json['orderUuid'] ?? json['orderToken'] ?? json['token'])
          as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'username': username,
      'orderItems': orderItems.map((item) => item.toJson()).toList(),
      'totalAmount': totalAmount,
      'orderStatus': orderStatus,
      'estPrepTime': estPrepTime,
      'createdAt': createdAt,
      'completedAt': completedAt,
      'updatedAt': updatedAt,
      'orderUuid': orderUuid,
    };
  }
}
