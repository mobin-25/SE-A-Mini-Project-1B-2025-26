import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/auth/login_request_dto.dart';
import '../models/auth/signup_request_dto.dart';
import 'cart_provider.dart';
import 'home_providers.dart';
import 'navigation_provider.dart';
import 'order_profile_providers.dart';
import 'service_providers.dart';
import 'transaction_provider.dart';

class AuthSessionNotifier extends AsyncNotifier<bool> {
  void _resetUserScopedState() {
    ref.invalidate(allItemsProvider);
    ref.invalidate(filteredItemsProvider);
    ref.invalidate(instantReadyItemsProvider);
    ref.invalidate(itemsPaginationProvider);
    ref.invalidate(selectedCategoryProvider);
    ref.invalidate(searchQueryProvider);
    ref.invalidate(priceRangeProvider);

    ref.invalidate(cartProvider);
    ref.invalidate(myOrdersProvider);
    ref.invalidate(ordersPaginationProvider);
    ref.invalidate(myProfileProvider);

    ref.read(mainNavigationIndexProvider.notifier).state = 0;
  }

  @override
  Future<bool> build() async {
    final jwt = await ref.read(tokenStorageServiceProvider).getJwt();
    return jwt != null && jwt.isNotEmpty;
  }

  Future<void> login({
    required String username,
    required String password,
  }) async {
    state = const AsyncLoading();

    final result = await ref.read(transactionCounterProvider.notifier).guard(
          () => AsyncValue.guard(() async {
            await ref.read(authServiceProvider).login(
                  LoginRequestDto(username: username, password: password),
                );
            _resetUserScopedState();
            return true;
          }),
        );

    // On error, keep state as false (not logged in) instead of error state
    // This prevents the login screen from being rebuilt and losing the error message
    if (result.hasError) {
      state = const AsyncData(false);
      throw result.error!;
    } else {
      state = result;
    }
  }

  Future<void> signup({
    required String username,
    required String password,
    required String mobileNumber,
    required String role,
  }) async {
    await ref.read(transactionCounterProvider.notifier).guard(
          () => ref.read(authServiceProvider).signup(
                SignupRequestDto(
                  username: username,
                  password: password,
                  mobileNumber: mobileNumber,
                  role: role,
                ),
              ),
        );
  }

  Future<void> logout() async {
    state = const AsyncLoading();

    await ref
        .read(transactionCounterProvider.notifier)
        .guard(() => ref.read(authServiceProvider).logout());

    _resetUserScopedState();
    state = const AsyncData(false);
  }

  /// Called when JWT token expires or becomes invalid
  Future<void> handleTokenExpiration() async {
    await ref.read(tokenStorageServiceProvider).clearAuth();
    state = const AsyncData(false);
  }
}

final authSessionProvider = AsyncNotifierProvider<AuthSessionNotifier, bool>(
  AuthSessionNotifier.new,
);
