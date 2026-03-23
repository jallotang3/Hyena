# 多平台 UI 架构设计方案

> **文档版本**: v1.0 | **创建时间**: 2026-03-23

## 问题描述

当前架构中 Controller/View 已分离，但 View 层需要同时支持：
1. **平台差异**：移动端（Android/iOS）vs 桌面端（Windows/macOS/Linux）
2. **系统规范**：Material Design（Android）vs Cupertino（iOS）vs Fluent（Windows）
3. **品牌定制**：不同运营商的品牌皮肤

**挑战**：如何在保持 Controller API 不变的前提下，优雅地处理这三个维度的差异？

---

## 解决方案：平台适配 + 主题定制

### 架构概览（简化版）

```
┌─────────────────────────────────────────────────────────────┐
│  Controller Layer (固定 API)                                 │
│  HomeController │ NodeController │ StoreController │ ...     │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  Platform Adapter Layer (平台适配层)                         │
│  ┌─────────────┬─────────────┬─────────────┐               │
│  │   Mobile    │   Desktop   │    iOS      │               │
│  │  (Material) │  (Adaptive) │ (Cupertino) │               │
│  └─────────────┴─────────────┴─────────────┘               │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  Theme Layer (主题层)                                        │
│  ThemeTokens (颜色/字体/圆角/图标)                           │
│  - Default Theme                                            │
│  - Brand X Theme                                            │
│  - Brand Y Theme                                            │
└─────────────────────────────────────────────────────────────┘
```

### 核心思想

1. **Controller Layer**：业务逻辑，平台无关
2. **Platform Adapter Layer**：处理平台差异（布局、交互、系统组件）
3. **Theme Layer**：处理品牌定制（颜色、字体、图标）

**简化理由**：
- 去掉了 `SkinPageFactory` 整页覆盖层（很少用到）
- 90% 的品牌定制只需要改颜色/字体，用 `ThemeTokens` 就够了
- 10% 真需要整页定制的，可以继承 `PlatformPageFactory` 实现
- 减少一层抽象，降低复杂度

---

## 方案 A：Platform-First（推荐）

### 1. 目录结构

```
lib/
├── controllers/              # Controller 层（不变）
│   ├── home_controller.dart
│   └── ...
├── platforms/                # 平台适配层（新增）
│   ├── mobile/               # 移动端（Material Design）
│   │   ├── pages/
│   │   │   ├── home_page.dart
│   │   │   ├── node_list_page.dart
│   │   │   └── ...
│   │   └── widgets/
│   │       ├── mobile_app_bar.dart
│   │       └── mobile_bottom_nav.dart
│   ├── desktop/              # 桌面端（Adaptive）
│   │   ├── pages/
│   │   │   ├── home_page.dart
│   │   │   └── ...
│   │   └── widgets/
│   │       ├── desktop_sidebar.dart
│   │       └── desktop_title_bar.dart
│   ├── ios/                  # iOS 专属（Cupertino，可选）
│   │   ├── pages/
│   │   │   ├── home_page.dart
│   │   │   └── ...
│   │   └── widgets/
│   │       └── cupertino_nav_bar.dart
│   └── platform_page_factory.dart  # 平台页面工厂
├── skins/                    # 品牌皮肤层（现有）
│   ├── default/
│   │   └── theme_tokens.dart
│   ├── brand_x/
│   │   └── theme_tokens.dart
│   └── skin_manager.dart
└── app.dart
```

### 2. PlatformPageFactory 实现

```dart
// lib/platforms/platform_page_factory.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum PlatformType {
  mobile,    // Android + iOS (Material)
  desktop,   // Windows + macOS + Linux
  ios,       // iOS (Cupertino) - 可选
}

abstract class PlatformPageFactory {
  /// 根据当前平台自动选择工厂
  static PlatformPageFactory create() {
    if (kIsWeb) {
      return DesktopPageFactory();
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return MobilePageFactory();
      case TargetPlatform.iOS:
        // 可选：使用专门的 iOS 工厂，或复用 Mobile
        return IosPageFactory(); // 或 MobilePageFactory()
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
        return DesktopPageFactory();
      default:
        return MobilePageFactory();
    }
  }

  // 所有页面的构建方法
  Widget buildHomePage(HomeController controller);
  Widget buildNodeListPage(NodeController controller);
  Widget buildStorePage(StoreController controller);
  // ... 其他页面
}
```

### 3. 移动端实现

```dart
// lib/platforms/mobile/mobile_page_factory.dart

import 'package:flutter/material.dart';
import '../../controllers/home_controller.dart';
import 'pages/home_page.dart';

class MobilePageFactory extends PlatformPageFactory {
  @override
  Widget buildHomePage(HomeController controller) {
    return MobileHomePage(controller: controller);
  }

  @override
  Widget buildNodeListPage(NodeController controller) {
    return MobileNodeListPage(controller: controller);
  }

  // ... 其他页面
}
```

```dart
// lib/platforms/mobile/pages/home_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/home_controller.dart';
import '../../../skins/theme_token_provider.dart';

class MobileHomePage extends StatelessWidget {
  final HomeController controller;

  const MobileHomePage({required this.controller, super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokenProvider.tokensOf(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hyena'),
        backgroundColor: tokens.colorPrimary,
      ),
      body: Column(
        children: [
          // 移动端布局：垂直排列
          _buildConnectionCard(context),
          _buildTrafficCard(context),
          _buildNodeCard(context),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildConnectionCard(BuildContext context) {
    return StreamBuilder(
      stream: controller.stateStream,
      builder: (context, snapshot) {
        final state = snapshot.data ?? EngineState.idle;
        return Card(
          child: ListTile(
            title: Text('状态: ${_stateText(state)}'),
            trailing: IconButton(
              icon: Icon(state == EngineState.connected
                ? Icons.stop : Icons.play_arrow),
              onPressed: state == EngineState.connected
                ? controller.disconnect
                : controller.connect,
            ),
          ),
        );
      },
    );
  }

  // ... 其他组件
}
```

### 4. 桌面端实现

```dart
// lib/platforms/desktop/pages/home_page.dart

import 'package:flutter/material.dart';
import '../../../controllers/home_controller.dart';
import '../widgets/desktop_sidebar.dart';

class DesktopHomePage extends StatelessWidget {
  final HomeController controller;

  const DesktopHomePage({required this.controller, super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 桌面端布局：左侧边栏 + 右侧内容
        const DesktopSidebar(),
        Expanded(
          child: Column(
            children: [
              _buildTitleBar(context),
              Expanded(
                child: Row(
                  children: [
                    // 左右分栏布局
                    Expanded(
                      flex: 2,
                      child: _buildConnectionPanel(context),
                    ),
                    Expanded(
                      flex: 3,
                      child: _buildTrafficPanel(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ... 桌面端特有的组件
}
```

### 5. iOS Cupertino 实现（可选）

```dart
// lib/platforms/ios/pages/home_page.dart

import 'package:flutter/cupertino.dart';
import '../../../controllers/home_controller.dart';

class IosHomePage extends StatelessWidget {
  final HomeController controller;

  const IosHomePage({required this.controller, super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Hyena'),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildConnectionCard(context),
            _buildTrafficCard(context),
            _buildNodeCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionCard(BuildContext context) {
    return StreamBuilder(
      stream: controller.stateStream,
      builder: (context, snapshot) {
        final state = snapshot.data ?? EngineState.idle;
        return CupertinoListSection(
          children: [
            CupertinoListTile(
              title: Text('状态: ${_stateText(state)}'),
              trailing: CupertinoButton(
                padding: EdgeInsets.zero,
                child: Icon(state == EngineState.connected
                  ? CupertinoIcons.stop_circle : CupertinoIcons.play_circle),
                onPressed: state == EngineState.connected
                  ? controller.disconnect
                  : controller.connect,
              ),
            ),
          ],
        );
      },
    );
  }

  // ... 其他 Cupertino 组件
}
```

### 6. Router 集成（简化版）

```dart
// lib/routes/app_router.dart

import 'package:go_router/go_router.dart';
import '../platforms/platform_page_factory.dart';
import '../controllers/home_controller.dart';

class AppRouter {
  static final _platformFactory = PlatformPageFactory.create();

  static final router = GoRouter(
    routes: [
      GoRoute(
        path: '/home',
        builder: (context, state) {
          final controller = Provider.of<HomeController>(context, listen: false);

          // 直接使用平台工厂构建页面
          // 页面内部通过 ThemeTokenProvider 获取品牌主题
          return _platformFactory.buildHomePage(controller);
        },
      ),
      // ... 其他路由
    ],
  );
}
```

### 7. 品牌定制方式

#### 方式 1: ThemeTokens 定制（推荐，90% 场景）

```dart
// lib/skins/brand_x/theme_tokens.dart

const kBrandXThemeTokens = ThemeTokens(
  colorPrimary: Color(0xFFF97316),      // 品牌主色
  colorBackground: Color(0xFFFFFBF5),   // 背景色
  colorSurface: Color(0xFFFFFFFF),      // 卡片色
  // ... 其他颜色
  radiusSmall: 10.0,
  radiusMedium: 16.0,
  radiusLarge: 28.0,
);

// 页面内使用
class MobileHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokenProvider.tokensOf(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: tokens.colorPrimary,  // 使用品牌主色
      ),
      // ...
    );
  }
}
```

#### 方式 2: 继承工厂定制（10% 场景，需要整页定制）

```dart
// lib/platforms/brand_x/brand_x_mobile_factory.dart

class BrandXMobilePageFactory extends MobilePageFactory {
  @override
  Widget buildHomePage(HomeController controller) {
    // 完全自定义首页
    return BrandXHomePage(controller: controller);
  }

  // 其他页面继承父类默认实现
}

// 在 main.dart 中使用
final platformFactory = BrandXMobilePageFactory(); // 而不是 PlatformPageFactory.create()
```

---

## 方案 B：Responsive Design（备选）

如果不想维护多套页面，可以使用响应式设计：

```dart
// lib/pages/home_page.dart

import 'package:flutter/material.dart';
import '../controllers/home_controller.dart';
import '../utils/responsive.dart';

class HomePage extends StatelessWidget {
  final HomeController controller;

  const HomePage({required this.controller, super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      mobile: (context) => _buildMobileLayout(context),
      tablet: (context) => _buildTabletLayout(context),
      desktop: (context) => _buildDesktopLayout(context),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hyena')),
      body: Column(children: [...]),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        const Sidebar(),
        Expanded(child: _buildContent()),
      ],
    );
  }
}
```

**优点**：
- 单一代码库，维护成本低
- 自动适配不同屏幕尺寸

**缺点**：
- 无法针对平台深度定制（如 iOS Cupertino）
- 代码复杂度高（大量条件判断）

---

## 方案对比

| 维度 | 方案 A (Platform-First) | 方案 B (Responsive) |
|------|------------------------|---------------------|
| 平台定制能力 | ⭐⭐⭐⭐⭐ 完全独立 | ⭐⭐⭐ 有限 |
| 代码复用 | ⭐⭐⭐ 中等（共享 Controller） | ⭐⭐⭐⭐⭐ 高 |
| 维护成本 | ⭐⭐⭐ 中等（多套 UI） | ⭐⭐⭐⭐ 低 |
| iOS 原生体验 | ⭐⭐⭐⭐⭐ 可用 Cupertino | ⭐⭐ 受限 |
| 桌面端体验 | ⭐⭐⭐⭐⭐ 可深度定制 | ⭐⭐⭐ 一般 |
| 品牌定制 | ⭐⭐⭐⭐⭐ 双层皮肤 | ⭐⭐⭐⭐ 单层皮肤 |

---

## 推荐方案

### 阶段 1：快速启动（方案 B）

如果团队资源有限，先用响应式设计：
- 移动端和桌面端共享代码
- 通过 `LayoutBuilder` 或 `MediaQuery` 判断屏幕尺寸
- 快速验证产品

### 阶段 2：体验优化（方案 A）

产品验证后，逐步迁移到平台优先：
- 先拆分移动端和桌面端
- 再针对 iOS 做 Cupertino 适配
- 最后针对 Windows 做 Fluent 适配

---

## 实施步骤

### Step 1: 创建平台适配层框架

```bash
mkdir -p lib/platforms/{mobile,desktop,ios}/pages
mkdir -p lib/platforms/{mobile,desktop,ios}/widgets
touch lib/platforms/platform_page_factory.dart
```

### Step 2: 实现 PlatformPageFactory

```dart
// 定义抽象接口
// 实现 MobilePageFactory
// 实现 DesktopPageFactory
// 实现 IosPageFactory（可选）
```

### Step 3: 迁移现有页面

```bash
# 将现有页面作为移动端实现
mv lib/features/*/screens/*.dart lib/platforms/mobile/pages/

# 创建桌面端页面
# 复制移动端页面，调整布局
```

### Step 4: 更新 Router

```dart
// 集成 PlatformPageFactory
// 保持 SkinPageFactory 作为第二层
```

### Step 5: 测试

```bash
# 在不同平台测试
flutter run -d android
flutter run -d windows
flutter run -d ios
```

---

## 常见问题

### Q1: 移动端 Android 和 iOS 需要分开吗？

**A**: 看需求：
- **不分开**（推荐）：Android 和 iOS 共用 Material Design，通过 `Theme` 微调
- **分开**：iOS 使用 Cupertino，提供原生体验，但维护成本高

### Q2: 桌面端 Windows/macOS/Linux 需要分开吗？

**A**: 通常不需要：
- 三者共用 `DesktopPageFactory`
- 通过 `Platform.isWindows` 等判断做微调（如标题栏）

### Q3: 品牌定制如何与平台适配结合？

**A**: 简化机制：
1. **平台层**：决定布局结构（移动端垂直、桌面端侧边栏）
2. **主题层**：决定颜色、字体、图标（ThemeTokens）
3. **特殊定制**：如需整页定制，继承 `PlatformPageFactory` 实现

**90% 的场景**：只需要修改 `ThemeTokens`
**10% 的场景**：继承 `PlatformPageFactory` 自定义页面

### Q4: Controller 需要感知平台吗？

**A**: **不需要**！这是关键：
- Controller 只提供业务 API
- 平台差异由 View 层处理
- 保持 Controller 的平台无关性

---

## 示例：完整的首页实现

### Controller（平台无关）

```dart
// lib/controllers/home_controller.dart

class HomeController extends ChangeNotifier {
  Stream<EngineState> get stateStream => _connectionUseCase.stateStream;
  Stream<TrafficStats> get trafficStream => _connectionUseCase.trafficStream;

  Future<void> connect() async { /* ... */ }
  Future<void> disconnect() async { /* ... */ }
  Future<void> switchRoutingMode(RoutingMode mode) async { /* ... */ }

  // 平台无关的业务逻辑
}
```

### 移动端 View

```dart
// lib/platforms/mobile/pages/home_page.dart

class MobileHomePage extends StatelessWidget {
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hyena')),
      body: Column(children: [...]),  // 垂直布局
      bottomNavigationBar: BottomNavigationBar(...),
    );
  }
}
```

### 桌面端 View

```dart
// lib/platforms/desktop/pages/home_page.dart

class DesktopHomePage extends StatelessWidget {
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Sidebar(...),  // 侧边栏
        Expanded(child: Row(children: [...])),  // 水平分栏
      ],
    );
  }
}
```

### iOS View（可选）

```dart
// lib/platforms/ios/pages/home_page.dart

class IosHomePage extends StatelessWidget {
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(...),
      child: Column(children: [...]),  // Cupertino 风格
    );
  }
}
```

---

## 总结

### 推荐架构（简化版）

```
Controller (业务逻辑，平台无关)
    ↓
PlatformPageFactory (平台适配：Mobile/Desktop/iOS)
    ↓
ThemeTokens (品牌主题：颜色/字体/圆角)
```

### 关键原则

1. **Controller 保持平台无关** - 只提供业务 API
2. **平台层处理布局差异** - 移动端垂直、桌面端侧边栏
3. **主题层处理品牌定制** - 颜色、字体、图标（ThemeTokens）
4. **特殊定制可继承** - 10% 需要整页定制的场景，继承工厂实现
5. **逐步迁移** - 先响应式，后平台优先

### 为什么去掉 SkinPageFactory？

1. **功能重叠** - `SkinPageFactory` 和 `PlatformPageFactory` 都是构建页面
2. **使用率低** - 90% 的品牌定制只需要改颜色/字体
3. **增加复杂度** - 两层工厂让代码难以理解和维护
4. **灵活性不减** - 真需要整页定制时，继承 `PlatformPageFactory` 即可

### 下一步

你想要我：
1. **实现 PlatformPageFactory 框架**？
2. **迁移现有页面到平台适配层**？
3. **创建桌面端示例页面**？
4. **创建 iOS Cupertino 示例页面**？

请告诉我你的选择！🚀
