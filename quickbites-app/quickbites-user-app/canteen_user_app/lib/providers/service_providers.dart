import 'package:event_bus/event_bus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_service.dart';
import '../services/cart_service.dart';
import '../services/item_service.dart';
import '../services/local_notification_service.dart';
import '../services/order_service.dart';
import '../services/order_updates_socket_service.dart';
import '../services/token_storage_service.dart';
import '../services/user_service.dart';
import 'auth_session_provider.dart';

final eventBusProvider = Provider<EventBus>((ref) {
  return EventBus();
});

final localNotificationServiceProvider = Provider<LocalNotificationService>((ref) {
  return LocalNotificationService();
});

final tokenStorageServiceProvider = Provider<TokenStorageService>((ref) {
  return TokenStorageService();
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    tokenStorage: ref.read(tokenStorageServiceProvider),
    onUnauthorized: () async {
      // Clear auth data first, then invalidate the auth session
      await ref.read(tokenStorageServiceProvider).clearAuth();
      ref.invalidate(authSessionProvider);
    },
  );
});

final itemServiceProvider = Provider<ItemService>((ref) {
  return ItemService(
    onUnauthorized: () async {
      await ref.read(tokenStorageServiceProvider).clearAuth();
      ref.invalidate(authSessionProvider);
    },
  );
});

final cartServiceProvider = Provider<CartService>((ref) {
  return CartService(
    onUnauthorized: () async {
      await ref.read(tokenStorageServiceProvider).clearAuth();
      ref.invalidate(authSessionProvider);
    },
  );
});

final orderServiceProvider = Provider<OrderService>((ref) {
  return OrderService(
    onUnauthorized: () async {
      await ref.read(tokenStorageServiceProvider).clearAuth();
      ref.invalidate(authSessionProvider);
    },
  );
});

final orderUpdatesSocketServiceProvider = Provider<OrderUpdatesSocketService>((ref) {
  return OrderUpdatesSocketService(
    tokenStorage: ref.read(tokenStorageServiceProvider),
    eventBus: ref.read(eventBusProvider),
  );
});

final userServiceProvider = Provider<UserService>((ref) {
  return UserService(
    onUnauthorized: () async {
      await ref.read(tokenStorageServiceProvider).clearAuth();
      ref.invalidate(authSessionProvider);
    },
  );
});
