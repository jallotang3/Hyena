/// 邀请统计摘要
class InviteSummary {
  const InviteSummary({
    required this.codes,
    required this.registeredCount,
    required this.commissionTotal,
    required this.commissionPending,
    required this.commissionBalance,
    required this.commissionRate,
  });

  final List<InviteCode> codes;
  final int registeredCount;

  /// 累计有效佣金（分）
  final int commissionTotal;

  /// 待确认佣金（分）
  final int commissionPending;

  /// 可用佣金余额（分）
  final int commissionBalance;

  /// 佣金比例（0.0–1.0）
  final double commissionRate;
}

/// 邀请码
class InviteCode {
  const InviteCode({
    required this.id,
    required this.code,
    required this.status,
    required this.createdAt,
  });

  final int id;
  final String code;

  /// 0 = 未使用
  final int status;
  final DateTime createdAt;

  bool get isUsed => status != 0;
}

/// 佣金明细记录
class CommissionRecord {
  const CommissionRecord({
    required this.id,
    required this.inviteUserId,
    required this.getAmount,
    required this.createdAt,
  });

  final int id;
  final int inviteUserId;

  /// 佣金金额（分）
  final int getAmount;
  final DateTime createdAt;
}
