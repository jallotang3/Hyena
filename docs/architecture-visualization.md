# 多平台 UI 架构可视化

## 架构全景图

```
┌─────────────────────────────────────────────────────────────────────┐
│                          Application Layer                          │
│                                                                     │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐            │
│  │   main.dart  │  │  app.dart    │  │ app_router   │            │
│  │              │  │              │  │              │            │
│  │ • 初始化平台  │  │ • MaterialApp│  │ • GoRouter   │            │
│  │ • 加载皮肤    │  │ • Provider   │  │ • 路由配置   │            │
│  └──────────────┘  └──────────────┘  └──────────────┘            │
└─────────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────────┐
│                         Controller Layer                            │
│                      (业务逻辑，平台无关)                            │
│                                                                     │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐            │
│  │    Home      │  │    Node      │  │  Settings    │            │
│  │  Controller  │  │  Controller  │  │  Controller  │            │
│  └──────────────┘  └──────────────┘  └──────────────┘            │
│                                                                     │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐            │
│  │   Profile    │  │    Store     │  │    Order     │            │
│  │  Controller  │  │  Controller  │  │  Controller  │            │
│  └──────────────┘  └──────────────┘  └──────────────┘            │
│                                                                     │
│  API: connect(), disconnect(), fetchUser(), etc.                   │
└─────────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────────┐
│                    Platform Adapter Layer                           │
│                      (平台适配，处理布局差异)                         │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │              PlatformPageFactory (抽象接口)                   │  │
│  │  • buildHomePage(controller)                                 │  │
│  │  • buildNodeListPage(controller)                             │  │
│  │  • buildSettingsPage(controller)                             │  │
│  │  • buildProfilePage(controller)                              │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                              ↓                                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐            │
│  │   Mobile     │  │   Desktop    │  │     iOS      │            │
│  │ PageFactory  │  │ PageFactory  │  │ PageFactory  │            │
│  │              │  │              │  │              │            │
│  │ Material     │  │ Sidebar +    │  │ Cupertino    │            │
│  │ Design       │  │ Multi-pane   │  │ Style        │            │
│  │              │  │              │  │              │            │
│  │ ✅ 已实现     │  │ ⏳ 待实现     │  │ ⏳ 可选       │            │
│  └──────────────┘  └──────────────┘  └──────────────┘            │
└─────────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────────┐
│                         Theme Layer                                 │
│                    (主题定制，处理品牌样式)                           │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │                      ThemeTokens                             │  │
│  │  • colorPrimary, colorBackground, colorSurface               │  │
│  │  • radiusSmall, radiusMedium, radiusLarge                    │  │
│  │  • fontFamily, fontSize, fontWeight                          │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                              ↓                                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐            │
│  │   Default    │  │   Brand X    │  │   Brand Y    │            │
│  │    Theme     │  │    Theme     │  │    Theme     │            │
│  │              │  │              │  │              │            │
│  │ Cyan/Dark    │  │ Orange/Light │  │ Custom       │            │
│  │ ✅ 已实现     │  │ ✅ 已实现     │  │ ⏳ 待实现     │            │
│  └──────────────┘  └──────────────┘  └──────────────┘            │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │         SkinPageFactory (可选，整页覆盖)                      │  │
│  │  • 10% 场景：需要完全自定义某个页面                           │  │
│  │  • 90% 场景：只需修改 ThemeTokens                             │  │
│  └─────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
```

## 页面构建流程

```
用户导航到 /home
       ↓
┌─────────────────────────────────────────┐
│  AppRouter (GoRouter)                   │
│                                         │
│  GoRoute(                               │
│    path: '/home',                       │
│    builder: (ctx, __) {                 │
│      final controller =                 │
│        ctx.read<HomeController>();      │
│                                         │
│      // 1. 尝试皮肤定制 (10%)           │
│      final skinPage =                   │
│        skinFactory.homePage(controller);│
│      if (skinPage != null)              │
│        return skinPage;                 │
│                                         │
│      // 2. 使用平台适配 (90%)           │
│      return platformFactory             │
│        .buildHomePage(controller);      │
│    }                                    │
│  )                                      │
└─────────────────────────────────────────┘
       ↓
┌─────────────────────────────────────────┐
│  PlatformPageFactory.buildHomePage()    │
│                                         │
│  根据平台返回对应实现:                   │
│  • Android → MobileHomePage             │
│  • iOS → MobileHomePage (或 IosHomePage)│
│  • Windows → DesktopHomePage            │
│  • macOS → DesktopHomePage              │
│  • Linux → DesktopHomePage              │
│  • Web → DesktopHomePage                │
└─────────────────────────────────────────┘
       ↓
┌─────────────────────────────────────────┐
│  MobileHomePage                         │
│                                         │
│  • 使用 ThemeTokenProvider 获取主题      │
│  • 使用 controller 获取业务数据          │
│  • 构建 Material Design UI              │
│  • 响应用户交互                          │
└─────────────────────────────────────────┘
```

## 目录结构详解

```
lib/
├── main.dart                           # 应用入口
│   └── SkinManager.instance.initPlatform()  # 初始化平台工厂
│
├── app.dart                            # 应用根组件
│   ├── MaterialApp
│   ├── ThemeTokenProvider              # 注入主题
│   └── MultiProvider                   # 注入 Controllers
│
├── routes/
│   └── app_router.dart                 # 路由配置
│       └── 双层工厂模式 (Skin + Platform)
│
├── controllers/                        # Controller 层
│   ├── home_controller.dart            # ✅ 首页业务逻辑
│   ├── node_controller.dart            # ✅ 节点业务逻辑
│   ├── settings_controller.dart        # ✅ 设置业务逻辑
│   ├── profile_controller.dart         # ✅ 个人中心业务逻辑
│   ├── store_controller.dart           # ⏳ 商店业务逻辑
│   ├── order_controller.dart           # ⏳ 订单业务逻辑
│   └── ticket_controller.dart          # ⏳ 工单业务逻辑
│
├── platforms/                          # Platform Adapter 层
│   ├── platform_page_factory.dart      # ✅ 平台工厂 (550行)
│   │   ├── PlatformPageFactory         # 抽象接口
│   │   ├── MobilePageFactory           # ✅ 移动端实现
│   │   ├── DesktopPageFactory          # ⏳ 桌面端实现
│   │   └── IosPageFactory              # ⏳ iOS 实现
│   │
│   ├── mobile/                         # 移动端页面
│   │   ├── pages/
│   │   │   ├── home_page.dart          # ✅ 首页 (634行)
│   │   │   ├── node_list_page.dart     # ✅ 节点列表 (400行)
│   │   │   ├── settings_page.dart      # ✅ 设置页 (218行)
│   │   │   ├── profile_page.dart       # ✅ 个人中心 (352行)
│   │   │   ├── store_page.dart         # ⏳ 商店页
│   │   │   ├── order_center_page.dart  # ⏳ 订单中心
│   │   │   └── ticket_list_page.dart   # ⏳ 工单列表
│   │   └── widgets/                    # 共享组件
│   │
│   ├── desktop/                        # 桌面端页面
│   │   ├── pages/                      # ⏳ 待实现
│   │   └── widgets/                    # ⏳ 待实现
│   │
│   └── ios/                            # iOS 页面
│       ├── pages/                      # ⏳ 可选
│       └── widgets/                    # ⏳ 可选
│
├── skins/                              # Theme 层
│   ├── skin_manager.dart               # ✅ 皮肤管理器
│   ├── theme_token_provider.dart       # ✅ 主题令牌
│   ├── skin_page_factory.dart          # ✅ 皮肤页面工厂
│   │
│   ├── default/                        # 默认主题
│   │   ├── theme_tokens.dart           # ✅ Cyan/Dark
│   │   └── default_page_factory.dart   # ✅ 默认工厂
│   │
│   └── brand_x/                        # Brand X 主题
│       ├── theme_tokens.dart           # ✅ Orange/Light
│       └── brand_x_page_factory.dart   # ✅ Brand X 工厂
│
└── features/                           # 原有功能模块
    ├── auth/                           # 认证
    ├── connection/                     # 连接
    ├── node/                           # 节点
    ├── store/                          # 商店
    ├── order/                          # 订单
    ├── ticket/                         # 工单
    └── profile/                        # 个人中心
```

## 数据流向图

```
┌─────────────────────────────────────────────────────────────┐
│                         User Action                         │
│                    (点击连接按钮)                            │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                      MobileHomePage                         │
│                                                             │
│  onPressed: () => controller.connect()                      │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                      HomeController                         │
│                                                             │
│  Future<void> connect() async {                             │
│    await _connectionUseCase.connect(currentNode!);          │
│    notifyListeners();  // 通知 UI 更新                      │
│  }                                                          │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                    ConnectionUseCase                        │
│                     (Domain Layer)                          │
│                                                             │
│  • 调用 Engine 连接                                          │
│  • 更新连接状态                                              │
│  • 发送状态流事件                                            │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                      SingboxDriver                          │
│                   (Infrastructure Layer)                    │
│                                                             │
│  • 启动 sing-box 进程                                        │
│  • 配置代理规则                                              │
│  • 监控连接状态                                              │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                    State Update Flow                        │
│                                                             │
│  ConnectionUseCase.stateStream                              │
│         ↓                                                   │
│  HomeController.stateStream                                 │
│         ↓                                                   │
│  StreamBuilder in MobileHomePage                            │
│         ↓                                                   │
│  UI 自动更新 (连接按钮变为断开按钮)                          │
└─────────────────────────────────────────────────────────────┘
```

## 主题定制流程

```
┌─────────────────────────────────────────────────────────────┐
│                    启动时加载皮肤                            │
│                                                             │
│  main() async {                                             │
│    // 1. 初始化平台工厂                                      │
│    SkinManager.instance.initPlatform();                     │
│                                                             │
│    // 2. 加载皮肤                                           │
│    final skinId = AppPreferences.instance.skinId;           │
│    await SkinManager.instance.load(skinId);                 │
│  }                                                          │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                    SkinManager.load()                       │
│                                                             │
│  • 根据 skinId 解析皮肤合约                                  │
│  • 加载 ThemeTokens                                         │
│  • 加载 SkinPageFactory (可选)                              │
│  • 验证合约版本                                              │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                  ThemeTokenProvider                         │
│                                                             │
│  • 将 ThemeTokens 注入到 Widget 树                           │
│  • 所有页面通过 ThemeTokenProvider.tokensOf(context)        │
│    获取主题令牌                                              │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                    页面使用主题                              │
│                                                             │
│  class MobileHomePage extends StatelessWidget {             │
│    @override                                                │
│    Widget build(BuildContext context) {                     │
│      final tokens = ThemeTokenProvider.tokensOf(context);   │
│                                                             │
│      return Scaffold(                                       │
│        backgroundColor: tokens.colorBackground,             │
│        appBar: AppBar(                                      │
│          backgroundColor: tokens.colorPrimary,              │
│        ),                                                   │
│        // ...                                               │
│      );                                                     │
│    }                                                        │
│  }                                                          │
└─────────────────────────────────────────────────────────────┘
```

## 平台检测逻辑

```
┌─────────────────────────────────────────────────────────────┐
│            PlatformPageFactory.create()                     │
└─────────────────────────────────────────────────────────────┘
                              ↓
                    ┌─────────────────┐
                    │   kIsWeb?       │
                    └─────────────────┘
                       ↓ Yes      ↓ No
              ┌────────────┐    ┌──────────────────────┐
              │  Desktop   │    │ defaultTargetPlatform│
              │  Factory   │    └──────────────────────┘
              └────────────┘              ↓
                                ┌─────────────────────┐
                                │   Android?          │
                                └─────────────────────┘
                                  ↓ Yes      ↓ No
                          ┌────────────┐  ┌──────────┐
                          │  Mobile    │  │   iOS?   │
                          │  Factory   │  └──────────┘
                          └────────────┘    ↓ Yes  ↓ No
                                    ┌────────────┐ ┌──────────┐
                                    │  Mobile/   │ │ Windows/ │
                                    │  iOS       │ │ macOS/   │
                                    │  Factory   │ │ Linux?   │
                                    └────────────┘ └──────────┘
                                                     ↓ Yes  ↓ No
                                              ┌────────────┐ ┌────────────┐
                                              │  Desktop   │ │  Mobile    │
                                              │  Factory   │ │  Factory   │
                                              └────────────┘ └────────────┘
```

## 关键设计决策

### 1. 为什么使用工厂模式？
- ✅ **解耦**: Controller 不需要知道具体的 UI 实现
- ✅ **扩展性**: 添加新平台只需实现新的工厂类
- ✅ **可测试性**: 可以轻松 mock 工厂进行测试
- ✅ **代码复用**: Controller 在所有平台共享

### 2. 为什么是双层工厂？
- ✅ **90/10 原则**: 90% 场景只需修改 ThemeTokens
- ✅ **灵活性**: 10% 场景可以通过 SkinPageFactory 完全定制
- ✅ **简化**: 避免三层工厂的复杂度
- ✅ **渐进式**: 可以先用 ThemeTokens，需要时再用 SkinPageFactory

### 3. 为什么 Controller 保持平台无关？
- ✅ **单一职责**: Controller 只负责业务逻辑
- ✅ **可维护性**: 业务逻辑变更不影响 UI
- ✅ **可测试性**: 可以独立测试业务逻辑
- ✅ **代码复用**: 一套 Controller 支持所有平台

### 4. 为什么使用 ThemeTokens？
- ✅ **一致性**: 确保整个应用的视觉一致性
- ✅ **可维护性**: 修改主题只需改一个地方
- ✅ **品牌定制**: 轻松实现多品牌支持
- ✅ **设计系统**: 符合现代设计系统理念

## 性能考虑

### 1. 页面构建性能
- ✅ 使用 `const` 构造函数减少重建
- ✅ 使用 `ListenableBuilder` 精确控制重建范围
- ✅ 使用 `StreamBuilder` 只在数据变化时重建
- ✅ 避免在 `build` 方法中创建新对象

### 2. 内存优化
- ✅ Controller 使用 `ChangeNotifier` 自动管理监听器
- ✅ 页面销毁时自动清理资源
- ✅ 图片使用缓存机制
- ✅ 列表使用 `ListView.builder` 懒加载

### 3. 启动性能
- ✅ 平台工厂在启动时初始化一次
- ✅ 皮肤加载异步进行
- ✅ 使用 `addPostFrameCallback` 延迟非关键操作
- ✅ 避免在启动时加载大量数据

## 总结

这个架构设计实现了：

1. ✅ **清晰的分层**: Controller → Platform → Theme
2. ✅ **高度解耦**: 各层职责明确，互不干扰
3. ✅ **易于扩展**: 添加新平台或主题非常简单
4. ✅ **代码复用**: Controller 和业务逻辑完全共享
5. ✅ **灵活定制**: 支持从简单到复杂的各种定制需求
6. ✅ **性能优化**: 考虑了构建、内存和启动性能
7. ✅ **可维护性**: 代码结构清晰，易于理解和维护

**这是一个生产级别的多平台 UI 架构！** 🚀
