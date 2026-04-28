import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/item_cart/cart_dto.dart';
import '../models/item_cart/cart_item_dto.dart';
import 'service_providers.dart';
import 'transaction_provider.dart';

class CartNotifier extends AsyncNotifier<CartDto> {
  // Debouncing map: cartItemId -> Timer
  final Map<int, Timer> _debounceTimers = {};
  // Pending changes map: cartItemId -> total change amount
  final Map<int, int> _pendingChanges = {};

  @override
  Future<CartDto> build() async {
    // Register cleanup callback when provider is disposed
    ref.onDispose(() {
      for (final timer in _debounceTimers.values) {
        timer.cancel();
      }
      _debounceTimers.clear();
      _pendingChanges.clear();
    });

    return ref.read(cartServiceProvider).getMyCart();
  }

  Future<void> refreshCart({bool showGlobalLoader = true}) async {
    await flushPendingQuantityUpdates();
    state = const AsyncLoading();

    final fetch = () => AsyncValue.guard(
          () => ref.read(cartServiceProvider).getMyCart(),
        );

    final nextState = showGlobalLoader
        ? await ref.read(transactionCounterProvider.notifier).guard(fetch)
        : await fetch();

    state = nextState;
  }

  Future<void> _runCartMutation(Future<CartDto> Function() mutation) async {
    await flushPendingQuantityUpdates();
    final previous = state;
    state = const AsyncLoading();
    final nextState = await ref.read(transactionCounterProvider.notifier).guard(
          () => AsyncValue.guard(mutation),
        );
    state = nextState;
    if (nextState.hasError) {
      state = previous;
      throw nextState.error!;
    }
  }

  Future<void> addToCart(int itemId) async {
    await _runCartMutation(
        () => ref.read(cartServiceProvider).addToCart(itemId));
  }

  Future<void> removeFromCart(int itemId) async {
    await _runCartMutation(
        () => ref.read(cartServiceProvider).removeFromCart(itemId));
  }

  Future<void> deleteItemFromCart(int itemId) async {
    await _runCartMutation(
      () => ref.read(cartServiceProvider).deleteItemFromCart(itemId),
    );
  }

  /// Optimistic quantity adjustment with debouncing
  /// This provides instant UI feedback and batches rapid clicks
  void adjustQuantityOptimistic(int cartItemId, int change) {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    // Step 1: OPTIMISTIC UI UPDATE - Update immediately on screen
    final updatedItems = currentState.cartItems
        .map((item) {
          if (item.cartItemId == cartItemId) {
            final newQuantity = item.quantity + change;
            if (newQuantity <= 0) {
              return null; // Mark for removal
            }
            final newPrice = item.menuItem.price * newQuantity;
            return item.copyWith(
              quantity: newQuantity,
              cartItemPrice: newPrice.toDouble(),
            );
          }
          return item;
        })
        .whereType<CartItemDto>()
        .toList();

    final newTotal = updatedItems.fold<double>(
      0,
      (sum, item) => sum + item.cartItemPrice,
    );
    final newEstPrepTime = updatedItems.fold<int>(
      0,
      (sum, item) => sum + (item.menuItem.readyIn * item.quantity),
    );

    state = AsyncData(
      currentState.copyWith(
        cartItems: updatedItems,
        totalCartPrice: newTotal,
        estPrepTime: newEstPrepTime,
      ),
    );

    // Step 2: DEBOUNCING - Track pending changes
    _pendingChanges[cartItemId] = (_pendingChanges[cartItemId] ?? 0) + change;

    // Cancel any existing timer for this item
    _debounceTimers[cartItemId]?.cancel();

    // Step 3: Set new timer - wait 1.5s after last tap
    _debounceTimers[cartItemId] = Timer(
      const Duration(milliseconds: 1500),
      () => _syncQuantityWithBackend(cartItemId),
    );
  }

  /// Immediately sends all pending debounced quantity updates to backend.
  Future<void> flushPendingQuantityUpdates() async {
    if (_pendingChanges.isEmpty) return;

    final pendingItemIds = _pendingChanges.keys.toList();
    for (final cartItemId in pendingItemIds) {
      _debounceTimers[cartItemId]?.cancel();
      await _syncQuantityWithBackend(cartItemId);
    }
  }

  /// Send the accumulated changes to backend after debounce period
  Future<void> _syncQuantityWithBackend(int cartItemId) async {
    final totalChange = _pendingChanges.remove(cartItemId);
    if (totalChange == null || totalChange == 0) return;

    final previousState = state;

    try {
      // Send accumulated change to backend
      final updatedCart = await ref
          .read(cartServiceProvider)
          .adjustQuantity(cartItemId, totalChange);

      // Update with server response
      state = AsyncData(updatedCart);
    } catch (error, stackTrace) {
      // Revert to previous state on error
      state = previousState;
      // Optionally re-throw to show error message
      state = AsyncError(error, stackTrace);
    } finally {
      _debounceTimers.remove(cartItemId);
    }
  }
}

final cartProvider =
    AsyncNotifierProvider<CartNotifier, CartDto>(CartNotifier.new);
