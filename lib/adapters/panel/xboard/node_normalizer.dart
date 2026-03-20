import 'dart:convert';
import '../../../core/models/proxy_node.dart';
import '../../../infrastructure/logging/app_logger.dart';

/// 节点解析器 — 将各种来源的原始数据统一映射为 ProxyNode
class NodeNormalizer {
  /// 从 xboard /user/server/fetch 响应的单个服务器对象解析
  static ProxyNode? fromXboardServer(Map<String, dynamic> data) {
    try {
      final id = data['id']?.toString() ?? '';
      final name = data['name']?.toString() ?? data['remark']?.toString() ?? '';
      final group = data['group_name']?.toString() ?? data['group']?.toString() ?? 'Default';
      final type = (data['type']?.toString() ?? 'shadowsocks').toLowerCase();
      final host = data['host']?.toString() ?? data['server']?.toString() ?? '';
      final port = (data['port'] as num?)?.toInt() ?? 443;

      if (host.isEmpty) return null;

      final extra = <String, dynamic>{};

      switch (type) {
        case 'shadowsocks':
          extra['method'] = data['cipher']?.toString() ?? 'aes-256-gcm';
          extra['password'] = data['password']?.toString() ?? '';
        case 'vmess':
          extra['uuid'] = data['uuid']?.toString() ?? '';
          extra['alter_id'] = (data['alter_id'] as num?)?.toInt() ?? 0;
          extra['security'] = data['security']?.toString() ?? 'auto';
          _addTransport(extra, data);
          _addTls(extra, data);
        case 'vless':
          extra['uuid'] = data['uuid']?.toString() ?? '';
          extra['flow'] = data['flow']?.toString() ?? '';
          _addTransport(extra, data);
          _addTls(extra, data);
        case 'trojan':
          extra['password'] = data['password']?.toString() ?? '';
          extra['sni'] = data['sni']?.toString() ?? host;
          _addTransport(extra, data);
        case 'hysteria2':
          extra['password'] = data['password']?.toString() ?? '';
          extra['obfs'] = data['obfs']?.toString();
          extra['obfs_password'] = data['obfs_password']?.toString();
      }

      return ProxyNode(
        id: id,
        name: name,
        group: group,
        protocol: type,
        address: host,
        port: port,
        extra: extra,
      );
    } catch (e) {
      AppLogger.w('节点解析失败: $e', tag: LogTag.adapter);
      return null;
    }
  }

  /// 从订阅内容（URL 模式，可能是 base64 编码的 JSON 或 URI 列表）解析
  static List<ProxyNode> fromSubscriptionContent(String content) {
    final nodes = <ProxyNode>[];

    try {
      // 尝试 JSON 格式（sing-box config）
      final json = jsonDecode(content) as Map<String, dynamic>;
      final outbounds = json['outbounds'] as List? ?? [];
      for (final o in outbounds) {
        final node = _fromSingboxOutbound(o as Map<String, dynamic>);
        if (node != null) nodes.add(node);
      }
      return nodes;
    } catch (_) {}

    // 尝试逐行 URI 格式
    for (final line in content.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      try {
        final node = _fromUri(trimmed);
        if (node != null) nodes.add(node);
      } catch (e) {
        AppLogger.d('URI 解析失败: $trimmed — $e', tag: LogTag.adapter);
      }
    }

    return nodes;
  }

  static ProxyNode? _fromSingboxOutbound(Map<String, dynamic> data) {
    final type = data['type']?.toString() ?? '';
    if (['direct', 'block', 'dns', 'selector', 'urltest'].contains(type)) return null;

    final server = data['server']?.toString() ?? '';
    if (server.isEmpty) return null;

    return ProxyNode(
      id: data['tag']?.toString() ?? server,
      name: data['tag']?.toString() ?? server,
      group: 'Default',
      protocol: type,
      address: server,
      port: (data['server_port'] as num?)?.toInt() ?? 443,
      extra: Map<String, dynamic>.from(data)
        ..remove('type')
        ..remove('server')
        ..remove('server_port')
        ..remove('tag'),
    );
  }

  static ProxyNode? _fromUri(String uri) {
    if (uri.startsWith('ss://')) return _parseShadowsocksUri(uri);
    if (uri.startsWith('vmess://')) return _parseVmessUri(uri);
    if (uri.startsWith('vless://')) return _parseVlessUri(uri);
    if (uri.startsWith('trojan://')) return _parseTrojanUri(uri);
    if (uri.startsWith('hy2://') || uri.startsWith('hysteria2://')) {
      return _parseHysteria2Uri(uri);
    }
    return null;
  }

  static ProxyNode? _parseShadowsocksUri(String uri) {
    try {
      final u = Uri.parse(uri);
      final userInfo = _decodeBase64OrPlain(u.userInfo);
      final parts = userInfo.split(':');
      return ProxyNode(
        id: '${u.host}:${u.port}',
        name: u.fragment.isNotEmpty ? Uri.decodeComponent(u.fragment) : u.host,
        group: 'Default',
        protocol: 'shadowsocks',
        address: u.host,
        port: u.port,
        extra: {
          'method': parts.isNotEmpty ? parts[0] : 'aes-256-gcm',
          'password': parts.length > 1 ? parts[1] : '',
        },
      );
    } catch (_) {
      return null;
    }
  }

  static ProxyNode? _parseVmessUri(String uri) {
    try {
      final payload = uri.substring('vmess://'.length);
      final json = jsonDecode(utf8.decode(base64.decode(base64.normalize(payload))))
          as Map<String, dynamic>;
      return ProxyNode(
        id: json['id']?.toString() ?? json['add']?.toString() ?? '',
        name: json['ps']?.toString() ?? json['add']?.toString() ?? '',
        group: json['group']?.toString() ?? 'Default',
        protocol: 'vmess',
        address: json['add']?.toString() ?? '',
        port: int.tryParse(json['port']?.toString() ?? '443') ?? 443,
        extra: {
          'uuid': json['id']?.toString() ?? '',
          'alter_id': int.tryParse(json['aid']?.toString() ?? '0') ?? 0,
          'security': json['scy']?.toString() ?? 'auto',
          'network': json['net']?.toString() ?? 'tcp',
          if (json['tls'] != null) 'tls': json['tls'],
          if (json['sni'] != null) 'sni': json['sni'],
        },
      );
    } catch (_) {
      return null;
    }
  }

  static ProxyNode? _parseVlessUri(String uri) {
    try {
      final u = Uri.parse(uri);
      return ProxyNode(
        id: u.userInfo,
        name: u.fragment.isNotEmpty ? Uri.decodeComponent(u.fragment) : u.host,
        group: 'Default',
        protocol: 'vless',
        address: u.host,
        port: u.port,
        extra: {
          'uuid': u.userInfo,
          'flow': u.queryParameters['flow'] ?? '',
          'encryption': u.queryParameters['encryption'] ?? 'none',
          if (u.queryParameters['security'] != null)
            'tls': u.queryParameters['security'],
          if (u.queryParameters['sni'] != null) 'sni': u.queryParameters['sni'],
          if (u.queryParameters['type'] != null)
            'network': u.queryParameters['type'],
        },
      );
    } catch (_) {
      return null;
    }
  }

  static ProxyNode? _parseTrojanUri(String uri) {
    try {
      final u = Uri.parse(uri);
      return ProxyNode(
        id: '${u.host}:${u.port}',
        name: u.fragment.isNotEmpty ? Uri.decodeComponent(u.fragment) : u.host,
        group: 'Default',
        protocol: 'trojan',
        address: u.host,
        port: u.port,
        extra: {
          'password': u.userInfo,
          'sni': u.queryParameters['sni'] ?? u.host,
          if (u.queryParameters['type'] != null)
            'network': u.queryParameters['type'],
        },
      );
    } catch (_) {
      return null;
    }
  }

  static ProxyNode? _parseHysteria2Uri(String uri) {
    try {
      final u = Uri.parse(uri.replaceFirst('hy2://', 'hysteria2://'));
      return ProxyNode(
        id: '${u.host}:${u.port}',
        name: u.fragment.isNotEmpty ? Uri.decodeComponent(u.fragment) : u.host,
        group: 'Default',
        protocol: 'hysteria2',
        address: u.host,
        port: u.port,
        extra: {
          'password': u.userInfo,
          'obfs': u.queryParameters['obfs'],
          'obfs_password': u.queryParameters['obfs-password'],
          'sni': u.queryParameters['sni'],
        },
      );
    } catch (_) {
      return null;
    }
  }

  static void _addTransport(Map<String, dynamic> extra, Map<String, dynamic> data) {
    final network = data['network']?.toString() ?? data['type']?.toString();
    if (network != null && network != 'tcp') {
      extra['network'] = network;
      if (network == 'ws') {
        extra['ws_path'] = data['ws_settings']?['path'] ?? data['path'];
        extra['ws_host'] = data['ws_settings']?['headers']?['Host'] ?? data['host'];
      } else if (network == 'grpc') {
        extra['grpc_service_name'] =
            data['grpc_settings']?['serviceName'] ?? data['service_name'];
      }
    }
  }

  static void _addTls(Map<String, dynamic> extra, Map<String, dynamic> data) {
    final tls = data['tls'] ?? data['security'];
    if (tls != null && tls.toString().isNotEmpty && tls != 'none') {
      extra['tls'] = tls;
      extra['sni'] = data['sni']?.toString() ?? data['server_name']?.toString();
    }
  }

  static String _decodeBase64OrPlain(String input) {
    try {
      return utf8.decode(base64.decode(base64.normalize(input)));
    } catch (_) {
      return input;
    }
  }
}
