import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/models/commercial/order.dart';
import '../../../core/result.dart';
import '../../../l10n/app_localizations.dart';
import '../../store/store_use_case.dart';
import '../order_use_case.dart';

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key, required this.tradeNo});
  final String tradeNo;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  Order? _order;
  bool _loading = true;
  String? _error;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final uc = context.read<OrderUseCase>();
    final result = await uc.fetchOrderDetail(tradeNo: widget.tradeNo);
    if (!mounted) return;
    if (result.isSuccess) {
      setState(() {
        _order = result.value;
        _loading = false;
      });
      if (_order!.isPending) _startPolling();
    } else {
      setState(() {
        _error = (result as Failure).error.message;
        _loading = false;
      });
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      final uc = context.read<OrderUseCase>();
      final statusResult = await uc.checkOrderStatus(tradeNo: widget.tradeNo);
      if (!mounted) return;
      if (statusResult.isSuccess) {
        final newStatus = OrderStatus.fromCode(statusResult.value);
        if (newStatus != _order?.status) {
          _loadDetail();
          if (newStatus != OrderStatus.pending) _pollTimer?.cancel();
        }
      }
    });
  }

  String _formatPrice(int cents) => '¥${(cents / 100).toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(s.orderNo)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 16),
                      FilledButton.tonal(
                          onPressed: _loadDetail, child: Text(s.retry)),
                    ],
                  ),
                )
              : _buildDetail(theme, s),
    );
  }

  Widget _buildDetail(ThemeData theme, S s) {
    final order = _order!;
    final statusLabel = _statusLabel(order.status, s);
    final statusColor = _statusColor(order.status, theme);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(s.orderNo, style: theme.textTheme.labelSmall),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 16),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: order.tradeNo));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(s.copied)),
                        );
                      },
                    ),
                  ],
                ),
                Text(order.tradeNo, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(statusLabel,
                      style: theme.textTheme.labelMedium
                          ?.copyWith(color: statusColor)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _InfoRow(label: s.plan, value: order.plan?.name ?? s.unknownPlan),
                _InfoRow(label: s.price, value: _formatPrice(order.totalAmount)),
                if (order.discountAmount != null && order.discountAmount! > 0)
                  _InfoRow(
                      label: s.orderDiscounted,
                      value: '-${_formatPrice(order.discountAmount!)}'),
                if (order.balanceAmount != null && order.balanceAmount! > 0)
                  _InfoRow(
                      label: s.accountBalance,
                      value: '-${_formatPrice(order.balanceAmount!)}'),
                if (order.couponCode != null)
                  _InfoRow(label: s.couponCode, value: order.couponCode!),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (order.isPending) ...[
          FilledButton(
            onPressed: () => _payOrder(context),
            child: Text(s.orderPayNow),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => _cancelOrder(context, s),
            child: Text(s.orderCancel),
          ),
        ],
      ],
    );
  }

  Future<void> _payOrder(BuildContext ctx) async {
    final uc = ctx.read<StoreUseCase>();
    final methodsResult = await uc.fetchPaymentMethods();
    if (!ctx.mounted) return;
    if (!methodsResult.isSuccess) return;

    final methods = methodsResult.value.where((m) => m.enable).toList();
    final methodId = methods.length <= 1
        ? methods.firstOrNull?.id ?? 1
        : await showModalBottomSheet<int>(
            context: ctx,
            builder: (context) {
              final s = S.of(context)!;
              return SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(s.storePaymentMethodLabel,
                          style: Theme.of(context).textTheme.titleMedium),
                    ),
                    ...methods.map((m) => ListTile(
                          leading: const Icon(Icons.payment),
                          title: Text(m.name),
                          onTap: () => Navigator.pop(context, m.id),
                        )),
                    const SizedBox(height: 8),
                  ],
                ),
              );
            },
          );

    if (methodId == null || !ctx.mounted) return;
    final payResult =
        await uc.checkout(tradeNo: widget.tradeNo, methodId: methodId);
    if (!ctx.mounted) return;
    if (payResult.isSuccess) {
      final pr = payResult.value;
      if (pr.redirectUrl != null) {
        ctx.push('/payment-result', extra: pr);
      } else {
        _loadDetail();
      }
    }
  }

  Future<void> _cancelOrder(BuildContext ctx, S s) async {
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: Text(s.cancelOrder),
        content: Text(s.cancelOrderConfirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false), child: Text(s.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true), child: Text(s.confirm)),
        ],
      ),
    );
    if (confirmed != true || !ctx.mounted) return;
    final uc = ctx.read<OrderUseCase>();
    await uc.cancelOrder(tradeNo: widget.tradeNo);
    if (ctx.mounted) _loadDetail();
  }

  String _statusLabel(OrderStatus status, S s) => switch (status) {
        OrderStatus.pending => s.orderStatusPending,
        OrderStatus.processing => s.orderStatusProcessing,
        OrderStatus.cancelled => s.orderStatusCancelled,
        OrderStatus.completed => s.orderStatusCompleted,
        OrderStatus.discounted => s.orderDiscounted,
      };

  Color _statusColor(OrderStatus status, ThemeData theme) => switch (status) {
        OrderStatus.pending => Colors.orange,
        OrderStatus.processing => theme.colorScheme.primary,
        OrderStatus.cancelled => Colors.grey,
        OrderStatus.completed => Colors.green,
        OrderStatus.discounted => Colors.blue,
      };
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
          Text(value, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
