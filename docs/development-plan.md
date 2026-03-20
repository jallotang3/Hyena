# Hyena · 开发计划（V1）

> **文档版本**: v1.0 | **状态**: 草稿 | **更新时间**: 2026-03
>
> 本文档基于需求分析（v1.2）、系统设计（v1.2）及 Xboard 客户端 OpenAPI 规范制定。

---

## 1. 总体策略

### 1.1 时间估算基准

| 假设 | 说明 |
|------|------|
| 团队规模 | 1～2 名全栈 Flutter 开发，阶段 3/4/5 可并行安排第 2 人 |
| 工作日 | 5 天/周，每天有效编码 6 小时 |
| 任务规模标注 | `S`（≤1天）/ `M`（2～3天）/ `L`（4～5天）/ `XL`（≥1周） |
| 总工期估算 | **约 20～26 周**（含测试与集成；不含 M6/M7 扩展阶段） |

### 1.2 阶段并行关系

```
P1 架构骨架（串行，所有阶段前置）
 ├─▶ P2 商业闭环          （依赖 P1，优先级最高）
 ├─▶ P3 节点与连接完善    （依赖 P1，可与 P2 并行）
 ├─▶ P4 皮肤 + 多语言     （依赖 P1，可与 P2/P3 并行）
 └─▶ P5 CI/CD 模板化      （依赖 P1，可早期并行启动）
      └─▶ P6 第二面板      （依赖 P3，V1 验证扩展性）
           └─▶ P7 品牌皮肤  （依赖 P4）
```

### 1.3 完成定义（DoD）

每个任务交付前须满足：
- 代码通过 `flutter analyze` 与 `dart format` 检查
- 核心模块（适配器/引擎/皮肤）有单元测试，关键路径覆盖率 ≥ 70%
- 无硬编码中文/英文 UI 字符串（通过 ARB i18n 机制）
- PR 经过自评 Checklist，README/注释描述清晰

---

## 2. Phase 1 · 架构骨架（必须串行，先行）

**目标**：三层扩展框架可跑通，完成「注册 → 登录 → 拉取订阅节点 → 建立连接」最小链路 Demo。

**预计工期**：4～5 周

### 2.1 项目脚手架与基础设施

| # | 任务 | 规模 | 说明 |
|---|------|------|------|
| 1.1 | Flutter 项目初始化（SDK 版本锁定、`pubspec.yaml` 依赖配置） | S | Dio / Provider / flutter_secure_storage / Hive / flutter_localizations / intl |
| 1.2 | 项目目录结构创建（`core/`, `features/`, `adapters/`, `skins/`, `l10n/`, `infrastructure/`） | S | 对照系统设计 §13 目录规范 |
| 1.3 | `AppConfig` 编译常量（`PANEL_API_BASE`, `PANEL_TYPE`, `SITE_ID`, `SKIN_ID`, `DEFAULT_LOCALE`） | S | `lib/config/app_config.dart` |
| 1.4 | Dio 封装（拦截器：认证头注入、超时配置、错误码统一转换） | M | `infrastructure/network/` |
| 1.5 | `SecureStorage` 封装（Token 读写，适配 Android Keystore / iOS Keychain） | S | `infrastructure/storage/` |
| 1.6 | `CacheStorage` 封装（Hive 初始化、节点列表落盘） | S | |
| 1.7 | `SharedPreferences` 封装（轻量配置，含 locale 偏好） | S | |
| 1.8 | 结构化日志（脱敏规则 + 文件滚动写入 + 全局 Logger 单例） | M | `infrastructure/logging/` |
| 1.9 | 全局错误类型定义（`AppError` 体系：`AuthException`, `PanelUnavailableException`, `NodeParseException`, `EngineStartException` 等） | S | `core/errors/` |
| 1.10 | `Result<T, E>` 类型封装 | S | `core/result.dart` |

### 2.2 领域层接口定义

| # | 任务 | 规模 | 说明 |
|---|------|------|------|
| 1.11 | `PanelAdapter` 抽象接口（认证/用户/节点/套餐/订单/工单/邀请/公告/知识库/统计全方法签名） | M | `core/interfaces/panel_adapter.dart` |
| 1.12 | `CoreEngine` 抽象接口（init / applyConfig / start / stop / reload / stateStream） | S | `core/interfaces/core_engine.dart` |
| 1.13 | `SkinContract` 抽象接口（contractVersion / themeTokens / supportedPages / componentOverrides） | S | `core/interfaces/skin_contract.dart` |
| 1.14 | 统一实体模型：`PanelSite`, `PanelUser`, `ProxyNode`, `TrafficStats`, `EngineState` | M | `core/models/` |
| 1.15 | 商业实体模型：`PlanItem`, `Order`, `PaymentMethod`, `Ticket`, `TicketMessage`, `InviteCode`, `CommissionRecord`, `Notice`, `KnowledgeArticle`, `GiftCardPreview` | M | `core/models/commercial/` |
| 1.16 | `PanelCapabilities` 能力声明模型 | S | |

### 2.3 面板适配器骨架（XboardAdapter — 认证 + 订阅）

| # | 任务 | 规模 | Xboard API | 说明 |
|---|------|------|-----------|------|
| 1.17 | `PanelAdapterRegistry` 注册与发现机制 | S | — | `adapters/panel/registry.dart` |
| 1.18 | `XboardAdapter` 骨架（初始化、Dio 实例、认证头组装） | S | — | `adapters/panel/xboard/` |
| 1.19 | 发送邮箱验证码 `sendEmailVerifyCode` | S | `POST /passport/comm/sendEmailVerify` | |
| 1.20 | 用户注册 `register` | S | `POST /passport/auth/register` | 含邀请码字段 |
| 1.21 | 用户登录 `login` | S | `POST /passport/auth/login` | 返回 `auth_data`（Bearer Token）存入 SecureStorage |
| 1.22 | 忘记密码 `resetPassword` | S | `POST /passport/auth/forget` | |
| 1.23 | 获取用户基本信息 `fetchUserInfo` | S | `GET /user/info` | 字段映射：`transfer_enable` → `trafficTotal`，`u+d` → `trafficUsed` 等 |
| 1.24 | 获取订阅信息 `fetchSubscribeInfo` | S | `GET /user/getSubscribe` | 订阅链接 + 设备数限制 |
| 1.25 | 节点拉取 — 订阅 URL 模式 | M | `GET /client/subscribe?token=` | base64 解码 → sing-box 配置解析 |
| 1.26 | 节点拉取 — API 接口模式 | M | `GET /user/server/fetch` | JSON → `ProxyNode[]` |
| 1.27 | `NodeNormalizer`（各协议字段映射：VLESS / VMess / Shadowsocks / Trojan / Hysteria2） | L | — | |
| 1.28 | 本地节点缓存（面板不可达时降级） | S | — | Hive 落盘 |

### 2.4 内核驱动骨架（SingboxDriver）

| # | 任务 | 规模 | 说明 |
|---|------|------|------|
| 1.29 | `EngineRegistry` + `EngineSelector` 框架 | S | `adapters/engine/registry.dart` |
| 1.30 | `SingboxDriver` Stub（实现 `CoreEngine` 接口，FFI 桩实现，状态可流转） | L | 参考 MagicLamp libbox 集成；`adapters/engine/singbox/` |
| 1.31 | `EngineConfigBuilder` — 基础配置生成（单节点 + 全局代理模式） | M | `ProxyNode` → sing-box JSON |
| 1.32 | libbox FFI 绑定（Android AAR + Windows DLL 集成，iOS/macOS 预留） | XL | `native/libs/`；参考 MagicLamp `lib/services/vpn` |
| 1.33 | VPN 权限申请流程（Android 平台 VPN 权限 + 服务组件注册） | M | |
| 1.34 | 连接状态机（idle → connecting → connected → disconnecting → error）完整流转 | M | |

### 2.5 认证 UseCase + 最小 UI

| # | 任务 | 规模 | 说明 |
|---|------|------|------|
| 1.35 | `AuthUseCase`（注册/登录/登出/Token 缓存/自动刷新检查） | M | `features/auth/` |
| 1.36 | `PanelSite.fromBuildConfig()` 初始化（App 启动时读取编译常量） | S | |
| 1.37 | 启动流程（Splash → 判断登录态 → 登录页 / 首页） | S | |
| 1.38 | 登录页 UI（账号 + 密码输入、登录按钮、「注册」「忘记密码」入口） | M | 对应设计稿 `03 · Login` |
| 1.39 | 注册页 UI（邮箱 + 验证码 + 密码 + 邀请码可选） | M | |
| 1.40 | 忘记密码页 UI（邮件验证码 + 新密码） | M | |
| 1.41 | `ConnectionUseCase` 最小实现（connect / disconnect / watchState） | M | `features/connection/` |
| 1.42 | 首页最小 UI（连接状态卡、当前节点、连接/断开按钮） | M | 对应设计稿 `04 · Home`（简化版） |
| 1.43 | Phase 1 集成验证：端到端跑通注册 → 登录 → 拉取节点 → 建立连接 | M | Smoke Test |

### 2.6 皮肤系统骨架

| # | 任务 | 规模 | 说明 |
|---|------|------|------|
| 1.44 | `SkinManager` 框架（按 skinId 加载，失败回退 default，合约版本校验） | M | `skins/skin_manager.dart` |
| 1.45 | `ThemeTokenProvider`（令牌注入 MaterialTheme，全局 BuildContext 可用） | M | `skins/theme_token_provider.dart` |
| 1.46 | default skin 骨架（`ThemeTokens` 基础颜色/字体/间距定义，不含全部页面覆盖） | M | `skins/default/` |

---

## 3. Phase 2 · 商业闭环

**目标**：完成 xboard 所有商业 API 对接与对应页面，实现「套餐购买 → 支付 → 工单客服 → 邀请推广」完整商业链路。

**预计工期**：5～6 周（可与 P3 部分并行）

### 3.1 XboardAdapter 商业接口补全

| # | 任务 | 规模 | Xboard API |
|---|------|------|-----------|
| 2.1 | 获取站点通用配置 `getSiteConfig` | S | `GET /guest/comm/config` / `GET /user/comm/config` |
| 2.2 | 获取公开套餐列表（访客态） | S | `GET /guest/plan/fetch` |
| 2.3 | 获取已登录用户套餐列表 `fetchPlans` | S | `GET /user/plan/fetch` |
| 2.4 | 获取单个套餐详情 `fetchPlanDetail` | S | `GET /user/plan/fetch?id=` |
| 2.5 | 创建订单 `createOrder` | S | `POST /user/order/save`（plan_id / period / coupon_code） |
| 2.6 | 获取支付方式列表 `fetchPaymentMethods` | S | `GET /user/order/getPaymentMethod` |
| 2.7 | 结算订单/发起支付 `checkout` | S | `POST /user/order/checkout`（trade_no / method）→ 返回 type + data |
| 2.8 | 轮询订单状态 `checkOrderStatus` | S | `GET /user/order/check?trade_no=` |
| 2.9 | 取消订单 `cancelOrder` | S | `POST /user/order/cancel` |
| 2.10 | 获取订单列表 `fetchOrders` | S | `GET /user/order/fetch` |
| 2.11 | 获取订单详情 `fetchOrderDetail` | S | `GET /user/order/detail?trade_no=` |
| 2.12 | 验证优惠码 `checkCoupon` | S | `POST /user/coupon/check` |
| 2.13 | 工单列表 `fetchTickets` | S | `GET /user/ticket/fetch` |
| 2.14 | 工单详情 `fetchTicketDetail` | S | `GET /user/ticket/fetch?id=` |
| 2.15 | 创建工单 `createTicket` | S | `POST /user/ticket/save` |
| 2.16 | 回复工单 `replyTicket` | S | `POST /user/ticket/reply` |
| 2.17 | 关闭工单 `closeTicket` | S | `POST /user/ticket/close` |
| 2.18 | 申请佣金提现（自动创建提现工单） | S | `POST /user/ticket/withdraw` |
| 2.19 | 邀请信息 + 佣金统计 `fetchInviteSummary` | S | `GET /user/invite/fetch` |
| 2.20 | 生成新邀请码 `generateInviteCode` | S | `GET /user/invite/save` |
| 2.21 | 佣金明细列表 `fetchCommissionDetails` | S | `GET /user/invite/details` |
| 2.22 | 佣金转账户余额 `transferCommissionToBalance` | S | `POST /user/transfer` |
| 2.23 | 修改密码 `changePassword` | S | `POST /user/changePassword` |
| 2.24 | 重置安全凭证（订阅 Token）`resetSecurity` | S | `GET /user/resetSecurity` |
| 2.25 | 更新用户通知设置 `updateUserSettings` | S | `POST /user/update` |
| 2.26 | 获取活跃会话列表 `getActiveSessions` | S | `GET /user/getActiveSession` |
| 2.27 | 移除活跃会话 `removeActiveSession` | S | `POST /user/removeActiveSession` |
| 2.28 | 公告列表 `fetchNotices` | S | `GET /user/notice/fetch` |
| 2.29 | 知识库分类列表 | S | `GET /user/knowledge/getCategory` |
| 2.30 | 知识库文章列表/搜索 `fetchKnowledge` | S | `GET /user/knowledge/fetch` |
| 2.31 | 知识库文章详情 `fetchKnowledgeDetail` | S | `GET /user/knowledge/fetch?id=` |
| 2.32 | 礼品卡查询 `checkGiftCard` | S | `POST /user/gift-card/check` |
| 2.33 | 礼品卡兑换 `redeemGiftCard` | S | `POST /user/gift-card/redeem` |
| 2.34 | 礼品卡兑换历史 `fetchGiftCardHistory` | S | `GET /user/gift-card/history` |
| 2.35 | 获取用户统计数据（待支付订单数/未关闭工单数/邀请数） | S | `GET /user/getStat` |
| 2.36 | 检查登录状态 | S | `GET /user/checkLogin` |
| 2.37 | 邮件链接一键登录 `loginWithMailLink` | S | `POST /passport/auth/loginWithMailLink` |
| 2.38 | 当月流量统计 `fetchTrafficLog` | S | `GET /user/stat/getTrafficLog` |

### 3.2 商业功能 UseCase

| # | 任务 | 规模 | 说明 |
|---|------|------|------|
| 2.39 | `StoreUseCase`（套餐列表、套餐详情、优惠码验证） | M | |
| 2.40 | `OrderUseCase`（创建订单、支付方式、发起支付、轮询状态、取消、历史、详情） | L | 含支付轮询逻辑（每 3s，最多 5 分钟） |
| 2.41 | `UserProfileUseCase`（用户信息、订阅详情、改密、重置 Token、会话管理、通知设置） | M | |
| 2.42 | `TicketUseCase`（列表、详情、创建、回复、关闭、提现申请） | M | |
| 2.43 | `InviteUseCase`（邀请码管理、统计、佣金明细、佣金转余额） | M | |
| 2.44 | `GiftCardUseCase`（查询、兑换、历史） | S | |
| 2.45 | `NoticeUseCase`（公告列表、已读状态） | S | |
| 2.46 | `KnowledgeUseCase`（分类、文章列表、搜索、详情） | S | |
| 2.47 | `StatUseCase`（当月流量日志） | S | |

### 3.3 商业功能页面 UI

| # | 任务 | 规模 | 对应设计稿 |
|---|------|------|----------|
| 2.48 | **首页完整版**：套餐用量卡（环形进度条）、流量速率、当前节点卡含收藏星标、路由模式切换 | L | `04 · Home` |
| 2.49 | **节点列表页**：节点卡片（名称/分组/延迟/协议）、全量/收藏筛选、搜索框 | L | `05 · Nodes` |
| 2.50 | **商店页**：Tab 切换（订阅/流量包）、4 档套餐卡片、支付方式列表、立即支付按钮 | L | `08 · Store` |
| 2.51 | **WebView / 系统浏览器跳转支付**（含支付轮询 + 结果页） | M | |
| 2.52 | **订单中心**：订单列表（状态筛选：全部/待支付/已完成）、订单条目 | M | `10 · Order Center` |
| 2.53 | **订单详情页**（路由 `/orders/:tradeNo`）：完整快照、待支付可继续支付/取消 | M | |
| 2.54 | **工单列表页**：工单条目（状态徽章）、新建工单按钮 | M | `11 · Ticket List` |
| 2.55 | **工单详情页**：气泡式对话布局（我方右侧/客服左侧）、底部输入框 + 发送、关闭按钮 | M | `12 · Ticket Detail` |
| 2.56 | **新建工单页**：主题/优先级/描述表单 | S | |
| 2.57 | **用户中心页**（Profile）：头像/邮箱/套餐卡片/流量卡/功能入口列表/登出 | M | `13 · Profile` |
| 2.58 | **邀请页**：统计数字、邀请链接+复制、提现按钮、近期邀请列表 | M | `14 · Invite` |
| 2.59 | **设置页**：内核选择/皮肤切换/自动连接/语言切换/关于 | M | `06 · Settings` |
| 2.60 | **诊断页**：日志列表、导出按钮 | S | `07 · Diagnostics` |
| 2.61 | **底部导航栏**：HOME / NODES / SETTINGS / MY 四 Tab，激活态联动 | S | 已含于设计稿 |

---

## 4. Phase 3 · 节点管理 + 连接完善

**目标**：测速、收藏、路由策略完整可用，自动重连、日志导出、流量统计图表上线。

**预计工期**：3～4 周（可与 P2 并行）

| # | 任务 | 规模 | 说明 |
|---|------|------|------|
| 3.1 | 单节点延迟测速（TCP 连通测试，超时 3s 视为不可用） | M | `features/node/` |
| 3.2 | 全量批量测速（并发，结果实时刷新到列表） | M | |
| 3.3 | 节点收藏（写入本地存储，与服务端无关） | S | |
| 3.4 | 节点排序（延迟 / 名称 / 收藏 / 分组切换） | S | |
| 3.5 | 节点搜索过滤（本地实时过滤） | S | |
| 3.6 | 路由模式切换（全局代理 / 规则分流 / 直连）实时生效，无需断开重连 | M | `EngineConfigBuilder` 路由策略实现 |
| 3.7 | 自动重连（可配置最大重试次数与间隔，`ConnectionUseCase` 内实现） | M | |
| 3.8 | 启动时自动连接上次节点（可在设置页关闭） | S | |
| 3.9 | 实时流量速率显示（上行/下行，从 sing-box stats 接口轮询） | M | |
| 3.10 | 内核日志采集 + 日志文件滚动 + 诊断页实时展示 | M | |
| 3.11 | 日志导出（脱敏后写入可分享文件） | S | |
| 3.12 | `EngineConfigBuilder` 完整实现（VLESS / VMess / SS / Trojan / Hysteria2 出站配置） | L | |
| 3.13 | `EngineCapabilities` 声明（协议支持 + 平台矩阵） | S | |
| 3.14 | 流量统计图表（当月每日流量柱状图，调用 `StatUseCase`） | M | `features/stat/` |
| 3.15 | 连接时长统计（可选，`[C]` 级需求） | S | |
| 3.16 | Phase 3 集成测试：连接状态机全路径（idle→connecting→connected→error→idle）、自动重连 3 次 | M | |

---

## 5. Phase 4 · 皮肤系统 + 多语言

**目标**：ThemeTokenProvider、SkinComponentRegistry 完整可用；default skin 覆盖全部 V1 页面；zh_CN + en 双语 ARB 全覆盖；设置页语言切换生效。

**预计工期**：3～4 周（可与 P3 并行）

### 5.1 皮肤系统完整实现

| # | 任务 | 规模 | 说明 |
|---|------|------|------|
| 4.1 | `ThemeTokenProvider` 完整实现（颜色/字体/间距/圆角 Token 挂载到 MaterialTheme） | M | |
| 4.2 | `SkinComponentRegistry`（组件槽位装配：connectButton / nodeCard / trafficBadge / statusIndicator / bottomNavBar / sideNavBar） | M | |
| 4.3 | `LayoutPresetResolver`（mobile / desktop 布局预设，响应式切换） | M | |
| 4.4 | default skin 全页面覆盖（登录 / 注册 / 首页 / 节点 / 商店 / 订单 / 工单 / 邀请 / 用户中心 / 设置 / 诊断 / 启动页） | L | `skins/default/` |
| 4.5 | `skin_manifest.json` 规范输出（contractVersion + 槽位声明） | S | |
| 4.6 | 皮肤合约文档（`docs/skin-contract.md`）输出 | M | |
| 4.7 | 皮肤加载版本校验（contractVersion 不兼容时降级 default，日志记录） | S | |
| 4.8 | Golden Test：ThemeToken 注入后 Widget 颜色正确性验证 | M | |

### 5.2 多语言（i18n/l10n）

| # | 任务 | 规模 | 说明 |
|---|------|------|------|
| 4.9 | `l10n.yaml` 配置 + `flutter gen-l10n` 接入（`app_en.arb` 为基准） | S | |
| 4.10 | `app_en.arb` 完整翻译 Key 定义（覆盖全部 UI 文案：认证/连接/节点/商店/订单/工单/邀请/设置/错误提示/空状态/Toast） | L | 约 150～200 个 Key |
| 4.11 | `app_zh_CN.arb` 简体中文翻译填写 | L | |
| 4.12 | `LocaleNotifier`（语言切换 + SharedPreferences 持久化 + MaterialApp.locale 联动） | M | `features/settings/locale_notifier.dart` |
| 4.13 | 设置页语言切换 UI（System / 简体中文 / English 三选项，立即生效） | S | |
| 4.14 | 全局文案审查：扫描禁止硬编码（`rg '"[^"]*[\u4e00-\u9fa5]'` 检查中文硬编码） | M | |
| 4.15 | 日期/数字/货币格式化统一使用 `intl.DateFormat` + Locale | S | |
| 4.16 | CI 中加入 `flutter gen-l10n` 步骤，保证 ARB 修改后自动生成代码 | S | |

---

## 6. Phase 5 · CI/CD 模板化构建

**目标**：`ci.yml` PR 自动检查；`build-template.yml` 参数化多平台构建；`release.yml` Tag 触发归档发布。

**预计工期**：2～3 周（可在 P1 完成后尽早启动）

| # | 任务 | 规模 | 说明 |
|---|------|------|------|
| 5.1 | `ci.yml`：PR 触发，`flutter analyze` + `dart format --check` + `flutter test` | S | `.github/workflows/ci.yml` |
| 5.2 | `build-template.yml`：Android（ubuntu-latest）APK / AAB 构建 | M | `--dart-define` 参数注入；R8 混淆开启 |
| 5.3 | `build-template.yml`：Windows（windows-latest）EXE / MSIX 构建 | M | WinTUN 驱动依赖检查 |
| 5.4 | pub cache + `.dart_tool` + build/ 缓存策略（`actions/cache@v4`） | S | 降低 CI 时间 |
| 5.5 | 品牌参数注入流程（`templates/client-profile.yaml` 解析 → `pubspec.yaml` / `build.gradle` / `Info.plist` 写入） | M | |
| 5.6 | `templates/client-profile.yaml` 默认模板（含 locale 字段） | S | |
| 5.7 | Android 签名配置（Keystore base64 → GitHub Secrets 注入 + `build.gradle` 配置） | M | |
| 5.8 | `release.yml`：Tag 触发，依赖 build-template 产物，生成 Release Notes，发布到 GitHub Releases | M | |
| 5.9 | 端到端验证：手动触发 `build-template.yml`，产出 Android APK + Windows EXE，appName / packageName 注入正确 | M | |
| 5.10 | macOS 构建支持（可选，`[C]` 级，需证书配置） | L | |

---

## 7. Phase 6 · 第二面板验证（v2board）

**目标**：接入 v2board 适配器，验证 `PanelAdapter` 扩展架构可行性与扩展成本。

**预计工期**：2～3 周（依赖 P3 完成）

| # | 任务 | 规模 | 说明 |
|---|------|------|------|
| 6.1 | v2board API 接口文档调研与字段映射分析 | M | 参考系统设计 §4.3 三层隔离策略 |
| 6.2 | `V2boardAdapter` 实现（认证 + 订阅 + 节点 + 用户信息，最小可用集） | L | `adapters/panel/v2board/` |
| 6.3 | `PanelAdapterRegistry` 注册 v2board 并验证按 panelType 发现 | S | |
| 6.4 | `PanelCapabilities` 差异点标注（v2board 不支持的功能 UI 优雅隐藏） | M | |
| 6.5 | 扩展成本评估报告（修改文件数/行数统计，验证"零侵入"目标） | S | |

---

## 8. Phase 7 · 品牌皮肤验证

**目标**：交付 `brand_x` 示例皮肤，验证皮肤合约可用性与品牌定制成本。

**预计工期**：2 周（依赖 P4 完成）

| # | 任务 | 规模 | 说明 |
|---|------|------|------|
| 7.1 | `brand_x` 皮肤目录创建（`skins/brand_x/`），继承 default 合约 | S | |
| 7.2 | 自定义 `ThemeTokens`（品牌主色/字体替换） | S | |
| 7.3 | 至少覆盖 2 个自定义槽位（如 `connectButton` + `nodeCard`） | M | |
| 7.4 | `skin_manifest.json` 声明 + 版本校验通过 | S | |
| 7.5 | CI 构建指定 `SKIN_ID=brand_x` 正确加载品牌皮肤 | S | |
| 7.6 | 皮肤预览开发工具（可选，`[C]` 级，独立运行不依赖完整业务） | L | |

---

## 9. Xboard API 对接清单（按模块）

> 完整对应关系，用于开发期逐条核对。

| 模块 | API 端点 | Method | 功能 | 优先级 | 阶段 |
|------|---------|--------|------|--------|------|
| 站点配置 | `/guest/comm/config` | GET | 获取站点配置（无需认证） | [M] | P2 |
| 站点配置 | `/user/comm/config` | GET | 获取用户端站点通用配置 | [S] | P2 |
| 认证 | `/passport/comm/sendEmailVerify` | POST | 发送邮箱验证码 | [M] | P1 |
| 认证 | `/passport/auth/register` | POST | 用户注册 | [M] | P1 |
| 认证 | `/passport/auth/login` | POST | 用户登录，返回 auth_data | [M] | P1 |
| 认证 | `/passport/auth/forget` | POST | 忘记密码重置 | [M] | P1 |
| 认证 | `/passport/auth/loginWithMailLink` | POST | 发送邮件登录链接 | [S] | P2 |
| 认证 | `/passport/auth/token2Login` | GET | Token 换取登录态 | [S] | P2 |
| 用户 | `/user/checkLogin` | GET | 检查登录状态 | [M] | P2 |
| 用户 | `/user/info` | GET | 用户基本信息 | [M] | P1 |
| 用户 | `/user/getSubscribe` | GET | 订阅详情 | [M] | P1 |
| 用户 | `/user/getStat` | GET | 统计（待支付单数/未关闭工单数/邀请数） | [M] | P2 |
| 用户 | `/user/changePassword` | POST | 修改密码 | [M] | P2 |
| 用户 | `/user/update` | POST | 更新通知设置 | [S] | P2 |
| 用户 | `/user/resetSecurity` | GET | 重置订阅 Token | [M] | P2 |
| 用户 | `/user/getActiveSession` | GET | 活跃会话列表 | [S] | P2 |
| 用户 | `/user/removeActiveSession` | POST | 移除会话（强制下线） | [S] | P2 |
| 用户 | `/user/transfer` | POST | 佣金转账户余额 | [S] | P2 |
| 节点 | `/client/subscribe?token=` | GET | 订阅配置（代理节点，URL 模式） | [M] | P1 |
| 节点 | `/user/server/fetch` | GET | 节点列表（API 模式） | [M] | P1 |
| 套餐 | `/guest/plan/fetch` | GET | 访客公开套餐列表 | [M] | P2 |
| 套餐 | `/user/plan/fetch` | GET | 已登录用户套餐列表 | [M] | P2 |
| 订单 | `/user/order/save` | POST | 创建订单 | [M] | P2 |
| 订单 | `/user/order/getPaymentMethod` | GET | 支付方式列表 | [M] | P2 |
| 订单 | `/user/order/checkout` | POST | 结算/发起支付 | [M] | P2 |
| 订单 | `/user/order/check` | GET | 查询订单支付状态（轮询） | [M] | P2 |
| 订单 | `/user/order/fetch` | GET | 历史订单列表 | [M] | P2 |
| 订单 | `/user/order/detail` | GET | 订单详情 | [M] | P2 |
| 订单 | `/user/order/cancel` | POST | 取消订单 | [M] | P2 |
| 优惠码 | `/user/coupon/check` | POST | 验证优惠码 | [M] | P2 |
| 礼品卡 | `/user/gift-card/types` | GET | 礼品卡类型列表 | [S] | P2 |
| 礼品卡 | `/user/gift-card/check` | POST | 查询礼品卡信息（预览） | [S] | P2 |
| 礼品卡 | `/user/gift-card/redeem` | POST | 兑换礼品卡 | [S] | P2 |
| 礼品卡 | `/user/gift-card/history` | GET | 兑换历史 | [S] | P2 |
| 工单 | `/user/ticket/fetch` | GET | 工单列表 / 工单详情 | [M] | P2 |
| 工单 | `/user/ticket/save` | POST | 创建工单 | [M] | P2 |
| 工单 | `/user/ticket/reply` | POST | 回复工单 | [M] | P2 |
| 工单 | `/user/ticket/close` | POST | 关闭工单 | [M] | P2 |
| 工单 | `/user/ticket/withdraw` | POST | 申请佣金提现（创建提现工单） | [S] | P2 |
| 邀请 | `/user/invite/fetch` | GET | 邀请信息 + 佣金统计 | [M] | P2 |
| 邀请 | `/user/invite/save` | GET | 生成新邀请码 | [M] | P2 |
| 邀请 | `/user/invite/details` | GET | 佣金明细（分页） | [S] | P2 |
| 公告 | `/user/notice/fetch` | GET | 公告列表（分页） | [S] | P2 |
| 知识库 | `/user/knowledge/getCategory` | GET | 知识库分类列表 | [S] | P2 |
| 知识库 | `/user/knowledge/fetch` | GET | 知识库文章列表/搜索/详情 | [S] | P2 |
| 统计 | `/user/stat/getTrafficLog` | GET | 当月每日流量日志 | [S] | P3 |
| 支付 | `/user/comm/getStripePublicKey` | POST | Stripe 支付公钥（有 Stripe 时使用） | [S] | P2 |
| 应用 | `/client/app/getVersion` | GET | 客户端版本信息（更新检查） | [S] | P5 |

---

## 10. 测试计划

### 10.1 单元测试（各阶段随开发同步完成）

| 模块 | 关键测试用例 | 目标覆盖率 |
|------|------------|-----------|
| `XboardAdapter` | `login` 字段映射（正常/401/超时）；`createOrder`+`checkout` 支付流程；`fetchTickets`/`createTicket`/`replyTicket`；`NodeNormalizer` 各协议 | ≥ 80% |
| `PanelAdapterRegistry` | 注册与发现；未注册类型抛出 `UnsupportedPanelException` | ≥ 80% |
| `EngineConfigBuilder` | 各协议 + 各路由策略输出配置正确性 | ≥ 70% |
| `OrderUseCase` | 轮询成功/超时/取消分支覆盖 | ≥ 70% |
| `SkinManager` | 合法皮肤加载；合约版本不匹配降级到 default | ≥ 60% |
| `ThemeTokenProvider` | Token 注入后 Widget 颜色（Golden Test） | ≥ 60% |
| `LocaleNotifier` | 语言切换 + 持久化 + 回退 fallback | ≥ 70% |

### 10.2 集成测试（P2 完成后执行，P3 完善后补充）

| 场景 | 优先级 |
|------|--------|
| 注册 → 登录 → 购买套餐 → 订阅拉取 → 连接 → 断开 全链路 | [M] |
| Token 过期 → 自动刷新 → 无感继续使用 | [M] |
| 工单创建 → 客服回复（mock）→ 用户回复 → 关闭 | [M] |
| 优惠码有效/过期/不适用套餐 各分支 | [M] |
| 面板 API 不可达 → 缓存节点降级使用 | [M] |
| 皮肤切换 → 商业页面与连接页面均无功能回归 | [S] |

### 10.3 多平台 Smoke Test（P5 CI 产物验证）

| 平台 | 验证项 |
|------|--------|
| Android | 安装、登录、连接节点、订单购买 |
| Windows | 安装、登录、连接节点、WinTUN 驱动加载 |

---

## 11. 风险与应对（开发视角补充）

| 风险 | 处置策略 |
|------|---------|
| libbox FFI 集成耗时超预期 | P1 最早提测 FFI 绑定（1.32）；可先用 Stub 跑通业务流程后再接真实内核 |
| Xboard 支付 `checkout` 返回 type 多样（webview / qrcode / redirect） | 按 type 分支处理，V1 优先支持 redirect + webview；qrcode 作为 [S] |
| WebView 跳转支付在部分 Android 厂商系统受限 | 同时支持系统浏览器跳转作为降级方案 |
| ARB 文案量大（约 200 Key），翻译工作量超预期 | 可使用机器翻译初稿 + 人工校对；en 基准 Key 先行，zh_CN 随开发逐步补全 |
| sing-box 配置格式随版本变化 | 锁定版本号（`pubspec.yaml`），升级时运行配置映射回归测试 |
| 皮肤合约过度开放 | V1 限定 6 个槽位，合约评审后再扩展 |
| Stripe 支付公钥获取需额外接口 | 按需接入；优先 Alipay / 微信等国内支付方式 |

---

## 12. 工期总览

| 阶段 | 工期（工作周） | 开始条件 | 可并行 |
|------|-------------|---------|--------|
| P1 架构骨架 | 4～5 周 | 立即开始 | — |
| P2 商业闭环 | 5～6 周 | P1 完成 | P3、P4 |
| P3 节点与连接 | 3～4 周 | P1 完成 | P2、P4 |
| P4 皮肤 + 多语言 | 3～4 周 | P1 完成 | P2、P3 |
| P5 CI/CD | 2～3 周 | P1 完成 | P2/P3/P4 |
| P6 第二面板 | 2～3 周 | P3 完成 | — |
| P7 品牌皮肤 | 2 周 | P4 完成 | — |
| **V1 主交付（P1～P5）** | **约 17～22 周** | — | — |

> **实际建议**：P1（串行 4 周）→ P2 + P3 + P4 + P5 并行推进（6～8 周）→ 集成测试 + 修复（2 周）→ P6/P7 可选扩展。

---

## 13. 首个 Sprint 建议（开始工作的第 1～2 周）

> 优先建立能运行的骨架，越快让代码跑起来越好。

1. 搭建 Flutter 项目、配置依赖（任务 1.1～1.2）
2. 创建 `AppConfig` 编译常量（任务 1.3）
3. 封装 Dio + SecureStorage（任务 1.4～1.5）
4. 定义 `PanelAdapter` 接口 + 核心领域模型（任务 1.11～1.16）
5. 实现 `XboardAdapter` 登录 + 用户信息（任务 1.18～1.23）
6. 完成最简登录页 UI，能跑通「登录 → 拿到 Token → 获取用户信息」（任务 1.38）
7. 同步启动 `ci.yml` 基础配置（代码检查 + 测试），让 CI 从第一天开始工作（任务 5.1）
