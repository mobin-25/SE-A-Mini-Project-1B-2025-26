import 'package:canteen_user_app/services/item_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/item_cart/item_dto.dart';
import 'service_providers.dart';

final allItemsProvider = FutureProvider<List<ItemDto>>((ref) async {
  return ref.read(itemServiceProvider).getItems();
});

final selectedCategoryProvider = StateProvider<String?>((ref) => null);

final searchQueryProvider = StateProvider<String>((ref) => '');

final priceRangeProvider = StateProvider<(int, int)?>((ref) => null);

final filteredItemsProvider = FutureProvider<List<ItemDto>>((ref) async {
  final selectedCategory = ref.watch(selectedCategoryProvider);
  final searchQuery = ref.watch(searchQueryProvider);
  final priceRange = ref.watch(priceRangeProvider);

  List<ItemDto> items;

  // Fetch items from backend
  if (selectedCategory == null) {
    items = await ref.read(itemServiceProvider).getItems();
  } else {
    items = await ref.read(itemServiceProvider).getItemsByCategory(selectedCategory);
  }

  // Apply search filter (fuzzy search - partial name matching)
  if (searchQuery.isNotEmpty) {
    items = items
        .where((item) => item.itemName.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();
  }

  // Apply price range filter
  if (priceRange != null) {
    final (minPrice, maxPrice) = priceRange;
    items = items.where((item) => item.price >= minPrice && item.price <= maxPrice).toList();
  }

  return items;
});

final instantReadyItemsProvider = FutureProvider<List<ItemDto>>((ref) async {
  return ref.read(itemServiceProvider).getInstantReadyItems();
});

// Pagination state for items
class ItemsPaginationState {
  final List<ItemDto> items;
  final int currentPage;
  final bool isLoading;
  final bool hasMore;
  final String? error;
  final String? selectedCategory;

  ItemsPaginationState({
    required this.items,
    required this.currentPage,
    required this.isLoading,
    required this.hasMore,
    this.error,
    this.selectedCategory,
  });

  ItemsPaginationState copyWith({
    List<ItemDto>? items,
    int? currentPage,
    bool? isLoading,
    bool? hasMore,
    String? error,
    String? selectedCategory,
  }) {
    return ItemsPaginationState(
      items: items ?? this.items,
      currentPage: currentPage ?? this.currentPage,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error ?? this.error,
      selectedCategory: selectedCategory ?? this.selectedCategory,
    );
  }
}

// Items pagination notifier
class ItemsPaginationNotifier extends StateNotifier<ItemsPaginationState> {
  final ItemService _itemService;

  ItemsPaginationNotifier(this._itemService)
      : super(ItemsPaginationState(
          items: [],
          currentPage: 0,
          isLoading: false,
          hasMore: true,
        ));

  Future<void> loadInitial({String? category}) async {
    state = ItemsPaginationState(
      items: [],
      currentPage: 0,
      isLoading: true,
      hasMore: true,
      selectedCategory: category,
    );

    try {
      final response = category == null
          ? await _itemService.getItemsPaginated(0)
          : await _itemService.getItemsByCategoryPaginated(category, 0);
      
      state = ItemsPaginationState(
        items: response.content,
        currentPage: 0,
        isLoading: false,
        hasMore: !response.last,
        selectedCategory: category,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);

    try {
      final nextPage = state.currentPage + 1;
      final response = state.selectedCategory == null
          ? await _itemService.getItemsPaginated(nextPage)
          : await _itemService.getItemsByCategoryPaginated(
              state.selectedCategory!, nextPage);
      
      state = ItemsPaginationState(
        items: [...state.items, ...response.content],
        currentPage: nextPage,
        isLoading: false,
        hasMore: !response.last,
        selectedCategory: state.selectedCategory,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refresh() async {
    await loadInitial(category: state.selectedCategory);
  }

  void changeCategory(String? category) {
    loadInitial(category: category);
  }
}

final itemsPaginationProvider =
    StateNotifierProvider<ItemsPaginationNotifier, ItemsPaginationState>(
  (ref) => ItemsPaginationNotifier(ref.read(itemServiceProvider)),
);

