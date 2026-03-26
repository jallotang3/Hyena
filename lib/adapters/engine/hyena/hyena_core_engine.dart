import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../../core/interfaces/core_engine.dart';
import '../../../core/models/proxy_node.dart';
import '../../../core/models/traffic_stats.dart';
import '../../../core/errors/app_error.dart';
import '../../../infrastructure/logging/app_logger.dart';
import '../singbox/singbox_config_builder.dart';
import 'hyena_core_mobile_bridge.dart';
import 'hyena_core_desktop_ffi.dart';
import 'hyena_core_grpc_client.dart';

/// HyenaCore 内核驱动（由上游 hiddify-core 构建的 HyenaCore 库）
/// - initialize(): FFI setup，mode=GRPC_NORMAL_INSECURE，库自动启动 gRPC 服务
/// - connect(): FFI start + gRPC 流量/日志订阅
/// - disconnect(): FFI stop + gRPC 断开
class HyenaCoreEngine implements CoreEngine {
  @override
  String get engineType => 'hyena';

  EngineState _state = EngineState.idle;
  ProxyNode? _currentNode;
  RoutingMode _currentMode = RoutingMode.rule;

  final _stateController = StreamController<EngineState>.broadcast();
  final _trafficController = StreamController<TrafficStats>.broadcast();
  final _logController = StreamController<String>.broadcast();

  StreamSubscription<TrafficStats>? _trafficSub;
  StreamSubscription<String>? _logSub;
  Timer? _trafficFallbackTimer;

  String? _workingDir;
  HyenaCoreGrpcClient? _grpc;

  /// Android/iOS：MethodChannel 已 setup 成功（与桌面 FFI 二选一）
  bool _mobileChannelReady = false;

  @override
  Stream<EngineState> get stateStream => _stateController.stream;

  @override
  Stream<TrafficStats> get trafficStream => _trafficController.stream;

  @override
  Stream<String> get logStream => _logController.stream;

  @override
  EngineState get currentState => _state;

  @override
  Future<String?> get version async => null;

  @override
  Future<void> initialize() async {
    AppLogger.i('初始化 HyenaCoreEngine...', tag: LogTag.vpn);

    _workingDir = await _resolveWorkingDir();
    await Directory(_workingDir!).create(recursive: true);

    if (Platform.isAndroid || Platform.isIOS) {
      try {
        await HyenaCoreMobileBridge.setup(
          basePath: _workingDir!,
          workingDir: _workingDir!,
          tempDir: Directory.systemTemp.path,
          mode: 0, // OLD：移动端无本地 gRPC 客户端需求时先走旧模式
        );
        _mobileChannelReady = true;
        AppLogger.i('HyenaCore 移动平台 setup 成功', tag: LogTag.vpn);
      } catch (e) {
        AppLogger.w('HyenaCore 移动平台 setup 失败，进入 stub: $e', tag: LogTag.vpn);
      }
      return;
    }

    final loaded = await HyenaCoreDesktopFfi.load();
    if (!loaded) {
      AppLogger.w('HyenaCore 加载失败，进入 stub 模式', tag: LogTag.vpn);
      return;
    }

    // 选一个空闲端口，让库在该端口启动 gRPC 服务（GRPC_NORMAL_INSECURE = 3）
    final grpcPort = await findFreePort();
    final listenAddr = '127.0.0.1:$grpcPort';

    final err = HyenaCoreDesktopFfi.setup(
      baseDir: _workingDir!,
      workingDir: _workingDir!,
      tempDir: Directory.systemTemp.path,
      mode: 3, // GRPC_NORMAL_INSECURE
      listen: listenAddr,
      debug: false,
    );

    if (err != null) {
      AppLogger.w('HyenaCore setup 警告: $err', tag: LogTag.vpn);
    } else {
      AppLogger.i('HyenaCore setup 成功，gRPC=$listenAddr', tag: LogTag.vpn);
      _grpc = HyenaCoreGrpcClient(host: '127.0.0.1', port: grpcPort);
      await _grpc!.connect();
    }
  }

  @override
  Future<void> connect(ProxyNode node, RoutingMode mode) async {
    if (_state == EngineState.connecting || _state == EngineState.connected) {
      AppLogger.w('已在连接中，跳过', tag: LogTag.vpn);
      return;
    }

    _setState(EngineState.connecting);
    _currentNode = node;
    _currentMode = mode;

    try {
      final configJson = SingboxConfigBuilder.build(node: node, mode: mode);

      if (!_nativeCoreAvailable) {
        AppLogger.i('[Stub] 模拟连接成功', tag: LogTag.vpn);
        await Future.delayed(const Duration(milliseconds: 800));
        _setState(EngineState.connected);
        _startTrafficSimulation();
        return;
      }

      final configPath = await _writeConfig(configJson);

      if ((Platform.isAndroid || Platform.isIOS) && _mobileChannelReady) {
        await HyenaCoreMobileBridge.start(configPath: configPath);
        _setState(EngineState.connected);
        AppLogger.i('HyenaCore 移动平台连接成功', tag: LogTag.vpn);
        _startStreams();
        return;
      }

      final err = HyenaCoreDesktopFfi.start(configPath);
      if (err != null) {
        _setState(EngineState.error);
        throw EngineStartException(err);
      }

      _setState(EngineState.connected);
      AppLogger.i('HyenaCore 连接成功', tag: LogTag.vpn);
      _startStreams();
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
    _stopStreams();

    try {
      if ((Platform.isAndroid || Platform.isIOS) && _mobileChannelReady) {
        await HyenaCoreMobileBridge.stop();
      } else if (HyenaCoreDesktopFfi.isLoaded) {
        final err = HyenaCoreDesktopFfi.stop();
        if (err != null) AppLogger.w('stop 警告: $err', tag: LogTag.vpn);
      }
      _setState(EngineState.idle);
      AppLogger.i('HyenaCore 已断开', tag: LogTag.vpn);
    } catch (e) {
      _setState(EngineState.error);
      AppLogger.e('断开失败: $e', tag: LogTag.vpn);
      rethrow;
    }
  }

  @override
  Future<void> switchRoutingMode(RoutingMode mode) async {
    _currentMode = mode;
    if (_state != EngineState.connected || _currentNode == null) return;

    _setState(EngineState.connecting);
    _stopStreams();
    try {
      final configJson = SingboxConfigBuilder.build(node: _currentNode!, mode: _currentMode);
      if (!_nativeCoreAvailable) {
        await Future.delayed(const Duration(milliseconds: 200));
        _setState(EngineState.connected);
        return;
      }
      final configPath = await _writeConfig(configJson);
      if ((Platform.isAndroid || Platform.isIOS) && _mobileChannelReady) {
        await HyenaCoreMobileBridge.stop();
        await HyenaCoreMobileBridge.start(configPath: configPath);
        _setState(EngineState.connected);
        _startStreams();
        return;
      }
      final err = HyenaCoreDesktopFfi.restart(configPath);
      if (err != null) {
        _setState(EngineState.error);
        AppLogger.e('路由模式切换失败: $err', tag: LogTag.vpn);
        return;
      }
      _setState(EngineState.connected);
      _startStreams();
    } catch (e) {
      _setState(EngineState.error);
      AppLogger.e('路由模式切换异常: $e', tag: LogTag.vpn);
    }
  }

  @override
  Future<void> dispose() async {
    _stopStreams();
    await _grpc?.disconnect();
    if ((Platform.isAndroid || Platform.isIOS) && _mobileChannelReady) {
      try {
        await HyenaCoreMobileBridge.stop();
      } catch (_) {}
    }
    if (HyenaCoreDesktopFfi.isLoaded) {
      HyenaCoreDesktopFfi.stop();
      HyenaCoreDesktopFfi.cleanup();
    }
    await _stateController.close();
    await _trafficController.close();
    await _logController.close();
  }

  // ── 内部工具 ──────────────────────────────────────────────────────────────

  bool get _nativeCoreAvailable =>
      HyenaCoreDesktopFfi.isLoaded ||
      ((Platform.isAndroid || Platform.isIOS) && _mobileChannelReady);

  void _setState(EngineState state) {
    _state = state;
    _stateController.add(state);
  }

  void _startStreams() {
    if (_grpc != null && _grpc!.isConnected) {
      _trafficSub = _grpc!.systemInfoStream().listen(
        _trafficController.add,
        onError: (e) => AppLogger.w('流量流错误: $e', tag: LogTag.vpn),
      );
      _logSub = _grpc!.logStream().listen(
        _logController.add,
        onError: (e) => AppLogger.w('日志流错误: $e', tag: LogTag.vpn),
      );
    } else {
      _startTrafficSimulation();
    }
  }

  void _stopStreams() {
    _trafficSub?.cancel();
    _trafficSub = null;
    _logSub?.cancel();
    _logSub = null;
    _trafficFallbackTimer?.cancel();
    _trafficFallbackTimer = null;
  }

  Future<String> _writeConfig(String configJson) async {
    final dir = _workingDir ?? Directory.systemTemp.path;
    final file = File('$dir/current.json');
    await file.writeAsString(configJson);
    return file.path;
  }

  Future<String> _resolveWorkingDir() async {
    if (Platform.isMacOS) {
      final home = Platform.environment['HOME'] ?? Directory.current.path;
      return '$home/Library/Application Support/Hyena';
    } else if (Platform.isWindows) {
      final appData = Platform.environment['LOCALAPPDATA'] ??
          Platform.environment['APPDATA'] ??
          Directory.current.path;
      return '$appData\\Hyena';
    } else if (Platform.isLinux) {
      final home = Platform.environment['HOME'] ?? Directory.current.path;
      return '$home/.config/hyena';
    } else if (Platform.isAndroid || Platform.isIOS) {
      final appDoc = await getApplicationDocumentsDirectory();
      return appDoc.path;
    }
    return Directory.current.path;
  }

  void _startTrafficSimulation() {
    var up = 0.0;
    var down = 0.0;
    _trafficFallbackTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      up += 1024 * 50;
      down += 1024 * 200;
      _trafficController.add(TrafficStats(
        uploadSpeed: 1024 * 50,
        downloadSpeed: 1024 * 200,
        uploadBytes: up.toInt(),
        downloadBytes: down.toInt(),
      ));
    });
  }
}
