/// 统一的用户领域模型，屏蔽各面板字段差异
class PanelUser {
  const PanelUser({
    required this.email,
    required this.trafficUsed,
    required this.trafficTotal,
    required this.expireAt,
    required this.planName,
    this.balance = 0,
    this.commissionBalance = 0,
    this.planId,
    this.uuid,
  });

  final String email;

  /// 已用流量（字节）
  final int trafficUsed;

  /// 总流量限额（字节），-1 表示无限
  final int trafficTotal;

  final DateTime? expireAt;
  final String planName;

  /// 账户余额（分）
  final int balance;

  /// 佣金余额（分）
  final int commissionBalance;

  final int? planId;
  final String? uuid;

  bool get hasActivePlan => expireAt != null && expireAt!.isAfter(DateTime.now());

  double get trafficUsedPercent {
    if (trafficTotal <= 0) return 0.0;
    return trafficUsed / trafficTotal;
  }

  /// 剩余流量（字节）
  int get trafficRemaining => (trafficTotal - trafficUsed).clamp(0, trafficTotal);

  factory PanelUser.fromJson(Map<String, dynamic> json) {
    return PanelUser(
      email: json['email'] as String,
      trafficUsed: json['trafficUsed'] as int,
      trafficTotal: json['trafficTotal'] as int,
      expireAt: json['expireAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['expireAt'] as int)
          : null,
      planName: json['planName'] as String? ?? '',
      balance: json['balance'] as int? ?? 0,
      commissionBalance: json['commissionBalance'] as int? ?? 0,
      planId: json['planId'] as int?,
      uuid: json['uuid'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'email': email,
        'trafficUsed': trafficUsed,
        'trafficTotal': trafficTotal,
        'expireAt': expireAt?.millisecondsSinceEpoch,
        'planName': planName,
        'balance': balance,
        'commissionBalance': commissionBalance,
        'planId': planId,
        'uuid': uuid,
      };

  PanelUser copyWith({
    String? email,
    int? trafficUsed,
    int? trafficTotal,
    DateTime? expireAt,
    String? planName,
    int? balance,
    int? commissionBalance,
  }) {
    return PanelUser(
      email: email ?? this.email,
      trafficUsed: trafficUsed ?? this.trafficUsed,
      trafficTotal: trafficTotal ?? this.trafficTotal,
      expireAt: expireAt ?? this.expireAt,
      planName: planName ?? this.planName,
      balance: balance ?? this.balance,
      commissionBalance: commissionBalance ?? this.commissionBalance,
      planId: planId,
      uuid: uuid,
    );
  }
}

/// 订阅详情
class SubscribeInfo {
  const SubscribeInfo({
    required this.subscribeUrl,
    this.deviceLimit,
    this.speedLimit,
    this.resetDay,
    this.token,
  });

  final String subscribeUrl;
  final int? deviceLimit;

  /// 限速（Mbps），null 表示不限
  final int? speedLimit;

  /// 流量重置日（1-28）
  final int? resetDay;

  final String? token;
}

/// 用户快捷统计（首页概览数据）
class UserStat {
  const UserStat({
    required this.pendingOrderCount,
    required this.openTicketCount,
    required this.inviteCount,
  });

  final int pendingOrderCount;
  final int openTicketCount;
  final int inviteCount;
}
