/// 统一节点领域模型，屏蔽各面板与各协议的字段差异
class ProxyNode {
  const ProxyNode({
    required this.id,
    required this.name,
    required this.group,
    required this.protocol,
    required this.address,
    required this.port,
    this.extra = const {},
    this.latency,
    this.isFavorite = false,
  });

  final String id;
  final String name;
  final String group;

  /// 协议：vless / vmess / shadowsocks / trojan / hysteria2
  final String protocol;

  final String address;
  final int port;

  /// 协议特有字段（uuid、password、flow 等）
  final Map<String, dynamic> extra;

  /// 延迟（ms），null 表示未测速
  final int? latency;

  final bool isFavorite;

  ProxyNode copyWith({
    int? latency,
    bool? isFavorite,
  }) {
    return ProxyNode(
      id: id,
      name: name,
      group: group,
      protocol: protocol,
      address: address,
      port: port,
      extra: extra,
      latency: latency ?? this.latency,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  // ── JSON 序列化（用于 Hive 缓存）─────────────────────────────────────────

  factory ProxyNode.fromJson(Map<String, dynamic> json) {
    return ProxyNode(
      id: json['id'] as String,
      name: json['name'] as String,
      group: json['group'] as String? ?? '',
      protocol: json['protocol'] as String,
      address: json['address'] as String,
      port: json['port'] as int,
      extra: Map<String, dynamic>.from(json['extra'] as Map? ?? {}),
      latency: json['latency'] as int?,
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'group': group,
        'protocol': protocol,
        'address': address,
        'port': port,
        'extra': extra,
        'latency': latency,
        'isFavorite': isFavorite,
      };

  @override
  String toString() => 'ProxyNode($protocol://$address:$port [$name])';
}
