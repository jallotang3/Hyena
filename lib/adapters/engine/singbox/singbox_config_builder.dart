import 'dart:convert';
import '../../../core/models/proxy_node.dart';
import '../../../core/models/traffic_stats.dart';

/// sing-box 配置生成器
/// 将 ProxyNode + RoutingMode 转换为 sing-box JSON 配置字符串
class SingboxConfigBuilder {
  static String build({
    required ProxyNode node,
    required RoutingMode mode,
    int mixedPort = 7890,
    int dnsPort = 5354,
  }) {
    final config = {
      'log': {'level': 'info', 'timestamp': true},
      'dns': _buildDns(dnsPort),
      'inbounds': _buildInbounds(mixedPort),
      'outbounds': _buildOutbounds(node),
      'route': _buildRoute(mode),
    };
    return jsonEncode(config);
  }

  static Map<String, dynamic> _buildDns(int port) => {
        'servers': [
          {'tag': 'google', 'address': 'tls://8.8.8.8'},
          {'tag': 'local', 'address': '114.114.114.114', 'detour': 'direct'},
        ],
        'rules': [
          {'geosite': 'cn', 'server': 'local'},
        ],
      };

  static List<Map<String, dynamic>> _buildInbounds(int port) => [
        {
          'type': 'mixed',
          'tag': 'mixed-in',
          'listen': '127.0.0.1',
          'listen_port': port,
          'sniff': true,
        },
      ];

  static List<Map<String, dynamic>> _buildOutbounds(ProxyNode node) {
    final proxy = _buildOutbound(node);
    return [
      proxy,
      {'type': 'direct', 'tag': 'direct'},
      {'type': 'block', 'tag': 'block'},
      {'type': 'dns', 'tag': 'dns-out'},
    ];
  }

  static Map<String, dynamic> _buildOutbound(ProxyNode node) {
    return switch (node.protocol.toLowerCase()) {
      'shadowsocks' => _buildShadowsocks(node),
      'vmess' => _buildVmess(node),
      'vless' => _buildVless(node),
      'trojan' => _buildTrojan(node),
      'hysteria2' => _buildHysteria2(node),
      _ => {'type': 'direct', 'tag': 'proxy'},
    };
  }

  static Map<String, dynamic> _buildShadowsocks(ProxyNode node) => {
        'type': 'shadowsocks',
        'tag': 'proxy',
        'server': node.address,
        'server_port': node.port,
        'method': node.extra['method'] ?? 'aes-256-gcm',
        'password': node.extra['password'] ?? '',
      };

  static Map<String, dynamic> _buildVmess(ProxyNode node) => {
        'type': 'vmess',
        'tag': 'proxy',
        'server': node.address,
        'server_port': node.port,
        'uuid': node.extra['uuid'] ?? '',
        'alter_id': node.extra['alter_id'] ?? 0,
        'security': node.extra['security'] ?? 'auto',
        if (node.extra['tls'] != null) 'tls': {'enabled': true, 'server_name': node.extra['sni'] ?? node.address},
        if (node.extra['network'] != null && node.extra['network'] != 'tcp')
          'transport': _buildTransport(node),
      };

  static Map<String, dynamic> _buildVless(ProxyNode node) => {
        'type': 'vless',
        'tag': 'proxy',
        'server': node.address,
        'server_port': node.port,
        'uuid': node.extra['uuid'] ?? '',
        'flow': node.extra['flow'] ?? '',
        if (node.extra['tls'] != null)
          'tls': {
            'enabled': true,
            'server_name': node.extra['sni'] ?? node.address,
            if (node.extra['tls'] == 'reality') 'reality': {'enabled': true},
          },
        if (node.extra['network'] != null && node.extra['network'] != 'tcp')
          'transport': _buildTransport(node),
      };

  static Map<String, dynamic> _buildTrojan(ProxyNode node) => {
        'type': 'trojan',
        'tag': 'proxy',
        'server': node.address,
        'server_port': node.port,
        'password': node.extra['password'] ?? '',
        'tls': {
          'enabled': true,
          'server_name': node.extra['sni'] ?? node.address,
        },
      };

  static Map<String, dynamic> _buildHysteria2(ProxyNode node) => {
        'type': 'hysteria2',
        'tag': 'proxy',
        'server': node.address,
        'server_port': node.port,
        'password': node.extra['password'] ?? '',
        if (node.extra['obfs'] != null)
          'obfs': {
            'type': node.extra['obfs'],
            'password': node.extra['obfs_password'] ?? '',
          },
        'tls': {
          'enabled': true,
          'server_name': node.extra['sni'] ?? node.address,
        },
      };

  static Map<String, dynamic> _buildTransport(ProxyNode node) {
    final network = node.extra['network'] as String? ?? 'tcp';
    return switch (network) {
      'ws' => {
          'type': 'ws',
          'path': node.extra['ws_path'] ?? '/',
          'headers': {
            if (node.extra['ws_host'] != null) 'Host': node.extra['ws_host'],
          },
        },
      'grpc' => {
          'type': 'grpc',
          'service_name': node.extra['grpc_service_name'] ?? '',
        },
      'h2' => {'type': 'http', 'path': node.extra['path'] ?? '/'},
      _ => {'type': network},
    };
  }

  static Map<String, dynamic> _buildRoute(RoutingMode mode) {
    return switch (mode) {
      RoutingMode.global => {
          'rules': [
            {'protocol': 'dns', 'outbound': 'dns-out'},
          ],
          'final': 'proxy',
        },
      RoutingMode.direct => {
          'rules': [
            {'protocol': 'dns', 'outbound': 'dns-out'},
          ],
          'final': 'direct',
        },
      RoutingMode.rule => {
          'rules': [
            {'protocol': 'dns', 'outbound': 'dns-out'},
            {'geoip': 'private', 'outbound': 'direct'},
            {'geosite': 'cn', 'outbound': 'direct'},
            {'geoip': 'cn', 'outbound': 'direct'},
          ],
          'final': 'proxy',
          'auto_detect_interface': true,
        },
    };
  }
}
