import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/item_cart/item_dto.dart';
import '../providers/cart_provider.dart';
import '../widgets/glass_card.dart';

class ItemDetailScreen extends ConsumerStatefulWidget {
  final ItemDto item;

  const ItemDetailScreen({super.key, required this.item});

  @override
  ConsumerState<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends ConsumerState<ItemDetailScreen> {
  bool _isAdding = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: CachedNetworkImage(
              imageUrl: widget.item.imageUrl,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => const ColoredBox(
                color: Color(0xFFE2E8F0),
                child: Icon(Icons.fastfood_rounded, size: 48),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.65),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Hero(
                    tag: 'menu_item_${widget.item.itemId}',
                    child: Material(
                      color: Colors.transparent,
                      child: GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.item.itemName,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${widget.item.category} • Ready in ${widget.item.readyIn} min',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '₹${widget.item.price}',
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.w900,
                                      ),
                                ),
                                FilledButton.icon(
                                  onPressed: (widget.item.isAvailable && !_isAdding)
                                      ? () async {
                                          setState(() => _isAdding = true);
                                          try {
                                            await ref
                                                .read(cartProvider.notifier)
                                                .addToCart(widget.item.itemId);
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
                                                          '${widget.item.itemName} added to cart',
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
                                                  content: const Row(
                                                    children: [
                                                      Icon(Icons.error_outline, color: Colors.white, size: 20),
                                                      SizedBox(width: 12),
                                                      Expanded(
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
                                          } finally {
                                            if (mounted) {
                                              setState(() => _isAdding = false);
                                            }
                                          }
                                        }
                                      : null,
                                  icon: _isAdding
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.add_shopping_cart_rounded),
                                  label: Text(_isAdding ? 'Adding...' : 'Add to Cart'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
