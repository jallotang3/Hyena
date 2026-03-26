# Hyena

<div align="center">

**Multi-panel pluggable VPN client**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue.svg)](https://flutter.dev/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS%20%7C%20Windows%20%7C%20macOS%20%7C%20Linux-lightgrey.svg)](https://github.com/jallotang3/Hyena)

[English](README.md) | [简体中文](README_zh.md)

</div>

---

## Overview

Hyena is a **multi-panel pluggable VPN client** for SaaS-style operations:

- **Panel adapters**: Xboard, V2board (extensible)
- **Skins**: brandable UI without changing business logic
- **Core engine**: **HyenaCore** integration (desktop FFI + mobile MethodChannel + optional local gRPC for stats/logs); `SingboxDriver` remains as stub/fallback where no native library is available
- **CI/CD**: templates for branded builds (`--dart-define` panel/site/skin)

## Features

### Panels & protocols

- **Adapters**: Xboard and V2board (full); SSPanel planned; add panels via `PanelAdapter` + registry
- **Protocols**: VLESS / VMess / Shadowsocks / Trojan / Hysteria2 (via sing-box JSON from subscription)
- **UX**: latency tests, node selection, multi-language (English, 简体中文)

### Business (typical SaaS flows)

- Plans → orders → payment
- Tickets, invites, traffic charts
- Configurable via `AppConfig` / `--dart-define`

### Connection stack (current)

| Layer | Notes |
|--------|--------|
| **HyenaCoreEngine** (`engineType: hyena`) | Default on **Android, iOS, Windows, macOS, Linux** when native **HyenaCore** is present |
| Desktop | Dynamic library + C FFI (`HyenaCoreDesktopFfi`), optional **gRPC** (`HyenaCoreGrpcClient`) for live traffic & logs |
| Mobile | **MethodChannel** `com.hyena/core` → Kotlin (`HyenaCorePlugin`) / Swift (`HyenaCorePlugin`) |
| Fallback | **SingboxDriver** stub (e.g. web or if native load/setup fails) |

See **[HyenaCore integration plan](docs/hyena-core/integration-plan.md)** for symbols, phases, and platform notes.

### Native binaries (not in Git)

Large artifacts (**`.aar`**, **`.dll`**, **`.dylib`**, **`HyenaCore.xcframework`**, etc.) are **gitignored** (GitHub file-size limits). Place them under `native/libs/` according to the integration doc before building. Headers and `HyenaCore.podspec` may be tracked for reference.

### Developer experience

- Layered architecture: controllers → use cases → adapters / `CoreEngine`
- Provider for DI; `go_router` for navigation
- Skin system: `SkinManager`, `SkinPageFactory`, mobile shell & bottom nav

## Quick start

### Prerequisites

- Flutter 3.x / Dart 3.x
- Android Studio / Xcode (mobile)
- Visual Studio 2022 (Windows desktop)
- **HyenaCore** native libraries copied into `native/libs/` (see integration plan)

### Run (development)

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

**Android + HyenaCore AAR**: the app defaults to **not** loading `HyenaCoreEngine` on Android (uses `SingboxDriver` stub) to avoid a known native **Go TLS / psiphon-tls** crash at startup. After you have a fixed AAR, add `--dart-define=HYENA_CORE_ANDROID=true`. See [integration plan §7](docs/hyena-core/integration-plan.md).

### Production build (example)

```bash
flutter build apk \
  --dart-define=PANEL_API_BASE=https://panel.example.com \
  --dart-define=PANEL_TYPE=xboard \
  --dart-define=SITE_ID=prod \
  --dart-define=SITE_NAME=YourBrand \
  --dart-define=SKIN_ID=default
```

## Documentation

- [Requirements analysis](docs/requirements-analysis.md)
- [System design](docs/system-design.md)
- [Development plan](docs/development-plan.md)
- [Progress](docs/progress.md)
- [Skin contract](docs/skin-contract.md)
- [HyenaCore integration](docs/hyena-core/integration-plan.md)
- [Panel adapter guide](docs/guides/panel-adapter-development.md)

## Architecture (simplified)

```
┌─────────────────────────────────────────┐
│  UI (skins / mobile shell)              │
├─────────────────────────────────────────┤
│  Controllers                            │
├─────────────────────────────────────────┤
│  Use cases (auth, nodes, connection…)    │
├─────────────────────────────────────────┤
│  Domain: PanelAdapter │ CoreEngine      │
├─────────────────────────────────────────┤
│  Infra: Xboard/V2board │ HyenaCoreEngine│
│         SingboxDriver (stub) │ storage   │
└─────────────────────────────────────────┘
```

## Customization

### New panel adapter

See [Panel adapter development](docs/guides/panel-adapter-development.md).

### New skin

Register via `SkinManager` and optional `SkinPageFactory` (see [skin contract](docs/skin-contract.md)).

## Testing

```bash
flutter test
flutter test --coverage
```

## Contributing

1. Fork → feature branch → PR  
2. Run `flutter analyze` / `dart format`  
3. Add tests when behavior changes  

## License

MIT — see [LICENSE](LICENSE).

## Acknowledgments

- [sing-box](https://github.com/SagerNet/sing-box)
- [Xboard](https://github.com/cedar2025/Xboard), [V2board](https://github.com/v2board/v2board)
- HyenaCore builds on upstream **hiddify-core**-style mobile/desktop bindings (see integration doc)

## Links

- Issues: [github.com/jallotang3/Hyena/issues](https://github.com/jallotang3/Hyena/issues)

---

<div align="center">
Made with care by the Hyena team
</div>
