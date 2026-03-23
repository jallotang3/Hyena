# 面板适配器开发指南

> **文档版本**: v1.0 | **更新时间**: 2026-03-23

本文档指导开发者如何为 Hyena 添加新的面板适配器，以支持更多后端面板系统。

---

## 1. 概述

### 1.1 什么是面板适配器

面板适配器（Panel Adapter）是 Hyena 与后端面板系统之间的桥梁，负责：

- 将面板特定的 API 调用转换为统一的领域模型
- 处理不同面板的认证机制差异
- 映射各面板的字段命名和数据格式
- 声明面板支持的功能能力

### 1.2 架构位置

```
┌─────────────────────────────────────────┐
│  Application Layer (UseCase)            │
│  ↓ 依赖抽象接口 PanelAdapter              │
├─────────────────────────────────────────┤
│  Domain Layer                           │
│  - PanelAdapter (interface)             │
│  - PanelUser / ProxyNode (models)       │
├─────────────────────────────────────────┤
│  Infrastructure Layer                   │
│  - XboardAdapter (implements)           │
│  - V2boardAdapter (implements)          │
│  - YourAdapter (implements) ← 新增      │
└─────────────────────────────────────────┘
```

**关键原则**：
- 业务层只依赖 `PanelAdapter` 接口，不依赖具体实现
- 新增适配器**零侵入**业务代码
- 通过 `PanelAdapterRegistry` 注册与发现

---

## 2. 快速开始

### 2.1 创建适配器骨架

```bash
# 1. 创建适配器目录
mkdir -p lib/adapters/panel/your_panel

# 2. 创建适配器文件
touch lib/adapters/panel/your_panel/your_panel_adapter.dart
```

### 2.2 实现 PanelAdapter 接口

```dart
import 'package:dio/dio.dart';
import '../../../core/interfaces/panel_adapter.dart';
import '../../../core/models/panel_site.dart';
import '../../../core/models/panel_user.dart';
import '../../../core/models/proxy_node.dart';
// ... 其他必需的 imports

class YourPanelAdapter implements PanelAdapter {
  YourPanelAdapter();

  @override
  String get panelType => 'your_panel'; // 唯一标识符

  // Dio 实例缓存（推荐）
  final Map<String, Dio> _dioCache = {};

  Dio _dio(PanelSite site, [String? authData]) {
    final key = '${site.baseUrl}|${authData ?? ''}';
    return _dioCache.putIfAbsent(key, () {
      return Dio(BaseOptions(
        baseUrl: '${site.baseUrl}/api/v1', // 根据实际面板调整
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (authData != null) 'Authorization': authData,
        },
      ));
    });
  }

  // 实现所有必需的接口方法...
  @override
  Future<AuthResult> login(PanelSite site, Credentials credentials) async {
    // TODO: 实现登录逻辑
    throw UnimplementedError();
  }

  // ... 其他方法
}
```

### 2.3 注册适配器

在 `lib/main.dart` 中注册：

```dart
void main() async {
  // ...

  final adapterRegistry = PanelAdapterRegistry.instance;
  adapterRegistry.register(XboardAdapter());
  adapterRegistry.register(V2boardAdapter());
  adapterRegistry.register(YourPanelAdapter()); // 新增

  // ...
}
```

---

## 3. 接口实现详解

### 3.1 必需实现的方法

`PanelAdapter` 接口包含以下模块（共 40+ 方法）：

| 模块 | 方法数 | 优先级 | 说明 |
|------|--------|--------|------|
| 认证 | 5 | 必须 | 登录、注册、重置密码等 |
| 用户信息 | 6 | 必须 | 用户资料、订阅信息、节点列表 |
| 套餐 | 2 | 必须 | 套餐列表、套餐详情 |
| 订单与支付 | 7 | 必须 | 创建订单、支付、查询状态 |
| 工单 | 5 | 推荐 | 工单列表、创建、回复、关闭 |
| 邀请 | 4 | 推荐 | 邀请码、佣金统计、佣金转账 |
| 优惠码 | 1 | 推荐 | 优惠码验证 |
| 礼品卡 | 3 | 可选 | 礼品卡查询、兑换、历史 |
| 公告 | 1 | 可选 | 公告列表 |
| 知识库 | 2 | 可选 | 文章列表、文章详情 |
| 流量统计 | 1 | 可选 | 每日流量记录 |

### 3.2 认证模块示例

```dart
@override
Future<AuthResult> login(PanelSite site, Credentials credentials) async {
  try {
    final resp = await _dio(site).post('/passport/auth/login', data: {
      'email': credentials.email,
      'password': credentials.password,
    });

    // 解析响应
    final data = resp.data['data'] as Map<String, dynamic>;
    final authData = data['token']?.toString() ?? '';

    // 返回统一的 AuthResult
    return AuthResult(
      authData: authData.startsWith('Bearer ') ? authData : 'Bearer $authData',
      user: _mapUser(data, credentials.email),
    );
  } on DioException catch (e) {
    throw _mapDioError(e);
  }
}

@override
Future<bool> sendEmailVerifyCode(PanelSite site, String email) async {
  try {
    await _dio(site).post('/passport/comm/sendEmailVerify', data: {'email': email});
    return true;
  } on DioException catch (e) {
    throw _mapDioError(e);
  }
}

@override
Future<AuthResult> register(PanelSite site, RegisterCredentials cred) async {
  // 类似 login 实现
}

@override
Future<bool> resetPassword(PanelSite site, String email, String code, String newPwd) async {
  // 实现密码重置
}

@override
Future<void> logout(PanelSite site, AuthContext auth) async {
  // 大多数面板无专用登出接口，清除本地 Token 即可
}
```

### 3.3 用户信息模块示例

```dart
@override
Future<PanelUser> fetchUserInfo(PanelSite site, AuthContext auth) async {
  try {
    final resp = await _dio(site, auth.authData).get('/user/info');
    final data = resp.data['data'] as Map<String, dynamic>;

    return PanelUser(
      email: data['email']?.toString() ?? auth.email,
      balance: (data['balance'] as num?)?.toInt() ?? 0,
      commissionBalance: (data['commission_balance'] as num?)?.toInt() ?? 0,
      planId: (data['plan_id'] as num?)?.toInt(),
      expiredAt: _parseTimestamp(data['expired_at']),
      trafficTotal: (data['transfer_enable'] as num?)?.toInt() ?? 0,
      trafficUsed: ((data['u'] as num?)?.toInt() ?? 0) +
                   ((data['d'] as num?)?.toInt() ?? 0),
      uuid: data['uuid']?.toString() ?? '',
    );
  } on DioException catch (e) {
    throw _mapDioError(e);
  }
}

@override
Future<List<ProxyNode>> fetchNodes(PanelSite site, AuthContext auth) async {
  try {
    final resp = await _dio(site, auth.authData).get('/user/server/fetch');
    final list = resp.data['data'] as List;

    final nodes = <ProxyNode>[];
    for (final item in list) {
      final node = _parseNode(item as Map<String, dynamic>);
      if (node != null) nodes.add(node);
    }
    return nodes;
  } on DioException catch (e) {
    throw _mapDioError(e);
  }
}
```

### 3.4 节点解析

**关键点**：不同面板的节点字段命名可能不同，需要统一映射到 `ProxyNode` 模型。

```dart
ProxyNode? _parseNode(Map<String, dynamic> data) {
  try {
    final type = (data['type']?.toString() ?? 'shadowsocks').toLowerCase();
    final host = data['host']?.toString() ?? data['server']?.toString() ?? '';
    final port = (data['port'] as num?)?.toInt() ?? 443;

    if (host.isEmpty) return null;

    final extra = <String, dynamic>{};

    switch (type) {
      case 'shadowsocks':
        extra['method'] = data['cipher']?.toString() ?? 'aes-256-gcm';
        extra['password'] = data['password']?.toString() ?? '';
      case 'vmess':
        extra['uuid'] = data['uuid']?.toString() ?? '';
        extra['alter_id'] = (data['alter_id'] as num?)?.toInt() ?? 0;
        extra['security'] = data['security']?.toString() ?? 'auto';
      case 'vless':
        extra['uuid'] = data['uuid']?.toString() ?? '';
        extra['flow'] = data['flow']?.toString() ?? '';
      case 'trojan':
        extra['password'] = data['password']?.toString() ?? '';
        extra['sni'] = data['sni']?.toString() ?? host;
      case 'hysteria2':
        extra['password'] = data['password']?.toString() ?? '';
    }

    return ProxyNode(
      id: data['id']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
      group: data['group']?.toString() ?? 'Default',
      protocol: type,
      address: host,
      port: port,
      extra: extra,
    );
  } catch (e) {
    AppLogger.w('节点解析失败: $e', tag: LogTag.adapter);
    return null;
  }
}
```

### 3.5 错误处理

统一错误映射到 Hyena 的异常体系：

```dart
AppError _mapDioError(DioException e) {
  final statusCode = e.response?.statusCode;
  final message = e.response?.data?['message']?.toString();

  // 401 → AuthException
  if (statusCode == 401) {
    return AuthException(message ?? '认证失败，请重新登录');
  }

  // 超时 → NetworkException
  if (e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.receiveTimeout) {
    return const NetworkException('请求超时');
  }

  // 连接失败 → NetworkException
  if (e.type == DioExceptionType.connectionError) {
    return const NetworkException('网络连接失败');
  }

  // 5xx → PanelUnavailableException
  if (statusCode != null && statusCode >= 500) {
    return PanelUnavailableException(
      message ?? '服务器错误',
      statusCode: statusCode,
    );
  }

  // 其他 → 通用 AppError
  return AppError(message ?? '请求失败: ${e.message}');
}
```

### 3.6 能力声明

通过 `PanelCapabilities` 声明面板支持的功能：

```dart
@override
Future<PanelCapabilities> getCapabilities() async {
  return const PanelCapabilities(
    supportsRefreshToken: false,        // 是否支持 Token 刷新
    supportsAnnouncement: true,         // 是否支持公告
    supportsOrderManagement: true,      // 是否支持订单管理
    supportsTicketSystem: true,         // 是否支持工单系统
    supportsInviteSystem: true,         // 是否支持邀请返佣
    supportsGiftCard: false,            // 是否支持礼品卡
    supportsKnowledgeBase: false,       // 是否支持知识库
    supportedProtocols: {               // 支持的协议
      'vless',
      'vmess',
      'shadowsocks',
      'trojan',
      'hysteria2',
    },
  );
}
```

**UI 层会根据能力声明自动显示/隐藏功能入口**。

---

## 4. 字段映射对照表

### 4.1 用户信息字段

| Hyena 模型字段 | xboard | v2board | 说明 |
|---------------|--------|---------|------|
| `email` | `email` | `email` | 用户邮箱 |
| `balance` | `balance` | `balance` | 账户余额（分） |
| `commissionBalance` | `commission_balance` | `commission_balance` | 佣金余额（分） |
| `planId` | `plan_id` | `plan_id` | 当前套餐 ID |
| `expiredAt` | `expired_at` | `expired_at` | 到期时间（Unix 时间戳） |
| `trafficTotal` | `transfer_enable` | `transfer_enable` | 流量总量（字节） |
| `trafficUsed` | `u + d` | `u + d` | 已用流量（字节） |
| `uuid` | `uuid` | `token` | 订阅 Token |

### 4.2 节点字段

| Hyena 模型字段 | xboard | v2board | 说明 |
|---------------|--------|---------|------|
| `id` | `id` | `id` | 节点 ID |
| `name` | `name` | `name` | 节点名称 |
| `group` | `group_name` | `group` | 分组名称 |
| `protocol` | `type` | `type` | 协议类型 |
| `address` | `host` | `host` | 服务器地址 |
| `port` | `port` | `port` | 端口 |
| `extra` | — | — | 协议特定参数 |

### 4.3 订单字段

| Hyena 模型字段 | xboard | v2board | 说明 |
|---------------|--------|---------|------|
| `tradeNo` | `trade_no` | `trade_no` | 订单号 |
| `status` | `status` | `status` | 订单状态（0=待支付, 1=已完成） |
| `totalAmount` | `total_amount` | `total_amount` | 订单总金额（分） |
| `period` | `period` | `period` | 计费周期 |
| `couponCode` | `coupon_code` | `coupon_code` | 优惠码 |

---

## 5. 测试

### 5.1 单元测试

为适配器编写单元测试（参考 `test/adapters/panel/xboard/node_normalizer_test.dart`）：

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hyena/adapters/panel/your_panel/your_panel_adapter.dart';

void main() {
  group('YourPanelAdapter', () {
    late YourPanelAdapter adapter;

    setUp(() {
      adapter = YourPanelAdapter();
    });

    test('panelType 返回正确的标识符', () {
      expect(adapter.panelType, equals('your_panel'));
    });

    // 更多测试...
  });
}
```

### 5.2 集成测试

1. 准备测试环境（测试面板实例）
2. 配置 `dart-define` 参数：
   ```bash
   flutter run \
     --dart-define=PANEL_API_BASE=https://test.yourpanel.com \
     --dart-define=PANEL_TYPE=your_panel \
     --dart-define=SITE_ID=test \
     --dart-define=SITE_NAME=TestSite
   ```
3. 验证核心流程：
   - 注册 → 登录 → 拉取节点 → 连接
   - 购买套餐 → 支付 → 订单查询
   - 创建工单 → 回复 → 关闭

---

## 6. 常见问题

### Q1: 面板 API 文档不完整怎么办？

**A**: 参考面板源码或抓包分析：
1. 查看面板前端源码（通常是 Vue/React）
2. 使用浏览器开发者工具抓包
3. 参考同类面板的已有适配器（如 xboard → v2board）

### Q2: 面板不支持某些功能怎么办？

**A**: 通过 `PanelCapabilities` 声明不支持，并在方法中抛出 `UnsupportedError`：

```dart
@override
Future<GiftCardPreview> checkGiftCard(
    PanelSite site, AuthContext auth, String code) async {
  throw UnsupportedError('your_panel 不支持礼品卡功能');
}
```

### Q3: 字段命名差异很大怎么办？

**A**: 在适配器内部做映射，保持对外接口一致：

```dart
PanelUser _mapUser(Map<String, dynamic> data, String fallbackEmail) {
  // 面板用 'quota' 表示流量总量
  final trafficTotal = (data['quota'] as num?)?.toInt() ?? 0;

  // 面板用 'used_quota' 表示已用流量
  final trafficUsed = (data['used_quota'] as num?)?.toInt() ?? 0;

  return PanelUser(
    email: data['email']?.toString() ?? fallbackEmail,
    trafficTotal: trafficTotal,
    trafficUsed: trafficUsed,
    // ...
  );
}
```

### Q4: 如何处理面板特有的功能？

**A**: 如果功能不在 `PanelAdapter` 接口中，有两种方案：
1. **推荐**：提交 PR 扩展接口（如果功能通用）
2. **临时**：在适配器中添加扩展方法（但业务层无法直接调用）

---

## 7. 提交 PR

完成适配器开发后，欢迎提交 PR：

1. **代码规范**：
   - 通过 `flutter analyze` 和 `dart format` 检查
   - 单元测试覆盖率 ≥ 60%
   - 无硬编码 URL 或密钥

2. **文档**：
   - 更新 `README.md` 支持的面板列表
   - 在 PR 描述中说明面板特性和差异

3. **测试**：
   - 提供测试面板地址（可选）
   - 附上核心流程的测试截图

---

## 8. 参考资料

- [Xboard 源码](https://github.com/cedar2025/Xboard)
- [V2board 源码](https://github.com/v2board/v2board)
- [Hyena 系统设计文档](../system-design.md)
- [Hyena 需求分析文档](../requirements-analysis.md)

---

## 附录：完整接口清单

```dart
abstract class PanelAdapter {
  String get panelType;

  // 认证 (5)
  Future<bool> sendEmailVerifyCode(PanelSite site, String email);
  Future<AuthResult> register(PanelSite site, RegisterCredentials cred);
  Future<AuthResult> login(PanelSite site, Credentials credentials);
  Future<void> logout(PanelSite site, AuthContext auth);
  Future<bool> resetPassword(PanelSite site, String email, String code, String newPwd);

  // 用户信息 (6)
  Future<PanelUser> fetchUserInfo(PanelSite site, AuthContext auth);
  Future<SubscribeInfo> fetchSubscribeInfo(PanelSite site, AuthContext auth);
  Future<List<ProxyNode>> fetchNodes(PanelSite site, AuthContext auth);
  Future<UserStat> fetchUserStat(PanelSite site, AuthContext auth);
  Future<bool> changePassword(PanelSite site, AuthContext auth, String oldPwd, String newPwd);
  Future<String> resetSecurity(PanelSite site, AuthContext auth);
  Future<void> updateUserSettings(PanelSite site, AuthContext auth, UserSettings settings);

  // 套餐 (2)
  Future<List<PlanItem>> fetchPlans(PanelSite site, AuthContext auth);
  Future<PlanItem> fetchPlanDetail(PanelSite site, AuthContext auth, int planId);

  // 订单与支付 (7)
  Future<String> createOrder(PanelSite site, AuthContext auth, OrderRequest req);
  Future<List<PaymentMethod>> fetchPaymentMethods(PanelSite site, AuthContext auth);
  Future<PaymentResult> checkout(PanelSite site, AuthContext auth, String tradeNo, int methodId);
  Future<int> checkOrderStatus(PanelSite site, AuthContext auth, String tradeNo);
  Future<bool> cancelOrder(PanelSite site, AuthContext auth, String tradeNo);
  Future<List<Order>> fetchOrders(PanelSite site, AuthContext auth, {int? status});
  Future<Order> fetchOrderDetail(PanelSite site, AuthContext auth, String tradeNo);

  // 优惠码 / 礼品卡 (4)
  Future<CouponInfo> checkCoupon(PanelSite site, AuthContext auth, CouponCheckRequest req);
  Future<GiftCardPreview> checkGiftCard(PanelSite site, AuthContext auth, String code);
  Future<GiftCardRedeemResult> redeemGiftCard(PanelSite site, AuthContext auth, String code);
  Future<List<GiftCardUsage>> fetchGiftCardHistory(PanelSite site, AuthContext auth);

  // 工单 (5)
  Future<List<Ticket>> fetchTickets(PanelSite site, AuthContext auth);
  Future<Ticket> fetchTicketDetail(PanelSite site, AuthContext auth, int ticketId);
  Future<bool> createTicket(PanelSite site, AuthContext auth, TicketRequest req);
  Future<bool> replyTicket(PanelSite site, AuthContext auth, int ticketId, String message);
  Future<bool> closeTicket(PanelSite site, AuthContext auth, int ticketId);

  // 邀请 (4)
  Future<InviteSummary> fetchInviteSummary(PanelSite site, AuthContext auth);
  Future<bool> generateInviteCode(PanelSite site, AuthContext auth);
  Future<List<CommissionRecord>> fetchCommissionDetails(PanelSite site, AuthContext auth, int page);
  Future<bool> transferCommissionToBalance(PanelSite site, AuthContext auth, int amount);

  // 公告 / 知识库 / 流量统计 (4)
  Future<List<Notice>> fetchNotices(PanelSite site, AuthContext auth, {int page = 1});
  Future<List<KnowledgeArticle>> fetchKnowledge(PanelSite site, AuthContext auth, {String? language, String? keyword});
  Future<KnowledgeArticle> fetchKnowledgeDetail(PanelSite site, AuthContext auth, int id);
  Future<List<TrafficRecord>> fetchTrafficLog(PanelSite site, AuthContext auth);

  // 能力声明 (1)
  Future<PanelCapabilities> getCapabilities();
}
```
