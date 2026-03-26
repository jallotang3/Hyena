/// 编译期常量 — 由 CI/CD --dart-define 注入，运行时为只读常量，用户不可修改。
///
/// 构建示例：
/// ```
/// flutter build apk \
///   --dart-define=PANEL_API_BASE=https://panel.example.com \
///   --dart-define=PANEL_TYPE=xboard \
///   --dart-define=SITE_ID=brand_x_prod \
///   --dart-define=SITE_NAME=HyenaVPN \
///   --dart-define=SKIN_ID=brand_x
///   --dart-define=HYENA_CORE_ANDROID=false  # 仅当需关闭 HyenaCore、使用 Singbox stub 时
/// ```
abstract final class AppConfig {
  static const panelApiBase = String.fromEnvironment(
    'PANEL_API_BASE',
    defaultValue: 'http://192.168.0.227:7001/',
  );
  static const panelType = String.fromEnvironment(
    'PANEL_TYPE',
    defaultValue: 'xboard',
  );
  static const siteId = String.fromEnvironment(
    'SITE_ID',
    defaultValue: 'dev',
  );
  static const siteName = String.fromEnvironment(
    'SITE_NAME',
    defaultValue: 'HyenaVPN',
  );
  static const skinId = String.fromEnvironment(
    'SKIN_ID',
    defaultValue: 'default',
  );
  static const defaultLocale = String.fromEnvironment(
    'DEFAULT_LOCALE',
    defaultValue: 'system',
  );

  /// Android 是否使用 `HyenaCoreEngine`（gomobile AAR）。
  /// 默认 **true**（上游 Android 构建已带 `without_psiphon`，避免 TLS 冲突）。
  /// 若需仅用 UI、不接真实内核，可 `--dart-define=HYENA_CORE_ANDROID=false`。
  static const enableHyenaCoreAndroid = bool.fromEnvironment(
    'HYENA_CORE_ANDROID',
    defaultValue: true,
  );

  static const appVersion = '0.1.0';
}
