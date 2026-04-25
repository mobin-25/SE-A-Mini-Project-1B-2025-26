import '../models/order_user/order_ticket_dto.dart';
import '../models/order_user/user_response_dto.dart';
import 'api_client.dart';

class PagedResponse<T> {
  final List<T> content;
  final int pageNumber;
  final int pageSize;
  final int totalElements;
  final int totalPages;
  final bool last;

  PagedResponse({
    required this.content,
    required this.pageNumber,
    required this.pageSize,
    required this.totalElements,
    required this.totalPages,
    required this.last,
  });

  factory PagedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return PagedResponse(
      content: (json['content'] as List<dynamic>)
          .map((item) => fromJsonT(item as Map<String, dynamic>))
          .toList(),
      pageNumber: json['number'] as int,
      pageSize: json['size'] as int,
      totalElements: json['totalElements'] as int,
      totalPages: json['totalPages'] as int,
      last: json['last'] as bool,
    );
  }
}

class UserService {
  final ApiClient _apiClient;

  UserService({ApiClient? apiClient, Future<void> Function()? onUnauthorized})
      : _apiClient = apiClient ?? ApiClient(onUnauthorized: onUnauthorized);

  Future<List<OrderTicketDto>> getMyOrders() async {
    final json = await _apiClient.get('/users/my-orders');
    return (json as List<dynamic>)
        .map((order) => OrderTicketDto.fromJson(order as Map<String, dynamic>))
        .toList();
  }

  Future<PagedResponse<OrderTicketDto>> getMyOrdersPaginated(int pageNo) async {
    final json = await _apiClient.get('/users/my-orders?pageNo=$pageNo');
    return PagedResponse.fromJson(
      json as Map<String, dynamic>,
      (json) => OrderTicketDto.fromJson(json),
    );
  }

  Future<UserResponseDto> getMyProfile() async {
    final json = await _apiClient.get('/users');
    return UserResponseDto.fromJson(json as Map<String, dynamic>);
  }
}
