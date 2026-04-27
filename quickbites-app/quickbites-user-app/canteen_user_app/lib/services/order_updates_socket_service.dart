import 'dart:convert';

import 'package:event_bus/event_bus.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../config/api_config.dart';
import '../events/order_updates_events.dart';
import '../models/order_user/order_ticket_dto.dart';
import 'token_storage_service.dart';

class OrderUpdatesSocketService {
  final TokenStorageService _tokenStorage;
  final EventBus _eventBus;

  StompClient? _client;
  bool _isConnected = false;

  OrderUpdatesSocketService({
    required TokenStorageService tokenStorage,
    required EventBus eventBus,
  })  : _tokenStorage = tokenStorage,
        _eventBus = eventBus;

  bool get isConnected => _isConnected;

  Future<void> connect() async {
    if (_isConnected) return;

    final jwt = await _tokenStorage.getJwt();
    if (jwt == null || jwt.isEmpty) {
      return;
    }
    _connectWithNativeWebSocket(jwt);
  }

  void _connectWithNativeWebSocket(String jwt) {
    _client?.deactivate();
    _client = StompClient(
      config: StompConfig(
        url: ApiConfig.websocketStompUrl,
        reconnectDelay: const Duration(seconds: 5),
        heartbeatOutgoing: const Duration(seconds: 15),
        heartbeatIncoming: const Duration(seconds: 15),
        stompConnectHeaders: {'Authorization': 'Bearer $jwt'},
        webSocketConnectHeaders: {'Authorization': 'Bearer $jwt'},
        onConnect: _onConnected,
        onDisconnect: _onDisconnected,
        onWebSocketError: (dynamic error) =>
            _onTransportError('WebSocket error: $error'),
        onStompError: (frame) => _onTransportError(
          "STOMP error: ${frame.body ?? 'Unknown'}",
        ),
      ),
    );
    _client?.activate();
  }

  void _onConnected(StompFrame frame) {
    _isConnected = true;
    _eventBus.fire(const OrderUpdatesConnectionChangedEvent(true));

    _client?.subscribe(
      destination: '/user/queue/order-updates',
      callback: (payload) {
        final body = payload.body;
        if (body == null || body.isEmpty) return;

        try {
          final decoded = jsonDecode(body);
          if (decoded is! Map<String, dynamic>) {
            throw const FormatException('Unexpected payload shape');
          }

          final dto = OrderTicketDto.fromJson(decoded);
          _eventBus.fire(OrderStatusUpdatedEvent(dto));
        } catch (e) {
          _eventBus.fire(OrderUpdatesErrorEvent(
            'Failed to parse order update payload: $e',
          ));
        }
      },
    );
  }

  void _onDisconnected(StompFrame frame) {
    _isConnected = false;
    _eventBus.fire(const OrderUpdatesConnectionChangedEvent(false));
  }

  void _onTransportError(String message) {
    final normalized = message.toLowerCase();
    final isSockJsUpgrade404 =
        normalized.contains('not upgraded to websocket') &&
        normalized.contains('http status code: 404') &&
        normalized.contains('/ws/');

    if (!isSockJsUpgrade404) {
      _eventBus.fire(OrderUpdatesErrorEvent(message));
    }
  }

  void disconnect() {
    _isConnected = false;
    _client?.deactivate();
    _client = null;
    _eventBus.fire(const OrderUpdatesConnectionChangedEvent(false));
  }
}
