import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../controllers/store_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../../../skins/theme_token_provider.dart';

/// 移动端商店页（Material Design）
class MobileStorePage extends StatefulWidget {
  final StoreController controller;

  const MobileStorePage({required this.controller, super.key});

  @override
  State<MobileStorePage> createState() => _MobileStorePageState();
}

class _MobileStorePageState extends State<MobileStorePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.fetchPlans();
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
        title: Text(s.store),
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
              onRetry: () => widget.controller.fetchPlans(),
            );
          }

          final sellable = widget.controller.plans
              .where((p) => p.show && p.sell)
              .toList();

          if (sellable.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 64,
                    color: tokens.colorMuted,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    s.noPlans,
                    style: TextStyle(color: tokens.colorMuted),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sellable.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (_, i) => _PlanCard(
              plan: sellable[i],
              tokens: tokens,
              controller: widget.controller,
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

class _PlanCard extends StatefulWidget {
  const _PlanCard({
    required this.plan,
    required this.tokens,
    required this.controller,
  });

  final PlanItem plan;
  final ThemeTokens tokens;
  final StoreController controller;

  @override
  State<_PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends State<_PlanCard> {
  String? _selectedPeriod;

  PlanItem get plan => widget.plan;
  ThemeTokens get tokens => widget.tokens;

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

  String _formatPrice(int cents) => '¥${(cents / 100).toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final periods = _availablePeriods;
    _selectedPeriod ??= periods.isNotEmpty ? periods[0] : null;

    return Container(
      decoration: BoxDecoration(
        color: tokens.colorSurface,
        borderRadius: BorderRadius.circular(tokens.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 套餐头部
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: tokens.colorPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(tokens.radiusMedium),
                topRight: Radius.circular(tokens.radiusMedium),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    plan.name,
                    style: TextStyle(
                      color: tokens.colorOnBackground,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: tokens.colorPrimary,
                    borderRadius: BorderRadius.circular(tokens.radiusSmall),
                  ),
                  child: Text(
                    _formatTraffic(plan.transferEnable),
                    style: TextStyle(
                      color: tokens.colorOnPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 套餐内容
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 套餐描述
                if (plan.content?.isNotEmpty ?? false) ...[
                  Text(
                    plan.content!,
                    style: TextStyle(
                      color: tokens.colorMuted,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 周期选择
                if (periods.length > 1) ...[
                  Text(
                    s.storePlansLabel,
                    style: TextStyle(
                      color: tokens.colorMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: periods.map((period) {
                      final isSelected = period == _selectedPeriod;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedPeriod = period;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? tokens.colorPrimary
                                : tokens.colorBackground,
                            borderRadius: BorderRadius.circular(tokens.radiusSmall),
                            border: Border.all(
                              color: isSelected
                                  ? tokens.colorPrimary
                                  : tokens.colorMuted.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            _periodLabel(period, s),
                            style: TextStyle(
                              color: isSelected
                                  ? tokens.colorOnPrimary
                                  : tokens.colorOnBackground,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                // 价格和购买按钮
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatPrice(plan.priceFor(_selectedPeriod ?? '') ?? 0),
                            style: TextStyle(
                              color: tokens.colorPrimary,
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (_selectedPeriod != null && _selectedPeriod != 'onetime_price')
                            Text(
                              '/ ${_periodLabel(_selectedPeriod!, s)}',
                              style: TextStyle(
                                color: tokens.colorMuted,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _selectedPeriod == null ? null : () async {
                        final tradeNo = await widget.controller.createOrder(
                          plan.id,
                          _selectedPeriod!,
                          null,
                        );
                        if (tradeNo != null && context.mounted) {
                          // 跳转到支付结果页面
                          context.push('/payment-result', extra: PaymentResult(
                            type: 'balance',
                            tradeNo: tradeNo,
                          ));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: tokens.colorPrimary,
                        foregroundColor: tokens.colorOnPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(tokens.radiusSmall),
                        ),
                      ),
                      child: Text(s.buyNow),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
