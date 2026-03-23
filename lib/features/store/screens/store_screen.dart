import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../controllers/store_controller.dart';
import '../../../l10n/app_localizations.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StoreController>().fetchPlans();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(s.store)),
      body: Consumer<StoreController>(
        builder: (_, ctrl, __) {
          if (ctrl.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (ctrl.error != null) {
            return _ErrorView(
                message: ctrl.error!, onRetry: () => ctrl.fetchPlans());
          }
          final sellable =
              ctrl.plans.where((p) => p.show && p.sell).toList();
          return _PlanList(plans: sellable);
        },
      ),
    );
  }
}

// ── 套餐列表 ──────────────────────────────────────────────────────────────

class _PlanList extends StatelessWidget {
  const _PlanList({required this.plans});
  final List<PlanItem> plans;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    if (plans.isEmpty) {
      return Center(child: Text(s.noPlans));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: plans.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _PlanCard(plan: plans[i]),
    );
  }
}

// ── 套餐卡片 ──────────────────────────────────────────────────────────────

class _PlanCard extends StatefulWidget {
  const _PlanCard({required this.plan});
  final PlanItem plan;

  @override
  State<_PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends State<_PlanCard> {
  String? _selectedPeriod;

  PlanItem get plan => widget.plan;

  List<String> get _availablePeriods =>
      PlanItem.periods.where((p) => plan.priceFor(p) != null).toList();

  String _periodLabel(String period, S s) {
    switch (period) {
      case 'month_price':
        return s.periodMonth;
      case 'quarter_price':
        return s.periodQuarter;
      case 'half_year_price':
        return s.periodHalfYear;
      case 'year_price':
        return s.periodYear;
      case 'two_year_price':
        return s.periodTwoYear;
      case 'three_year_price':
        return s.periodThreeYear;
      case 'onetime_price':
        return s.periodOnetime;
      default:
        return period;
    }
  }

  String _formatTraffic(int? bytes) {
    if (bytes == null) return '∞';
    final gb = bytes / (1024 * 1024 * 1024);
    return '${gb.toStringAsFixed(0)} GB';
  }

  String _formatPrice(int cents) =>
      '¥${(cents / 100).toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = S.of(context)!;
    final periods = _availablePeriods;
    _selectedPeriod ??= periods.isNotEmpty ? periods[0] : null;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(plan.name,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _formatTraffic(plan.transferEnable),
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (plan.speedLimit != null) ...[
                  Icon(Icons.speed,
                      size: 14,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                  const SizedBox(width: 4),
                  Text('${plan.speedLimit! ~/ 1024} Mbps',
                      style: theme.textTheme.labelSmall),
                  const SizedBox(width: 12),
                ],
                if (plan.deviceLimit != null) ...[
                  Icon(Icons.devices,
                      size: 14,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                  const SizedBox(width: 4),
                  Text('${plan.deviceLimit} ${s.devices}',
                      style: theme.textTheme.labelSmall),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: periods.map((p) {
                final selected = p == _selectedPeriod;
                return ChoiceChip(
                  label: Text(_periodLabel(p, s)),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedPeriod = p),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedPeriod != null
                      ? _formatPrice(plan.priceFor(_selectedPeriod!)!)
                      : '–',
                  style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold),
                ),
                FilledButton(
                  onPressed:
                      _selectedPeriod == null ? null : () => _confirmOrder(context, s),
                  child: Text(s.buyNow),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmOrder(BuildContext context, S s) async {
    await showDialog<bool>(
      context: context,
      builder: (_) => _OrderConfirmDialog(
        plan: plan,
        period: _selectedPeriod!,
        price: plan.priceFor(_selectedPeriod!)!,
        onConfirm: (coupon) => _submitOrder(context, coupon),
      ),
    );
  }

  Future<bool> _submitOrder(BuildContext context, String? coupon) async {
    final ctrl = context.read<StoreController>();
    final tradeNo = await ctrl.createOrder(plan.id, _selectedPeriod!, coupon);
    if (tradeNo == null || !context.mounted) {
      if (context.mounted && ctrl.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ctrl.error!),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return false;
    }

    final methodId = await _selectPaymentMethod(context, ctrl);
    if (methodId == null || !context.mounted) return false;

    final pr = await ctrl.checkout(tradeNo, methodId);
    if (pr == null || !context.mounted) return false;

    if (pr.redirectUrl != null && context.mounted) {
      context.push('/payment-result', extra: pr);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context)!.orderCreated)),
      );
    }
    return true;
  }

  Future<int?> _selectPaymentMethod(
      BuildContext ctx, StoreController ctrl) async {
    await ctrl.fetchPaymentMethods();
    if (!ctx.mounted) return null;
    final methods =
        ctrl.paymentMethods.where((m) => m.enable).toList();
    if (methods.isEmpty) return 1;
    if (methods.length == 1) return methods.first.id;

    return showModalBottomSheet<int>(
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
                    subtitle: m.handlingFeePercent != null
                        ? Text(
                            '${(m.handlingFeePercent! * 100).toStringAsFixed(1)}%')
                        : null,
                    onTap: () => Navigator.pop(context, m.id),
                  )),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

// ── 下单确认弹窗 ──────────────────────────────────────────────────────────

class _OrderConfirmDialog extends StatefulWidget {
  const _OrderConfirmDialog({
    required this.plan,
    required this.period,
    required this.price,
    required this.onConfirm,
  });

  final PlanItem plan;
  final String period;
  final int price;
  final Future<bool> Function(String? coupon) onConfirm;

  @override
  State<_OrderConfirmDialog> createState() => _OrderConfirmDialogState();
}

class _OrderConfirmDialogState extends State<_OrderConfirmDialog> {
  final _couponCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _couponCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    return AlertDialog(
      title: Text(s.confirmOrder),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${s.plan}: ${widget.plan.name}'),
          const SizedBox(height: 4),
          Text('${s.price}: ¥${(widget.price / 100).toStringAsFixed(2)}'),
          const SizedBox(height: 12),
          TextField(
            controller: _couponCtrl,
            decoration: InputDecoration(
              labelText: s.couponCode,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context, false),
          child: Text(s.cancel),
        ),
        FilledButton(
          onPressed: _loading
              ? null
              : () async {
                  setState(() => _loading = true);
                  final coupon = _couponCtrl.text.trim();
                  final ok =
                      await widget.onConfirm(coupon.isEmpty ? null : coupon);
                  if (context.mounted) Navigator.pop(context, ok);
                },
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Text(s.confirm),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, size: 48),
          const SizedBox(height: 12),
          Text(message),
          const SizedBox(height: 16),
          FilledButton.tonal(onPressed: onRetry, child: Text(s.retry)),
        ],
      ),
    );
  }
}
