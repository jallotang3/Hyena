/// 套餐领域模型
class PlanItem {
  const PlanItem({
    required this.id,
    required this.name,
    required this.prices,
    this.transferEnable,
    this.speedLimit,
    this.deviceLimit,
    this.content,
    this.show = true,
    this.sell = true,
  });

  final int id;
  final String name;

  /// 流量限额（字节），null = 无限
  final int? transferEnable;

  /// 限速（Kbps），null = 不限速
  final int? speedLimit;

  /// 设备数限制，null = 不限
  final int? deviceLimit;

  /// 各周期价格（分）：month_price / quarter_price / half_year_price / year_price / two_year_price / three_year_price / onetime_price
  final Map<String, int?> prices;

  /// 套餐详细描述（HTML/Markdown）
  final String? content;

  final bool show;
  final bool sell;

  /// 获取某周期价格（分），null 表示该周期不可购买
  int? priceFor(String period) => prices[period];

  static const periods = [
    'month_price',
    'quarter_price',
    'half_year_price',
    'year_price',
    'two_year_price',
    'three_year_price',
    'onetime_price',
  ];
}
