# Hyena

<div align="center">

**多面板可插拔 VPN 客户端**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue.svg)](https://flutter.dev/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS%20%7C%20Windows%20%7C%20macOS%20%7C%20Linux-lightgrey.svg)](https://github.com/jallotang3/Hyena)

[English](README.md) | [简体中文](README_zh.md)

</div>

---

## 概述

Hyena 面向 **多面板、可品牌化** 的 VPN 客户端场景：

- **面板适配**：已支持 Xboard、V2board，可扩展更多面板
- **皮肤系统**：换肤不改业务逻辑
- **内核**：默认使用 **HyenaCore**（`HyenaCoreEngine`，`engineType` 为 `hyena`）——桌面 FFI、移动端 MethodChannel、桌面可选 gRPC 流量/日志；无原生库时回退 **`SingboxDriver`** 占位
- **构建**：通过 `--dart-define` 注入面板地址、站点、皮肤等

## 功能概览

### 面板与协议

- **适配器**：Xboard、V2board 完整对接；SSPanel 等可插拔
- **协议**：VLESS / VMess / Shadowsocks / Trojan / Hysteria2（经 sing-box JSON）
- **体验**：延迟测试、节点切换、多语言（含简体中文）

### 业务功能（典型 SaaS）

- 套餐 → 订单 → 支付
- 工单、邀请、流量展示
- 通过 `AppConfig` / `--dart-define` 配置站点信息

### 连接与内核（当前实现）

| 层级 | 说明 |
|------|------|
| **HyenaCoreEngine** | 在 **Android / iOS / Windows / macOS / Linux** 上，原生 **HyenaCore** 可用时作为默认引擎 |
| **桌面** | 动态库 + C FFI（`HyenaCoreDesktopFfi`），可选用 **gRPC**（`HyenaCoreGrpcClient`）拉取实时流量与日志 |
| **移动端** | **MethodChannel** `com.hyena/core` → Kotlin / Swift 插件调用 gomobile 接口 |
| **回退** | 无库或初始化失败时使用 **SingboxDriver** 模拟（例如 Web 或调试） |

详细符号、目录与分阶段说明见 **[HyenaCore 对接方案](docs/hyena-core/integration-plan.md)**。

### 原生二进制与仓库

体积较大的产物（**`.aar`、`.dll`、`.dylib`、`HyenaCore.xcframework`** 等）受 **GitHub 体积限制**，已通过 **`.gitignore`** 排除。克隆后请按集成文档将文件放到 `native/libs/` 对应路径再编译；仓库中可保留头文件、`HyenaCore.podspec` 等轻量引用文件。

### 开发体验

- 分层：控制器 → 用例 → 适配器 / `CoreEngine`
- 状态：Provider；路由：go_router
- 皮肤：`SkinManager`、`SkinPageFactory`；移动端壳层与底部导航等

## 快速开始

### 环境要求

- Flutter 3.x / Dart 3.x
- Android Studio / Xcode（移动端）
- Visual Studio 2022（Windows 桌面）
- 按文档准备 **HyenaCore** 各平台库文件

### 运行（开发）

```bash
git clone https://github.com/jallotang3/Hyena.git
cd Hyena
flutter pub get
flutter gen-l10n

flutter run \
  --dart-define=PANEL_API_BASE=https://panel.example.com \
  --dart-define=PANEL_TYPE=xboard \
  --dart-define=SITE_ID=dev \
  --dart-define=SITE_NAME=HyenaVPN
```

### Android 与 HyenaCore AAR

若 HyenaCore 的 AAR 在启动时因 Go TLS 依赖冲突崩溃（见 `docs/hyena-core/integration-plan.md` §7），默认 **不**启用原生引擎；确认 AAR 可用后再加：

`--dart-define=HYENA_CORE_ANDROID=true`

### 发布构建（示例）

```bash
flutter build apk \
  --dart-define=PANEL_API_BASE=https://panel.example.com \
  --dart-define=PANEL_TYPE=xboard \
  --dart-define=SITE_ID=prod \
  --dart-define=SITE_NAME=YourBrand \
  --dart-define=SKIN_ID=default
```

## 文档索引

- [需求分析](docs/requirements-analysis.md)
- [系统设计](docs/system-design.md)
- [开发计划](docs/development-plan.md)
- [进度](docs/progress.md)
- [皮肤契约](docs/skin-contract.md)
- **[HyenaCore 对接](docs/hyena-core/integration-plan.md)**
- [面板适配开发指南](docs/guides/panel-adapter-development.md)

## 架构简图

```
┌─────────────────────────────────────────┐
│  UI（皮肤 / 移动端壳层）               │
├─────────────────────────────────────────┤
│  Controller 层                          │
├─────────────────────────────────────────┤
│  用例层（登录、节点、连接等）            │
├─────────────────────────────────────────┤
│  领域：PanelAdapter │ CoreEngine        │
├─────────────────────────────────────────┤
│  基础设施：Xboard/V2board │ HyenaCoreEngine│
│            SingboxDriver（占位）│ 存储   │
└─────────────────────────────────────────┘
```

## 定制扩展

### 新面板

见 [面板适配开发指南](docs/guides/panel-adapter-development.md)。

### 新皮肤

通过 `SkinManager` 与可选的 `SkinPageFactory` 注册，详见 [皮肤契约](docs/skin-contract.md)。

## 测试

```bash
flutter test
flutter test --coverage
```

## 参与贡献

1. Fork → 功能分支 → 提交 PR  
2. 提交前执行 `flutter analyze`、`dart format`  
3. 行为变更请补充测试  

## 许可证

MIT，见 [LICENSE](LICENSE)。

## 致谢

- [sing-box](https://github.com/SagerNet/sing-box)
- [Xboard](https://github.com/cedar2025/Xboard)、[V2board](https://github.com/v2board/v2board)
- HyenaCore 绑定思路与上游 **hiddify-core** 生态一致（详见对接文档）

## 链接

- 问题反馈：[github.com/jallotang3/Hyena/issues](https://github.com/jallotang3/Hyena/issues)

---

<div align="center">
Hyena 团队
</div>
