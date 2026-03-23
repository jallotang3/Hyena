import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../controllers/order_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../../../skins/theme_token_provider.dart';

/// 移动端订单中心页（Material Design）
class MobileOrderCenterPage extends StatefulWidget {
  final OrderController controller;

  const MobileOrderCenterPage({required this.controller, super.key});

  @override
  State<MobileOrderCenterPage> createState() => _MobileOrderCenterPageState();
}

class _MobileOrderCenterPageState extends State<MobileOrderCenterPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.fetchOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokenProvider.tokensOf(context);
    final s = S.of(context)!;

    return Scaffold(
      backgroundColor: tokens.colorBackground,
      appBar: AppBar(
        backgroundColor: tokens.colorBackground,
        title: Text(s.orders),
      ),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          if (widget.controller.isLoading) {
            return Center(
              child: CircularProgressIndicator(color: tokens.colorPrimary),
            );
          }

          if (widget.controller.error != null) {
            return _ErrorView(
              message: widget.controller.error!,
              tokens: tokens,
              onRetry: () => widget.controller.fetchOrders(),
            );
          }

          if (widget.controller.orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 64,
                    color: tokens.colorMuted,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    s.noOrders,
                    style: TextStyle(color: tokens.colorMuted),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => widget.controller.fetchOrders(),
            color: tokens.colorPrimary,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: widget.controller.orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _OrderCard(
                order: widget.controller.orders[i],
                tokens: tokens,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.tokens,
    required this.onRetry,
  });

  final String message;
  final ThemeTokens tokens;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: tokens.colorError),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: tokens.colorMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: tokens.colorPrimary,
              foregroundColor: tokens.colorOnPrimary,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.tokens,
  });

  final Order order;
  final ThemeTokens tokens;

  Color _statusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.completed:
        return tokens.colorSuccess;
      case OrderStatus.pending:
        return tokens.colorPrimary;
      case OrderStatus.cancelled:
        return tokens.colorMuted;
      default:
        return tokens.colorPrimary;
    }
  }

  String _statusLabel(OrderStatus status, S s) {
    switch (status) {
      case OrderStatus.pending:
        return s.orderPending;
      case OrderStatus.processing:
        return s.orderProcessing;
      case OrderStatus.cancelled:
        return s.orderCancelled;
      case OrderStatus.completed:
        return s.orderCompleted;
      case OrderStatus.discounted:
        return s.orderDiscounted;
    }
  }

  String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  String _formatPrice(int cents) => '¥${(cents / 100).toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;

    return GestureDetector(
      onTap: () => context.push('/orders/${order.tradeNo}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: tokens.colorSurface,
          borderRadius: BorderRadius.circular(tokens.radiusMedium),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 订单号和状态
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${s.orderNo}: ${order.tradeNo}',
                    style: TextStyle(
                      color: tokens.colorOnBackground,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(order.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(tokens.radiusSmall),
                  ),
                  child: Text(
                    _statusLabel(order.status, s),
                    style: TextStyle(
                      color: _statusColor(order.status),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 套餐名称
            Text(
              order.plan?.name ?? s.orders,
              style: TextStyle(
                color: tokens.colorOnBackground,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),

            // 订单信息
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatPrice(order.totalAmount),
                        style: TextStyle(
                          color: tokens.colorMuted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(order.createdAt),
                        style: TextStyle(
                          color: tokens.colorMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: tokens.colorMuted,
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
