import 'dart:async';

import 'package:canteen_user_app/providers/order_profile_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/cart_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/service_providers.dart';
import '../providers/transaction_provider.dart';
import '../utils/app_error_message.dart';
import '../widgets/skeleton_box.dart';

String _formatPrepTime(int minutes) {
  if (minutes <= 0) {
    return 'Starts right after checkout';
  }

  if (minutes < 60) {
    return 'About $minutes min';
  }

  final hours = minutes ~/ 60;
  final remainingMinutes = minutes % 60;
  if (remainingMinutes == 0) {
    return 'About $hours hr';
  }

  return 'About $hours hr $remainingMinutes min';
}

String _prepTimeSupportMessage(int minutes) {
  if (minutes <= 10) {
    return 'Nice and quick — your order should be ready soon after you place it.';
  }

  if (minutes <= 25) {
    return 'Freshly prepared for you. Thanks for giving us a little time to make it right.';
  }

  return 'We\'ll prepare everything fresh and keep things moving as smoothly as possible.';
}

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartAsync = ref.watch(cartProvider);

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: const Text('Your Cart')),
        body: RefreshIndicator(
          onRefresh: () async {
            await ref.read(cartProvider.notifier).flushPendingQuantityUpdates();
            unawaited(
              ref.read(cartProvider.notifier).refreshCart(showGlobalLoader: false),
            );

            // Hide pull indicator quickly once skeleton becomes visible.
            await Future<void>.delayed(const Duration(milliseconds: 100));
          },
          child: cartAsync.when(
            skipLoadingOnRefresh: false,
            loading: () => const _CartSkeleton(),
            error: (error, _) => ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(
                            Icons.wifi_off_rounded,
                            color: Color(0xFF475569),
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Couldn\'t load your cart',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        appErrorMessage(error),
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            data: (cart) {
              if (cart.cartItems.isEmpty) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    const SizedBox(height: 36),
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFFF5A1F).withOpacity(0.03),
                            const Color(0xFFFF8C42).withOpacity(0.04),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFFFFE9DE),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF5A1F).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.shopping_bag_outlined,
                              size: 26,
                              color: Color(0xFFFF5A1F),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Your cart is empty',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0F172A),
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add items from the menu to get started.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: const Color(0xFF64748B),
                                  height: 1.35,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Your selected dishes will appear here.',
                            textAlign: TextAlign.center,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: const Color(0xFF94A3B8),
                                    ),
                          ),
                          const SizedBox(height: 18),
                          FilledButton.icon(
                            onPressed: () {
                              ref
                                  .read(mainNavigationIndexProvider.notifier)
                                  .state = 0;
                            },
                            icon: const Icon(Icons.restaurant_menu_rounded, size: 18),
                            label: const Text('Browse Menu'),
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
                      ),
                    ),
                  ],
                );
              }

              return GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  ref.read(cartProvider.notifier).flushPendingQuantityUpdates();
                },
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFE0F2FE),
                            const Color(0xFFF0FDF4),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFFBFDBFE),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.75),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.schedule_rounded,
                              color: Color(0xFF0369A1),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Freshly prepared for you',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatPrepTime(cart.estPrepTime),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0369A1),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _prepTimeSupportMessage(cart.estPrepTime),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    height: 1.45,
                                    color: Color(0xFF334155),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...cart.cartItems.map(
                      (cartItem) => Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF5A1F).withOpacity(0.08),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Item Image
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  cartItem.menuItem.imageUrl,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            const Color(0xFFFF5A1F)
                                                .withOpacity(0.2),
                                            const Color(0xFFFF8C42)
                                                .withOpacity(0.2),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.restaurant_menu_rounded,
                                        color: Color(0xFFFF5A1F),
                                        size: 32,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Item Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            cartItem.menuItem.itemName,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF0F172A),
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        InkWell(
                                          onTap: () async {
                                            try {
                                              await ref
                                                  .read(cartProvider.notifier)
                                                  .deleteItemFromCart(
                                                      cartItem.cartItemId);
                                            } catch (e) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      appErrorMessage(
                                                        e,
                                                        fallback: 'Unable to remove this item. Please try again.',
                                                      ),
                                                    ),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFEF2F2),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              size: 18,
                                              color: Color(0xFFDC2626),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      cartItem.menuItem.category,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '₹${cartItem.cartItemPrice.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFFFF5A1F),
                                          ),
                                        ),
                                        Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                const Color(0xFFFF5A1F)
                                                    .withOpacity(0.1),
                                                const Color(0xFFFF8C42)
                                                    .withOpacity(0.1),
                                              ],
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: const Color(0xFFFF5A1F)
                                                  .withOpacity(0.3),
                                              width: 1.5,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              InkWell(
                                                onTap: () {
                                                  // Optimistic update - instant UI response
                                                  ref
                                                      .read(
                                                          cartProvider.notifier)
                                                      .adjustQuantityOptimistic(
                                                          cartItem.cartItemId,
                                                          -1);
                                                },
                                                borderRadius:
                                                    const BorderRadius.only(
                                                  topLeft: Radius.circular(10),
                                                  bottomLeft:
                                                      Radius.circular(10),
                                                ),
                                                child: Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 12,
                                                    vertical: 8,
                                                  ),
                                                  child: const Icon(
                                                    Icons.remove,
                                                    size: 18,
                                                    color: Color(0xFFFF5A1F),
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 14,
                                                  vertical: 8,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFFF5A1F)
                                                      .withOpacity(0.15),
                                                ),
                                                child: Text(
                                                  '${cartItem.quantity}',
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w700,
                                                    color: Color(0xFF0F172A),
                                                  ),
                                                ),
                                              ),
                                              InkWell(
                                                onTap: () {
                                                  // Optimistic update - instant UI response
                                                  ref
                                                      .read(
                                                          cartProvider.notifier)
                                                      .adjustQuantityOptimistic(
                                                          cartItem.cartItemId,
                                                          1);
                                                },
                                                borderRadius:
                                                    const BorderRadius.only(
                                                  topRight: Radius.circular(10),
                                                  bottomRight:
                                                      Radius.circular(10),
                                                ),
                                                child: Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 12,
                                                    vertical: 8,
                                                  ),
                                                  child: const Icon(
                                                    Icons.add,
                                                    size: 18,
                                                    color: Color(0xFFFF5A1F),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
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
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Items',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                '${cart.cartItems.length}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF334155),
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child:
                                Divider(color: Colors.grey.shade200, height: 1),
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.only(top: 2),
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE0F2FE),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.access_time_rounded,
                                        size: 16,
                                        color: Color(0xFF0369A1),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Estimated prep time',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            _prepTimeSupportMessage(
                                                cart.estPrepTime),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade500,
                                              height: 1.4,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _formatPrepTime(cart.estPrepTime),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0369A1),
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child:
                                Divider(color: Colors.grey.shade200, height: 1),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total Amount',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Inclusive of all taxes',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '₹${cart.totalCartPrice.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F172A).withOpacity(0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: cart.cartItems.isEmpty
                              ? null
                              : () async {
                                  try {
                                    await ref
                                        .read(cartProvider.notifier)
                                        .flushPendingQuantityUpdates();
                                    await ref
                                        .read(
                                            transactionCounterProvider.notifier)
                                        .guard(
                                          () => ref
                                              .read(orderServiceProvider)
                                              .placeOrder(),
                                        );
                                    await ref
                                        .read(cartProvider.notifier)
                                        .refreshCart();
                                    // Refresh both old and new orders providers
                                    ref.invalidate(myOrdersProvider);
                                    ref
                                        .read(ordersPaginationProvider.notifier)
                                        .refresh();
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Row(
                                            children: [
                                              const Icon(Icons.check_circle,
                                                  color: Colors.white,
                                                  size: 22),
                                              const SizedBox(width: 12),
                                              const Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      'Order Placed Successfully',
                                                      style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w600),
                                                    ),
                                                    SizedBox(height: 2),
                                                    Text(
                                                      'Track your order in the Orders tab',
                                                      style: TextStyle(
                                                          fontSize: 13,
                                                          color:
                                                              Colors.white70),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          backgroundColor:
                                              const Color(0xFF15803D),
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12)),
                                          margin: const EdgeInsets.all(16),
                                          duration: const Duration(
                                              milliseconds: 1500),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: const Row(
                                            children: [
                                              Icon(Icons.error_outline,
                                                  color: Colors.white,
                                                  size: 20),
                                              SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  'Unable to place order. Please try again.',
                                                  style:
                                                      TextStyle(fontSize: 15),
                                                ),
                                              ),
                                            ],
                                          ),
                                          backgroundColor:
                                              const Color(0xFFDC2626),
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10)),
                                          margin: const EdgeInsets.all(16),
                                        ),
                                      );
                                    }
                                  }
                                },
                          borderRadius: BorderRadius.circular(14),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 15,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.shopping_bag_outlined,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'Place Order',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CartSkeleton extends StatelessWidget {
  const _CartSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...List.generate(
          3,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SkeletonBox(height: 16, width: 150),
                      SkeletonBox(height: 20, width: 20),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SkeletonBox(height: 14, width: 52),
                      Row(
                        children: [
                          SkeletonBox(height: 28, width: 28),
                          SizedBox(width: 8),
                          SkeletonBox(height: 14, width: 18),
                          SizedBox(width: 8),
                          SkeletonBox(height: 28, width: 28),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonBox(height: 16, width: 56),
              SkeletonBox(height: 22, width: 84),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const SkeletonBox(
            height: 44, borderRadius: BorderRadius.all(Radius.circular(14))),
      ],
    );
  }
}
