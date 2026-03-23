# 多平台 UI 架构 - 快速开始指南

## 🚀 5分钟快速上手

### 前置条件

- Flutter SDK 3.0+
- Dart 3.0+
- 已配置好的开发环境（Android Studio / VS Code）

### 第一步：了解架构

这个架构分为三层：

```
Controller (业务逻辑) → Platform (平台适配) → Theme (主题定制)
```

- **Controller**: 处理业务逻辑，平台无关
- **Platform**: 根据平台提供不同的 UI 实现
- **Theme**: 通过 ThemeTokens 定制品牌样式

### 第二步：运行项目

```bash
# 克隆项目
cd /path/to/hyena

# 获取依赖
flutter pub get

# 运行项目（移动端）
flutter run -d android  # 或 ios

# 运行项目（桌面端）
flutter run -d windows  # 或 macos/linux
```

### 第三步：查看已实现的页面

已实现的移动端页面：
- ✅ 首页 (`/home`)
- ✅ 节点列表 (`/nodes`)
- ✅ 设置页 (`/settings`)
- ✅ 个人中心 (`/profile`)

在应用中导航到这些页面，查看实际效果。

## 📝 添加新页面的完整流程

### 场景：添加一个"关于"页面

#### 1. 创建 Controller（如果需要）

```dart
// lib/controllers/about_controller.dart
import 'package:flutter/foundation.dart';

class AboutController extends ChangeNotifier {
  String get appVersion => '1.0.0';
  String get buildNumber => '100';

  Future<void> checkUpdate() async {
    // 检查更新逻辑
    notifyListeners();
  }
}
```

#### 2. 创建移动端页面

```dart
// lib/platforms/mobile/pages/about_page.dart
import 'package:flutter/material.dart';
import '../../../controllers/about_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../../../skins/theme_token_provider.dart';

class MobileAboutPage extends StatelessWidget {
  final AboutController controller;

  const MobileAboutPage({required this.controller, super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokenProvider.tokensOf(context);
    final s = S.of(context)!;

    return Scaffold(
      backgroundColor: tokens.colorBackground,
      appBar: AppBar(
        backgroundColor: tokens.colorBackground,
        title: Text(s.about),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 应用图标
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: tokens.colorPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(tokens.radiusLarge),
              ),
              child: Icon(
                Icons.info_outline,
                size: 50,
                color: tokens.colorPrimary,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 应用名称
          Center(
            child: Text(
              s.appName,
              style: TextStyle(
                color: tokens.colorOnBackground,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // 版本号
          Center(
            child: Text(
              'v${controller.appVersion} (${controller.buildNumber})',
              style: TextStyle(
                color: tokens.colorMuted,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // 检查更新按钮
          ElevatedButton(
            onPressed: () => controller.checkUpdate(),
            style: ElevatedButton.styleFrom(
              backgroundColor: tokens.colorPrimary,
              foregroundColor: tokens.colorOnPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(tokens.radiusMedium),
              ),
            ),
            child: Text(s.checkUpdate),
          ),
        ],
      ),
    );
  }
}
```

#### 3. 更新 PlatformPageFactory

```dart
// lib/platforms/platform_page_factory.dart

// 1. 添加导入
import 'mobile/pages/about_page.dart';

// 2. 在抽象类中添加方法
abstract class PlatformPageFactory {
  // ... 其他方法

  /// 关于页
  Widget buildAboutPage(AboutController controller);
}

// 3. 在 MobilePageFactory 中实现
class MobilePageFactory extends PlatformPageFactory {
  // ... 其他方法

  @override
  Widget buildAboutPage(AboutController controller) {
    return MobileAboutPage(controller: controller);
  }
}

// 4. 在 DesktopPageFactory 中实现（占位符）
class DesktopPageFactory extends PlatformPageFactory {
  // ... 其他方法

  @override
  Widget buildAboutPage(AboutController controller) {
    return _placeholder('Desktop About Page');
  }
}

// 5. 在 IosPageFactory 中实现（占位符）
class IosPageFactory extends PlatformPageFactory {
  // ... 其他方法

  @override
  Widget buildAboutPage(AboutController controller) {
    return _placeholder('iOS About Page');
  }
}
```

#### 4. 注册 Controller

```dart
// lib/main.dart

// 1. 添加导入
import 'controllers/about_controller.dart';

// 2. 在 MultiProvider 中添加
runApp(
  MultiProvider(
    providers: [
      // ... 其他 providers

      ChangeNotifierProvider(
        create: (_) => AboutController(),
      ),
    ],
    child: const HyenaApp(),
  ),
);
```

#### 5. 添加路由

```dart
// lib/routes/app_router.dart

// 1. 添加导入
import '../controllers/about_controller.dart';

// 2. 在 routes 中添加
static GoRouter router(AuthNotifier auth) {
  final platformFactory = SkinManager.instance.platformFactory;
  final skinFactory = SkinManager.instance.pageFactory;

  return GoRouter(
    // ... 其他配置
    routes: [
      // ... 其他路由

      GoRoute(
        path: '/about',
        builder: (ctx, __) {
          final controller = ctx.read<AboutController>();

          // 1. 尝试皮肤定制
          final skinPage = skinFactory.aboutPage(controller);
          if (skinPage != null) return skinPage;

          // 2. 使用平台适配
          return platformFactory.buildAboutPage(controller);
        },
      ),
    ],
  );
}
```

#### 6. 添加导航入口

```dart
// 在设置页或其他页面添加导航按钮
ListTile(
  leading: Icon(Icons.info_outline, color: tokens.colorPrimary),
  title: Text(s.about, style: TextStyle(color: tokens.colorOnBackground)),
  trailing: Icon(Icons.chevron_right, color: tokens.colorMuted),
  onTap: () => context.push('/about'),
),
```

#### 7. 添加 l10n 字符串（如果需要）

```json
// lib/l10n/app_en.arb
{
  "about": "About",
  "checkUpdate": "Check for Updates"
}

// lib/l10n/app_zh_CN.arb
{
  "about": "关于",
  "checkUpdate": "检查更新"
}
```

#### 8. 测试

```bash
# 运行应用
flutter run

# 导航到关于页面
# 验证功能是否正常
```

### 完成！🎉

现在你已经成功添加了一个新页面，它会：
- ✅ 在移动端显示 Material Design 风格
- ✅ 在桌面端显示占位符（待实现）
- ✅ 支持主题定制（通过 ThemeTokens）
- ✅ 支持国际化（通过 l10n）
- ✅ 支持皮肤覆盖（通过 SkinPageFactory）

## 🎨 定制品牌主题

### 场景：创建一个新的品牌主题 "Brand Y"

#### 1. 创建主题文件

```dart
// lib/skins/brand_y/theme_tokens.dart
import 'package:flutter/material.dart';
import '../theme_token_provider.dart';

/// Brand Y 主题 - 橙色/浅色
const kBrandYThemeTokens = ThemeTokens(
  // 颜色
  colorPrimary: Color(0xFFFF6B35),      // 橙色
  colorBackground: Color(0xFFFFFBF5),   // 米白色
  colorSurface: Color(0xFFFFFFFF),      // 白色
  colorSurfaceVariant: Color(0xFFF5F5F5), // 浅灰
  colorOnBackground: Color(0xFF1A1A1A), // 深灰
  colorOnSurface: Color(0xFF2C2C2C),    // 深灰
  colorOnPrimary: Color(0xFFFFFFFF),    // 白色
  colorMuted: Color(0xFF9E9E9E),        // 灰色
  colorError: Color(0xFFF44336),        // 红色
  colorSuccess: Color(0xFF4CAF50),      // 绿色

  // 圆角
  radiusSmall: 12.0,
  radiusMedium: 16.0,
  radiusLarge: 24.0,

  // 字体（可选）
  fontFamily: 'Roboto',
);
```

#### 2. 创建页面工厂（可选，如需整页定制）

```dart
// lib/skins/brand_y/brand_y_page_factory.dart
import 'package:flutter/widgets.dart';
import '../../controllers/home_controller.dart';
import '../skin_page_factory.dart';

class BrandYPageFactory extends SkinPageFactory {
  // 只覆盖需要特殊定制的页面
  // 其他页面返回 null，使用默认实现

  @override
  Widget? homePage(HomeController c) {
    // 如果需要完全自定义首页，返回自定义实现
    // return BrandYHomePage(controller: c);

    // 否则返回 null，使用默认实现 + ThemeTokens
    return null;
  }
}
```

#### 3. 注册皮肤

```dart
// lib/skins/skin_manager.dart

// 1. 添加导入
import 'brand_y/theme_tokens.dart';
import 'brand_y/brand_y_page_factory.dart';

// 2. 在 _resolveSkin 中添加
Future<SkinContract> _resolveSkin(String skinId) async {
  return switch (skinId) {
    'default' => _DefaultSkinContract(),
    'brand_x' => _BrandXSkinContract(),
    'brand_y' => _BrandYSkinContract(),  // 新增
    _ => throw ArgumentError('Unknown skinId: $skinId'),
  };
}

// 3. 添加合约类
class _BrandYSkinContract implements SkinContract {
  @override
  String get contractVersion => '1.0.0';

  @override
  String get skinId => 'brand_y';

  @override
  ThemeTokens get themeTokens => kBrandYThemeTokens;

  @override
  SkinPageFactory get pageFactory => BrandYPageFactory();
}
```

#### 4. 切换皮肤

```dart
// 在设置页或其他地方添加皮肤切换
await SkinManager.instance.load('brand_y');
```

#### 5. 测试

```bash
# 运行应用
flutter run

# 切换到 Brand Y 皮肤
# 验证主题是否正确应用
```

### 完成！🎨

现在你已经成功创建了一个新的品牌主题，它会：
- ✅ 应用到所有页面
- ✅ 保持一致的视觉风格
- ✅ 支持运行时切换
- ✅ 可选择性地覆盖特定页面

## 🖥️ 实现桌面端页面

### 场景：实现桌面端首页

#### 1. 创建桌面端页面

```dart
// lib/platforms/desktop/pages/home_page.dart
import 'package:flutter/material.dart';
import '../../../controllers/home_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../../../skins/theme_token_provider.dart';
import '../widgets/desktop_sidebar.dart';

class DesktopHomePage extends StatelessWidget {
  final HomeController controller;

  const DesktopHomePage({required this.controller, super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokenProvider.tokensOf(context);

    return Scaffold(
      backgroundColor: tokens.colorBackground,
      body: Row(
        children: [
          // 左侧边栏
          const DesktopSidebar(),

          // 右侧内容区
          Expanded(
            child: Column(
              children: [
                // 标题栏
                _buildTitleBar(context, tokens),

                // 内容区（水平分栏）
                Expanded(
                  child: Row(
                    children: [
                      // 左侧面板（连接控制）
                      Expanded(
                        flex: 2,
                        child: _buildConnectionPanel(context, tokens),
                      ),

                      // 右侧面板（流量统计）
                      Expanded(
                        flex: 3,
                        child: _buildTrafficPanel(context, tokens),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleBar(BuildContext context, ThemeTokens tokens) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: tokens.colorSurface,
        border: Border(
          bottom: BorderSide(
            color: tokens.colorMuted.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Hyena VPN',
            style: TextStyle(
              color: tokens.colorOnBackground,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.settings_outlined, color: tokens.colorMuted),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionPanel(BuildContext context, ThemeTokens tokens) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Connection',
            style: TextStyle(
              color: tokens.colorOnBackground,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),

          // 连接按钮
          StreamBuilder<EngineState>(
            stream: controller.stateStream,
            builder: (context, snapshot) {
              final state = snapshot.data ?? EngineState.idle;
              final isConnected = state == EngineState.connected;

              return ElevatedButton(
                onPressed: isConnected
                    ? controller.disconnect
                    : controller.connect,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isConnected
                      ? tokens.colorError
                      : tokens.colorPrimary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(tokens.radiusMedium),
                  ),
                ),
                child: Text(
                  isConnected ? 'Disconnect' : 'Connect',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTrafficPanel(BuildContext context, ThemeTokens tokens) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Traffic Statistics',
            style: TextStyle(
              color: tokens.colorOnBackground,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),

          // 流量统计
          StreamBuilder<TrafficStats>(
            stream: controller.trafficStream,
            builder: (context, snapshot) {
              final stats = snapshot.data ?? TrafficStats.zero;

              return Row(
                children: [
                  Expanded(
                    child: _buildTrafficCard(
                      'Upload',
                      stats.uploadSpeed,
                      stats.uploadBytes,
                      tokens,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTrafficCard(
                      'Download',
                      stats.downloadSpeed,
                      stats.downloadBytes,
                      tokens,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTrafficCard(
    String label,
    double speed,
    int total,
    ThemeTokens tokens,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tokens.colorSurface,
        borderRadius: BorderRadius.circular(tokens.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: tokens.colorMuted,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${speed.toStringAsFixed(1)} MB/s',
            style: TextStyle(
              color: tokens.colorOnBackground,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Total: ${(total / 1024 / 1024).toStringAsFixed(1)} MB',
            style: TextStyle(
              color: tokens.colorMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
```

#### 2. 创建侧边栏组件

```dart
// lib/platforms/desktop/widgets/desktop_sidebar.dart
import 'package:flutter/material.dart';
import '../../../skins/theme_token_provider.dart';

class DesktopSidebar extends StatelessWidget {
  const DesktopSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokenProvider.tokensOf(context);

    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: tokens.colorSurface,
        border: Border(
          right: BorderSide(
            color: tokens.colorMuted.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // Logo
          Icon(
            Icons.vpn_key,
            size: 40,
            color: tokens.colorPrimary,
          ),
          const SizedBox(height: 8),
          Text(
            'Hyena',
            style: TextStyle(
              color: tokens.colorOnBackground,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 40),

          // 导航项
          _NavItem(
            icon: Icons.home_outlined,
            label: 'Home',
            isActive: true,
            tokens: tokens,
            onTap: () {},
          ),
          _NavItem(
            icon: Icons.dns_outlined,
            label: 'Nodes',
            isActive: false,
            tokens: tokens,
            onTap: () {},
          ),
          _NavItem(
            icon: Icons.settings_outlined,
            label: 'Settings',
            isActive: false,
            tokens: tokens,
            onTap: () {},
          ),
          _NavItem(
            icon: Icons.person_outline,
            label: 'Profile',
            isActive: false,
            tokens: tokens,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.tokens,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final ThemeTokens tokens;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: isActive ? tokens.colorPrimary : tokens.colorMuted,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isActive ? tokens.colorPrimary : tokens.colorOnBackground,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isActive,
      selectedTileColor: tokens.colorPrimary.withValues(alpha: 0.1),
      onTap: onTap,
    );
  }
}
```

#### 3. 更新 DesktopPageFactory

```dart
// lib/platforms/platform_page_factory.dart

// 1. 添加导入
import 'desktop/pages/home_page.dart';

// 2. 在 DesktopPageFactory 中实现
class DesktopPageFactory extends PlatformPageFactory {
  @override
  Widget buildHomePage(HomeController controller) {
    return DesktopHomePage(controller: controller);
  }

  // ... 其他方法
}
```

#### 4. 测试

```bash
# 运行桌面端
flutter run -d windows  # 或 macos/linux

# 验证桌面端首页是否正确显示
```

### 完成！🖥️

现在你已经成功实现了桌面端首页，它会：
- ✅ 显示侧边栏导航
- ✅ 使用水平分栏布局
- ✅ 适配大屏幕
- ✅ 使用相同的 Controller 和业务逻辑
- ✅ 支持主题定制

## 🐛 常见问题

### Q1: 如何调试平台检测？

```dart
// 在 main.dart 中添加日志
void main() async {
  // ...
  SkinManager.instance.initPlatform();

  // 添加调试日志
  print('Platform: ${SkinManager.instance.platformFactory.platformType}');

  // ...
}
```

### Q2: 如何在运行时切换皮肤？

```dart
// 在设置页或其他地方
await SkinManager.instance.load('brand_x');

// 重启应用以应用新皮肤
if (context.mounted) {
  // 方法1: 使用 Phoenix 包重启
  Phoenix.rebirth(context);

  // 方法2: 手动重启（简单但不优雅）
  exit(0);
}
```

### Q3: 如何添加新的 ThemeToken？

```dart
// 1. 在 ThemeTokens 类中添加新字段
class ThemeTokens {
  // ... 现有字段

  final Color colorWarning;  // 新增

  const ThemeTokens({
    // ... 现有参数
    required this.colorWarning,  // 新增
  });
}

// 2. 在所有主题中添加值
const kDefaultThemeTokens = ThemeTokens(
  // ... 现有值
  colorWarning: Color(0xFFFFA726),  // 新增
);

// 3. 在页面中使用
Container(
  color: tokens.colorWarning,
  // ...
)
```

### Q4: 如何处理平台特定的功能？

```dart
// 使用 Platform 类检测
import 'dart:io';

if (Platform.isAndroid) {
  // Android 特定代码
} else if (Platform.isIOS) {
  // iOS 特定代码
} else if (Platform.isWindows) {
  // Windows 特定代码
}

// 或者在 Controller 中提供平台无关的 API
class HomeController {
  Future<void> shareApp() async {
    if (Platform.isAndroid || Platform.isIOS) {
      // 使用 share_plus 包
      await Share.share('Check out Hyena VPN!');
    } else {
      // 桌面端：复制到剪贴板
      await Clipboard.setData(ClipboardData(text: 'Check out Hyena VPN!'));
    }
  }
}
```

### Q5: 如何测试不同平台的 UI？

```bash
# 方法1: 使用真机/模拟器
flutter run -d android
flutter run -d ios
flutter run -d windows

# 方法2: 使用 Flutter DevTools
flutter run --observatory-port=8888
# 然后在浏览器中打开 DevTools

# 方法3: 使用截图测试
flutter test --update-goldens
```

## 📚 更多资源

### 文档
- [设计文档](../guides/multi-platform-ui-architecture.md)
- [实现总结](../implementation-summary.md)
- [架构可视化](../architecture-visualization.md)

### 外部资源
- [Flutter 官方文档](https://flutter.dev/docs)
- [Material Design 3](https://m3.material.io/)
- [Cupertino (iOS) Design](https://developer.apple.com/design/human-interface-guidelines/ios)
- [Fluent Design (Windows)](https://www.microsoft.com/design/fluent/)

### 示例代码
- 移动端首页: `lib/platforms/mobile/pages/home_page.dart`
- 节点列表: `lib/platforms/mobile/pages/node_list_page.dart`
- 设置页: `lib/platforms/mobile/pages/settings_page.dart`
- 个人中心: `lib/platforms/mobile/pages/profile_page.dart`

## 🎯 下一步

现在你已经掌握了这个架构的基础知识，可以：

1. ✅ 添加新页面
2. ✅ 定制品牌主题
3. ✅ 实现桌面端页面
4. ✅ 调试和测试

继续探索和实践，祝你开发愉快！🚀

---

**需要帮助？**
- 查看文档: `docs/` 目录
- 查看示例: `lib/platforms/mobile/pages/` 目录
- 提交 Issue: [GitHub Issues](https://github.com/your-repo/issues)

**Created by**: Claude Code
**Version**: 1.0.0
**Last Updated**: 2026-03-23
