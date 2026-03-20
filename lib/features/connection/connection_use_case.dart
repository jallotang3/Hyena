import '../../core/interfaces/core_engine.dart';
import '../../core/models/proxy_node.dart';
import '../../core/models/traffic_stats.dart';
import '../../infrastructure/logging/app_logger.dart';

/// 连接 UseCase — 管理节点连接/断开/重连/路由切换
class ConnectionUseCase {
  ConnectionUseCase({required CoreEngine engine}) : _engine = engine;

  final CoreEngine _engine;
  ProxyNode? _currentNode;
  RoutingMode _currentMode = RoutingMode.rule;
  int _retryCount = 0;

  static const int maxRetries = 3;

  ProxyNode? get currentNode => _currentNode;
  RoutingMode get currentMode => _currentMode;
  EngineState get state => _engine.currentState;

  Stream<EngineState> get stateStream => _engine.stateStream;
  Stream<TrafficStats> get trafficStream => _engine.trafficStream;

  Future<void> initialize() async {
    await _engine.initialize();
  }

  Future<void> connect(ProxyNode node, {RoutingMode? mode}) async {
    _currentNode = node;
    _currentMode = mode ?? _currentMode;
    _retryCount = 0;
    await _doConnect();
  }

  Future<void> disconnect() async {
    _retryCount = 0;
    await _engine.disconnect();
    _currentNode = null;
  }

  Future<void> switchMode(RoutingMode mode) async {
    _currentMode = mode;
    await _engine.switchRoutingMode(mode);
  }

  Future<void> retry() async {
    if (_currentNode == null) return;
    if (_retryCount >= maxRetries) {
      AppLogger.w('达到最大重试次数 ($maxRetries)', tag: LogTag.vpn);
      return;
    }
    _retryCount++;
    AppLogger.i('重试连接 ($_retryCount/$maxRetries)', tag: LogTag.vpn);
    await Future.delayed(Duration(seconds: _retryCount));
    await _doConnect();
  }

  Future<void> _doConnect() async {
    try {
      await _engine.connect(_currentNode!, _currentMode);
    } catch (e) {
      AppLogger.e('连接失败: $e', tag: LogTag.vpn);
      if (_retryCount < maxRetries) await retry();
    }
  }

  Future<void> dispose() => _engine.dispose();
}
