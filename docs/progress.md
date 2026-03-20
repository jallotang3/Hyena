# Hyena — 开发进度记录

> 最后更新：2026-03-20

## 当前状态：P2 商业闭环完成，P3 待开始

---

## Phase 1 · 架构骨架（已完成）

### P1-1 ✅ Flutter 项目初始化

- `pubspec.yaml` 全量依赖配置（dio / provider / go_router / flutter_secure_storage / hive_flutter / ffi / intl / flutter_localizations ...）
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
│   ├── storage/        # AppPreferences + SecureStorage
│   └── logging/        # AppLogger（脱敏 + 结构化日志）
├── adapters/
│   ├── panel/          # PanelAdapterRegistry + XboardAdapter + NodeNormalizer
│   └── engine/         # EngineRegistry + SingboxDriver + LibboxFfi + ConfigBuilder
├── features/
│   ├── auth/           # AuthUseCase + AuthNotifier
│   ├── connection/     # ConnectionUseCase + ConnectionNotifier
│   └── [其他业务模块]  # 占位，P2 实现
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
| `lib/infrastructure/storage/preferences.dart` | SharedPreferences 封装（locale / node / routing / favorites / skin） |
| `lib/infrastructure/storage/secure_storage.dart` | flutter_secure_storage（auth_data / email） |
| `lib/infrastructure/logging/app_logger.dart` | 结构化日志，含脱敏（Token/邮箱/私有IP） |

### P1-3 ✅ 领域层接口 + 实体模型

**领域模型：**
- `PanelSite` — 站点（build-time 注入，用户不可修改）
- `PanelUser` — 用户信息统一模型
- `ProxyNode` — 节点统一模型（protocol / address / port / extra）
- `TrafficStats` — 实时流量统计
- `EngineState` / `RoutingMode` — 连接状态与路由模式枚举
- `PlanItem / Order / PaymentMethod / Ticket / InviteSummary / Notice / KnowledgeArticle` 等商业领域模型

**核心接口：**
- `PanelAdapter` — 47 个 API 方法的完整抽象（认证 / 用户 / 套餐 / 订单 / 工单 / 邀请 / 公告 / 知识库 / 流量统计）
- `CoreEngine` — 内核驱动抽象（connect / disconnect / switchRoutingMode / stateStream / trafficStream）

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
- `SingboxConfigBuilder` — 将 `ProxyNode + RoutingMode` 转换为 sing-box JSON 配置（支持 ss/vmess/vless/trojan/hy2 + WS/gRPC/H2 传输层）

**libbox 工作目录（参考 MagicLamp）：**
| 平台 | 路径 |
|------|------|
| Windows | `%LOCALAPPDATA%\Hyena` |
| macOS | `~/Library/Application Support/Hyena` |
| Android/iOS | ApplicationDocumentsDirectory |
| Linux | `~/.config/hyena` |

### P1-6 ✅ 最小 UI（Splash / Login / Home）

- `SplashScreen` — 启动动画 + 自动会话恢复（go → /home 或 /login）
- `LoginScreen` — 表单校验 + 错误提示 + 加载态
- `RegisterScreen` — 邮件验证码 + 邀请码（可选）
- `ForgotPasswordScreen` — 重置密码
- `HomeScreen` — 连接按钮（圆形状态指示）+ 实时流量卡片 + 当前节点卡片 + 路由模式选择 + 底部导航栏（4 Tab）

**P2 页面（占位路由）：** `/nodes / /store / /orders / /tickets / /profile / /invite / /settings / /diagnostics`

### P1-7 ✅ SkinManager 骨架 + default skin 令牌

- `ThemeTokens` — 10 个颜色令牌 + 3 个圆角令牌
- `ThemeTokenProvider` — InheritedWidget，`tokensOf(context)` 全局读取，`toMaterialTheme()` 生成 MaterialTheme
- Default Skin — "Terminal Minimal" 深色：Primary Cyan `#22D3EE`，背景 `#0A0F1C`，可扩展为多品牌皮肤

---

## Phase 2 · 商业闭环（待开始）

### 待实现
- [ ] 节点列表页（NodeListScreen）— 搜索 / 过滤 / 排序 / 收藏 / 延迟测速
- [ ] 商店页（StoreScreen）— 套餐选择（订阅/流量包 Tab）+ 支付方式 + 立即支付
- [ ] 订单中心（OrderCenterScreen）— 列表 / 详情 / 支付轮询 / 取消
- [ ] 工单系统（TicketListScreen / TicketDetailScreen / NewTicketScreen）
- [ ] 个人中心（ProfileScreen）— 流量概览 + 快速入口
- [ ] 邀请返佣（InviteScreen）— 邀请链接 + 佣金统计 + 提现
- [ ] 优惠码 / 礼品卡兑换

### 需要引入的包
- `webview_flutter` — 支付 WebView（已在 pubspec 中）
- 支付状态轮询（1s x 30 次）

---

## Phase 3–7（规划中）

详见 `docs/development-plan.md`

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

---

## Phase 2 · 商业闭环（已完成）

### P2-0 ✅ Hive 缓存层
- `CacheStorage` 单例：节点（1h TTL）/ 用户（5min）/ 套餐（2h）缓存
- `main.dart` 集成初始化

### P2-1 ✅ 节点模块
- `NodeUseCase`：fetchNodes（带缓存回落）、收藏管理
- `NodeNotifier`：ChangeNotifier，支持搜索过滤 + 分组
- `NodeListScreen`：Tab（全部 / 收藏）+ 搜索栏 + 分组列表 + 延迟显示

### P2-2 ✅ 商店
- `StoreUseCase`：fetchPlans / createOrder / checkout / checkCoupon
- `StoreScreen`：套餐卡片（周期选择 / 价格 / 流量标签）+ 下单确认弹窗

### P2-3 ✅ 订单中心
- `OrderUseCase`：fetchOrders / cancelOrder
- `OrderCenterScreen`：订单卡片（状态色 / 取消二次确认）

### P2-4 ✅ 工单系统
- `TicketUseCase`：fetch / detail / create / reply / close
- `TicketListScreen`：新建弹窗（主题 / 优先级 / 内容）
- `TicketDetailScreen`：气泡对话 UI + 回复输入框 + 关闭按钮

### P2-5 ✅ 个人中心
- `ProfileUseCase`：fetchUser（缓存）/ fetchTrafficLogs / changePassword
- `ProfileScreen`：头像 / 流量进度条 / 余额卡片 / 菜单列表

### P2-6 ✅ 邀请返佣
- `InviteUseCase`：fetchInviteSummary / generateInviteCode
- `InviteScreen`：统计卡 + 邀请码列表（一键复制）

### P2-7 ✅ 设置页 + 语言切换
- `LocaleNotifier`：运行时语言切换，持久化到 AppPreferences
- `SettingsScreen`：语言选择 + 版本信息
- `app.dart`：`Consumer2<AuthNotifier, LocaleNotifier>` 注入 `locale`

### P2-8 ✅ AppRouter 补全
- 所有占位路由替换为真实页面
- HomeScreen 连接按钮：无节点 → 跳转 `/nodes`；有节点 → 直接连接
- HomeScreen 重构为使用 `ConnectionNotifier`（代替 UseCase 直接调用）

---

## 已知问题 / 技术债

| 编号 | 描述 | 优先级 | 计划解决阶段 |
|------|------|--------|-------------|
| TD-03 | TrafficPolling 目前仅做 Stub，P3 接 sing-box 流量 Stream | 中 | P3 |
| TD-06 | 支付宝 / 微信支付 URL 目前仅 SnackBar 显示，P3 接 WebView/URL launcher | 高 | P3 |
| TD-07 | XboardAdapter 未实现全部方法（`fetchUserInfo`/`fetchNodes` 等），P3 补全 | 高 | P3 |
| TD-08 | NodeListScreen 节点延迟测速（Ping）未实现 | 中 | P3 |
| TD-09 | ProfileScreen 流量日志页面未完成 | 低 | P3 |
| TD-10 | 桌面端 tray_manager / window_manager 集成未实现 | 中 | P4 |
