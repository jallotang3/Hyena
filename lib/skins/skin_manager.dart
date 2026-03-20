import '../infrastructure/logging/app_logger.dart';
import 'theme_token_provider.dart';
import 'default/theme_tokens.dart';

/// 皮肤管理器 — 按 skinId 加载皮肤包，加载失败自动回退 default
class SkinManager {
  SkinManager._();
  static final SkinManager instance = SkinManager._();

  ThemeTokens _tokens = kDefaultThemeTokens;
  String _activeSkinId = 'default';

  ThemeTokens get tokens => _tokens;
  String get activeSkinId => _activeSkinId;

  Future<void> load(String skinId) async {
    try {
      _tokens = await _resolveSkin(skinId);
      _activeSkinId = skinId;
      AppLogger.i('皮肤加载成功: $skinId', tag: LogTag.skin);
    } catch (e) {
      AppLogger.w('皮肤 $skinId 加载失败，回退到 default: $e', tag: LogTag.skin);
      _tokens = kDefaultThemeTokens;
      _activeSkinId = 'default';
    }
  }

  Future<ThemeTokens> _resolveSkin(String skinId) async {
    return switch (skinId) {
      'default' => kDefaultThemeTokens,
      // 未来在此添加更多皮肤：
      // 'brand_x' => BrandXSkin.tokens,
      _ => throw ArgumentError('Unknown skinId: $skinId'),
    };
  }
}
