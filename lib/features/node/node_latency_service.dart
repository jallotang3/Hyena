import 'dart:async';
import 'dart:io';

import '../../core/models/proxy_node.dart';
import '../../infrastructure/logging/app_logger.dart';

/// 节点延迟测速服务 — TCP 连通性测试
class NodeLatencyService {
  static const Duration _timeout = Duration(seconds: 3);
  static const int _maxConcurrency = 10;

  /// 单节点测速：TCP 握手计时
  static Future<int?> testSingle(ProxyNode node) async {
    try {
      final stopwatch = Stopwatch()..start();
      final socket = await Socket.connect(
        node.address,
        node.port,
        timeout: _timeout,
      );
      stopwatch.stop();
      socket.destroy();
      return stopwatch.elapsedMilliseconds;
    } on SocketException {
      return null;
    } on TimeoutException {
      return null;
    } catch (e) {
      AppLogger.d('测速失败 ${node.name}: $e', tag: LogTag.node);
      return null;
    }
  }

  /// 批量并发测速，通过回调实时返回结果
  static Future<Map<String, int?>> testBatch(
    List<ProxyNode> nodes, {
    void Function(String nodeId, int? latency)? onResult,
  }) async {
    final results = <String, int?>{};

    final chunks = <List<ProxyNode>>[];
    for (var i = 0; i < nodes.length; i += _maxConcurrency) {
      chunks.add(nodes.sublist(
          i, i + _maxConcurrency > nodes.length ? nodes.length : i + _maxConcurrency));
    }

    for (final chunk in chunks) {
      final futures = chunk.map((node) async {
        final latency = await testSingle(node);
        results[node.id] = latency;
        onResult?.call(node.id, latency);
      });
      await Future.wait(futures);
    }

    AppLogger.i(
      '批量测速完成: ${results.values.where((v) => v != null).length}/${nodes.length} 可达',
      tag: LogTag.node,
    );
    return results;
  }
}
