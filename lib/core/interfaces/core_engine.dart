import '../models/traffic_stats.dart';
import '../models/proxy_node.dart';

/// 内核驱动抽象接口 — 屏蔽 sing-box / clash 等内核实现细节
abstract class CoreEngine {
  /// 内核类型标识（singbox / clash / ...）
  String get engineType;

  /// 内核版本（运行时获取）
  Future<String?> get version;

  /// 连接状态流
  Stream<EngineState> get stateStream;

  /// 实时流量统计流
  Stream<TrafficStats> get trafficStream;

  /// 当前连接状态
  EngineState get currentState;

  /// 初始化内核（加载 native 库、设置工作目录）
  Future<void> initialize();

  /// 应用配置并启动连接
  Future<void> connect(ProxyNode node, RoutingMode mode);

  /// 断开连接
  Future<void> disconnect();

  /// 切换路由模式（实时生效，不需要重连）
  Future<void> switchRoutingMode(RoutingMode mode);

  /// 获取内核日志流
  Stream<String> get logStream;

  /// 释放资源
  Future<void> dispose();
}

/// 内核能力声明
class EngineCapabilities {
  const EngineCapabilities({
    required this.engineType,
    this.supportedProtocols = const {'vless', 'vmess', 'shadowsocks', 'trojan'},
    this.supportedPlatforms = const {'android', 'windows'},
    this.supportsRuleset = true,
    this.supportsMultiOutbound = false,
  });

  final String engineType;
  final Set<String> supportedProtocols;
  final Set<String> supportedPlatforms;
  final bool supportsRuleset;
  final bool supportsMultiOutbound;
}
