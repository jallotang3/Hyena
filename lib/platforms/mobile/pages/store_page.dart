import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../controllers/store_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../../../skins/theme_token_provider.dart';

/// 移动端商店页
class MobileStorePage extends StatefulWidget {
  final StoreController controller;
  const MobileStorePage({required this.controller, super.key});

  @override
  State<MobileStorePage> createState() => _MobileStorePageState();
}

class _MobileStorePageState extends State<MobileStorePage> {
  // 当前选中的套餐和周期
  PlanItem? _selectedPlan;
  String? _selectedPeriod;
  // 当前选中的支付方式
  int? _selectedMethodId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await widget.controller.fetchPlans();
      await widget.controller.fetchPaymentMethods();
      _initDefaults();
    });
  }

  void _initDefaults() {
    final sellable = widget.controller.plans.where((p) => p.show && p.sell).toList();
    if (sellable.isNotEmpty) {
      final plan = sellable.first;
      final periods = _periodsOf(plan);
      setState(() {
        _selectedPlan = plan;
        _selectedPeriod = periods.isNotEmpty ? periods.first : null;
      });
    }
    final methods = widget.controller.paymentMethods.where((m) => m.enable).toList();
    if (methods.isNotEmpty) {
      setState(() => _selectedMethodId = methods.first.id);
    }
  }

  List<String> _periodsOf(PlanItem plan) =>
      PlanItem.periods.where((p) => plan.priceFor(p) != null).toList();

  String _periodLabel(String period, S s) => switch (period) {
        'month_price' => s.periodMonth,
        'quarter_price' => s.periodQuarter,
        'half_year_price' => s.periodHalfYear,
        'year_price' => s.periodYear,
        'two_year_price' => s.periodTwoYear,
        'three_year_price' => s.periodThreeYear,
        'onetime_price' => s.periodOnetime,
        _ => period,
      };

  String _formatTraffic(int? gb) {
    if (gb == null) return '∞';
    if (gb >= 1024) return '${(gb / 1024).toStringAsFixed(1)} TB';
    return '$gb GB';
  }

  String _formatSpeed(int? mbps) {
    if (mbps == null) return '∞';
    if (mbps >= 1000) return '${(mbps / 1000).toStringAsFixed(1)} Gbps';
    return '$mbps Mbps';
  }

  String _formatPrice(int cents) => '¥${(cents / 100).toStringAsFixed(2)}';

  String _stripMarkdown(String text) => text
      .replaceAll(RegExp(r'#{1,6}\s*'), '')
      .replaceAll(RegExp(r'\*{1,2}([^*]+)\*{1,2}'), r'$1')
      .replaceAll(RegExp(r'^\s*[-*+]\s+', multiLine: true), '• ')
      .replaceAll(RegExp(r'\[([^\]]+)\]\([^)]+\)'), r'$1')
      .replaceAll(RegExp(r'`[^`]+`'), '')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();

  // 当前选中价格（分）
  int get _currentPrice {
    if (_selectedPlan == null || _selectedPeriod == null) return 0;
    return _selectedPlan!.priceFor(_selectedPeriod!) ?? 0;
  }

  Future<void> _pay(BuildContext context) async {
    if (_selectedPlan == null || _selectedPeriod == null || _selectedMethodId == null) return;

    // 1. 创建订单
    final tradeNo = await widget.controller.createOrder(
      _selectedPlan!.id,
      _selectedPeriod!,
      null,
    );
    if (tradeNo == null || !context.mounted) return;

    // 2. 结账
    final result = await widget.controller.checkout(tradeNo, _selectedMethodId!);
    if (!context.mounted) return;

    context.push('/payment-result', extra: PaymentResult(
      type: result?.type ?? 'balance',
      tradeNo: tradeNo,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokenProvider.tokensOf(context);
    final s = S.of(context)!;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: tokens.colorBackground,
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          if (widget.controller.isLoading) {
            return Center(child: CircularProgressIndicator(color: tokens.colorPrimary));
          }
          if (widget.controller.error != null) {
            return _ErrorView(
              message: widget.controller.error!,
              tokens: tokens,
              onRetry: () async {
                await widget.controller.fetchPlans();
                await widget.controller.fetchPaymentMethods();
                _initDefaults();
              },
            );
          }

          final sellable = widget.controller.plans.where((p) => p.show && p.sell).toList();
          if (sellable.isEmpty) {
            return Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.shopping_bag_outlined, size: 56, color: tokens.colorMuted),
                const SizedBox(height: 12),
                Text(s.noPlans, style: TextStyle(color: tokens.colorMuted)),
              ]),
            );
          }

          // 确保选中状态有效
          if (_selectedPlan == null || !sellable.contains(_selectedPlan)) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _initDefaults());
          }

          final methods = widget.controller.paymentMethods.where((m) => m.enable).toList();

          return Column(
            children: [
              // ── Banner ──
              Container(
                height: topPadding + 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      tokens.colorPrimary,
                      tokens.colorPrimary.withValues(alpha: 0.75),
                    ],
                  ),
                ),
                padding: EdgeInsets.fromLTRB(20, topPadding + 10, 20, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(s.store,
                        style: TextStyle(
                          color: tokens.colorOnPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        )),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 1),
                      child: Text(s.storePlansLabel,
                          style: TextStyle(
                            color: tokens.colorOnPrimary.withValues(alpha: 0.7),
                            fontSize: 12,
                          )),
                    ),
                  ],
                ),
              ),

              // ── 套餐列表（65%高度）──
              Expanded(
                flex: 65,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                  itemCount: sellable.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _PlanCard(
                    plan: sellable[i],
                    isSelected: _selectedPlan == sellable[i],
                    selectedPeriod: _selectedPlan == sellable[i] ? _selectedPeriod : null,
                    tokens: tokens,
                    periodLabel: _periodLabel,
                    formatTraffic: _formatTraffic,
                    formatSpeed: _formatSpeed,
                    formatPrice: _formatPrice,
                    stripMarkdown: _stripMarkdown,
                    onSelectPlan: (plan, period) => setState(() {
                      _selectedPlan = plan;
                      _selectedPeriod = period;
                    }),
                    onSelectPeriod: (period) => setState(() => _selectedPeriod = period),
                  ),
                ),
              ),

              // ── 支付区域（35%高度）──
              Expanded(
                flex: 35,
                child: Container(
                  decoration: BoxDecoration(
                    color: tokens.colorSurface,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 支付方式标题
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                        child: Text(
                          s.storePaymentMethodLabel,
                          style: TextStyle(
                            color: tokens.colorMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),

                      // 支付方式列表
                      if (methods.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            '暂无可用支付方式',
                            style: TextStyle(color: tokens.colorMuted, fontSize: 13),
                          ),
                        )
                      else
                        SizedBox(
                          height: 44,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: methods.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (_, i) {
                              final m = methods[i];
                              final isSelected = m.id == _selectedMethodId;
                              return GestureDetector(
                                onTap: () => setState(() => _selectedMethodId = m.id),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? tokens.colorPrimary.withValues(alpha: 0.1)
                                        : tokens.colorBackground,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSelected
                                          ? tokens.colorPrimary
                                          : tokens.colorMuted.withValues(alpha: 0.2),
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Text(
                                    m.name,
                                    style: TextStyle(
                                      color: isSelected
                                          ? tokens.colorPrimary
                                          : tokens.colorOnBackground,
                                      fontSize: 13,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                      const Spacer(),

                      // 金额 + 立即付款
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          16, 8, 16, MediaQuery.of(context).padding.bottom + 12),
                        child: Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '应付金额',
                                  style: TextStyle(color: tokens.colorMuted, fontSize: 11),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _formatPrice(_currentPrice),
                                  style: TextStyle(
                                    color: tokens.colorPrimary,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w700,
                                    height: 1,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: (_selectedPlan == null ||
                                          _selectedPeriod == null ||
                                          _selectedMethodId == null ||
                                          widget.controller.isSubmitting)
                                      ? null
                                      : () => _pay(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: tokens.colorPrimary,
                                    foregroundColor: tokens.colorOnPrimary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(tokens.radiusMedium),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: widget.controller.isSubmitting
                                      ? SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: tokens.colorOnPrimary,
                                          ),
                                        )
                                      : Text(
                                          s.storePayNow(
                                            '¥',
                                            (_currentPrice / 100).toStringAsFixed(2),
                                          ),
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── 套餐卡片 ──────────────────────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.isSelected,
    required this.selectedPeriod,
    required this.tokens,
    required this.periodLabel,
    required this.formatTraffic,
    required this.formatSpeed,
    required this.formatPrice,
    required this.stripMarkdown,
    required this.onSelectPlan,
    required this.onSelectPeriod,
  });

  final PlanItem plan;
  final bool isSelected;
  final String? selectedPeriod;
  final ThemeTokens tokens;
  final String Function(String, S) periodLabel;
  final String Function(int?) formatTraffic;
  final String Function(int?) formatSpeed;
  final String Function(int) formatPrice;
  final String Function(String) stripMarkdown;
  final void Function(PlanItem, String?) onSelectPlan;
  final void Function(String) onSelectPeriod;

  List<String> get _periods =>
      PlanItem.periods.where((p) => plan.priceFor(p) != null).toList();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final periods = _periods;
    final monthPrice = plan.priceFor('month_price');

    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          onSelectPlan(plan, periods.isNotEmpty ? periods.first : null);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: tokens.colorSurface,
          borderRadius: BorderRadius.circular(tokens.radiusMedium),
          border: Border.all(
            color: isSelected
                ? tokens.colorPrimary
                : tokens.colorMuted.withValues(alpha: 0.1),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 第1行：套餐名称 + 月付价格
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Row(
                children: [
                  // 选中指示点
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? tokens.colorPrimary : tokens.colorMuted.withValues(alpha: 0.3),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      plan.name,
                      style: TextStyle(
                        color: tokens.colorOnBackground,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (monthPrice != null)
                    RichText(
                      text: TextSpan(children: [
                        TextSpan(
                          text: formatPrice(monthPrice),
                          style: TextStyle(
                            color: tokens.colorPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(
                          text: '/${s.periodMonth}',
                          style: TextStyle(
                            color: tokens.colorMuted,
                            fontSize: 11,
                          ),
                        ),
                      ]),
                    ),
                ],
              ),
            ),

            // 第2行：流量、限速、设备数、详细
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
              child: Row(
                children: [
                  _Badge(
                    icon: Icons.data_usage_rounded,
                    label: formatTraffic(plan.transferEnable),
                    tokens: tokens,
                  ),
                  const SizedBox(width: 6),
                  _Badge(
                    icon: Icons.speed_rounded,
                    label: formatSpeed(plan.speedLimit),
                    tokens: tokens,
                  ),
                  if (plan.deviceLimit != null) ...[
                    const SizedBox(width: 6),
                    _Badge(
                      icon: Icons.devices_rounded,
                      label: '${plan.deviceLimit} ${s.devices}',
                      tokens: tokens,
                    ),
                  ],
                  const Spacer(),
                  if (plan.content?.isNotEmpty ?? false)
                    GestureDetector(
                      onTap: () => _showDetail(context, s),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: tokens.colorPrimary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '详细',
                          style: TextStyle(
                            color: tokens.colorPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // 第3行：周期价格选择
            if (periods.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  itemCount: periods.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (_, i) {
                    final period = periods[i];
                    final price = plan.priceFor(period)!;
                    final isSel = isSelected && period == selectedPeriod;
                    return GestureDetector(
                      onTap: () {
                        if (isSelected) {
                          onSelectPeriod(period);
                        } else {
                          onSelectPlan(plan, period);
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSel
                              ? tokens.colorPrimary
                              : tokens.colorBackground,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isSel
                                ? tokens.colorPrimary
                                : tokens.colorMuted.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              periodLabel(period, s),
                              style: TextStyle(
                                color: isSel ? tokens.colorOnPrimary : tokens.colorMuted,
                                fontSize: 10,
                              ),
                            ),
                            Text(
                              formatPrice(price),
                              style: TextStyle(
                                color: isSel ? tokens.colorOnPrimary : tokens.colorOnBackground,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context, S s) {
    final tokens = ThemeTokenProvider.tokensOf(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: tokens.colorSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text(plan.name,
                    style: TextStyle(
                      color: tokens.colorOnBackground,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    )),
              ),
              IconButton(
                icon: Icon(Icons.close, color: tokens.colorMuted, size: 20),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ]),
            const SizedBox(height: 12),
            Text(
              stripMarkdown(plan.content!),
              style: TextStyle(color: tokens.colorOnBackground, fontSize: 14, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 小 Badge ──────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.label, required this.tokens});
  final IconData icon;
  final String label;
  final ThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: tokens.colorMuted),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(color: tokens.colorMuted, fontSize: 12)),
      ],
    );
  }
}

// ── 错误视图 ──────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.tokens, required this.onRetry});
  final String message;
  final ThemeTokens tokens;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.error_outline, size: 56, color: tokens.colorError),
        const SizedBox(height: 12),
        Text(message,
            style: TextStyle(color: tokens.colorMuted), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: onRetry,
          style: ElevatedButton.styleFrom(
            backgroundColor: tokens.colorPrimary,
            foregroundColor: tokens.colorOnPrimary,
          ),
          child: const Text('Retry'),
        ),
      ]),
    );
  }
}
