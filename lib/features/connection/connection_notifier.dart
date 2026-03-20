import 'dart:async';
import 'package:flutter/material.dart';
import 'connection_use_case.dart';
import '../../core/models/proxy_node.dart';
import '../../core/models/traffic_stats.dart';

/// ChangeNotifier 包装器 — 让 Provider Consumer 感知连接状态变化
class ConnectionNotifier extends ChangeNotifier {
  ConnectionNotifier(this.useCase) {
    _stateSub = useCase.stateStream.listen((_) => notifyListeners());
    _trafficSub = useCase.trafficStream.listen((stats) {
      _lastTraffic = stats;
      notifyListeners();
    });
  }

  final ConnectionUseCase useCase;
  late final StreamSubscription<EngineState> _stateSub;
  late final StreamSubscription<TrafficStats> _trafficSub;

  TrafficStats _lastTraffic = TrafficStats.zero;

  EngineState get state => useCase.state;
  ProxyNode? get currentNode => useCase.currentNode;
  TrafficStats get traffic => _lastTraffic;

  Future<void> connectToNode(ProxyNode node) async {
    await useCase.connect(node);
    notifyListeners();
  }

  Future<void> disconnect() async {
    await useCase.disconnect();
    notifyListeners();
  }

  Future<void> switchMode(RoutingMode mode) async {
    await useCase.switchMode(mode);
    notifyListeners();
  }

  @override
  void dispose() {
    _stateSub.cancel();
    _trafficSub.cancel();
    super.dispose();
  }
}
