/// 实时流量统计（连接期间的速率数据）
class TrafficStats {
  const TrafficStats({
    this.uploadBytes = 0,
    this.downloadBytes = 0,
    this.uploadSpeed = 0,
    this.downloadSpeed = 0,
  });

  final int uploadBytes;
  final int downloadBytes;

  /// 上行速率（bytes/s）
  final double uploadSpeed;

  /// 下行速率（bytes/s）
  final double downloadSpeed;

  static const zero = TrafficStats();
}

/// 内核连接状态
enum EngineState {
  idle,
  preparing,
  connecting,
  connected,
  disconnecting,
  error,
}

/// 路由模式
enum RoutingMode {
  global,
  rule,
  direct,
}
