import 'package:flutter/material.dart';
import 'connection_use_case.dart';
import '../../core/models/traffic_stats.dart';

/// ChangeNotifier 包装器 — 让 Provider Consumer 感知连接状态变化
class ConnectionNotifier extends ChangeNotifier {
  ConnectionNotifier(this.useCase) {
    useCase.stateStream.listen((_) => notifyListeners());
    useCase.trafficStream.listen((_) => notifyListeners());
  }

  final ConnectionUseCase useCase;

  EngineState get state => useCase.state;
}
