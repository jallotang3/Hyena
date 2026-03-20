import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/commercial/order.dart';
import '../../../core/result.dart';
import '../../../l10n/app_localizations.dart';
import '../order_use_case.dart';

class OrderCenterScreen extends StatefulWidget {
  const OrderCenterScreen({super.key});

  @override
  State<OrderCenterScreen> createState() => _OrderCenterScreenState();
}

class _OrderCenterScreenState extends State<OrderCenterScreen> {
  List<Order> _orders = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await context.read<OrderUseCase>().fetchOrders();
    if (!mounted) return;
    if (result.isSuccess) {
      setState(() {
        _orders = result.value;
        _loading = false;
      });
    } else {
      setState(() {
        _error = (result as Failure).error.message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(s.orders)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorRetry(message: _error!, onRetry: _loadOrders)
              : _orders.isEmpty
                  ? Center(child: Text(s.noOrders))
                  : RefreshIndicator(
                      onRefresh: _loadOrders,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _orders.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => _OrderCard(
                            order: _orders[i], onRefresh: _loadOrders),
                      ),
                    ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onRefresh});
  final Order order;
  final VoidCallback onRefresh;

  Color _statusColor(OrderStatus s, ThemeData t) {
    switch (s) {
      case OrderStatus.completed:
        return Colors.green;
      case OrderStatus.pending:
        return t.colorScheme.tertiary;
      case OrderStatus.cancelled:
        return t.colorScheme.onSurface.withValues(alpha: 0.4);
      default:
        return t.colorScheme.primary;
    }
  }

  String _statusLabel(OrderStatus s, S loc) {
    switch (s) {
      case OrderStatus.pending:
        return loc.orderPending;
      case OrderStatus.processing:
        return loc.orderProcessing;
      case OrderStatus.cancelled:
        return loc.orderCancelled;
      case OrderStatus.completed:
        return loc.orderCompleted;
      case OrderStatus.discounted:
        return loc.orderDiscounted;
    }
  }

  String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = S.of(context)!;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(order.plan?.name ?? s.unknownPlan,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _statusColor(order.status, theme)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(_statusLabel(order.status, s),
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: _statusColor(order.status, theme))),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('${s.orderNo}: ${order.tradeNo}',
                style: theme.textTheme.bodySmall?.copyWith(
                    color:
                        theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('¥${(order.totalAmount / 100).toStringAsFixed(2)}',
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(color: theme.colorScheme.primary)),
                Text(_formatDate(order.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.5))),
              ],
            ),
            if (order.isPending) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _cancelOrder(context, s),
                  child: Text(s.cancel,
                      style:
                          TextStyle(color: theme.colorScheme.error)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _cancelOrder(BuildContext context, S s) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(s.cancelOrder),
        content: Text(s.cancelOrderConfirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(s.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(s.confirm)),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    final result = await context.read<OrderUseCase>().cancelOrder(tradeNo: order.tradeNo);
    if (context.mounted) {
      if (result.isSuccess) {
        onRefresh();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text((result as Failure).error.message)),
        );
      }
    }
  }
}

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.receipt_long_outlined, size: 48),
          const SizedBox(height: 12),
          Text(message),
          const SizedBox(height: 16),
          FilledButton.tonal(onPressed: onRetry, child: Text(s.retry)),
        ],
      ),
    );
  }
}
