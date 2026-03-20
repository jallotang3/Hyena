import '../../core/interfaces/core_engine.dart';

/// 内核注册与发现
class EngineRegistry {
  EngineRegistry._();
  static final EngineRegistry instance = EngineRegistry._();

  final Map<String, CoreEngine> _engines = {};
  String? _activeEngineType;

  void register(CoreEngine engine) => _engines[engine.engineType] = engine;

  CoreEngine get active {
    final type = _activeEngineType ?? _engines.keys.firstOrNull;
    if (type == null || !_engines.containsKey(type)) {
      throw StateError('No engine registered. Call register() first.');
    }
    return _engines[type]!;
  }

  void setActive(String engineType) {
    assert(_engines.containsKey(engineType), 'Engine $engineType not registered');
    _activeEngineType = engineType;
  }

  bool isRegistered(String engineType) => _engines.containsKey(engineType);
}
