import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/cart_provider.dart';
import '../providers/home_providers.dart';
import '../utils/app_error_message.dart';
import '../widgets/item_card.dart';
import '../widgets/skeleton_box.dart';
import 'item_detail_screen.dart';
import 'search_results_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  final _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Load initial items only if empty
    Future.microtask(() {
      final currentState = ref.read(itemsPaginationProvider);
      if (currentState.items.isEmpty && !currentState.isLoading) {
        final selectedCategory = ref.read(selectedCategoryProvider);
        ref.read(itemsPaginationProvider.notifier).loadInitial(category: selectedCategory);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      ref.read(itemsPaginationProvider.notifier).loadMore();
    }
  }

  String _displayCategoryTitle(String? selectedCategory) {
    if (selectedCategory == null) return 'Popular Today';
    final pretty = selectedCategory
        .toLowerCase()
        .split('_')
        .map((part) => part.isEmpty
            ? part
            : '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
    return '$pretty Picks';
  }

  void _showPriceFilterDialog() {
    final currentRange = ref.read(priceRangeProvider);
    int minPrice = currentRange?.$1 ?? 0;
    int maxPrice = currentRange?.$2 ?? 500;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF5A1F), Color(0xFFFF8C42)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.tune, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Text('Filter by Price'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF5A1F), Color(0xFFFF8C42)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.currency_rupee,
                        color: Colors.white, size: 28),
                    Text(
                      '$minPrice',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '—',
                        style: TextStyle(
                          fontSize: 24,
                          color: Colors.white70,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),
                    const Icon(Icons.currency_rupee,
                        color: Colors.white, size: 28),
                    Text(
                      '$maxPrice',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFE4D6)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Min Price',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF5A1F), Color(0xFFFF8C42)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.currency_rupee,
                                  color: Colors.white, size: 14),
                              Text(
                                '$minPrice',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: const Color(0xFFFF5A1F),
                        inactiveTrackColor: const Color(0xFFFFE4D6),
                        thumbColor: const Color(0xFFFF5A1F),
                        overlayColor: const Color(0xFFFF5A1F).withOpacity(0.2),
                        valueIndicatorColor: const Color(0xFFFF5A1F),
                        valueIndicatorTextStyle:
                            const TextStyle(color: Colors.white),
                      ),
                      child: Slider(
                        value: minPrice.toDouble(),
                        min: 0,
                        max: 500,
                        divisions: 50,
                        label: '₹$minPrice',
                        onChanged: (value) {
                          setState(() {
                            minPrice = value.toInt();
                            if (minPrice > maxPrice) maxPrice = minPrice;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFE4D6)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Max Price',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF5A1F), Color(0xFFFF8C42)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.currency_rupee,
                                  color: Colors.white, size: 14),
                              Text(
                                '$maxPrice',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: const Color(0xFFFF5A1F),
                        inactiveTrackColor: const Color(0xFFFFE4D6),
                        thumbColor: const Color(0xFFFF5A1F),
                        overlayColor: const Color(0xFFFF5A1F).withOpacity(0.2),
                        valueIndicatorColor: const Color(0xFFFF5A1F),
                        valueIndicatorTextStyle:
                            const TextStyle(color: Colors.white),
                      ),
                      child: Slider(
                        value: maxPrice.toDouble(),
                        min: 0,
                        max: 500,
                        divisions: 50,
                        label: '₹$maxPrice',
                        onChanged: (value) {
                          setState(() {
                            maxPrice = value.toInt();
                            if (maxPrice < minPrice) minPrice = maxPrice;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                ref.read(priceRangeProvider.notifier).state = null;
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[600],
              ),
              child: const Text('Clear'),
            ),
            FilledButton(
              onPressed: () {
                ref.read(priceRangeProvider.notifier).state =
                    (minPrice, maxPrice);
                Navigator.pop(context);
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF5A1F),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Apply Filter'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Must call for AutomaticKeepAliveClientMixin
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final paginationState = ref.watch(itemsPaginationProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final priceRange = ref.watch(priceRangeProvider);

    // Apply local filters on paginated items
    var displayItems = paginationState.items;
    if (searchQuery.isNotEmpty) {
      displayItems = displayItems
          .where((item) =>
              item.itemName.toLowerCase().contains(searchQuery.toLowerCase()))
          .toList();
    }
    if (priceRange != null) {
      final (minPrice, maxPrice) = priceRange;
      displayItems = displayItems
          .where((item) => item.price >= minPrice && item.price <= maxPrice)
          .toList();
    }

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          unawaited(
            Future<void>(() async {
              await ref.read(itemsPaginationProvider.notifier).refresh();
              ref.invalidate(instantReadyItemsProvider);
            }),
          );

          await Future<void>.delayed(const Duration(milliseconds: 100));
        },
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFF2E8), Color(0xFFFFFBF7)],
            ),
          ),
          child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            textInputAction: TextInputAction.search,
                            decoration: InputDecoration(
                              hintText: 'Search for dishes...',
                              prefixIcon: const Icon(Icons.search_rounded),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear_rounded),
                                      onPressed: () {
                                        setState(() {
                                          _searchController.clear();
                                        });
                                        ref
                                            .read(searchQueryProvider.notifier)
                                            .state = '';
                                      },
                                    )
                                  : null,
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {});
                            },
                            onSubmitted: (value) {
                              if (value.trim().isEmpty) return;
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => SearchResultsScreen(
                                      searchQuery: value.trim()),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: ref.watch(priceRangeProvider) != null
                                ? const Color(0xFFFF5A1F)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0F000000),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            onPressed: _showPriceFilterDialog,
                            icon: Icon(
                              Icons.tune_rounded,
                              color: ref.watch(priceRangeProvider) != null
                                  ? Colors.white
                                  : const Color(0xFF64748B),
                            ),
                            tooltip: 'Filter by price',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFFF7E36), Color(0xFFFFB067)],
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33FF7E36),
                          blurRadius: 26,
                          offset: Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.24),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: const Text(
                            '🔥 Hot right now on campus',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Cravings calling?\nGrab your bite now.',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                height: 1.15,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Freshly prepared canteen favourites in minutes.',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.92),
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _CategoryHeaderDelegate(
                selectedCategory: selectedCategory,
                onCategorySelected: (category) {
                  ref.read(selectedCategoryProvider.notifier).state = category;
                  ref.read(itemsPaginationProvider.notifier).changeCategory(category);
                },
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _displayCategoryTitle(selectedCategory),
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F172A),
                                ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE5D4),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            selectedCategory ?? 'ALL ITEMS',
                            style: const TextStyle(
                              color: Color(0xFF9A3412),
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (ref.watch(searchQueryProvider).isNotEmpty ||
                        ref.watch(priceRangeProvider) != null) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (ref.watch(searchQueryProvider).isNotEmpty)
                            Chip(
                              label: Text(
                                  'Search: \"${ref.watch(searchQueryProvider)}\"'),
                              deleteIcon: const Icon(Icons.close, size: 18),
                              onDeleted: () {
                                setState(() {
                                  _searchController.clear();
                                });
                                ref.read(searchQueryProvider.notifier).state =
                                    '';
                              },
                              backgroundColor: const Color(0xFFE0F2FE),
                              side: BorderSide.none,
                            ),
                          if (ref.watch(priceRangeProvider) != null)
                            Chip(
                              label: Text(
                                  'Price: ₹${ref.watch(priceRangeProvider)!.$1} - ₹${ref.watch(priceRangeProvider)!.$2}'),
                              deleteIcon: const Icon(Icons.close, size: 18),
                              onDeleted: () {
                                ref.read(priceRangeProvider.notifier).state =
                                    null;
                              },
                              backgroundColor: const Color(0xFFFFE5D4),
                              side: BorderSide.none,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _buildItemsList(displayItems, paginationState),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildItemsList(List<dynamic> items, ItemsPaginationState state) {
    if (state.isLoading && items.isEmpty) {
      return const _HomeItemsSkeleton();
    }

    if (state.error != null && items.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFE4E6),
          borderRadius: BorderRadius.circular(14),
        ),
         child: Text(
           appErrorMessage(
             state.error!,
             fallback: 'Unable to load menu items right now. Please try again.',
           ),
           style: const TextStyle(
               color: Color(0xFF9F1239), fontWeight: FontWeight.w600),
         ),
      );
    }

    if (items.isEmpty) {
      final searchQuery = ref.watch(searchQueryProvider);
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFFF5A1F).withOpacity(0.1),
              const Color(0xFFFF8C42).withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFFFE4D6),
            width: 2,
          ),
        ),
        child: Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5A1F).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  searchQuery.isNotEmpty
                      ? Icons.search_off_rounded
                      : Icons.restaurant_menu_rounded,
                  size: 56,
                  color: const Color(0xFFFF5A1F),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                searchQuery.isNotEmpty ? 'No Results Found' : 'No Items Available',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                searchQuery.isNotEmpty
                    ? 'We couldn\'t find "$searchQuery" in our menu. Try searching for something else!'
                    : 'The canteen is currently restocking. Check back soon!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF64748B),
                      height: 1.5,
                    ),
              ),
              if (searchQuery.isNotEmpty) ...[
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                    });
                    ref.read(searchQueryProvider.notifier).state = '';
                  },
                  icon: const Icon(Icons.clear_rounded),
                  label: const Text('Clear Search'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5A1F),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    final children = List.generate(items.length, (index) {
      final item = items[index];
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: ItemCard(
          item: item,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ItemDetailScreen(item: item),
              ),
            );
          },
          onAdd: () async {
            try {
              await ref.read(cartProvider.notifier).addToCart(item.itemId);
              // Refresh cart to show updated data when user switches to cart
              ref.invalidate(cartProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${item.itemName} added to cart',
                            style: const TextStyle(fontSize: 15),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: const Color(0xFF15803D),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    margin: const EdgeInsets.all(16),
                    duration: const Duration(milliseconds: 1500),
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.white, size: 20),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Unable to add item to cart',
                            style: TextStyle(fontSize: 15),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: const Color(0xFFDC2626),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    margin: const EdgeInsets.all(16),
                  ),
                );
              }
            }
          },
        ),
      );
    });

    // Add loading indicator at bottom if loading more
    if (state.isLoading && items.isNotEmpty) {
      children.add(
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Column(children: children);
  }
}

class _HomeItemsSkeleton extends StatelessWidget {
  const _HomeItemsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        5,
        (_) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonBox(
                  width: 86,
                  height: 86,
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      SkeletonBox(height: 16, width: 140),
                      SizedBox(height: 8),
                      SkeletonBox(height: 12, width: 110),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SkeletonBox(height: 18, width: 56),
                          SkeletonBox(height: 34, width: 108),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String? selectedCategory;
  final Function(String?) onCategorySelected;

  _CategoryHeaderDelegate({
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  static const _banners = [
    (
      category: null,
      title: 'All Items',
      subtitle: 'Browse full canteen menu 🍽️',
      icon: '🍽️',
      colors: [Color(0xFFFF7A18), Color(0xFFFFB347)],
    ),
    (
      category: 'BREAKFAST',
      title: 'Breakfast',
      subtitle: 'Start your day with hot meals 🥪',
      icon: '🥪',
      colors: [Color(0xFFFFA726), Color(0xFFFF7043)],
    ),
    (
      category: 'SNACK',
      title: 'Snacks',
      subtitle: 'Quick bites between lectures 🌮',
      icon: '🌮',
      colors: [Color(0xFFFF8A65), Color(0xFFFF5252)],
    ),
    (
      category: 'BEVERAGE',
      title: 'Beverages',
      subtitle: 'Stay hydrated and refreshed 🧋',
      icon: '🧋',
      colors: [Color(0xFF4FC3F7), Color(0xFF00ACC1)],
    ),
    (
      category: 'VEG',
      title: 'Veg Specials',
      subtitle: 'Delicious vegetarian options 🥗',
      icon: '🥗',
      colors: [Color(0xFF8BC34A), Color(0xFF43A047)],
    ),
  ];

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final opacity = (1 - (shrinkOffset / maxExtent)).clamp(0.0, 1.0);

    return Container(
      color: Color(0xFFFFF8F2).withValues(alpha: 0.95),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8 + (8 * opacity),
        bottom: 8 + (8 * opacity),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(
            _banners.length,
            (index) {
              final banner = _banners[index];
              final isSelected = selectedCategory == banner.category;

              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: AnimatedScale(
                  scale: isSelected ? 1.05 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: FilterChip(
                    selected: isSelected,
                    onSelected: (_) => onCategorySelected(banner.category),
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          banner.icon,
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          banner.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: const Color(0xFFFFE5D4),
                    selectedColor: banner.colors.first,
                    side: BorderSide(
                      color:
                          isSelected ? banner.colors.first : Colors.transparent,
                      width: 2,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  double get maxExtent => 70;

  @override
  double get minExtent => 62;

  @override
  bool shouldRebuild(covariant _CategoryHeaderDelegate oldDelegate) {
    return oldDelegate.selectedCategory != selectedCategory;
  }
}
