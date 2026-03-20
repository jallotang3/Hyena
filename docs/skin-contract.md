# Hyena · 界面设计规范（Skin Contract）

> **文档版本**: v1.0 | **状态**: 草稿 | **更新时间**: 2026-03
>
> 本文档定义了 Hyena 所有页面的 Controller API 契约。
> 皮肤开发者 / UI 设计者只需依赖本文档中列出的**状态属性**和**操作方法**，
> 无需了解 UseCase / Adapter / Storage 等业务内部实现。

---

## 1. 架构概览

```
┌─────────────────────────────────────────────┐
│  View（Page Widget）                         │
│  ✅ 读取 Controller 状态                      │
│  ✅ 调用 Controller 方法                      │
│  ✅ 使用 ThemeTokens 获取样式                  │
│  ❌ 禁止直接引用 UseCase / Adapter / Storage   │
└──────────────────┬──────────────────────────┘
                   │
          Controller API（固定契约）
                   │
┌──────────────────▼──────────────────────────┐
│  ScreenController（extends ChangeNotifier）  │
│  内部编排 UseCase + Notifier                  │
│  对外暴露稳定的 getter + action               │
└─────────────────────────────────────────────┘
```

### 基本规则

1. 每个 Controller 继承 `ChangeNotifier`，通过 `Provider` 注入。
2. View 通过 `context.watch<XxxController>()` 监听状态变化。
3. View 通过 `context.read<XxxController>().action()` 触发操作。
4. Controller API 一旦发布即为稳定契约，破坏性变更需升级 `contractVersion`。

---

## 2. Controller API 清单

### 2.1 SplashController

> 启动页（`/splash`）— 会话恢复、自动连接、导航决策

| 类型 | 名称 | 类型/签名 | 说明 |
|------|------|-----------|------|
| 状态 | `isInitialized` | `bool` | 初始化是否完成 |
| 状态 | `shouldNavigateTo` | `String?` | 初始化完成后应跳转的路由（`/home` 或 `/login`） |
| 操作 | `initialize()` | `Future<void>` | 执行会话恢复 + 自动连接，完成后设置 `shouldNavigateTo` |

---

### 2.2 AuthController

> 登录（`/login`）、注册（`/register`）、忘记密码（`/forgot-password`）

| 类型 | 名称 | 类型/签名 | 说明 |
|------|------|-----------|------|
| 状态 | `isLoading` | `bool` | 正在执行登录/注册/重置操作 |
| 状态 | `isSendingCode` | `bool` | 正在发送验证码 |
| 状态 | `error` | `String?` | 最近一次操作的错误信息 |
| 状态 | `resetSuccess` | `bool` | 密码重置是否成功 |
| 操作 | `login(String email, String password)` | `Future<bool>` | 登录，返回是否成功 |
| 操作 | `register(String email, String password, String emailCode, String? inviteCode)` | `Future<bool>` | 注册 |
| 操作 | `sendEmailCode(String email)` | `Future<bool>` | 发送邮箱验证码 |
| 操作 | `resetPassword(String email, String code, String newPassword)` | `Future<bool>` | 重置密码 |
| 操作 | `clearError()` | `void` | 清除错误信息 |

---

### 2.3 HomeController

> 连接首页（`/home`）— 核心连接交互

| 类型 | 名称 | 类型/签名 | 说明 |
|------|------|-----------|------|
| 状态 | `connectionState` | `EngineState` | 连接状态（idle/connecting/connected/disconnecting/error） |
| 状态 | `currentNode` | `ProxyNode?` | 当前选中节点 |
| 状态 | `currentMode` | `RoutingMode` | 当前路由模式（global/rule/direct） |
| 状态 | `trafficUp` | `int` | 上行流量速率（bytes/s） |
| 状态 | `trafficDown` | `int` | 下行流量速率（bytes/s） |
| 状态 | `connectedSince` | `DateTime?` | 本次连接开始时间 |
| 状态 | `connectionDuration` | `Duration` | 本次连接持续时长 |
| 状态 | `userEmail` | `String?` | 当前登录用户邮箱 |
| 状态 | `isNodeFavorite` | `bool` | 当前节点是否已收藏 |
| 操作 | `connect()` | `Future<void>` | 连接当前节点 |
| 操作 | `disconnect()` | `Future<void>` | 断开连接 |
| 操作 | `switchNode(ProxyNode node)` | `Future<void>` | 切换到新节点并连接 |
| 操作 | `switchRoutingMode(RoutingMode mode)` | `Future<void>` | 切换路由模式（热切换） |
| 操作 | `toggleFavorite()` | `void` | 切换当前节点收藏状态 |
| 操作 | `refreshTraffic()` | `Future<void>` | 刷新流量统计 |

---

### 2.4 NodeController

> 节点列表（`/nodes`）— 节点浏览、搜索、排序、测速

| 类型 | 名称 | 类型/签名 | 说明 |
|------|------|-----------|------|
| 状态 | `nodes` | `List<ProxyNode>` | 已排序/过滤的节点列表 |
| 状态 | `favoriteNodes` | `List<ProxyNode>` | 收藏节点列表 |
| 状态 | `isLoading` | `bool` | 正在加载节点列表 |
| 状态 | `isTesting` | `bool` | 正在批量测速 |
| 状态 | `error` | `String?` | 错误信息 |
| 状态 | `sortMode` | `NodeSortMode` | 当前排序模式（name/latency/group） |
| 状态 | `filter` | `String` | 当前搜索关键词 |
| 状态 | `selectedNode` | `ProxyNode?` | 当前选中节点（高亮显示用） |
| 操作 | `load({bool forceRefresh})` | `Future<void>` | 加载/刷新节点列表 |
| 操作 | `testAllNodes()` | `Future<void>` | 批量测速 |
| 操作 | `setSortMode(NodeSortMode mode)` | `void` | 设置排序模式 |
| 操作 | `setFilter(String keyword)` | `void` | 设置搜索过滤 |
| 操作 | `toggleFavorite(String nodeId)` | `void` | 切换节点收藏 |
| 操作 | `selectAndConnect(ProxyNode node)` | `Future<void>` | 选择节点并连接 |

---

### 2.5 StoreController

> 商店（`/store`）、订单确认（`/order/confirm`）— 套餐浏览与下单

| 类型 | 名称 | 类型/签名 | 说明 |
|------|------|-----------|------|
| 状态 | `plans` | `List<PlanItem>` | 套餐列表 |
| 状态 | `isLoading` | `bool` | 正在加载 |
| 状态 | `error` | `String?` | 错误信息 |
| 状态 | `selectedPeriod` | `String?` | 选中的周期（month_price/quarter_price/...） |
| 状态 | `couponResult` | `CouponCheckResult?` | 优惠码验证结果 |
| 状态 | `paymentMethods` | `List<PaymentMethod>` | 可用支付方式 |
| 状态 | `isSubmitting` | `bool` | 正在提交订单 |
| 操作 | `fetchPlans()` | `Future<void>` | 获取套餐列表 |
| 操作 | `selectPeriod(String period)` | `void` | 选择周期 |
| 操作 | `checkCoupon(String code, int planId)` | `Future<void>` | 验证优惠码 |
| 操作 | `createOrder(int planId, String period, String? couponCode)` | `Future<String?>` | 创建订单，返回 tradeNo |
| 操作 | `fetchPaymentMethods()` | `Future<void>` | 获取支付方式 |
| 操作 | `checkout(String tradeNo, int methodId)` | `Future<PaymentResult?>` | 发起支付 |

---

### 2.6 OrderController

> 订单中心（`/orders`）、订单详情（`/orders/:tradeNo`）、支付结果（`/order/result`）

| 类型 | 名称 | 类型/签名 | 说明 |
|------|------|-----------|------|
| 状态 | `orders` | `List<Order>` | 订单列表 |
| 状态 | `currentOrder` | `Order?` | 当前查看的订单详情 |
| 状态 | `isLoading` | `bool` | 正在加载 |
| 状态 | `error` | `String?` | 错误信息 |
| 状态 | `isPaid` | `bool` | 当前订单是否已支付 |
| 操作 | `fetchOrders()` | `Future<void>` | 获取订单列表 |
| 操作 | `fetchOrderDetail(String tradeNo)` | `Future<void>` | 获取订单详情 |
| 操作 | `cancelOrder(String tradeNo)` | `Future<bool>` | 取消订单 |
| 操作 | `checkOrderStatus(String tradeNo)` | `Future<bool>` | 查询支付状态 |
| 操作 | `pollPaymentStatus(String tradeNo)` | `Future<void>` | 轮询支付状态直到完成 |

---

### 2.7 TicketController

> 工单列表（`/tickets`）、新建工单（`/tickets/new`）、工单详情（`/tickets/:id`）

| 类型 | 名称 | 类型/签名 | 说明 |
|------|------|-----------|------|
| 状态 | `tickets` | `List<Ticket>` | 工单列表 |
| 状态 | `currentTicket` | `Ticket?` | 当前查看的工单详情（含消息列表） |
| 状态 | `isLoading` | `bool` | 正在加载 |
| 状态 | `isSending` | `bool` | 正在发送回复 |
| 状态 | `error` | `String?` | 错误信息 |
| 操作 | `fetchTickets()` | `Future<void>` | 获取工单列表 |
| 操作 | `fetchTicketDetail(int ticketId)` | `Future<void>` | 获取工单详情 |
| 操作 | `createTicket(String subject, int level, String message)` | `Future<bool>` | 创建工单 |
| 操作 | `replyTicket(int ticketId, String message)` | `Future<bool>` | 回复工单 |
| 操作 | `closeTicket(int ticketId)` | `Future<bool>` | 关闭工单 |

---

### 2.8 ProfileController

> 用户中心（`/profile`）、邀请推广（`/invite`）、礼品卡（`/giftcard`）

| 类型 | 名称 | 类型/签名 | 说明 |
|------|------|-----------|------|
| 状态 | `user` | `PanelUser?` | 当前用户信息 |
| 状态 | `inviteSummary` | `InviteSummary?` | 邀请统计 |
| 状态 | `isLoading` | `bool` | 正在加载 |
| 状态 | `error` | `String?` | 错误信息 |
| 操作 | `fetchUser()` | `Future<void>` | 获取用户信息 |
| 操作 | `changePassword(String oldPwd, String newPwd)` | `Future<bool>` | 修改密码 |
| 操作 | `logout()` | `Future<void>` | 登出 |
| 操作 | `fetchInviteSummary()` | `Future<void>` | 获取邀请统计 |
| 操作 | `generateInviteCode()` | `Future<String?>` | 生成邀请码 |
| 操作 | `checkGiftCard(String code)` | `Future<GiftCardPreview?>` | 查询礼品卡 |
| 操作 | `redeemGiftCard(String code)` | `Future<bool>` | 兑换礼品卡 |

---

### 2.9 SettingsController

> 设置页（`/settings`）

| 类型 | 名称 | 类型/签名 | 说明 |
|------|------|-----------|------|
| 状态 | `autoConnect` | `bool` | 自动连接开关 |
| 状态 | `currentLocale` | `Locale?` | 当前语言（null 表示跟随系统） |
| 状态 | `currentSkinId` | `String` | 当前皮肤 ID |
| 操作 | `setAutoConnect(bool value)` | `Future<void>` | 设置自动连接 |
| 操作 | `setLocale(Locale? locale)` | `void` | 设置语言（null 表示跟随系统） |
| 操作 | `setSkin(String skinId)` | `Future<void>` | 切换皮肤 |

---

### 2.10 DiagController

> 诊断页（`/diagnostics`）— 日志查看与导出

| 类型 | 名称 | 类型/签名 | 说明 |
|------|------|-----------|------|
| 状态 | `logs` | `List<String>` | 日志条目列表（最新在前） |
| 状态 | `connectionState` | `EngineState` | 当前连接状态 |
| 状态 | `connectionDuration` | `Duration` | 连接持续时长 |
| 状态 | `isExporting` | `bool` | 正在导出日志 |
| 操作 | `refreshLogs()` | `void` | 刷新日志列表 |
| 操作 | `exportLogs()` | `Future<void>` | 导出并分享日志文件 |
| 操作 | `runDiagnostics()` | `Future<void>` | 运行诊断检查并写入结果 |

---

### 2.11 NoticeController

> 公告列表（`/notices`）

| 类型 | 名称 | 类型/签名 | 说明 |
|------|------|-----------|------|
| 状态 | `notices` | `List<Notice>` | 公告列表 |
| 状态 | `isLoading` | `bool` | 正在加载 |
| 状态 | `error` | `String?` | 错误信息 |
| 操作 | `fetchNotices()` | `Future<void>` | 获取公告列表 |
| 操作 | `markAsRead(int noticeId)` | `void` | 标记已读 |

---

### 2.12 KnowledgeController

> 帮助中心（`/help`）、帮助文章（`/help/:id`）

| 类型 | 名称 | 类型/签名 | 说明 |
|------|------|-----------|------|
| 状态 | `categories` | `List<KnowledgeCategory>` | 知识库分类 |
| 状态 | `articles` | `List<KnowledgeArticle>` | 当前分类的文章列表 |
| 状态 | `currentArticle` | `KnowledgeArticle?` | 当前查看的文章 |
| 状态 | `isLoading` | `bool` | 正在加载 |
| 状态 | `error` | `String?` | 错误信息 |
| 操作 | `fetchCategories()` | `Future<void>` | 获取分类列表 |
| 操作 | `fetchArticles(int categoryId)` | `Future<void>` | 获取文章列表 |
| 操作 | `fetchArticleDetail(int articleId)` | `Future<void>` | 获取文章详情 |
| 操作 | `search(String keyword)` | `Future<void>` | 搜索文章 |

---

### 2.13 TrafficChartController

> 流量统计（`/traffic-chart`）— 月流量图表

| 类型 | 名称 | 类型/签名 | 说明 |
|------|------|-----------|------|
| 状态 | `records` | `List<TrafficRecord>` | 每日流量记录 |
| 状态 | `totalUpload` | `int` | 当月总上传 |
| 状态 | `totalDownload` | `int` | 当月总下载 |
| 状态 | `isLoading` | `bool` | 正在加载 |
| 状态 | `error` | `String?` | 错误信息 |
| 操作 | `fetchTrafficLog()` | `Future<void>` | 获取月流量数据 |

---

## 3. SkinPageFactory 接口

皮肤开发者通过实现 `SkinPageFactory` 来覆盖页面。每个方法接收对应的 Controller，返回 `Widget?`。返回 `null` 表示使用默认页面。

```dart
abstract class SkinPageFactory {
  Widget? splashPage(SplashController c);
  Widget? loginPage(AuthController c);
  Widget? registerPage(AuthController c);
  Widget? forgotPasswordPage(AuthController c);
  Widget? homePage(HomeController c);
  Widget? nodePage(NodeController c);
  Widget? storePage(StoreController c);
  Widget? orderConfirmPage(StoreController c);
  Widget? paymentResultPage(OrderController c);
  Widget? orderCenterPage(OrderController c);
  Widget? orderDetailPage(OrderController c);
  Widget? ticketListPage(TicketController c);
  Widget? newTicketPage(TicketController c);
  Widget? ticketDetailPage(TicketController c);
  Widget? profilePage(ProfileController c);
  Widget? invitePage(ProfileController c);
  Widget? settingsPage(SettingsController c);
  Widget? diagnosticsPage(DiagController c);
  Widget? noticePage(NoticeController c);
  Widget? knowledgePage(KnowledgeController c);
  Widget? knowledgeDetailPage(KnowledgeController c);
  Widget? trafficChartPage(TrafficChartController c);
}
```

---

## 4. ThemeTokens 使用规范

所有 View 应通过 `ThemeTokenProvider.tokensOf(context)` 获取样式令牌，禁止硬编码颜色/字体。

### 4.1 当前可用 Token

| 分类 | Token | 类型 | 说明 |
|------|-------|------|------|
| 颜色 | `primaryColor` | `Color` | 主色调 |
| 颜色 | `secondaryColor` | `Color` | 辅助色 |
| 颜色 | `backgroundColor` | `Color` | 页面背景色 |
| 颜色 | `surfaceColor` | `Color` | 卡片/表面色 |
| 颜色 | `errorColor` | `Color` | 错误色 |
| 颜色 | `onPrimaryColor` | `Color` | 主色上的文字/图标色 |
| 圆角 | `borderRadius` | `double` | 通用圆角半径 |
| 间距 | `spacingXs` | `double` | 极小间距 (4) |
| 间距 | `spacingSm` | `double` | 小间距 (8) |
| 间距 | `spacingMd` | `double` | 中间距 (16) |
| 间距 | `spacingLg` | `double` | 大间距 (24) |
| 间距 | `spacingXl` | `double` | 极大间距 (32) |
| 字体 | `fontFamily` | `String?` | 全局字体 |
| 字体 | `fontSizeCaption` | `double` | 标注文字大小 |
| 字体 | `fontWeightNormal` | `FontWeight` | 正常字重 |
| 字体 | `fontWeightBold` | `FontWeight` | 粗体字重 |
| 按钮 | `buttonHeight` | `double` | 按钮高度 |
| 按钮 | `buttonPadding` | `EdgeInsets` | 按钮内边距 |
| 按钮 | `connectButtonSize` | `double` | 连接按钮尺寸 |

### 4.2 使用示例

```dart
// ✅ 正确：通过 Token 获取样式
final tokens = ThemeTokenProvider.tokensOf(context);
Container(
  padding: EdgeInsets.all(tokens.spacingMd),
  decoration: BoxDecoration(
    color: tokens.surfaceColor,
    borderRadius: BorderRadius.circular(tokens.borderRadius),
  ),
  child: Text('Hello', style: TextStyle(fontFamily: tokens.fontFamily)),
);

// ❌ 错误：硬编码颜色
Container(color: Color(0xFF2196F3)); // 禁止
```

---

## 5. 皮肤开发流程

### 5.1 创建新皮肤包

```
skins/
  brand_x/
    theme_tokens.dart        # 实现 ThemeTokens（颜色/字体/间距）
    brand_x_page_factory.dart # 实现 SkinPageFactory（覆盖需要定制的页面）
    assets/                  # 品牌资源（图标/图片/字体）
```

### 5.2 最小可用皮肤

只需提供自定义 `ThemeTokens`，页面工厂返回全 `null`（使用所有默认页面）：

```dart
class BrandXSkin implements SkinContract {
  @override String get contractVersion => '1.0.0';
  @override String get skinId => 'brand_x';
  @override ThemeTokens get themeTokens => BrandXThemeTokens();
  @override SkinPageFactory get pageFactory => DefaultPageFactory();
}
```

### 5.3 覆盖特定页面

只覆盖需要定制的页面，其余返回 `null`：

```dart
class BrandXPageFactory extends DefaultPageFactory {
  @override
  Widget? homePage(HomeController c) {
    return BrandXHomePage(controller: c);
  }
  // 其他页面返回 null，使用默认实现
}
```

### 5.4 自定义页面实现规则

1. 只通过 Controller 参数获取状态和调用操作。
2. 使用 `ThemeTokenProvider.tokensOf(context)` 获取样式。
3. 通过 `AnimatedBuilder` 或 `ListenableBuilder` 监听 Controller 变化。
4. 禁止 `context.read<UseCase>()` 等越层调用。

```dart
class BrandXHomePage extends StatelessWidget {
  final HomeController controller;
  const BrandXHomePage({required this.controller});

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokenProvider.tokensOf(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Scaffold(
          body: Column(children: [
            Text('状态: ${controller.connectionState}'),
            ElevatedButton(
              onPressed: controller.connectionState == EngineState.connected
                  ? controller.disconnect
                  : controller.connect,
              child: Text(controller.connectionState == EngineState.connected
                  ? '断开' : '连接'),
            ),
          ]),
        );
      },
    );
  }
}
```

---

## 6. 版本兼容性

| 规则 | 说明 |
|------|------|
| 新增状态属性 | 兼容变更，皮肤可选择使用或忽略 |
| 新增操作方法 | 兼容变更，皮肤可选择调用或不调用 |
| 修改已有属性类型 | **破坏性变更**，需升级 `contractVersion` 主版本号 |
| 删除已有属性/方法 | **破坏性变更**，需升级 `contractVersion` 主版本号 |
| 新增 ThemeToken | 兼容变更，提供默认值 |
| 新增 SkinPageFactory 方法 | 兼容变更，默认返回 `null` |
