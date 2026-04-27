import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/order_user/order_item_dto.dart';
import '../models/order_user/order_ticket_dto.dart';
import '../providers/cart_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/order_profile_providers.dart';
import '../providers/order_realtime_provider.dart';
import '../providers/service_providers.dart';
import '../providers/transaction_provider.dart';
import '../utils/app_error_message.dart';
import '../widgets/glass_card.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  final OrderTicketDto order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  late Future<OrderTicketDto> _detailFuture;
  bool _isReordering = false;
  bool _isCancelling = false;
  Timer? _liveOrderTimer;
  int? _liveWaitTimeMinutes;

  @override
  void initState() {
    super.initState();
    _detailFuture = _loadOrderDetails();
    _startLiveOrderPolling();
  }

  @override
  void dispose() {
    _liveOrderTimer?.cancel();
    super.dispose();
  }

  Future<OrderTicketDto> _loadOrderDetails() async {
    final id = widget.order.orderId;
    if (id == null) {
      return widget.order;
    }
    try {
      return await ref.read(orderServiceProvider).getOrderDetails(id);
    } catch (_) {
      // Fallback to existing data if detail endpoint fails.
      return widget.order;
    }
  }

  void _startLiveOrderPolling() {
    _liveOrderTimer?.cancel();
    _refreshLiveOrderData();
    _liveOrderTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => _refreshLiveOrderData(),
    );
  }

  Future<void> _refreshLiveOrderData() async {
    final orderId = widget.order.orderId;
    if (orderId == null) return;

    try {
      final latestOrder = await ref.read(orderServiceProvider).getOrderDetails(orderId);
      int? wait;
      if (_isQueueStatus(latestOrder.orderStatus)) {
        wait = await ref.read(orderServiceProvider).getOrderWaitTime(orderId);
      }

      if (!mounted) return;
      setState(() {
        _detailFuture = Future<OrderTicketDto>.value(latestOrder);
        _liveWaitTimeMinutes = wait;
      });

      final terminal = _isTerminalStatus(latestOrder.orderStatus);
      if (terminal && _liveOrderTimer?.isActive == true) {
        _liveOrderTimer?.cancel();
      }
    } catch (_) {
      // Keep existing UI state when polling fails.
    }
  }

  String _formatDate(BuildContext context, String rawDateTime) {
    final parsed = DateTime.tryParse(rawDateTime);
    if (parsed == null) return rawDateTime;

    final local = parsed.toLocal();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final datePart =
        '${local.day.toString().padLeft(2, '0')} ${months[local.month - 1]} ${local.year}';
    final timePart = TimeOfDay.fromDateTime(local).format(context);
    return '$datePart, $timePart';
  }

  Color _statusColor(String status) {
    switch (status.trim().toUpperCase()) {
      case 'DELIVERED':
        return const Color(0xFF16A34A);
      case 'CANCELLED':
        return const Color(0xFFDC2626);
      case 'READY':
        return const Color(0xFF2563EB);
      case 'IN_PROGRESS':
        return const Color(0xFFEA580C);
      case 'PENDING':
        return const Color(0xFF7C3AED);
      default:
        return const Color(0xFF64748B);
    }
  }

  String _statusLabel(String status) {
    switch (status.trim().toUpperCase()) {
      case 'IN_PROGRESS':
        return 'IN PROGRESS';
      default:
        return status.trim().toUpperCase();
    }
  }

  bool _isQueueStatus(String status) {
    final normalized = status.trim().toUpperCase();
    return normalized == 'PENDING' || normalized == 'IN_PROGRESS';
  }

  bool _isTerminalStatus(String status) {
    final normalized = status.trim().toUpperCase();
    return normalized == 'CANCELLED' || normalized == 'DELIVERED';
  }

  String _formatWaitTime(int minutes) {
    if (minutes <= 0) return 'Ready soon';
    if (minutes < 60) return '$minutes min';
    final hr = minutes ~/ 60;
    final min = minutes % 60;
    return min == 0 ? '$hr hr' : '$hr hr $min min';
  }

  bool _isPendingStatus(String status) {
    return status.trim().toUpperCase() == 'PENDING';
  }

  Future<void> _handleReorder() async {
    final orderId = widget.order.orderId;
    if (orderId == null || _isReordering) return;

    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reorder Items'),
        content: const Text('Do you want to reorder the exact same items?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reorder'),
          ),
        ],
      ),
    );

    if (approved != true) return;

    setState(() => _isReordering = true);
    try {
      await ref
          .read(transactionCounterProvider.notifier)
          .guard(() => ref.read(orderServiceProvider).reOrder(orderId));
      ref.invalidate(cartProvider);
      ref.invalidate(myOrdersProvider);
        ref.invalidate(ordersPaginationProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reorder successful! Items were added.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(mainNavigationIndexProvider.notifier).state = 1;
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              appErrorMessage(
                e,
                fallback: 'Unable to reorder right now. Please try again.',
              ),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isReordering = false);
      }
    }
  }

  Future<void> _handleCancelOrder(OrderTicketDto order) async {
    final orderId = order.orderId;
    if (orderId == null ||
        _isCancelling ||
        !_isPendingStatus(order.orderStatus)) {
      return;
    }

    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFFE4E6),
              foregroundColor: const Color(0xFF9F1239),
              elevation: 0,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (approved != true) return;

    setState(() => _isCancelling = true);
    try {
      await ref
          .read(transactionCounterProvider.notifier)
          .guard(() => ref.read(orderServiceProvider).cancelOrder(orderId));

      ref.invalidate(myOrdersProvider);
        ref.invalidate(ordersPaginationProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order cancelled successfully.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(mainNavigationIndexProvider.notifier).state = 2;
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              appErrorMessage(
                e,
                fallback: 'Unable to cancel order right now. Please try again.',
              ),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCancelling = false);
      }
    }
  }

  Widget _itemTile(BuildContext context, OrderItemDto item) {
    final itemTotal = item.historicalPrice * item.quantity;

    return GlassCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.menuItem.itemName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Qty: ${item.quantity} • ₹${item.historicalPrice.toStringAsFixed(0)} each',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '₹${itemTotal.toStringAsFixed(0)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(orderStatusUpdatesProvider, (_, next) {
      next.whenData((event) {
        final currentOrderId = widget.order.orderId;
        if (currentOrderId == null || event.order.orderId != currentOrderId) {
          return;
        }

        if (!mounted) return;
        setState(() {
          _detailFuture = Future<OrderTicketDto>.value(event.order);
          if (!_isQueueStatus(event.order.orderStatus)) {
            _liveWaitTimeMinutes = null;
          }
        });
      });
    });

    final canReorder = widget.order.orderId != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
      ),
      body: FutureBuilder<OrderTicketDto>(
        future: _detailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError && !snapshot.hasData) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  appErrorMessage(
                    snapshot.error!,
                    fallback: 'Unable to load order details right now. Please try again.',
                  ),
                ),
              ],
            );
          }

          final order = snapshot.data ?? widget.order;
          final normalizedStatus = order.orderStatus.trim().toUpperCase();
            final liveEta = _isQueueStatus(normalizedStatus)
              ? ((_liveWaitTimeMinutes != null && _liveWaitTimeMinutes! >= 0)
                ? _liveWaitTimeMinutes!
                : order.estPrepTime)
              : null;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₹${order.totalAmount.toStringAsFixed(0)}',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _statusColor(order.orderStatus)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _statusLabel(order.orderStatus),
                            style: TextStyle(
                              color: _statusColor(order.orderStatus),
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (order.orderId != null)
                      Text(
                        'Order ID: ${order.orderId}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    const SizedBox(height: 2),
                    Text(
                      'Placed at: ${_formatDate(context, order.createdAt)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (liveEta != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.schedule_rounded,
                              size: 18,
                              color: Color(0xFF1D4ED8),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Estimated wait time: ${_formatWaitTime(liveEta)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: const Color(0xFF1E3A8A),
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // QR Code section - only show when order is READY
              if (order.orderUuid != null && normalizedStatus == 'READY') ...[
                GlassCard(
                  child: Column(
                    children: [
                      Text(
                        'Your Order is Ready!',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF15803D),
                            ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Show this QR code at the counter to claim your order',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF64748B),
                            ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF15803D),
                            width: 2,
                          ),
                        ),
                        child: QrImageView(
                          data: order.orderUuid!,
                          version: QrVersions.auto,
                          size: 200,
                          backgroundColor: Colors.white,
                          errorStateBuilder: (context, error) {
                            return const Center(
                              child: Text('Error generating QR code'),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Order Code: ${(order.orderUuid!.length > 8 ? order.orderUuid!.substring(0, 8) : order.orderUuid!).toUpperCase()}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontFamily: 'monospace',
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ]
              // Show message if order is not ready yet
              else if (normalizedStatus != 'READY' &&
                  normalizedStatus != 'CANCELLED' &&
                  normalizedStatus != 'DELIVERED') ...[
                GlassCard(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF5A1F).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.restaurant_rounded,
                          color: Color(0xFFFF5A1F),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Preparing Your Order',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Your order will be prepared soon. QR code will appear when ready.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],
              Text(
                'Items (${order.orderItems.length})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 10),
              ...order.orderItems.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _itemTile(context, item),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: canReorder && !_isReordering ? _handleReorder : null,
                icon: _isReordering
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.replay_rounded),
                label: Text(
                  _isReordering ? 'Reordering...' : 'Reorder Same Items',
                ),
              ),
              if (_isPendingStatus(order.orderStatus)) ...[
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7F8),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFFE4E6)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Changed your mind?',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: const Color(0xFF9F1239),
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: _isCancelling
                            ? null
                            : () => _handleCancelOrder(order),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFFFE4E6),
                          foregroundColor: const Color(0xFF9F1239),
                          elevation: 0,
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: _isCancelling
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF9F1239),
                                ),
                              )
                            : const Icon(Icons.cancel_outlined),
                        label: Text(_isCancelling ? 'Cancelling...' : 'Cancel'),
                      ),
                    ],
                  ),
                ),
              ],
              if (!canReorder)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Order ID was not received from API, reorder is unavailable for this order.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
