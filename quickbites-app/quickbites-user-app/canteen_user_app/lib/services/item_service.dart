import '../models/item_cart/item_dto.dart';
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

class ItemService {
  final ApiClient _apiClient;

  ItemService({ApiClient? apiClient, Future<void> Function()? onUnauthorized})
      : _apiClient = apiClient ?? ApiClient(onUnauthorized: onUnauthorized);

  Future<List<ItemDto>> _getAllItemsFromEndpoint(String path) async {
    final firstResponse = await _apiClient.get(path);

    if (firstResponse is! Map || firstResponse['content'] is! List<dynamic>) {
      return _parseItemList(firstResponse);
    }

    final totalPages = switch (firstResponse['totalPages']) {
      num value => value.toInt(),
      String value => int.tryParse(value) ?? 1,
      _ => 1,
    };

    final items = <ItemDto>[..._parseItemList(firstResponse)];
    if (totalPages <= 1) {
      return items;
    }

    final separator = path.contains('?') ? '&' : '?';
    final remainingPages = await Future.wait(
      List.generate(totalPages - 1, (index) => index + 1).map(
        (pageNo) => _apiClient.get('$path${separator}pageNo=$pageNo'),
      ),
    );

    for (final response in remainingPages) {
      items.addAll(_parseItemList(response));
    }

    return items;
  }

  List<ItemDto> _parseItemList(dynamic json) {
    final rawItems = switch (json) {
      List<dynamic> list => list,
      Map<String, dynamic> map when map['content'] is List<dynamic> => map['content'] as List<dynamic>,
      Map<String, dynamic> map when map['items'] is List<dynamic> => map['items'] as List<dynamic>,
      Map<String, dynamic> map when map['data'] is List<dynamic> => map['data'] as List<dynamic>,
      Map map when map['content'] is List<dynamic> => map['content'] as List<dynamic>,
      Map map when map['items'] is List<dynamic> => map['items'] as List<dynamic>,
      Map map when map['data'] is List<dynamic> => map['data'] as List<dynamic>,
      _ => throw const ApiException('Unexpected item list response format'),
    };

    return rawItems.map(_parseItem).toList();
  }

  ItemDto _parseSingleItem(dynamic json) {
    if (json is List<dynamic>) {
      if (json.isEmpty) {
        throw const ApiException('Item not found');
      }
      return _parseItem(json.first);
    }

    if (json is Map<String, dynamic>) {
      final nestedList = json['content'] ?? json['items'] ?? json['data'];
      if (nestedList is List<dynamic>) {
        if (nestedList.isEmpty) {
          throw const ApiException('Item not found');
        }
        return _parseItem(nestedList.first);
      }
      return ItemDto.fromJson(json);
    }

    if (json is Map) {
      return _parseSingleItem(Map<String, dynamic>.from(json));
    }

    throw const ApiException('Unexpected item response format');
  }

  ItemDto _parseItem(dynamic item) {
    if (item is Map<String, dynamic>) {
      return ItemDto.fromJson(item);
    }

    if (item is Map) {
      return ItemDto.fromJson(Map<String, dynamic>.from(item));
    }

    throw const ApiException('Unexpected item payload format');
  }

  Future<List<ItemDto>> getItems() async {
    return _getAllItemsFromEndpoint('/item');
  }

  Future<PagedResponse<ItemDto>> getItemsPaginated(int pageNo) async {
    final json = await _apiClient.get('/item?pageNo=$pageNo');
    return PagedResponse.fromJson(
      json as Map<String, dynamic>,
      (json) => ItemDto.fromJson(json),
    );
  }

  Future<List<ItemDto>> getItemsByCategory(String categoryName) async {
    final normalizedCategory = categoryName.trim().toUpperCase();
    return _getAllItemsFromEndpoint('/item/category?categoryName=$normalizedCategory');
  }

  Future<PagedResponse<ItemDto>> getItemsByCategoryPaginated(
      String categoryName, int pageNo) async {
    final normalizedCategory = categoryName.trim().toUpperCase();
    final json =
        await _apiClient.get('/item/category?categoryName=$normalizedCategory&pageNo=$pageNo');
    return PagedResponse.fromJson(
      json as Map<String, dynamic>,
      (json) => ItemDto.fromJson(json),
    );
  }

  Future<List<ItemDto>> getInstantReadyItems() async {
    final json = await _apiClient.get('/item/instant-ready');
    return _parseItemList(json);
  }

  Future<ItemDto> getItemByName(String itemName) async {
    final json = await _apiClient.get('/item/$itemName');
    return _parseSingleItem(json);
  }

  Future<List<ItemDto>> getItemsByPriceRange(int minPrice, int maxPrice) async {
    final json = await _apiClient.get('/item/price-range?minPrice=$minPrice&highPrice=$maxPrice');
    return _parseItemList(json);
  }
}
