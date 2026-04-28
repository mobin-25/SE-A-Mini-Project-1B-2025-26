import '../models/order_user/order_ticket_dto.dart';

class OrderStatusUpdatedEvent {
  final OrderTicketDto order;

  const OrderStatusUpdatedEvent(this.order);
}

class OrderUpdatesConnectionChangedEvent {
  final bool isConnected;

  const OrderUpdatesConnectionChangedEvent(this.isConnected);
}

class OrderUpdatesErrorEvent {
  final String message;

  const OrderUpdatesErrorEvent(this.message);
}
