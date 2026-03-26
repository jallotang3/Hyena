import 'dart:async';
import 'dart:io';
import 'package:grpc/grpc.dart';
import '../../../core/models/traffic_stats.dart';
import '../../../infrastructure/logging/app_logger.dart' hide LogLevel;
import 'proto/v2/hcore/hcore.pb.dart';
import 'proto/v2/hcore/hcore_service.pbgrpc.dart';
import 'proto/v2/hcommon/common.pb.dart';

/// HyenaCore gRPC 客户端
/// 连接到 HyenaCore 库在本地启动的 gRPC 服务，获取实时流量和日志
class HyenaCoreGrpcClient {
  final String host;
  final int port;

  ClientChannel? _channel;
  CoreClient? _stub;

  HyenaCoreGrpcClient({required this.host, required this.port});

  bool get isConnected => _channel != null;

  Future<void> connect() async {
    _channel = ClientChannel(
      host,
      port: port,
      options: const ChannelOptions(credentials: ChannelCredentials.insecure()),
    );
    _stub = CoreClient(_channel!);
    AppLogger.i('gRPC 连接到 $host:$port', tag: LogTag.vpn);
  }

  Future<void> disconnect() async {
    await _channel?.shutdown();
    _channel = null;
    _stub = null;
  }

  /// 启动 VPN（通过 gRPC）
  Future<CoreInfoResponse> start(String configPath) async {
    _ensureConnected();
    return _stub!.start(StartRequest(configPath: configPath));
  }

  /// 停止 VPN（通过 gRPC）
  Future<CoreInfoResponse> stop() async {
    _ensureConnected();
    return _stub!.stop(Empty());
  }

  /// 重启 VPN（通过 gRPC）
  Future<CoreInfoResponse> restart(String configPath) async {
    _ensureConnected();
    return _stub!.restart(StartRequest(configPath: configPath));
  }

  /// 实时系统信息流（流量统计）
  Stream<TrafficStats> systemInfoStream() {
    _ensureConnected();
    return _stub!
        .getSystemInfoStream(Empty())
        .map((info) => TrafficStats(
              uploadSpeed: info.uplink.toDouble(),
              downloadSpeed: info.downlink.toDouble(),
              uploadBytes: info.uplinkTotal.toInt(),
              downloadBytes: info.downlinkTotal.toInt(),
            ))
        .handleError((e) {
      AppLogger.w('gRPC systemInfoStream 错误: $e', tag: LogTag.vpn);
    });
  }

  /// 实时日志流
  Stream<String> logStream({LogLevel level = LogLevel.INFO}) {
    _ensureConnected();
    return _stub!
        .logListener(LogRequest(level: level))
        .map((msg) => '[${msg.level.name}] ${msg.message}')
        .handleError((e) {
      AppLogger.w('gRPC logStream 错误: $e', tag: LogTag.vpn);
    });
  }

  void _ensureConnected() {
    if (_stub == null) throw StateError('gRPC client not connected. Call connect() first.');
  }
}

/// 查找本机可用端口
Future<int> findFreePort() async {
  final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final port = server.port;
  await server.close();
  return port;
}
