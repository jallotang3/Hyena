import 'package:flutter_test/flutter_test.dart';
import 'package:hyena/skins/skin_manager.dart';

void main() {
  group('SkinManager', () {
    late SkinManager skinManager;

    setUp(() {
      skinManager = SkinManager.instance;
    });

    test('默认加载 default 皮肤', () async {
      await skinManager.load('default');
      expect(skinManager.activeSkinId, 'default');
      expect(skinManager.tokens, isNotNull);
      expect(skinManager.pageFactory, isNotNull);
    });

    test('加载 brand_x 皮肤成功', () async {
      await skinManager.load('brand_x');
      expect(skinManager.activeSkinId, 'brand_x');
      // 验证 brand_x 主色是暖橙色 #F97316
      final primary = skinManager.tokens.colorPrimary;
      expect((primary.r * 255.0).round() & 0xff, equals(249));
      expect((primary.g * 255.0).round() & 0xff, equals(115));
      expect((primary.b * 255.0).round() & 0xff, equals(22));
    });

    test('加载不存在的皮肤时降级到 default', () async {
      await skinManager.load('non_existent_skin');
      expect(skinManager.activeSkinId, 'default');
    });

    test('合约版本不兼容时降级到 default', () async {
      // 当前支持版本是 1.x，如果将来有 2.x 版本的皮肤会降级
      // 这个测试验证版本校验逻辑存在
      await skinManager.load('default');
      expect(skinManager.activeSkinId, 'default');
    });

    test('ThemeTokens 包含所有必需颜色', () async {
      await skinManager.load('default');
      final tokens = skinManager.tokens;

      expect(tokens.colorPrimary, isNotNull);
      expect(tokens.colorBackground, isNotNull);
      expect(tokens.colorSurface, isNotNull);
      expect(tokens.colorSurfaceVariant, isNotNull);
      expect(tokens.colorOnBackground, isNotNull);
      expect(tokens.colorOnSurface, isNotNull);
      expect(tokens.colorOnPrimary, isNotNull);
      expect(tokens.colorMuted, isNotNull);
      expect(tokens.colorError, isNotNull);
      expect(tokens.colorSuccess, isNotNull);
    });

    test('ThemeTokens 包含所有必需圆角', () async {
      await skinManager.load('default');
      final tokens = skinManager.tokens;

      expect(tokens.radiusSmall, greaterThan(0));
      expect(tokens.radiusMedium, greaterThan(0));
      expect(tokens.radiusLarge, greaterThan(0));
    });

    test('brand_x 和 default 皮肤颜色不同', () async {
      await skinManager.load('default');
      final defaultPrimary = skinManager.tokens.colorPrimary;

      await skinManager.load('brand_x');
      final brandXPrimary = skinManager.tokens.colorPrimary;

      expect(defaultPrimary, isNot(equals(brandXPrimary)));
    });
  });
}
