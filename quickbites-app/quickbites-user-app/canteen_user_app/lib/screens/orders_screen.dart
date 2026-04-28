import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/order_user/order_ticket_dto.dart';
import '../providers/order_profile_providers.dart';
import '../providers/order_realtime_provider.dart';
import '../providers/service_providers.dart';
import '../utils/app_error_message.dart';
import '../widgets/skeleton_box.dart';
import 'order_detail_screen.dart';
import '../widgets/glass_card.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  Timer? _queueTimer;
  int? _totalQueueWaitTime;
  final Map<int, int> _orderWaitTimes = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _refreshQueueSummary();
    _refreshActiveOrderWaitTimes();
    _queueTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) async {
        await _refreshQueueSummary();
        await _refreshActiveOrderWaitTimes();
      },
    );
    // Load initial data only if empty
    Future.microtask(() {
      final currentState = ref.read(ordersPaginationProvider);
      if (!currentState.hasFetchedOnce && !currentState.isLoading) {
        ref.read(ordersPaginationProvider.notifier).loadInitial();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _queueTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshQueueSummary() async {
    try {
      final wait = await ref.read(orderServiceProvider).getTotalQueueWaitTime();
      if (!mounted) return;
      setState(() {
        _totalQueueWaitTime = wait;
      });
    } catch (_) {
      // Keep old value silently.
    }
  }

  Future<void> _refreshActiveOrderWaitTimes() async {
    final state = ref.read(ordersPaginationProvider);
    final activeOrders = state.orders.where((order) {
      final status = order.orderStatus.trim().toUpperCase();
      return status == 'PENDING' || status == 'IN_PROGRESS';
    }).toList();

    if (activeOrders.isEmpty) {
      if (!mounted) return;
      setState(() {
        _orderWaitTimes.clear();
      });
      return;
    }

    final futures = activeOrders
        .where((order) => order.orderId != null)
        .map((order) async {
          final orderId = order.orderId!;
          final wait = await ref.read(orderServiceProvider).getOrderWaitTime(orderId);
          return MapEntry(orderId, wait);
        })
        .toList();

    try {
      final entries = await Future.wait(futures);
      if (!mounted) return;
      setState(() {
        _orderWaitTimes
          ..clear()
          ..addEntries(entries);
      });
    } catch (_) {
      // Ignore single refresh failures; next poll will retry.
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(ordersPaginationProvider.notifier).loadMore();
    }
  }

  Future<void> _waitUntilOrdersLoadingStarts() async {
    for (var i = 0; i < 20; i++) {
      final state = ref.read(ordersPaginationProvider);
      if (state.isLoading) return;
      await Future<void>.delayed(const Duration(milliseconds: 16));
    }
  }

  DateTime? _parsePlacedAt(String rawDateTime) {
    return DateTime.tryParse(rawDateTime)?.toLocal();
  }

  String _getSectionLabel(DateTime now, DateTime placedAt) {
    final todayStart = DateTime(now.year, now.month, now.day);
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));
    final lastWeekStart = todayStart.subtract(const Duration(days: 7));

    if (!placedAt.isBefore(todayStart)) {
      return 'Today';
    }
    if (!placedAt.isBefore(yesterdayStart)) {
      return 'Yesterday';
    }
    if (!placedAt.isBefore(lastWeekStart)) {
      return 'Last 7 Days';
    }
    return 'Older';
  }

  Widget _sectionHeader(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 10),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
      ),
    );
  }

  Widget _orderCard(BuildContext context, OrderTicketDto order) {
    final normalizedStatus = order.orderStatus.trim().toUpperCase();
    final activeQueueOrder =
        normalizedStatus == 'PENDING' || normalizedStatus == 'IN_PROGRESS';
    final liveWait = order.orderId == null ? null : _orderWaitTimes[order.orderId!];

    return GlassCard(
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
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color:
                      _statusColor(order.orderStatus).withValues(alpha: 0.12),
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
          if (activeQueueOrder) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                      liveWait == null
                          ? 'Estimated wait: Fetching live ETA...'
                          : liveWait < 0
                              ? 'Estimated wait: Finalizing...'
                              : 'Estimated wait: ${_formatWaitTime(liveWait)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF1E3A8A),
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Placed at: ${_formatPlacedAt(context, order.createdAt)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${order.orderItems.length} item(s)',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ],
      ),
    );
  }

  String _formatPlacedAt(BuildContext context, String rawDateTime) {
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

  String _formatWaitTime(int minutes) {
    if (minutes <= 0) return 'Ready soon';
    if (minutes < 60) return '$minutes min';
    final hr = minutes ~/ 60;
    final min = minutes % 60;
    return min == 0 ? '$hr hr' : '$hr hr $min min';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Must call for AutomaticKeepAliveClientMixin

    ref.listen(orderStatusUpdatesProvider, (_, next) {
      next.whenData((event) {
        final order = event.order;
        final orderId = order.orderId;
        if (orderId == null) return;

        ref.read(ordersPaginationProvider.notifier).applyOrderUpdate(order);

        final status = order.orderStatus.trim().toUpperCase();
        if (status == 'PENDING' || status == 'IN_PROGRESS') {
          unawaited(_refreshActiveOrderWaitTimes());
        } else {
          if (!mounted) return;
          setState(() {
            _orderWaitTimes.remove(orderId);
          });
        }
      });
    });

    final paginationState = ref.watch(ordersPaginationProvider);

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: const Text('My Orders')),
        body: RefreshIndicator(
          onRefresh: () async {
            final refreshFuture = ref.read(ordersPaginationProvider.notifier).refresh();

            unawaited(_refreshQueueSummary());
            unawaited(
              refreshFuture.then((_) => _refreshActiveOrderWaitTimes()),
            );

            await _waitUntilOrdersLoadingStarts();
            await Future<void>.delayed(const Duration(milliseconds: 80));
          },
          child: _buildOrdersList(paginationState),
        ),
      ),
    );
  }

  Widget _buildOrdersList(OrdersPaginationState state) {
    if (!state.hasFetchedOnce) {
      return const _OrdersSkeleton();
    }

    if (!state.isLoading && state.orders.isNotEmpty) {
      final needsLiveEta = state.orders.any((order) {
        final status = order.orderStatus.trim().toUpperCase();
        if (status != 'PENDING' && status != 'IN_PROGRESS') return false;
        final id = order.orderId;
        return id != null && !_orderWaitTimes.containsKey(id);
      });

      if (needsLiveEta) {
        Future.microtask(_refreshActiveOrderWaitTimes);
      }
    }

    if (state.isLoading && state.orders.isEmpty) {
      return const _OrdersSkeleton();
    }

    if (state.error != null && state.orders.isEmpty) {
      return ListView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
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
            child: Text(
              appErrorMessage(
                state.error!,
                fallback: 'Unable to load your orders right now. Please try again.',
              ),
              style: const TextStyle(
                color: Color(0xFF475569),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    }

    if (state.orders.isEmpty) {
      return ListView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 60),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
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
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5A1F).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    size: 56,
                    color: Color(0xFFFF5A1F),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'No Orders Yet',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Start ordering your favorite meals from the canteen. Your order history will appear here!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF64748B),
                        height: 1.5,
                      ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final now = DateTime.now();
    final sortedOrders = [...state.orders]..sort((a, b) {
        final aTime = _parsePlacedAt(a.createdAt);
        final bTime = _parsePlacedAt(b.createdAt);

        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });

    final grouped = <String, List<OrderTicketDto>>{
      'Today': [],
      'Yesterday': [],
      'Last 7 Days': [],
      'Older': [],
    };

    for (final order in sortedOrders) {
      final placedAt = _parsePlacedAt(order.createdAt);
      if (placedAt == null) {
        grouped['Older']!.add(order);
        continue;
      }
      final label = _getSectionLabel(now, placedAt);
      grouped[label]!.add(order);
    }

    final children = <Widget>[];

    final hasActiveOrders = state.orders.any((order) {
      final status = order.orderStatus.trim().toUpperCase();
      return status == 'PENDING' || status == 'IN_PROGRESS' || status == 'READY';
    });

    if (hasActiveOrders) {
      children.add(
        Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE0F2FE), Color(0xFFECFDF5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFBAE6FD)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.speed_rounded,
                  color: Color(0xFF0369A1),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Live Queue Insight',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _totalQueueWaitTime == null
                          ? 'Fetching queue estimate...'
                          : 'Current overall queue wait: ${_formatWaitTime(_totalQueueWaitTime!)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF0F172A),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    for (final entry in grouped.entries) {
      if (entry.value.isEmpty) continue;

      children.add(_sectionHeader(context, entry.key));
      for (final order in entry.value) {
        children.add(
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => OrderDetailScreen(order: order),
                ),
              );
            },
            child: _orderCard(context, order),
          ),
        );
        children.add(const SizedBox(height: 12));
      }
    }

    // Add loading indicator at the bottom
    if (state.isLoading) {
      children.add(const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      ));
    }

    if (children.isNotEmpty && !state.isLoading) {
      children.removeLast();
    }

    return ListView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: children,
    );
  }
}

class _OrdersSkeleton extends StatelessWidget {
  const _OrdersSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        const SkeletonBox(height: 18, width: 90),
        const SizedBox(height: 10),
        ...List.generate(
          4,
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
                      SkeletonBox(height: 24, width: 72),
                      SkeletonBox(height: 24, width: 92),
                    ],
                  ),
                  SizedBox(height: 10),
                  SkeletonBox(height: 13, width: double.infinity),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SkeletonBox(height: 12, width: 70),
                      SkeletonBox(height: 14, width: 14),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
