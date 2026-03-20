import 'dart:async';
import 'package:flutter/material.dart';
import 'connection_use_case.dart';
import '../../core/models/traffic_stats.dart';

/// ChangeNotifier 包装器 — 让 Provider Consumer 感知连接状态变化
class ConnectionNotifier extends ChangeNotifier {
  ConnectionNotifier(this.useCase) {
    _stateSub = useCase.stateStream.listen((_) => notifyListeners());
    _trafficSub = useCase.trafficStream.listen((_) => notifyListeners());
  }

  final ConnectionUseCase useCase;
  late final StreamSubscription<EngineState> _stateSub;
  late final StreamSubscription<TrafficStats> _trafficSub;

  EngineState get state => useCase.state;

  @override
  void dispose() {
    _stateSub.cancel();
    _trafficSub.cancel();
    super.dispose();
  }
}
