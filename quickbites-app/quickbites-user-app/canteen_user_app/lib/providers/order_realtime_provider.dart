import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../events/order_updates_events.dart';
import 'auth_session_provider.dart';
import 'service_providers.dart';

final orderRealtimeLifecycleProvider = Provider<void>((ref) {
  final realtimeService = ref.watch(orderUpdatesSocketServiceProvider);

  ref.listen<AsyncValue<bool>>(
    authSessionProvider,
    (_, next) {
      final loggedIn = next.asData?.value ?? false;
      if (loggedIn) {
        unawaited(realtimeService.connect());
      } else {
        realtimeService.disconnect();
      }
    },
    fireImmediately: true,
  );

  ref.onDispose(realtimeService.disconnect);
});

final orderStatusUpdatesProvider = StreamProvider<OrderStatusUpdatedEvent>((ref) {
  ref.watch(orderRealtimeLifecycleProvider);
  final bus = ref.watch(eventBusProvider);
  return bus.on<OrderStatusUpdatedEvent>();
});

final orderSocketConnectionProvider = StreamProvider<bool>((ref) {
  ref.watch(orderRealtimeLifecycleProvider);
  final bus = ref.watch(eventBusProvider);
  return bus
      .on<OrderUpdatesConnectionChangedEvent>()
      .map((event) => event.isConnected);
});

final orderSocketErrorsProvider = StreamProvider<String>((ref) {
  ref.watch(orderRealtimeLifecycleProvider);
  final bus = ref.watch(eventBusProvider);
  return bus.on<OrderUpdatesErrorEvent>().map((event) => event.message);
});
