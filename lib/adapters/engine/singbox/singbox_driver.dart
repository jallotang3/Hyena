import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../../core/interfaces/core_engine.dart';
import '../../../core/models/proxy_node.dart';
import '../../../core/models/traffic_stats.dart';
import '../../../core/errors/app_error.dart';
import '../../../infrastructure/logging/app_logger.dart';
import 'libbox_ffi.dart';
import 'singbox_config_builder.dart';

/// sing-box 内核驱动
/// 参考 MagicLamp: lib/services/vpn/singbox_service.dart + libbox_service.dart
class SingboxDriver implements CoreEngine {
  SingboxDriver();

  @override
  String get engineType => 'singbox';

  EngineState _state = EngineState.idle;
  final _stateController = StreamController<EngineState>.broadcast();
  final _trafficController = StreamController<TrafficStats>.broadcast();
  final _logController = StreamController<String>.broadcast();

  Timer? _trafficTimer;

  @override
  Stream<EngineState> get stateStream => _stateController.stream;

  @override
  Stream<TrafficStats> get trafficStream => _trafficController.stream;

  @override
  Stream<String> get logStream => _logController.stream;

  @override
  EngineState get currentState => _state;

  @override
  Future<String?> get version async {
    if (!LibboxFfi.isLoaded) return null;
    return LibboxFfi.version();
  }

  @override
  Future<void> initialize() async {
    AppLogger.i('初始化 SingboxDriver...', tag: LogTag.vpn);

    final loaded = await LibboxFfi.load();
    if (!loaded) {
      AppLogger.w('libbox 加载失败，进入降级模式（Stub）', tag: LogTag.vpn);
      return;
    }

    final workDir = await _getWorkingDirectory();
    AppLogger.i('工作目录: $workDir', tag: LogTag.vpn);

    final errPtr = LibboxFfi.setup(workDir, workDir, Directory.systemTemp.path);
    if (errPtr != null) {
      AppLogger.w('LibboxSetup 警告，继续运行', tag: LogTag.vpn);
    }

    final ver = LibboxFfi.version();
    AppLogger.i('sing-box 版本: $ver', tag: LogTag.vpn);
  }

  @override
  Future<void> connect(ProxyNode node, RoutingMode mode) async {
    if (_state == EngineState.connecting || _state == EngineState.connected) {
      AppLogger.w('已在连接中，跳过', tag: LogTag.vpn);
      return;
    }

    _setState(EngineState.connecting);
    AppLogger.i('开始连接节点: ${node.name}', tag: LogTag.vpn);

    try {
      final configJson = SingboxConfigBuilder.build(node: node, mode: mode);
      AppLogger.d('生成配置: ${configJson.length} 字符', tag: LogTag.vpn);

      if (!LibboxFfi.isLoaded) {
        // Stub 模式：模拟连接成功
        AppLogger.i('[Stub] 模拟连接成功（libbox 未加载）', tag: LogTag.vpn);
        await Future.delayed(const Duration(milliseconds: 800));
        _setState(EngineState.connected);
        _startTrafficSimulation();
        return;
      }

      final (success, error) = LibboxFfi.startVpn(configJson);
      if (!success) {
        _setState(EngineState.error);
        throw EngineStartException(error ?? '启动失败');
      }

      _setState(EngineState.connected);
      _startTrafficPolling();
      AppLogger.i('VPN 连接成功', tag: LogTag.vpn);
    } catch (e) {
      _setState(EngineState.error);
      AppLogger.e('连接失败: $e', tag: LogTag.vpn);
      rethrow;
    }
  }

  @override
  Future<void> disconnect() async {
    if (_state == EngineState.idle || _state == EngineState.disconnecting) return;

    _setState(EngineState.disconnecting);
    _trafficTimer?.cancel();
    _trafficTimer = null;

    try {
      if (LibboxFfi.isLoaded) {
        final (success, error) = LibboxFfi.stopVpn();
        if (!success) AppLogger.w('停止 VPN 时出错: $error', tag: LogTag.vpn);
      }
      _setState(EngineState.idle);
      AppLogger.i('VPN 已断开', tag: LogTag.vpn);
    } catch (e) {
      _setState(EngineState.error);
      AppLogger.e('断开失败: $e', tag: LogTag.vpn);
      rethrow;
    }
  }

  @override
  Future<void> switchRoutingMode(RoutingMode mode) async {
    AppLogger.i('切换路由模式: $mode', tag: LogTag.vpn);
    // TODO(P3): 实现路由模式热切换（通过 Clash API 或重载配置）
  }

  @override
  Future<void> dispose() async {
    _trafficTimer?.cancel();
    await _stateController.close();
    await _trafficController.close();
    await _logController.close();
    if (LibboxFfi.isLoaded && LibboxFfi.isRunning) {
      LibboxFfi.stopVpn();
    }
  }

  void _setState(EngineState state) {
    _state = state;
    _stateController.add(state);
  }

  void _startTrafficPolling() {
    _trafficTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      // TODO(P3): 通过 Clash API /traffic 或 libbox stats 接口获取真实流量
      _trafficController.add(const TrafficStats());
    });
  }

  /// Stub 模式：模拟流量数据用于 UI 调试
  void _startTrafficSimulation() {
    var up = 0.0;
    var down = 0.0;
    _trafficTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      up = (up + 1024 * 50).clamp(0, 1024 * 1024 * 10.0);
      down = (down + 1024 * 200).clamp(0, 1024 * 1024 * 50.0);
      _trafficController.add(TrafficStats(
        uploadSpeed: 1024 * 50,
        downloadSpeed: 1024 * 200,
        uploadBytes: up.toInt(),
        downloadBytes: down.toInt(),
      ));
    });
  }

  Future<String> _getWorkingDirectory() async {
    if (Platform.isWindows) {
      final appData = Platform.environment['LOCALAPPDATA'] ??
          Platform.environment['APPDATA'] ??
          Directory.current.path;
      final dir = Directory('$appData\\Hyena');
      if (!await dir.exists()) await dir.create(recursive: true);
      return dir.path;
    } else if (Platform.isMacOS) {
      final home = Platform.environment['HOME'] ?? Directory.current.path;
      final dir = Directory('$home/Library/Application Support/Hyena');
      if (!await dir.exists()) await dir.create(recursive: true);
      return dir.path;
    } else if (Platform.isAndroid || Platform.isIOS) {
      final appDoc = await getApplicationDocumentsDirectory();
      return appDoc.path;
    } else {
      final home = Platform.environment['HOME'] ?? Directory.current.path;
      final dir = Directory('$home/.config/hyena');
      if (!await dir.exists()) await dir.create(recursive: true);
      return dir.path;
    }
  }
}
