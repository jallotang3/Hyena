import 'dart:async';

import '../../core/interfaces/core_engine.dart';
import '../../core/models/proxy_node.dart';
import '../../core/models/traffic_stats.dart';
import '../../infrastructure/logging/app_logger.dart';
import '../../infrastructure/storage/preferences.dart';

/// 连接 UseCase — 管理节点连接/断开/重连/路由切换/自动连接/连接时长
class ConnectionUseCase {
  ConnectionUseCase({required CoreEngine engine}) : _engine = engine;

  final CoreEngine _engine;
  ProxyNode? _currentNode;
  RoutingMode _currentMode = RoutingMode.rule;
  int _retryCount = 0;
  DateTime? _connectedSince;
  StreamSubscription<EngineState>? _autoReconnectSub;

  static const int maxRetries = 3;

  ProxyNode? get currentNode => _currentNode;
  RoutingMode get currentMode => _currentMode;
  EngineState get state => _engine.currentState;
  DateTime? get connectedSince => _connectedSince;

  Duration get connectionDuration => _connectedSince != null
      ? DateTime.now().difference(_connectedSince!)
      : Duration.zero;

  Stream<EngineState> get stateStream => _engine.stateStream;
  Stream<TrafficStats> get trafficStream => _engine.trafficStream;
  Stream<String> get logStream => _engine.logStream;

  Future<void> initialize() async {
    await _engine.initialize();
    _setupAutoReconnect();
  }

  Future<void> connect(ProxyNode node, {RoutingMode? mode}) async {
    _currentNode = node;
    _currentMode = mode ?? _currentMode;
    _retryCount = 0;
    _connectedSince = null;
    await _doConnect();
  }

  Future<void> disconnect() async {
    _retryCount = 0;
    _connectedSince = null;
    await _engine.disconnect();
    _currentNode = null;
  }

  Future<void> switchMode(RoutingMode mode) async {
    _currentMode = mode;
    await AppPreferences.instance.setRoutingMode(mode.name);
    await _engine.switchRoutingMode(mode);
  }

  /// 启动时自动连接上次使用的节点（需要外部调用方提供节点查找）
  Future<bool> tryAutoConnect(ProxyNode? lastNode) async {
    if (!AppPreferences.instance.autoConnect) return false;
    if (lastNode == null) return false;
    AppLogger.i('自动连接节点: ${lastNode.name}', tag: LogTag.vpn);
    await connect(lastNode);
    return true;
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
      _connectedSince = DateTime.now();
    } catch (e) {
      AppLogger.e('连接失败: $e', tag: LogTag.vpn);
      if (_retryCount < maxRetries) await retry();
    }
  }

  void _setupAutoReconnect() {
    _autoReconnectSub = _engine.stateStream.listen((state) {
      if (state == EngineState.error && _currentNode != null && _retryCount < maxRetries) {
        retry();
      }
    });
  }

  Future<void> dispose() async {
    await _autoReconnectSub?.cancel();
    await _engine.dispose();
  }
}
