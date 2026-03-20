import 'plan_item.dart';

/// 订单状态
enum OrderStatus {
  pending(0),
  processing(1),
  cancelled(2),
  completed(3),
  discounted(4);

  const OrderStatus(this.code);
  final int code;

  static OrderStatus fromCode(int code) =>
      OrderStatus.values.firstWhere((e) => e.code == code, orElse: () => OrderStatus.pending);
}

/// 订单领域模型
class Order {
  const Order({
    required this.tradeNo,
    required this.status,
    required this.totalAmount,
    required this.period,
    required this.createdAt,
    this.balanceAmount,
    this.handlingAmount,
    this.discountAmount,
    this.plan,
    this.couponCode,
    this.callbackNo,
  });

  final String tradeNo;
  final OrderStatus status;

  /// 最终应付金额（分）
  final int totalAmount;

  /// 余额抵扣（分）
  final int? balanceAmount;

  /// 手续费（分）
  final int? handlingAmount;

  /// 优惠折扣（分）
  final int? discountAmount;

  final PlanItem? plan;
  final String period;
  final String? couponCode;
  final String? callbackNo;
  final DateTime createdAt;

  bool get isPending => status == OrderStatus.pending;
  bool get isCompleted => status == OrderStatus.completed;
  bool get isCancelled => status == OrderStatus.cancelled;
}

/// 支付方式
class PaymentMethod {
  const PaymentMethod({
    required this.id,
    required this.name,
    required this.payment,
    this.icon,
    this.handlingFeeFixed,
    this.handlingFeePercent,
    this.enable = true,
  });

  final int id;
  final String name;

  /// 支付渠道标识：stripe / alipay / wechat / ...
  final String payment;

  final String? icon;

  /// 固定手续费（分）
  final int? handlingFeeFixed;

  /// 百分比手续费（0.05 = 5%）
  final double? handlingFeePercent;

  final bool enable;
}

/// 支付结果
class PaymentResult {
  const PaymentResult({
    required this.type,
    required this.tradeNo,
    this.data,
    this.redirectUrl,
    this.qrCode,
  });

  /// 支付类型：webview / qrcode / redirect / balance
  final String type;
  final String tradeNo;
  final Map<String, dynamic>? data;
  final String? redirectUrl;
  final String? qrCode;
}

/// 优惠码信息
class CouponInfo {
  const CouponInfo({
    required this.code,
    required this.type,
    required this.value,
    this.limitUse,
    this.limitUsePeriod,
  });

  final String code;

  /// 折扣类型：1=固定金额(分) 2=百分比(%)
  final int type;
  final int value;
  final int? limitUse;
  final int? limitUsePeriod;
}
