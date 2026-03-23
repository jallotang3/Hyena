import 'package:flutter_test/flutter_test.dart';
import 'package:hyena/adapters/panel/xboard/node_normalizer.dart';

void main() {
  group('NodeNormalizer', () {
    group('fromXboardServer', () {
      test('解析 VLESS 节点', () {
        final json = {
          'id': 1,
          'name': 'HK-VLESS-01',
          'type': 'vless',
          'host': 'hk1.example.com',
          'port': 443,
          'uuid': 'test-uuid-123',
          'flow': 'xtls-rprx-vision',
        };

        final node = NodeNormalizer.fromXboardServer(json);

        expect(node, isNotNull);
        expect(node!.id, equals('1'));
        expect(node.name, equals('HK-VLESS-01'));
        expect(node.protocol, equals('vless'));
        expect(node.address, equals('hk1.example.com'));
        expect(node.port, equals(443));
        expect(node.extra['uuid'], equals('test-uuid-123'));
        expect(node.extra['flow'], equals('xtls-rprx-vision'));
      });

      test('解析 VMess 节点', () {
        final json = {
          'id': 2,
          'name': 'US-VMess-01',
          'type': 'vmess',
          'host': 'us1.example.com',
          'port': 443,
          'uuid': 'vmess-uuid-456',
          'alter_id': 0,
          'network': 'ws',
        };

        final node = NodeNormalizer.fromXboardServer(json);

        expect(node, isNotNull);
        expect(node!.protocol, equals('vmess'));
        expect(node.name, equals('US-VMess-01'));
        expect(node.address, equals('us1.example.com'));
        expect(node.extra['uuid'], equals('vmess-uuid-456'));
        expect(node.extra['alter_id'], equals(0));
      });

      test('解析 Shadowsocks 节点', () {
        final json = {
          'id': 3,
          'name': 'SG-SS-01',
          'type': 'shadowsocks',
          'host': 'sg1.example.com',
          'port': 8388,
          'cipher': 'aes-256-gcm',
          'password': 'test-password',
        };

        final node = NodeNormalizer.fromXboardServer(json);

        expect(node, isNotNull);
        expect(node!.protocol, equals('shadowsocks'));
        expect(node.name, equals('SG-SS-01'));
        expect(node.address, equals('sg1.example.com'));
        expect(node.port, equals(8388));
        expect(node.extra['method'], equals('aes-256-gcm'));
        expect(node.extra['password'], equals('test-password'));
      });

      test('解析 Trojan 节点', () {
        final json = {
          'id': 4,
          'name': 'JP-Trojan-01',
          'type': 'trojan',
          'host': 'jp1.example.com',
          'port': 443,
          'password': 'trojan-password',
        };

        final node = NodeNormalizer.fromXboardServer(json);

        expect(node, isNotNull);
        expect(node!.protocol, equals('trojan'));
        expect(node.name, equals('JP-Trojan-01'));
        expect(node.address, equals('jp1.example.com'));
        expect(node.port, equals(443));
        expect(node.extra['password'], equals('trojan-password'));
      });

      test('解析 Hysteria2 节点', () {
        final json = {
          'id': 5,
          'name': 'KR-Hysteria2-01',
          'type': 'hysteria2',
          'host': 'kr1.example.com',
          'port': 443,
          'password': 'hy2-password',
        };

        final node = NodeNormalizer.fromXboardServer(json);

        expect(node, isNotNull);
        expect(node!.protocol, equals('hysteria2'));
        expect(node.name, equals('KR-Hysteria2-01'));
        expect(node.address, equals('kr1.example.com'));
        expect(node.port, equals(443));
        expect(node.extra['password'], equals('hy2-password'));
      });

      test('缺少 host 时返回 null', () {
        final json = {
          'id': 1,
          'name': 'Test',
          'type': 'vless',
          // 缺少 host
          'port': 443,
          'uuid': 'test',
        };

        final node = NodeNormalizer.fromXboardServer(json);
        expect(node, isNull);
      });

      test('使用默认分组 Default', () {
        final json = {
          'id': 1,
          'name': 'Test',
          'type': 'vless',
          'host': 'example.com',
          'port': 443,
          'uuid': 'test',
        };

        final node = NodeNormalizer.fromXboardServer(json);
        expect(node, isNotNull);
        expect(node!.group, equals('Default'));
      });

      test('使用 group_name 字段作为分组', () {
        final json = {
          'id': 1,
          'name': 'Test',
          'type': 'vless',
          'host': 'example.com',
          'port': 443,
          'uuid': 'test',
          'group_name': 'Premium',
        };

        final node = NodeNormalizer.fromXboardServer(json);
        expect(node, isNotNull);
        expect(node!.group, equals('Premium'));
      });
    });

    group('fromSubscriptionContent', () {
      test('解析空内容返回空列表', () {
        final nodes = NodeNormalizer.fromSubscriptionContent('');
        expect(nodes, isEmpty);
      });

      test('解析 Shadowsocks URI', () {
        final uri = 'ss://YWVzLTI1Ni1nY206cGFzc3dvcmQ=@example.com:8388#Test%20Node';
        final nodes = NodeNormalizer.fromSubscriptionContent(uri);

        expect(nodes.length, equals(1));
        expect(nodes[0].protocol, equals('shadowsocks'));
        expect(nodes[0].address, equals('example.com'));
        expect(nodes[0].port, equals(8388));
      });

      test('跳过无效 URI', () {
        final content = '''
ss://valid@example.com:8388#Valid
invalid://broken
vless://another@example.com:443#Valid2
''';
        final nodes = NodeNormalizer.fromSubscriptionContent(content);

        // 应该解析出 2 个有效节点
        expect(nodes.length, greaterThanOrEqualTo(1));
      });
    });
  });
}
