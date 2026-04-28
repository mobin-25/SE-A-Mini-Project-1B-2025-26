import '../models/order_user/order_ticket_dto.dart';
import 'api_client.dart';

class OrderService {
  final ApiClient _apiClient;

  OrderService({ApiClient? apiClient, Future<void> Function()? onUnauthorized})
      : _apiClient = apiClient ?? ApiClient(onUnauthorized: onUnauthorized);

  Future<OrderTicketDto> placeOrder() async {
    final json = await _apiClient.post('/order/place');
    return OrderTicketDto.fromJson(json as Map<String, dynamic>);
  }

  Future<OrderTicketDto> getOrderDetails(int orderId) async {
    final json = await _apiClient.post('/order/get-order-detail/$orderId');
    return OrderTicketDto.fromJson(json as Map<String, dynamic>);
  }

  Future<void> reOrder(int orderId) async {
    await _apiClient.post('/order/re-order/$orderId');
  }

  Future<void> cancelOrder(int orderId) async {
    await _apiClient.post('/order/cancel-order/$orderId');
  }

  Future<int> getOrderWaitTime(int orderId) async {
    final response = await _apiClient.get('/order/$orderId/checkWaitTime');
    return _toInt(response);
  }

  Future<int> getTotalQueueWaitTime() async {
    final response = await _apiClient.get('/order/wait-time');
    return _toInt(response);
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is Map<String, dynamic>) {
      final raw = value['waitTime'] ?? value['minutes'] ?? value['value'];
      return _toInt(raw);
    }
    return 0;
  }
}
