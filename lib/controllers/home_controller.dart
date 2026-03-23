import 'dart:async';
import 'package:flutter/foundation.dart';

import '../core/models/proxy_node.dart';
import '../core/models/traffic_stats.dart';
import '../features/connection/connection_use_case.dart';
import '../features/auth/auth_use_case.dart';
import '../features/node/node_notifier.dart';

// 皮肤层只需导入本文件，无需直接依赖领域层
export '../core/models/proxy_node.dart';
export '../core/models/traffic_stats.dart' show EngineState, RoutingMode;

/// HomeController — 连接首页的固定 API 边界
class HomeController extends ChangeNotifier {
  HomeController({
    required ConnectionUseCase connectionUseCase,
    required AuthUseCase authUseCase,
    required NodeNotifier nodeNotifier,
  })  : _conn = connectionUseCase,
        _auth = authUseCase,
        _nodeNotifier = nodeNotifier {
    _stateSub = _conn.stateStream.listen((_) => notifyListeners());
    _trafficSub = _conn.trafficStream.listen((stats) {
      _lastTraffic = stats;
      notifyListeners();
    });
  }

  final ConnectionUseCase _conn;
  final AuthUseCase _auth;
  final NodeNotifier _nodeNotifier;
  late final StreamSubscription<EngineState> _stateSub;
  late final StreamSubscription<TrafficStats> _trafficSub;

  TrafficStats _lastTraffic = TrafficStats.zero;

  // ── 状态属性 ──
  EngineState get connectionState => _conn.state;
  ProxyNode? get currentNode => _conn.currentNode;
  RoutingMode get currentMode => _conn.currentMode;
  double get trafficUp => _lastTraffic.uploadSpeed;
  double get trafficDown => _lastTraffic.downloadSpeed;
  DateTime? get connectedSince => _conn.connectedSince;
  Duration get connectionDuration => _conn.connectionDuration;
  String? get userEmail => _auth.currentUser?.email;
  Stream<EngineState> get stateStream => _conn.stateStream;
  Stream<TrafficStats> get trafficStream => _conn.trafficStream;

  bool get isNodeFavorite {
    final node = currentNode;
    if (node == null) return false;
    return _nodeNotifier.favoriteNodes.any((n) => n.id == node.id);
  }

  bool get isConnecting =>
      connectionState == EngineState.connecting;

  // ── 操作方法 ──
  Future<void> connect() async {
    if (currentNode == null) return;
    await _conn.connect(currentNode!);
    notifyListeners();
  }

  Future<void> disconnect() async {
    await _conn.disconnect();
    notifyListeners();
  }

  Future<void> switchNode(ProxyNode node) async {
    await _conn.connect(node);
    notifyListeners();
  }

  Future<void> switchRoutingMode(RoutingMode mode) async {
    await _conn.switchMode(mode);
    notifyListeners();
  }

  void toggleFavorite() {
    final node = currentNode;
    if (node == null) return;
    _nodeNotifier.toggleFavorite(node.id);
    notifyListeners();
  }

  Future<void> refreshTraffic() async {
    notifyListeners();
  }

  @override
  void dispose() {
    _stateSub.cancel();
    _trafficSub.cancel();
    super.dispose();
  }
}
