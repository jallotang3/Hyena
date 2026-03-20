# Hyena 多面板 VPN 客户端 · 系统设计方案（V1）

> **文档版本**: v1.2 | **状态**: 评审中 | **更新时间**: 2026-03

---

## 1. 设计目标与原则

### 1.1 设计目标

- 支持多面板统一接入，V1 落地 xboard，后续零侵入扩展。
- 可插拔内核架构，V1 默认 sing-box，未来可替换/并行多内核。
- UI 皮肤独立封装，品牌定制不触碰业务代码。
- 通过 GitHub Actions + 配置模板自动生成多品牌多平台制品。
- 架构整体满足"可扩展、可观测、可测试"三大原则。

### 1.2 核心设计原则

| 原则 | 实践方式 |
|------|---------|
| 依赖倒置 | 业务层依赖抽象接口，不依赖具体实现（面板/内核/皮肤） |
| 单一职责 | 适配器/驱动/皮肤各层职责边界清晰，不相互侵入 |
| 开闭原则 | 新增面板/内核/皮肤通过注册扩展，不修改现有代码 |
| 可观测性 | 关键链路状态机 + 结构化日志 + 指标暴露 |

---

## 2. 总体架构

### 2.1 分层架构

```
┌──────────────────────────────────────────────────────────┐
│                   皮肤层 Skin Layer                       │
│  ThemeTokenProvider │ SkinComponentRegistry │ LayoutPreset │
├──────────────────────────────────────────────────────────┤
│                   展示层 UI Layer                         │
│  Pages（Splash/Login/Home/Nodes/Store/Order/Ticket/     │
│         Invite/Profile/Settings/Diag/Notice/Knowledge） │
│  消费 ViewModel，不直接依赖皮肤实现细节                    │
├──────────────────────────────────────────────────────────┤
│                   应用层 Application Layer                 │
│  AuthUseCase │ NodeUseCase │ ConnectionUseCase │ SiteUseCase│
├──────────────────────────────────────────────────────────┤
│                   领域层 Domain Layer                      │
│  PanelAdapter │ CoreEngine │ SkinContract │ 统一模型        │
├──────────────────┬────────────────────────────────────────┤
│  面板基础设施层   │          内核基础设施层                  │
│  XboardAdapter   │  SingboxDriver │ EngineRegistry         │
│  AdapterRegistry │  EngineConfigBuilder │ RoutingPolicy    │
├──────────────────┴────────────────────────────────────────┤
│                   通用基础设施层                            │
│  Network（Dio）│ SecureStorage │ CacheStorage │ Logger      │
└──────────────────────────────────────────────────────────┘
```

### 2.2 数据流

```
用户操作
  │
  ▼
UI Page（消费 ViewModel）
  │── 触发 Action ──▶ UseCase
                          │
                ┌─────────┴──────────┐
                ▼                    ▼
         PanelGateway          ConnectionUseCase
           │                         │
           ▼                         ▼
     PanelAdapter            EngineConfigBuilder
     (XboardAdapter)                 │
           │                         ▼
           ▼                   CoreEngine / EngineDriver
     RawNode[]              (SingboxDriver via FFI/libbox)
           │
           ▼
     NodeNormalizer
           │
           ▼
       ProxyNode[]  ──────────────▶ 缓存 + UI 展示
```

### 2.3 皮肤系统关系

```
SkinPackage (skinId)
  ├── theme_tokens.dart   → ThemeTokenProvider → MaterialTheme
  ├── components/         → SkinComponentRegistry → 组件槽位装配
  ├── assets/             → 图标 / 图片 / 字体资源
  └── skin_manifest.json  → 皮肤合约版本 + 槽位声明

        SkinManager
            │
     ┌──────┴───────┐
     ▼              ▼
DefaultSkin      BrandXSkin   (实现相同合约)
```

---

## 3. 模块详细设计

### 3.1 皮肤层（Skin Layer）

皮肤层是 UI 与业务之间的样式隔离层，独立于业务逻辑存在。

#### 3.1.1 核心组件

| 组件 | 职责 |
|------|------|
| `SkinManager` | 按 skinId 加载皮肤包；加载失败自动回退到 default skin |
| `ThemeTokenProvider` | 将皮肤令牌注入 Flutter MaterialTheme，全局可用 |
| `SkinComponentRegistry` | 维护组件槽位 → 具体 Widget 实现的映射表 |
| `LayoutPresetResolver` | 根据平台（mobile/desktop）返回对应布局预设 |
| `SkinContract` | 皮肤合约：版本号 + 可定制页面清单 + 组件槽位清单 |

#### 3.1.2 皮肤合约（Skin Contract）定义示意

```dart
/// 皮肤合约：每个皮肤包必须实现此接口
abstract class SkinContract {
  /// 合约版本，用于兼容性校验
  String get contractVersion; // e.g. "1.0.0"

  /// 皮肤 ID，全局唯一
  String get skinId;

  /// 主题令牌：颜色/字体/间距/圆角
  ThemeTokens get themeTokens;

  /// 可定制页面集合（未声明的页面使用 default 实现）
  Set<SkinPage> get supportedPages;

  /// 组件槽位实现（未注册的槽位使用 default 实现）
  Map<SkinSlot, WidgetBuilder> get componentOverrides;

  /// 资源包路径（图标/图片/字体）
  String get assetBasePath;
}

/// 可定制页面枚举
enum SkinPage { login, nodeList, connection, settings, splash }

/// 组件槽位枚举（V1 有限槽位，避免过度开放）
enum SkinSlot {
  connectButton,    // 连接/断开按钮
  nodeCard,         // 节点列表卡片
  trafficBadge,     // 流量徽章
  statusIndicator,  // 连接状态指示器
  bottomNavBar,     // 底部导航栏（移动端）
  sideNavBar,       // 侧边导航（桌面端）
}
```

#### 3.1.3 皮肤合约版本管理

- `contractVersion` 采用语义版本（SemVer）。
- 皮肤包加载时校验 `contractVersion` 是否与当前 SDK 兼容。
- 不兼容时降级到 default skin，日志记录原因。
- 皮肤包升级独立于业务版本，可单独发布。

### 3.2 展示层（UI Layer）

- 页面仅消费 UseCase 暴露的 ViewModel（纯数据，无样式）。
- 所有样式从 `ThemeTokenProvider` 或 `SkinComponentRegistry` 获取，禁止硬编码颜色/字体。
- 状态管理：V1 统一使用 **Provider**（参考 MagicLamp 实践）。
- 响应式布局：通过 `LayoutPresetResolver` 分离移动端与桌面端布局逻辑。

**页面清单（V1）**

| 页面 | 路由 | 说明 |
|------|------|------|
| 启动页 | `/splash` | 品牌动画、首次引导检测 |
| 注册 | `/register` | 邮箱注册（含邀请码） |
| 登录 | `/login` | 账号密码登录 |
| 忘记密码 | `/forgot-password` | 邮件验证码重置 |
| 连接首页 | `/home` | 当前节点、连接状态、实时流量、套餐概览 |
| 节点列表 | `/nodes` | 节点展示、测速、收藏、搜索 |
| 商店 | `/store` | 套餐列表与周期选择 |
| 订单确认 | `/order/confirm` | 套餐快照、优惠码、支付方式选择 |
| 支付结果 | `/order/result` | 支付成功/失败结果页 |
| 订单中心 | `/orders` | 历史订单列表 |
| 订单详情 | `/orders/:tradeNo` | 单笔订单详情 |
| 工单列表 | `/tickets` | 工单列表 |
| 新建工单 | `/tickets/new` | 提交工单 |
| 工单详情 | `/tickets/:id` | 对话式工单详情与回复 |
| 用户中心 | `/profile` | 用户信息、订阅详情、安全设置 |
| 邀请推广 | `/invite` | 邀请码、佣金统计、提现 |
| 礼品卡 | `/giftcard` | 礼品卡兑换与历史 |
| 公告 | `/notices` | 公告列表 |
| 帮助中心 | `/help` | 知识库分类与搜索 |
| 帮助文章 | `/help/:id` | 知识库文章详情 |
| 设置 | `/settings` | 主题、路由策略、自动连接、内核选择 |
| 诊断 | `/diagnostics` | 日志查看与导出 |

### 3.3 应用层（Application Layer）

```dart
// 示意：UseCase 只依赖领域接口，不依赖具体实现
class ConnectionUseCase {
  final CoreEngine _engine;
  final NodeRepository _nodeRepo;

  Future<void> connect(String nodeId) async { ... }
  Future<void> disconnect() async { ... }
  Stream<EngineState> watchState() => _engine.stateStream;
}
```

| UseCase | 职责 |
|---------|------|
| `AuthUseCase` | 注册、登录、登出、Token 刷新、忘记密码、登录状态持久化 |
| `SiteUseCase` | 站点新增/编辑/删除/切换、面板类型探测 |
| `NodeUseCase` | 订阅拉取、节点解析、测速、收藏、排序 |
| `ConnectionUseCase` | 配置生成、连接/断开/重连、状态流订阅 |
| `UserProfileUseCase` | 用户信息、订阅详情、修改密码、重置凭证、会话管理、通知设置 |
| `StoreUseCase` | 套餐列表、套餐详情、优惠码验证 |
| `OrderUseCase` | 创建订单、获取支付方式、发起支付、轮询状态、取消订单、历史订单 |
| `TicketUseCase` | 工单列表、工单详情、创建/回复/关闭工单、佣金提现申请 |
| `InviteUseCase` | 邀请码管理、邀请统计、佣金明细、佣金转余额 |
| `GiftCardUseCase` | 礼品卡查询、兑换、兑换历史 |
| `NoticeUseCase` | 公告列表、公告阅读状态 |
| `KnowledgeUseCase` | 知识库文章列表、搜索、文章详情 |
| `StatUseCase` | 当月流量统计数据 |
| `SkinUseCase` | 皮肤加载、切换、版本校验 |

### 3.4 领域层（Domain Layer）

#### 统一实体模型

```dart
/// 每个发行包对应唯一站点，baseUrl / panelType 由构建期 CI/CD 模板注入，
/// 运行时从编译常量读取，用户不可修改（无"输入站点地址"交互）。
class PanelSite {
  final String id, name, baseUrl;
  final String panelType; // xboard / v2board / sspanel
  final SiteConfig config;

  /// 从构建期编译常量构造（dart-define 注入）
  factory PanelSite.fromBuildConfig() => PanelSite(
    id:        const String.fromEnvironment('SITE_ID'),
    name:      const String.fromEnvironment('SITE_NAME'),
    baseUrl:   const String.fromEnvironment('PANEL_API_BASE'),
    panelType: const String.fromEnvironment('PANEL_TYPE'),
    config:    SiteConfig.defaults(),
  );
}

class PanelUser {
  final String email;
  final int trafficUsed, trafficTotal; // bytes
  final DateTime expireAt;
  final String planName;
}

class ProxyNode {
  final String id, name, group;
  final String protocol; // vless / vmess / ss / trojan / hysteria2
  final String address;
  final int port;
  final Map<String, dynamic> extra; // 协议特有字段
}

class TrafficStats {
  final int uploadBytes, downloadBytes;
  final double uploadSpeed, downloadSpeed; // bytes/s
}

enum EngineState { idle, preparing, connecting, connected, disconnecting, error }
```

#### 商业实体模型

```dart
// ── 套餐 ──────────────────────────────────────────────────────────────
class PlanItem {
  final int id;
  final String name;
  final int? transferEnable;    // 流量限额 (bytes)，null=无限
  final int? speedLimit;        // 限速 (Mbps)，null=不限
  final int? deviceLimit;       // 设备数限制，null=不限
  final Map<String, int> prices; // e.g. {"month_price": 1000, "quarter_price": 2800}
  final String? content;        // 套餐详细说明 HTML/Markdown
}

// ── 订单 ──────────────────────────────────────────────────────────────
class Order {
  final String tradeNo;
  final int status; // 0=待支付 1=开通中 2=撤销 3=已完成 4=折扣抵扣
  final int totalAmount;     // 分
  final int? balanceAmount;  // 余额抵扣金额（分）
  final int? handlingAmount; // 手续费（分）
  final PlanItem? plan;
  final String period; // month / quarter / half_year / year / ...
  final String? couponCode;
  final DateTime createdAt;
}

// ── 支付方式 ───────────────────────────────────────────────────────────
class PaymentMethod {
  final int id;
  final String name;
  final String payment; // stripe / alipay / wechat / ...
  final String? icon;
  final int? handlingFeeFixed;   // 分
  final double? handlingFeePercent;
}

// ── 工单 ──────────────────────────────────────────────────────────────
class Ticket {
  final int id;
  final String subject;
  final int level;    // 1=普通 2=高 3=紧急
  final int status;   // 0=待处理 1=已关闭
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<TicketMessage>? messages; // 详情时才展开
}

class TicketMessage {
  final int id;
  final int userId;
  final String message;
  final bool isMe;       // 是否为当前用户发出
  final DateTime createdAt;
}

// ── 邀请 & 佣金 ────────────────────────────────────────────────────────
class InviteCode {
  final int id;
  final String code;
  final int status; // 0=未使用
  final DateTime createdAt;
}

class CommissionRecord {
  final int id;
  final int inviteUserId;
  final int getAmount;   // 分
  final DateTime createdAt;
}

// ── 礼品卡 ─────────────────────────────────────────────────────────────
class GiftCardPreview {
  final String code;
  final bool canRedeem;
  final String? reason;
  final List<Map<String, dynamic>> rewardPreview;
}

// ── 公告 ───────────────────────────────────────────────────────────────
class Notice {
  final int id;
  final String title;
  final String content; // HTML
  final DateTime createdAt;
}

// ── 知识库 ─────────────────────────────────────────────────────────────
class KnowledgeArticle {
  final int id;
  final String category;
  final String title;
  final String? body;  // 详情时才填充
  final DateTime updatedAt;
}
```

---

## 4. 多面板适配器设计

### 4.1 统一接口

```dart
abstract class PanelAdapter {
  /// 面板类型标识，用于注册与发现
  String get panelType;

  // ── 认证 ─────────────────────────────────────────────────────────
  Future<AuthResult> register(PanelSite site, RegisterCredentials cred);
  Future<AuthResult> login(PanelSite site, Credentials credentials);
  Future<void> logout(PanelSite site, AuthContext auth);
  Future<AuthContext> refreshToken(PanelSite site, AuthContext auth);
  Future<bool> sendEmailVerifyCode(PanelSite site, String email);
  Future<bool> resetPassword(PanelSite site, String email, String code, String newPwd);

  // ── 用户信息 ──────────────────────────────────────────────────────
  Future<PanelUser> fetchUserInfo(PanelSite site, AuthContext auth);
  Future<SubscribeInfo> fetchSubscribeInfo(PanelSite site, AuthContext auth);
  Future<List<ProxyNode>> fetchNodes(PanelSite site, AuthContext auth);
  Future<bool> changePassword(PanelSite site, AuthContext auth, String oldPwd, String newPwd);
  Future<String> resetSecurity(PanelSite site, AuthContext auth);
  Future<void> updateUserSettings(PanelSite site, AuthContext auth, UserSettings settings);

  // ── 套餐 ──────────────────────────────────────────────────────────
  Future<List<PlanItem>> fetchPlans(PanelSite site, AuthContext auth);
  Future<PlanItem> fetchPlanDetail(PanelSite site, AuthContext auth, int planId);

  // ── 订单与支付 ────────────────────────────────────────────────────
  Future<String> createOrder(PanelSite site, AuthContext auth, OrderRequest req);
  Future<List<PaymentMethod>> fetchPaymentMethods(PanelSite site, AuthContext auth);
  Future<PaymentResult> checkout(PanelSite site, AuthContext auth, String tradeNo, int methodId);
  Future<int> checkOrderStatus(PanelSite site, AuthContext auth, String tradeNo);
  Future<bool> cancelOrder(PanelSite site, AuthContext auth, String tradeNo);
  Future<List<Order>> fetchOrders(PanelSite site, AuthContext auth, {int? status});
  Future<Order> fetchOrderDetail(PanelSite site, AuthContext auth, String tradeNo);

  // ── 优惠码 / 礼品卡 ───────────────────────────────────────────────
  Future<CouponInfo> checkCoupon(PanelSite site, AuthContext auth, CouponCheckRequest req);
  Future<GiftCardPreview> checkGiftCard(PanelSite site, AuthContext auth, String code);
  Future<GiftCardRedeemResult> redeemGiftCard(PanelSite site, AuthContext auth, String code);
  Future<List<GiftCardUsage>> fetchGiftCardHistory(PanelSite site, AuthContext auth);

  // ── 工单 ──────────────────────────────────────────────────────────
  Future<List<Ticket>> fetchTickets(PanelSite site, AuthContext auth);
  Future<Ticket> fetchTicketDetail(PanelSite site, AuthContext auth, int ticketId);
  Future<bool> createTicket(PanelSite site, AuthContext auth, TicketRequest req);
  Future<bool> replyTicket(PanelSite site, AuthContext auth, int ticketId, String message);
  Future<bool> closeTicket(PanelSite site, AuthContext auth, int ticketId);

  // ── 邀请 & 佣金 ───────────────────────────────────────────────────
  Future<InviteSummary> fetchInviteSummary(PanelSite site, AuthContext auth);
  Future<bool> generateInviteCode(PanelSite site, AuthContext auth);
  Future<List<CommissionRecord>> fetchCommissionDetails(PanelSite site, AuthContext auth, int page);
  Future<bool> transferCommissionToBalance(PanelSite site, AuthContext auth, int amount);

  // ── 公告 / 知识库 / 统计 ─────────────────────────────────────────
  Future<List<Notice>> fetchNotices(PanelSite site, AuthContext auth, {int page = 1});
  Future<List<KnowledgeArticle>> fetchKnowledge(PanelSite site, AuthContext auth, {String? language, String? keyword});
  Future<KnowledgeArticle> fetchKnowledgeDetail(PanelSite site, AuthContext auth, int id);
  Future<List<TrafficRecord>> fetchTrafficLog(PanelSite site, AuthContext auth);

  Future<PanelCapabilities> getCapabilities();
}

class PanelCapabilities {
  final bool supportsRefreshToken;
  final bool supportsAnnouncement;
  final bool supportsOrderManagement;
  final bool supportsTicketSystem;
  final bool supportsInviteSystem;
  final bool supportsGiftCard;
  final bool supportsKnowledgeBase;
  final Set<String> supportedProtocols;
}
```

### 4.2 XboardAdapter（V1 实现）

xboard 用户端 API 分为 10 大模块，`XboardAdapter` 完整实现上述接口：

#### API 基础约定

| 项目 | 说明 |
|------|------|
| 基础路径 | `{baseUrl}/api/v1` |
| 认证方式 | `Authorization: {authData}` 请求头（Bearer Token） |
| 响应格式 | `{ "data": ..., "message": "..." }` |
| 错误码 | HTTP 401 → `AuthExpiredException`；422 → `ApiValidationException`；5xx → `PanelUnavailableException` |

#### 字段映射

| xboard 字段 | 领域模型字段 |
|-------------|------------|
| `transfer_enable` | `PanelUser.trafficTotal` (bytes) |
| `u + d` | `PanelUser.trafficUsed` (bytes) |
| `expired_at` | `PanelUser.expireAt` (Unix timestamp → DateTime) |
| `balance` | `PanelUser.balance` (分) |
| `commission_balance` | `PanelUser.commissionBalance` (分) |
| `plan_id` | 需再发起 `/plan/fetch?id=` 获取套餐名 |
| 订单 `status` 0/1/2/3 | `Order.status` 待支付/开通中/撤销/已完成 |
| 工单 `level` 1/2/3 | `Ticket.level` 普通/高/紧急 |

#### 订阅解析双模式

```dart
// 模式 A：订阅 URL 模式（base64 编码的 clash/sing-box 配置）
Future<List<ProxyNode>> _parseFromSubscribeUrl(String url) async {
  final raw = await _dio.get(url);
  final decoded = utf8.decode(base64.decode(raw));
  return SingboxConfigParser.parse(decoded);
}

// 模式 B：API 接口模式（JSON 节点列表）
Future<List<ProxyNode>> _parseFromApiEndpoint(PanelSite site, AuthContext auth) async {
  final resp = await _dio.get('/user/server/fetch', headers: _authHeaders(auth));
  return resp.data['data'].map((n) => _mapToProxyNode(n)).toList();
}
```

#### 支付流程状态机

```
创建订单 (save)
    │
    ▼
[tradeNo]
    │
    ▼
获取支付方式列表 (getPaymentMethod)
    │
    ▼
结算 (checkout)
    │
    ├─ type=-1 → 免费订单，直接完成
    ├─ type=0  → 跳转 URL（系统浏览器或 WebView）
    └─ type=1  → 返回支付数据（二维码等）
    │
    ▼
轮询状态 (check) 每 3s 一次
    │
    ├─ status=3 → 已完成，订阅更新
    ├─ status=0 → 继续轮询（最多 5 分钟）
    └─ 超时     → 提示用户手动刷新或联系客服
```

### 4.3 多面板字段统一策略

不同面板的 API 字段名称、单位、枚举值各不相同，统一策略分三层：

#### 三层隔离架构

```
xboard 原始 JSON        v2board 原始 JSON       sspanel 原始 JSON
{ transfer_enable }     { transfer }            { transfer_enable }
{ u + d }               { used_traffic }        { u + d }
{ balance } (分)        { balance } (分)        { money } (元)
{ expired_at } (Unix)   { expired_at } (Unix)   { expire_in } (ISO 8601)
        │                       │                       │
        ▼                       ▼                       ▼
  XboardAdapter         V2boardAdapter          SspanelAdapter
  （字段映射+异常翻译）  （字段映射+异常翻译）   （字段映射+异常翻译）
        └───────────────────────┼───────────────────────┘
                                ▼
                       统一领域模型 Domain Model
               PanelUser / ProxyNode / Order / Ticket ...
                                │
                                ▼
                    应用层 UseCase / UI（无感知面板差异）
```

**规则**：所有差异必须在 Adapter 内部消化，外部只暴露领域模型。

#### 关键字段跨面板对比与映射

| 语义 | xboard 字段 | v2board 字段 | sspanel 字段 | 领域模型字段（统一） |
|------|------------|-------------|-------------|-----------------|
| 认证凭证 | `auth_data` | `token` | `api_token` | `AuthContext.token` |
| 总流量 | `transfer_enable` (bytes) | `transfer` (bytes) | `transfer_enable` (bytes) | `PanelUser.trafficTotal` (bytes) |
| 已用流量 | `u + d` (bytes) | `u + d` (bytes) | `u + d` (bytes) | `PanelUser.trafficUsed` (bytes) |
| 到期时间 | `expired_at` (Unix 秒, null=永久) | `expired_at` (Unix 秒) | `expire_in` (ISO 8601 字符串) | `PanelUser.expireAt` (DateTime?) |
| 余额 | `balance` (分) | `balance` (分) | `money` (元，需 ×100) | `PanelUser.balance` (分) |
| 工单优先级 | `level` 1/2/3 整数 | `priority` 0/1/2 整数 | `level` "L"/"M"/"H" 字符串 | `Ticket.level` 枚举 |
| 订单状态 | `status` 0/1/2/3 整数 | `status` 0/1/2 整数 | `status` 字符串枚举 | `OrderStatus` 枚举 |
| 节点主机 | `server` | `host` | `server` | `ProxyNode.host` |
| 节点端口 | `server_port` | `port` | `port` | `ProxyNode.port` |

#### 映射代码示例（余额单位转换 & 时间格式统一）

```dart
// XboardAdapter：balance 已是分，expired_at 是 Unix 秒
PanelUser _mapUser(Map<String, dynamic> json) => PanelUser(
  trafficTotal: json['transfer_enable'] as int,
  trafficUsed: (json['u'] as int) + (json['d'] as int),
  expireAt: json['expired_at'] != null
      ? DateTime.fromMillisecondsSinceEpoch((json['expired_at'] as int) * 1000)
      : null,                                           // null = 永不过期
  balance: json['balance'] as int,                     // 已是分
);

// V2boardAdapter：字段名不同
PanelUser _mapUser(Map<String, dynamic> json) => PanelUser(
  trafficTotal: json['transfer'] as int,               // ← 字段名差异
  trafficUsed: (json['u'] as int) + (json['d'] as int),
  expireAt: json['expired_at'] != null
      ? DateTime.fromMillisecondsSinceEpoch((json['expired_at'] as int) * 1000)
      : null,
  balance: json['balance'] as int,
);

// SspanelAdapter：money 是元（double），expire_in 是 ISO 8601
PanelUser _mapUser(Map<String, dynamic> json) => PanelUser(
  trafficTotal: json['transfer_enable'] as int,
  trafficUsed: (json['u'] as int) + (json['d'] as int),
  expireAt: json['expire_in'] != null
      ? DateTime.parse(json['expire_in'] as String)    // ← 格式差异
      : null,
  balance: ((json['money'] as double) * 100).round(), // ← 单位差异：元→分
);
```

#### 枚举值映射（工单优先级示例）

```dart
// 三个面板的 level/priority 字段编码各不相同，统一映射到领域枚举
enum TicketLevel { normal, high, urgent }

// XboardAdapter: 1/2/3 整数
TicketLevel _mapLevel(int v) => switch (v) {
  1 => TicketLevel.normal, 2 => TicketLevel.high, _ => TicketLevel.urgent,
};

// V2boardAdapter: 0/1/2 整数（起始值不同）
TicketLevel _mapLevel(int v) => switch (v) {
  0 => TicketLevel.normal, 1 => TicketLevel.high, _ => TicketLevel.urgent,
};

// SspanelAdapter: "L"/"M"/"H" 字符串
TicketLevel _mapLevel(String v) => switch (v) {
  'L' => TicketLevel.normal, 'M' => TicketLevel.high, _ => TicketLevel.urgent,
};
```

#### 功能能力声明（处理面板功能不对等）

各面板支持的功能集合不同，通过 `PanelCapabilities` 声明，UI 按需显示：

```dart
// SspanelAdapter：无礼品卡、无知识库
@override
Future<PanelCapabilities> getCapabilities() async => PanelCapabilities(
  supportsTicketSystem: true,
  supportsGiftCard: false,        // sspanel 无礼品卡模块
  supportsKnowledgeBase: false,   // sspanel 无知识库
  supportsOrderManagement: false, // sspanel 订单模型差异大，V2 支持
  supportedProtocols: {'shadowsocks', 'v2ray', 'trojan'},
);

// UI 层按能力动态显示/隐藏入口
final caps = await adapter.getCapabilities();
if (caps.supportsGiftCard) _showGiftCardEntry();
if (caps.supportsTicketSystem) _showTicketEntry();
```

### 4.4 适配器注册机制

```dart
class PanelAdapterRegistry {
  static final _registry = <String, PanelAdapter>{};

  static void register(PanelAdapter adapter) {
    _registry[adapter.panelType] = adapter;
  }

  static PanelAdapter resolve(String panelType) {
    return _registry[panelType] ?? (throw UnsupportedPanelException(panelType));
  }
}

// 启动时注册（V1）
void setupAdapters() {
  PanelAdapterRegistry.register(XboardAdapter());
  // 后续：PanelAdapterRegistry.register(V2boardAdapter());
  // 后续：PanelAdapterRegistry.register(SspanelAdapter());
}
```

---

## 5. 可插拔内核引擎设计（V1 默认 sing-box）

### 5.1 接口定义

```dart
/// 内核统一控制接口（业务层只依赖此接口）
abstract class CoreEngine {
  Stream<EngineState> get stateStream;
  Stream<TrafficStats> get trafficStream;

  Future<void> initialize(EngineConfig config);
  Future<void> start();
  Future<void> stop();
  Future<void> reload(EngineConfig config);
  Future<EngineState> getState();
  Future<String> collectLogs();
}

/// 内核驱动抽象（具体内核实现此接口）
abstract class EngineDriver {
  String get engineType; // singbox / xray / ...

  Future<void> load(String configJson);
  Future<void> start();
  Future<void> stop();
  Stream<String> get logStream;
  EngineCapabilities get capabilities;
}

class EngineCapabilities {
  final Set<String> supportedProtocols;
  final Set<String> supportedPlatforms;
  final bool supportsHotReload;
  final String version;
}
```

### 5.2 SingboxDriver 实现要点

- 通过 Dart FFI 调用 libbox 动态库（参考 MagicLamp `singbox_service.dart` 分层实践）。
- 平台差异封装在 `SingboxDriver` 内部：Android AAR / iOS xcframework / Windows DLL / macOS dylib。
- libbox 生命周期：`libboxSetup()` → `libboxStart(config)` → `libboxStop()`。

### 5.3 配置生成流程

```
ProxyNode + RoutingPolicy
        │
        ▼
  NodeNormalizer
  （字段标准化 + 协议映射）
        │
        ▼
  EngineConfigBuilder
  （选择对应内核的 ConfigBuilder 实现）
        │
        ▼
  sing-box config JSON
  （outbounds / inbounds / route / dns）
        │
        ▼
  CoreEngine.initialize(config) → start()
```

### 5.4 状态机

```
                  ┌──────────────────────────┐
                  │                          │
  [idle] ──start──▶ [preparing] ──ready──▶ [connecting]
                                                │
                              ┌─────────────────┤
                              ▼                 ▼
                         [connected]         [error]
                              │                 │
                           stop()           retry / stop()
                              │
                              ▼
                        [disconnecting] ──▶ [idle]
```

### 5.5 内核注册与切换

```dart
class EngineRegistry {
  static final _drivers = <String, EngineDriver>{};

  static void register(EngineDriver driver) {
    _drivers[driver.engineType] = driver;
  }

  static EngineDriver resolve(String engineType) {
    return _drivers[engineType] ?? (throw UnsupportedEngineException(engineType));
  }
}

class EngineSelector {
  static EngineDriver select(String preferredType, {String fallback = 'singbox'}) {
    try {
      final driver = EngineRegistry.resolve(preferredType);
      return driver.capabilities.supportedPlatforms.contains(Platform.operatingSystem)
          ? driver
          : EngineRegistry.resolve(fallback);
    } catch (_) {
      return EngineRegistry.resolve(fallback);
    }
  }
}
```

---

## 6. 数据与配置设计

### 6.1 本地数据存储选型

| 数据域 | 存储方案 | 原因 |
|--------|---------|------|
| 站点配置、App 设置、皮肤设置 | `shared_preferences` | 轻量 KV，量少 |
| Token、密钥、凭证 | `flutter_secure_storage` | 平台安全存储 |
| 节点缓存（大量结构化数据） | `Hive`（NoSQL）或 `sqflite` | 支持复杂查询与批量读写 |
| 用户信息缓存 | `Hive` + TTL 策略 | 减少 API 请求频率 |
| 运行时日志 | 文件（按日滚动，保留 7 天） | 支持导出排障 |

**存储键规范**（`shared_preferences`）：

```
hyena.sites                 // List<String> JSON
hyena.current_site_id       // String
hyena.app_settings          // JSON
hyena.engine_settings       // JSON
hyena.skin.skin_id          // String
hyena.skin.contract_version // String
```

### 6.2 模板配置（CI/CD 品牌化参数）

`templates/client-profile.yaml` 示例：

```yaml
brand:
  appName: "HyenaVPN"
  bundleId: "com.example.hyenavpn"       # iOS
  packageName: "com.example.hyenavpn"    # Android

panel:
  # 构建期通过 --dart-define 注入，运行时为编译常量，用户不可修改
  # 对应 String.fromEnvironment('PANEL_TYPE') / 'PANEL_API_BASE' / 'SITE_NAME'
  panelType: "xboard"
  apiBase: "https://panel.example.com"
  siteName: "HyenaVPN"
  siteId: "brand_x_prod"

engine:
  defaultEngineType: "singbox"
  enabledEngines:
    - singbox

skin:
  skinId: "default"               # 指定皮肤包 ID
  contractVersion: "1.0.0"
  layoutPreset: "auto"            # auto / mobile / desktop

assets:
  iconPath: "./assets/brand_x/icon.png"
  splashPath: "./assets/brand_x/splash.png"

features:
  enableAutoUpdate: true
  enableDesktopTray: true
  enableDiagnosticsPage: true
```

### 6.3 构建期注入机制（独立打包策略）

**核心原则**：每个站点对应一个独立发行包，站点地址与面板类型是**编译常量**，不由用户输入。

#### 注入方式：`--dart-define`

CI/CD 流水线从模板读取参数后，通过 `--dart-define` 传入 Flutter 编译器：

```bash
flutter build apk \
  --dart-define=PANEL_API_BASE=https://panel.example.com \
  --dart-define=PANEL_TYPE=xboard \
  --dart-define=SITE_ID=brand_x_prod \
  --dart-define=SITE_NAME=HyenaVPN \
  --dart-define=SKIN_ID=brand_x
```

#### 运行时读取

```dart
// lib/core/app_config.dart — 全局单例，在 main() 最早初始化
class AppConfig {
  static const panelApiBase = String.fromEnvironment('PANEL_API_BASE');
  static const panelType    = String.fromEnvironment('PANEL_TYPE');
  static const siteId       = String.fromEnvironment('SITE_ID');
  static const siteName     = String.fromEnvironment('SITE_NAME');
  static const skinId       = String.fromEnvironment('SKIN_ID', defaultValue: 'default');
}
```

#### 启动流程影响

```
App 启动
  │
  ▼
AppConfig 从编译常量读取站点信息（无用户输入）
  │
  ▼
PanelSite.fromBuildConfig() 构造站点对象
  │
  ▼
PanelAdapterRegistry.resolve(AppConfig.panelType) 获取对应适配器
  │
  ▼
直接进入登录/注册页（无站点配置向导）
```

#### 与多站点架构的关系

| 维度 | 独立打包（当前策略） | 多站点运行时配置（未来可选） |
|------|-------------------|--------------------------|
| 站点地址来源 | 编译常量（CI/CD 注入） | 用户输入或扫码 |
| 用户首次体验 | 直接登录，无配置步骤 | 需要输入站点地址 |
| 适用场景 | ToC 商业发行包 | 开发者/高级用户自托管 |
| 代码影响 | `PanelSite.fromBuildConfig()` | 需补充站点配置 UI 与存储 |

> V1 仅实现独立打包策略，多站点配置作为 `[W]` 级需求暂不开发。

---

## 7. 国际化与本地化设计（i18n/l10n）

### 7.1 技术选型

| 项目 | 选型 | 说明 |
|------|------|------|
| 翻译文件格式 | ARB（Application Resource Bundle） | Flutter 官方标准，工具链完善 |
| 代码生成 | `flutter gen-l10n` | 由 ARB 生成强类型 `AppLocalizations` 类 |
| 运行时本地化 | `flutter_localizations` + `intl` | 覆盖内置 Widget 文案及日期/数字格式化 |
| 语言偏好存储 | `shared_preferences` | key: `hyena.locale`，值为 BCP 47 语言标签或 `system` |

### 7.2 支持语言（V1）

| 语言 | 标签 | ARB 文件 | 状态 |
|------|------|---------|------|
| 英语 | `en` | `app_en.arb` | V1 基准，作为 fallback |
| 简体中文 | `zh_CN` | `app_zh_CN.arb` | V1 内置 |
| 繁体中文 | `zh_TW` | `app_zh_TW.arb` | V2 候选 |

> **扩展规则**：新增语言只需新建对应 ARB 文件并在 `l10n.yaml` 的 `supported-locales` 中声明，无需修改任何业务代码。

### 7.3 目录结构与配置

```
lib/l10n/
  app_en.arb         # 基准翻译（Key + 英文值）
  app_zh_CN.arb      # 简体中文翻译
  app_zh_TW.arb      # 繁体中文（V2）

l10n.yaml            # flutter gen-l10n 配置
```

`l10n.yaml` 配置：

```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
output-class: S                     # 使用短类名方便调用：S.of(context).loginTitle
preferred-supported-locales:        # 优先语言排序
  - en
  - zh_CN
```

ARB 文件示例（`app_en.arb`）：

```json
{
  "@@locale": "en",
  "loginTitle": "SIGN IN",
  "@loginTitle": { "description": "Login page title" },
  "loginSubtitle": "Welcome back",
  "emailHint": "Email address",
  "passwordHint": "Password",
  "forgotPassword": "Forgot password?",
  "signInButton": "SIGN IN",
  "trafficUsed": "{used} / {total}",
  "@trafficUsed": {
    "placeholders": {
      "used": { "type": "String" },
      "total": { "type": "String" }
    }
  }
}
```

### 7.4 语言切换流程

```
用户在设置页选择语言
        │
        ▼
LocaleUseCase.setLocale(locale)
        │
        ├── SharedPreferences.setString('hyena.locale', 'zh_CN')
        │
        └── LocaleNotifier.notify(Locale('zh', 'CN'))
                │
                ▼
        MaterialApp.locale 更新 → 全局 Widget 重建 → 立即生效
```

```dart
// lib/core/app_config.dart — 构建期默认语言（可通过 CI/CD 模板指定）
static const defaultLocale = String.fromEnvironment(
  'DEFAULT_LOCALE',
  defaultValue: 'system',   // 'system' = 跟随系统，或指定 'en' / 'zh_CN'
);

// lib/features/settings/locale_notifier.dart
class LocaleNotifier extends ChangeNotifier {
  Locale? _locale;           // null = 跟随系统
  Locale? get locale => _locale;

  Future<void> load() async {
    final saved = prefs.getString('hyena.locale');
    _locale = saved != null && saved != 'system'
        ? _parseLocale(saved)
        : null;
  }

  Future<void> set(String tag) async {
    await prefs.setString('hyena.locale', tag);
    _locale = tag == 'system' ? null : _parseLocale(tag);
    notifyListeners();
  }
}
```

### 7.5 文案规范

| 规范 | 说明 |
|------|------|
| **禁止硬编码** | 所有用户可见字符串（含错误提示、空状态、Toast）必须通过 `S.of(context).xxx` 引用 |
| **Key 命名** | `<功能模块><语义>`，小驼峰，如 `storePageTitle`、`orderStatusPending` |
| **Fallback** | 翻译 Key 在当前语言 ARB 中缺失时，自动回退到 `en` |
| **日期格式** | 使用 `intl.DateFormat` 按 Locale 格式化，不硬编码格式字符串 |
| **金额格式** | 货币符号由面板返回数据决定，不依赖 Locale |
| **复数规则** | 使用 ARB `{count, plural, one{...} other{...}}` 语法处理复数 |

### 7.6 CI/CD 模板新增字段

```yaml
# templates/client-profile.yaml
locale:
  defaultLocale: "system"     # system / en / zh_CN，品牌可指定默认语言
  supportedLocales:           # 该品牌包支持的语言（可裁剪，减小包体积）
    - en
    - zh_CN
```

---

## 8. 错误处理策略

### 7.1 异常分类

| 类型 | 示例 | 处理策略 |
|------|------|---------|
| `AuthException` | Token 失效、账号错误 | 静默刷新 → 失败则跳转登录页 |
| `PanelUnavailableException` | 面板 API 超时/5xx | 使用本地缓存，降级展示 |
| `NodeParseException` | 订阅格式异常 | 跳过异常节点，正常节点继续，日志记录 |
| `EngineStartException` | 内核启动失败 | 进入 error 状态，展示错误原因，提示重试 |
| `SkinLoadException` | 皮肤包加载失败 | 降级到 default skin，不影响业务 |
| `NetworkException` | 无网络 | 提示网络不可用，不崩溃 |

### 7.2 全局错误边界

- 所有 UseCase 返回 `Result<T, AppError>` 或通过 `Stream` 推送错误状态。
- UI 层统一处理 AppError → 用户友好提示，不直接显示堆栈信息。
- 关键异常上报结构化日志（脱敏后）。

---

## 9. 升级与版本管理

### 8.1 内核版本管理

- libbox 版本号写入 `engine_settings`，升级前记录旧版本。
- 升级流程：下载新 libbox → 本地验证签名 → 停止旧内核 → 替换 → 启动 → 失败则回滚。
- V1 内核与应用一起打包发布，不支持独立热更新（V2 路线）。

### 8.2 皮肤版本管理

- `skin_manifest.json` 包含 `skinVersion`（皮肤内容版本）和 `contractVersion`（合约版本）。
- 加载时校验 `contractVersion` 是否满足当前 SDK 支持范围（SemVer 兼容检查）。
- 皮肤更新独立于业务版本，可单独打包替换 `skins/brand_x/` 目录内容。

### 8.3 面板适配器版本管理

- 每个适配器有独立的 `adapterVersion`，记录于注册元数据。
- 面板接口变更时，适配器内部处理兼容逻辑，不暴露到 UseCase 层。

---

## 10. CI/CD 方案（GitHub Actions）

### 9.1 流水线架构

```
PR 提交
  └─▶ ci.yml
        ├── flutter analyze
        ├── dart format --check
        └── flutter test (unit tests)

Tag 推送 / 手动 dispatch
  └─▶ build-template.yml
        ├── 读取 templates/client-profile.yaml
        ├── 注入品牌参数（appName / packageName / skinId）
        ├── 注入皮肤资源
        ├── 构建矩阵（parallel jobs）:
        │     ├── Android (ubuntu-latest) → APK / AAB
        │     ├── Windows (windows-latest) → EXE / MSIX
        │     └── macOS (macos-latest, optional) → DMG
        └── 上传制品（按品牌 + 版本命名）

  └─▶ release.yml（Tag 触发）
        ├── 依赖 build-template 产物
        ├── 生成 Release Notes（基于 Commit 信息）
        └── 发布到 GitHub Releases
```

### 9.2 构建缓存策略

```yaml
# 示意：关键缓存配置
- uses: actions/cache@v4
  with:
    path: |
      ~/.pub-cache
      .dart_tool/
      build/
    key: ${{ runner.os }}-flutter-${{ hashFiles('pubspec.lock') }}
    restore-keys: |
      ${{ runner.os }}-flutter-
```

### 9.3 品牌参数注入流程

```
workflow_dispatch inputs
  │  brand_id / version / target_platform / build_mode
  │
  ▼
parse-config job
  │  读取 templates/${brand_id}.yaml
  │  合并默认配置
  │
  ▼
inject-params job
  │  写入 pubspec.yaml（version）
  │  写入 android/app/build.gradle（applicationId / versionCode）
  │  写入 ios/Runner/Info.plist（bundleId）
  │  替换 assets/（图标 / 启动图）
  │  写入 lib/config/app_config.dart（skinId / panelType 等运行时参数）
  │
  ▼
build job（matrix）
```

### 9.4 密钥与签名

| 平台 | 签名材料 | 存储位置 |
|------|---------|---------|
| Android | keystore 文件 + 密码 | GitHub Secrets（base64 编码） |
| Windows | 代码签名证书 | GitHub Secrets 或自托管 Runner |
| macOS / iOS | Apple Developer 证书 + PP | 自托管 macOS Runner（推荐） |

- 公开检查流水线（ci.yml）无签名，只验证代码质量。
- 私有构建流水线（build-template.yml）含签名，Repository 权限控制。

---

## 11. 安全设计

| 安全域 | 措施 |
|--------|------|
| 凭证存储 | `flutter_secure_storage`（Android Keystore / iOS Keychain / Windows DPAPI） |
| 网络传输 | TLS 严格校验；支持受控证书固定（`SecurityContext`） |
| 日志脱敏 | Token / 用户名 / 明文 IP 不写入日志；导出前二次过滤 |
| 代码保护 | Android R8 混淆；iOS Strip Symbols；禁止 debug 版本发布 |
| 皮肤安全 | 皮肤包加载前校验合约版本；禁止皮肤包注册系统级权限组件 |
| 内核配置 | 配置文件写入应用私有目录；不暴露到公共存储 |

---

## 12. 测试策略

### 11.1 测试分层与覆盖率目标

| 层级 | 类型 | 覆盖率目标 | 框架 |
|------|------|-----------|------|
| 领域层 / 应用层 | 单元测试 | ≥ 70% | `flutter_test` + `mockito` |
| 适配器层 | 单元测试 + 接口契约测试 | ≥ 80% | `flutter_test` + `mockito` |
| 皮肤层 | 单元测试 + Golden Test | ≥ 60% | `flutter_test` |
| 主流程 | 集成测试 | 核心场景 100% | `integration_test` |

### 11.2 关键测试用例

**面板适配器**
- `XboardAdapter.login` 字段映射正确性（正常 / 401 / 超时）
- `XboardAdapter.createOrder` + `checkout` 支付流程覆盖（正常 / 免费 / 超时）
- `XboardAdapter.fetchTickets` / `createTicket` / `replyTicket` 工单全流程
- `NodeNormalizer` 各协议字段映射（VLESS / VMess / SS / Trojan / Hysteria2）
- `PanelAdapterRegistry` 注册与发现，未注册类型抛出 `UnsupportedPanelException`

**内核引擎**
- `EngineConfigBuilder` 在不同节点协议和路由策略下输出配置正确性
- `EngineSelector` 首选驱动不可用时降级到 fallback
- 状态机正确流转（idle → connecting → connected → idle）

**商业功能**
- `OrderUseCase` 轮询逻辑：成功/超时/取消分支覆盖
- `CouponService` 验证优惠码：有效/过期/不适用套餐
- `InviteUseCase.transferCommissionToBalance` 余额转账正确性

**皮肤系统**
- `SkinManager` 加载合法皮肤；合约版本不匹配时降级到 default
- `ThemeTokenProvider` 令牌注入后 Widget 颜色正确（Golden Test）
- 切换 `skinId` 前后 ViewModel 数据一致（业务无回归）

**集成测试**
- 注册 → 登录 → 购买套餐 → 订阅拉取 → 连接 → 断开 全链路
- Token 过期 → 自动刷新 → 无感继续使用
- 工单创建 → 客服回复 → 用户继续回复 → 关闭
- 皮肤切换 → 商业页面与连接页面均无功能回归

---

## 13. 项目目录结构

```text
lib/
  core/                          # 领域层
    models/                      # 统一实体（ProxyNode, PanelSite, TrafficStats...）
    interfaces/                  # 抽象接口（CoreEngine, PanelAdapter, SkinContract...）
    errors/                      # 统一异常定义
    result.dart                  # Result<T, E> 类型

  features/                      # 应用层（按功能特性划分）
    auth/                        # 注册、登录、忘记密码
    site/                        # 站点信息（构建期注入，无配置 UI）
    node/                        # 节点列表、测速、收藏
    connection/                  # 连接管理、状态机
    profile/                     # 用户中心、订阅详情、安全设置
    store/                       # 商店（套餐列表）
    order/                       # 订单管理与支付
    ticket/                      # 工单系统
    invite/                      # 邀请推广与佣金
    giftcard/                    # 礼品卡兑换
    notice/                      # 公告
    knowledge/                   # 知识库/帮助中心
    stat/                        # 流量统计
    settings/                    # 应用设置
    diagnostics/                 # 诊断与日志

  adapters/
    panel/
      registry.dart              # PanelAdapterRegistry
      xboard/                    # XboardAdapter 实现
      v2board/                   # (预留，V2)
    engine/
      registry.dart              # EngineRegistry + EngineSelector
      singbox/                   # SingboxDriver 实现（FFI 封装）
      config_builders/           # EngineConfigBuilder 各内核实现

  skins/
    skin_manager.dart            # SkinManager
    skin_component_registry.dart # SkinComponentRegistry
    theme_token_provider.dart    # ThemeTokenProvider
    layout_preset_resolver.dart  # LayoutPresetResolver
    default/                     # 默认皮肤包（完整实现）
      theme_tokens.dart
      components/
      assets/
      skin_manifest.json
    brand_x/                     # 示例品牌皮肤（V2）

  l10n/                          # 多语言翻译文件（ARB）
    app_en.arb                   # 英语（基准）
    app_zh_CN.arb                # 简体中文

  infrastructure/
    network/                     # Dio 封装、拦截器
    storage/
      secure_storage.dart        # flutter_secure_storage 封装
      cache_storage.dart         # Hive / sqflite 封装
      preferences.dart           # shared_preferences 封装
    logging/                     # 结构化日志、脱敏、文件滚动

  config/
    app_config.dart              # 运行时参数（由 CI/CD 注入或本地读取）

  app.dart
  main.dart

native/
  libs/
    android/                     # libbox AAR
    ios/                         # libbox xcframework
    windows/                     # libbox DLL
    macos/                       # libbox dylib

l10n.yaml                        # flutter gen-l10n 配置

templates/
  client-profile.yaml            # 默认品牌模板
  brand_x.yaml                   # 示例品牌模板

.github/
  workflows/
    ci.yml
    build-template.yml
    release.yml
```

---

## 14. 分阶段实施计划

| 阶段 | 主要工作 | 并行关系 | 产出 |
|------|---------|---------|------|
| **阶段 1** 架构骨架 | 项目脚手架；领域层接口；XboardAdapter（认证+订阅）；SingboxDriver stub；SkinManager 框架；注册→登录→订阅→连接 Demo | 串行（其他阶段前置） | 三层扩展框架验证 |
| **阶段 2** 商业闭环 | XboardAdapter 全接口（套餐/订单/工单/邀请/礼品卡/公告/知识库）；商店/订单/工单/用户中心/邀请推广全部页面 | 依赖阶段 1 | **可商业运营** |
| **阶段 3** 节点与连接 | 测速；收藏；状态机完整实现；自动重连；路由切换；日志导出；流量统计图表 | 可与阶段 2 并行 | 核心连接能力完整 |
| **阶段 4** 皮肤系统 + 多语言 | ThemeTokenProvider；SkinComponentRegistry；default skin 全页面（含商业页面）；皮肤合约文档；i18n 框架接入（zh_CN + en ARB 全页面覆盖）；设置页语言切换 | 可与阶段 3 并行 | default skin 可用；双语支持 |
| **阶段 5** CI/CD | ci.yml；build-template.yml；release.yml；Android + Windows 制品验证；缓存策略 | 依赖阶段 1 | 自动化构建可用 |
| **阶段 6** 第二面板 | v2board Adapter；验证适配器扩展成本 | 依赖阶段 3 | 多面板扩展验证 |
| **阶段 7** 品牌皮肤 | brand_x 示例皮肤；皮肤预览工具 | 依赖阶段 4 | 皮肤定制交付验证 |

---

## 15. 关键架构决策记录（ADR）

| ADR | 决策 | 背景与后果 |
|-----|------|-----------|
| ADR-001 | 采用 Flutter 统一多端客户端 | 一套代码覆盖 Android/iOS/Windows/macOS；代价是原生能力受限，FFI 处理平台差异 |
| ADR-002 | 采用适配器模式支持多面板 | 面板接口差异大，适配器隔离变化；新增面板不影响业务层；代价是适配器维护需跟随面板升级 |
| ADR-003 | 可插拔内核架构，V1 默认 sing-box | 避免与单一内核强绑定；代价是抽象层增加一定复杂度，需保持接口稳定 |
| ADR-004 | GitHub Actions + YAML 模板化构建 | 可重复、可审计的自动化交付；代价是 iOS 自托管 Runner 维护成本较高 |
| ADR-005 | UI 皮肤化架构，与业务逻辑解耦 | 品牌定制不触碰业务代码；代价是皮肤合约需严格管理，过度开放会增加维护负担 |
| ADR-006 | Provider 作为 V1 状态管理方案 | 团队熟悉度高，MagicLamp 已有实践；代价是复杂异步状态管理可读性不如 Riverpod |
| ADR-007 | ARB + flutter gen-l10n 作为 i18n 方案 | Flutter 官方推荐，强类型生成代码防拼写错误；新增语言只需加 ARB 文件；代价是每次修改文案需重新生成，CI 需加 gen-l10n 步骤 |
