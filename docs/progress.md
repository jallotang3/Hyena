# Hyena — 开发进度记录

> 最后更新：2026-03-20

## 当前状态：P4 Controller/View 分离 + 皮肤系统 已完成

---

## Phase 1 · 架构骨架（已完成）

### P1-1 ✅ Flutter 项目初始化

- `pubspec.yaml` 全量依赖配置（dio / provider / go_router / flutter_secure_storage / hive_flutter / ffi / intl / flutter_localizations / share_plus ...）
- `l10n.yaml` + ARB 多语言文件（en / zh_CN / zh fallback）
- 全部目录结构创建完毕

**关键目录结构：**
```
lib/
├── config/             # 编译期常量（dart-define）
├── core/
│   ├── errors/         # 统一异常体系 (AppError)
│   ├── models/         # 领域模型 (PanelUser / ProxyNode / commercial/...)
│   ├── interfaces/     # 抽象接口 (PanelAdapter / CoreEngine)
│   └── result.dart     # Result<T> 函数式错误处理
├── infrastructure/
│   ├── network/        # DioClient（拦截器：Auth / Logging / Error）
│   ├── storage/        # AppPreferences + SecureStorage + CacheStorage
│   └── logging/        # AppLogger + LogFileManager（脱敏 + 滚动文件 + recentLogs）
├── adapters/
│   ├── panel/          # PanelAdapterRegistry + XboardAdapter + NodeNormalizer
│   └── engine/         # EngineRegistry + SingboxDriver + LibboxFfi + ConfigBuilder
├── features/
│   ├── auth/           # AuthUseCase + AuthNotifier
│   ├── connection/     # ConnectionUseCase + ConnectionNotifier
│   ├── node/           # NodeUseCase + NodeNotifier + NodeLatencyService + NodeListScreen
│   ├── store/          # StoreUseCase + StoreScreen + PaymentResultScreen
│   ├── order/          # OrderUseCase + OrderCenterScreen + OrderDetailScreen
│   ├── ticket/         # TicketUseCase + TicketListScreen + TicketDetailScreen
│   ├── profile/        # ProfileUseCase + ProfileScreen
│   ├── invite/         # InviteUseCase + InviteScreen
│   ├── giftcard/       # GiftCardUseCase
│   ├── notice/         # NoticeUseCase
│   ├── knowledge/      # KnowledgeUseCase
│   ├── stat/           # StatUseCase + TrafficChartScreen
│   ├── diagnostics/    # DiagnosticsScreen（实时日志 + 导出）
│   └── settings/       # LocaleNotifier + SettingsScreen（自动连接开关 + 工具入口）
├── skins/              # SkinManager + ThemeTokenProvider + default 皮肤令牌
├── l10n/               # ARB 文件（en / zh_CN / zh）
├── routes/             # AppRouter (go_router)
├── app.dart            # HyenaApp（MaterialApp.router + ThemeToken）
└── main.dart           # 启动：初始化 + Provider 注入
```

### P1-2 ✅ 基础设施层

| 文件 | 功能 |
|------|------|
| `lib/config/app_config.dart` | 编译期常量（dart-define）：PANEL_API_BASE / PANEL_TYPE / SITE_ID / SKIN_ID |
| `lib/infrastructure/network/dio_client.dart` | Dio 封装，Token 自动注入，错误码→AppError 映射 |
| `lib/infrastructure/storage/preferences.dart` | SharedPreferences 封装（locale / node / routing / favorites / skin / autoConnect） |
| `lib/infrastructure/storage/secure_storage.dart` | flutter_secure_storage（auth_data / email / readAuthContext） |
| `lib/infrastructure/logging/app_logger.dart` | 结构化日志，含脱敏（Token/邮箱/私有IP）+ recentLogs 环形缓冲 + 文件写入 |
| `lib/infrastructure/logging/log_file_manager.dart` | 日志文件管理：滚动写入（2MB/文件，最多3个）+ 脱敏导出 + 系统分享 |

### P1-3 ✅ 领域层接口 + 实体模型

**领域模型：**
- `PanelSite` — 站点（build-time 注入，用户不可修改）
- `PanelUser` — 用户信息统一模型
- `ProxyNode` — 节点统一模型（protocol / address / port / extra / latency / isFavorite）
- `TrafficStats` — 实时流量统计（速率 + 总量）
- `EngineState` / `RoutingMode` — 连接状态与路由模式枚举
- `PlanItem / Order / PaymentMethod / Ticket / InviteSummary / Notice / KnowledgeArticle / TrafficRecord` 等商业领域模型

**核心接口：**
- `PanelAdapter` — 47 个 API 方法的完整抽象（认证 / 用户 / 套餐 / 订单 / 工单 / 邀请 / 公告 / 知识库 / 流量统计）
- `CoreEngine` — 内核驱动抽象（connect / disconnect / switchRoutingMode / stateStream / trafficStream / logStream）
- `EngineCapabilities` — 内核能力声明（协议支持 + 平台矩阵）

### P1-4 ✅ XboardAdapter 认证模块 + 节点拉取

- 全量实现 `PanelAdapter` 接口（对接 xboard `/api/v1/...` 端点）
- `NodeNormalizer`：支持 xboard API 格式 + 订阅 URL 格式（ss/vmess/vless/trojan/hy2 URI 解析 + sing-box JSON 格式）
- 字段映射：`transfer_enable` → `trafficTotal`，`u+d` → `trafficUsed`，`expired_at` 时间戳 → `DateTime` 等

### P1-5 ✅ SingboxDriver 骨架（参考 MagicLamp FFI 集成）

- `LibboxFfi` — 平台多路复用 FFI 绑定层
  - Windows: `libbox-amd64.dll` via `DynamicLibrary.open`
  - Android: `libbox.so` via JNI
  - macOS/iOS: `DynamicLibrary.process()`
  - Linux: `libbox.so`
- `SingboxDriver` — 实现 `CoreEngine` 接口，含 **Stub 模式**（libbox 未加载时模拟连接+流量数据，用于 UI 开发）
- `SingboxConfigBuilder` — 将 `ProxyNode + RoutingMode` 转换为 sing-box JSON 配置（支持 ss/vmess/vless/trojan/hy2 + WS/gRPC/H2 传输层 + 三种路由模式）

**libbox 工作目录（参考 MagicLamp）：**
| 平台 | 路径 |
|------|------|
| Windows | `%LOCALAPPDATA%\Hyena` |
| macOS | `~/Library/Application Support/Hyena` |
| Android/iOS | ApplicationDocumentsDirectory |
| Linux | `~/.config/hyena` |

### P1-6 ✅ 最小 UI（Splash / Login / Home）

- `SplashScreen` — 启动动画 + 自动会话恢复 + 自动连接上次节点
- `LoginScreen` — 表单校验 + 错误提示 + 加载态
- `RegisterScreen` — 邮件验证码 + 邀请码（可选）
- `ForgotPasswordScreen` — 重置密码
- `HomeScreen` — 连接按钮（圆形状态指示）+ 实时流量卡片 + 连接时长显示 + 当前节点卡片 + 路由模式选择 + 底部导航栏（4 Tab）

### P1-7 ✅ SkinManager 骨架 + default skin 令牌

- `ThemeTokens` — 10 个颜色令牌 + 3 个圆角令牌
- `ThemeTokenProvider` — InheritedWidget，`tokensOf(context)` 全局读取，`toMaterialTheme()` 生成 MaterialTheme
- Default Skin — "Terminal Minimal" 深色：Primary Cyan `#22D3EE`，背景 `#0A0F1C`，可扩展为多品牌皮肤

---

## Phase 2 · 商业闭环（已完成）

### P2-0 ✅ Hive 缓存层
- `CacheStorage` 单例：节点（1h TTL）/ 用户（5min）/ 套餐（2h）缓存
- `main.dart` 集成初始化

### P2-1 ✅ 节点模块
- `NodeUseCase`：fetchNodes（带缓存回落）、收藏管理、lastNodeId 持久化
- `NodeNotifier`：ChangeNotifier，支持搜索过滤 + 分组 + 排序 + 测速
- `NodeListScreen`：Tab（全部 / 收藏）+ 搜索栏 + 分组列表 + 延迟显示 + 选择节点保存 lastNodeId

### P2-2 ✅ 商店
- `StoreUseCase`：fetchPlans / createOrder / checkout / checkCoupon / fetchPaymentMethods
- `StoreScreen`：套餐卡片（周期选择 / 价格 / 流量标签）+ 下单确认弹窗 + 动态支付方式选择（BottomSheet）
- `PaymentResultScreen`：外部浏览器支付跳转 + 订单状态轮询 + 支付成功/等待状态展示

### P2-3 ✅ 订单中心
- `OrderUseCase`：fetchOrders / fetchOrderDetail / checkOrderStatus / fetchPaymentMethods / cancelOrder
- `OrderCenterScreen`：订单卡片（状态色 / 取消二次确认）
- `OrderDetailScreen`：订单详情（金额 / 优惠 / 余额抵扣）+ 支付 / 取消操作 + 待支付状态自动轮询

### P2-4 ✅ 工单系统
- `TicketUseCase`：fetch / detail / create / reply / close
- `TicketListScreen`：新建弹窗（主题 / 优先级 / 内容）
- `TicketDetailScreen`：气泡对话 UI + 回复输入框 + 关闭按钮

### P2-5 ✅ 个人中心
- `ProfileUseCase`：fetchUser（缓存）/ fetchTrafficLogs / changePassword / resetSecurity / updateUserSettings / fetchSubscribeInfo
- `ProfileScreen`：头像 / 流量进度条 / 余额卡片 / 菜单列表

### P2-6 ✅ 邀请返佣
- `InviteUseCase`：fetchInviteSummary / generateInviteCode / fetchCommissionDetails / transferCommissionToBalance
- `InviteScreen`：统计卡 + 邀请码列表（一键复制）

### P2-7 ✅ 设置页 + 语言切换
- `LocaleNotifier`：运行时语言切换，持久化到 AppPreferences（修复 locale 存储格式）
- `SettingsScreen`：自动连接开关 + 语言选择 + 工具入口（流量图表 / 诊断）+ 版本信息
- `app.dart`：`Consumer2<AuthNotifier, LocaleNotifier>` 注入 `locale`

### P2-8 ✅ AppRouter 补全
- 所有占位路由替换为真实页面
- 路由列表：`/splash`, `/login`, `/register`, `/forgot-password`, `/home`, `/nodes`, `/store`, `/orders`, `/orders/:tradeNo`, `/payment-result`, `/tickets`, `/profile`, `/invite`, `/settings`, `/diagnostics`, `/traffic-chart`

### P2-9 ✅ 新增 UseCase 模块
- `GiftCardUseCase`：checkGiftCard / redeemGiftCard / fetchHistory
- `NoticeUseCase`：fetchNotices
- `KnowledgeUseCase`：fetchArticles / fetchDetail
- `StatUseCase`：fetchStat / fetchTrafficLog

### P2-10 ✅ Bug 修复（代码审查发现）
- **B-1**：`ConnectionNotifier.traffic` 恒返回 null → 改为缓存最近一次 `TrafficStats` 值
- **B-2**：`NodeListScreen.setFavoriteAware()` 空实现 → 接入 `AppPreferences.setLastNodeId()`
- **B-3**：`StoreScreen._submitOrder` 硬编码 `methodId: 1` → 动态弹出支付方式选择 BottomSheet
- **B-4**：`HomeScreen` 收藏按钮占位注释 → 接入 `NodeNotifier.toggleFavorite`
- **B-5**：`NodeListScreen` 硬编码中文 `'默认'` → 国际化 `s.nodesFilterAll`
- **B-6**：`LocaleNotifier.setLocale()` 存储 `"en_"` 格式 → 修复为正确的 locale tag
- **DiagnosticsScreen**：新增诊断页面（连通性检测 + 日志查看 + 导出）
- **AppLogger.recentLogs**：新增环形日志缓冲区（200 条），支持 DiagnosticsScreen 展示

---

## Phase 3 · 节点管理 + 连接完善（已完成）

### P3-1 ✅ 节点延迟测速
- `NodeLatencyService`：TCP 连通性测试（3s 超时）
  - `testSingle()`：单节点测速，返回延迟毫秒数
  - `testBatch()`：批量并发测速（最大并发 10），通过回调实时返回结果
- `NodeNotifier.testNode()` / `testAllNodes()` 整合到状态管理
- `NodeListScreen` AppBar 增加测速按钮（带 loading 状态指示）

### P3-2 ✅ 节点排序
- `NodeSortMode` 枚举：name / latency / group
- `NodeNotifier.setSortMode()` 切换排序
- `NodeListScreen` AppBar 增加 PopupMenuButton 排序菜单
- 延迟排序：未测速节点排末尾

### P3-3 ✅ 路由模式热切换
- `SingboxDriver.switchRoutingMode()` 完整实现
  - 已连接状态：停止当前内核 → 使用新路由模式重新生成配置 → 重启内核
  - Stub 模式：模拟 200ms 切换延迟
- `ConnectionUseCase.switchMode()` 同步持久化路由模式到 `AppPreferences`

### P3-4 ✅ 启动时自动连接
- `AppPreferences.autoConnect` 开关（默认关闭）
- `ConnectionUseCase.tryAutoConnect()`：检查开关 + 自动连接
- `SplashScreen._tryAutoConnect()`：登录成功后异步查找 lastNodeId 对应节点并连接
- `SettingsScreen`：自动连接 SwitchListTile 开关

### P3-5 ✅ 实时流量速率 + 连接时长统计
- `ConnectionUseCase.connectedSince` / `connectionDuration`：连接时长跟踪
- `ConnectionNotifier` 暴露 `connectionDuration` / `connectedSince` 给 UI
- `HomeScreen._ConnectionDurationChip`：实时计时器（HH:MM:SS 格式），每秒刷新
- `ConnectionUseCase.logStream` 暴露内核日志流

### P3-6 ✅ 日志采集 + 文件滚动 + 诊断页增强
- `LogFileManager`：日志文件管理器
  - 滚动写入：2MB/文件，最多保留 3 个历史文件
  - `exportLogs()`：合并所有日志文件，生成导出文件
  - `shareExport()`：通过 `share_plus` 系统分享导出文件
- `AppLogger.enableFileLogging()`：启用文件日志写入（main.dart 中初始化）
- `DiagnosticsScreen` 增强：
  - 定时刷新日志（2 秒间隔）
  - 逆序显示（最新日志在顶部）
  - 导出按钮接入 `LogFileManager.shareExport()`
  - 诊断运行时显示连接时长

### P3-7 ✅ 流量统计图表
- `TrafficChartScreen`：当月每日流量柱状图
  - 调用 `StatUseCase.fetchTrafficLog()` 获取数据
  - 汇总卡片：当月总上行 / 总下行 / 总用量
  - 柱状图：上行（主色）+ 下行（绿色）堆叠柱
  - 明细列表：逆序显示每日流量
  - 下拉刷新 + 加载/错误/空状态
- 路由：`/traffic-chart`
- 入口：设置页 → 工具区 → 流量统计

### P3-8 ✅ 自动重连
- `ConnectionUseCase._setupAutoReconnect()`：监听 stateStream，error 时自动触发 retry
- 最大重试 3 次，间隔递增（1s, 2s, 3s）

---

## Phase 4 · Controller/View 分离 + 皮肤系统（已完成）

### 架构决策（ADR-008）
- **选定方案**：Controller/View 分离 + Page Override 皮肤方案
- **核心思路**：
  1. 每个页面对应一个 `ScreenController`（extends `ChangeNotifier`），暴露固定的状态属性和操作方法
  2. View 层只通过 Controller API 交互，禁止直接引用 UseCase / Adapter / Storage
  3. `SkinPageFactory` 可整页覆盖任意页面，但 Controller API 不变
  4. 编写 `docs/skin-contract.md` 作为 UI 设计者的唯一依赖文档

### 文档更新（已完成）
- ✅ `docs/system-design.md` v1.3 — 新增 Controller Layer 分层、Controller 清单、SkinPageFactory 架构
- ✅ `docs/development-plan.md` v1.1 — 重写 P4 任务列表（13 个 Controller 抽取 + 页面改造 + 皮肤框架）
- ✅ `docs/skin-contract.md` v1.0 — 界面设计规范（13 个 Controller 的完整 API 清单 + ThemeTokens 规范 + 皮肤开发指南）

### P4-1 ✅ Controller 层创建
| 编号 | Controller | 状态 |
|------|-----------|------|
| 4.1 | `HomeController` | ✅ |
| 4.2 | `AuthController` | ✅ |
| 4.3 | `NodeController` | ✅ |
| 4.4 | `StoreController` | ✅ |
| 4.5 | `OrderController` | ✅ |
| 4.6 | `TicketController` | ✅ |
| 4.7 | `ProfileController` | ✅ |
| 4.8 | `SettingsController` | ✅ |
| 4.9 | `DiagController` | ✅ |
| 4.10 | `NoticeController` | ✅ |
| 4.11 | `KnowledgeController` | ✅ |
| 4.12 | `TrafficChartController` | ✅ |
| 4.13 | `SplashController` | ✅ |

### P4-2 ✅ SkinPageFactory 框架
- ✅ `SkinContract` 接口（`skins/skin_contract.dart`）
- ✅ `SkinPageFactory` 抽象接口（`skins/skin_page_factory.dart`）
- ✅ `DefaultPageFactory` 实现（`skins/default/default_page_factory.dart`）
- ✅ `SkinManager` 升级为 Contract 模式（加载 SkinContract 而非纯 ThemeTokens）

### P4-3 ✅ 页面改造
- ✅ 所有页面改造为只通过 Controller 交互
  - `HomeScreen`：使用 `HomeController`（stateStream / trafficStream / connect / disconnect / switchRoutingMode / toggleFavorite）
  - `LoginScreen` / `RegisterScreen` / `ForgotPasswordScreen`：使用 `AuthController`（login / register / sendEmailCode / resetPassword）
  - `SplashScreen`：使用 `SplashController`（initialize / shouldNavigateTo）
  - `NodeListScreen`：使用 `NodeController`（load / testAllNodes / setSortMode / setFilter / selectAndConnect / toggleFavorite）
  - `StoreScreen`：使用 `StoreController`（fetchPlans / createOrder / checkout / fetchPaymentMethods）
  - `OrderCenterScreen` / `OrderDetailScreen`：使用 `OrderController`（fetchOrders / fetchOrderDetail / cancelOrder / checkOrderStatus）
  - `PaymentResultScreen`：使用 `OrderController`（checkOrderStatus）
  - `TicketListScreen` / `TicketDetailScreen`：使用 `TicketController`（fetchTickets / createTicket / replyTicket / closeTicket）
  - `ProfileScreen`：使用 `ProfileController`（fetchUser / changePassword / logout）
  - `InviteScreen`：使用 `ProfileController`（fetchInviteSummary / generateInviteCode）
  - `SettingsScreen`：使用 `SettingsController`（autoConnect / setLocale / setAutoConnect）— 改为 StatelessWidget
  - `DiagnosticsScreen`：使用 `DiagController`（refreshLogs / runDiagnostics / exportLogs）
  - `TrafficChartScreen`：使用 `TrafficChartController`（fetchTrafficLog / records）
- ✅ Router 集成 SkinPageFactory（先查皮肤工厂再用默认页面）
- ✅ Controller Provider 注册（`main.dart` MultiProvider 注入 13 个 ScreenController）

---

## 已知问题 / 技术债

| 编号 | 描述 | 优先级 | 计划解决阶段 |
|------|------|--------|-------------|
| TD-03 | TrafficPolling 目前仅做 Stub，需接 sing-box Clash API 获取真实流量 | 中 | 接入 libbox 时解决 |
| TD-10 | 桌面端 tray_manager / window_manager 集成未实现 | 中 | P5 |
| TD-12 | 部分 P2 页面直接使用 Theme.of(context) 而非 ThemeTokenProvider | 低 | P4 改造时顺带修复 |
| TD-13 | EngineConfigBuilder 完整实现 — 当前已支持 5 种协议 + 3 种路由 + 3 种传输层，基本完整 | 低 | 按需补充 |
| TD-14 | Phase 3 集成测试 — 连接状态机全路径测试待补充 | 中 | P5 |

---

## 构建命令示例

```bash
# 开发调试（xboard 示例站点）
flutter run \
  --dart-define=PANEL_API_BASE=https://panel.example.com \
  --dart-define=PANEL_TYPE=xboard \
  --dart-define=SITE_ID=dev \
  --dart-define=SITE_NAME=HyenaVPN

# 正式品牌打包（Android APK）
flutter build apk \
  --dart-define=PANEL_API_BASE=https://panel.example.com \
  --dart-define=PANEL_TYPE=xboard \
  --dart-define=SITE_ID=brand_x_prod \
  --dart-define=SITE_NAME=BrandX \
  --dart-define=SKIN_ID=brand_x \
  --dart-define=DEFAULT_LOCALE=zh_CN
```

---

## libbox 接入说明

Hyena 参考 MagicLamp（`/Users/tianwanggaidihu/src/MagicLamp`）的 libbox 集成方式：

1. **Android**：将 `libbox.aar` 放入 `android/app/libs/`，`build.gradle` 添加 `implementation(name: "libbox", ext: "aar")`
2. **Windows**：将 `libbox-amd64.dll` 放入应用同级目录或 `native/libs/windows/x64/`
3. **iOS/macOS**：通过 `DynamicLibrary.process()` 调用系统已链接的 libbox framework
4. **开发 Stub**：libbox 未加载时自动进入模拟模式，支持 UI 全流程调试（无需 native 库）
