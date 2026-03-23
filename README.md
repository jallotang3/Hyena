# Hyena

<div align="center">

**多面板可插拔 VPN 客户端**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue.svg)](https://flutter.dev/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Android%20%7C%20Windows%20%7C%20macOS%20%7C%20iOS-lightgrey.svg)](https://github.com/yourusername/hyena)

[English](README.md) | [简体中文](README_zh.md)

</div>

---

## 📖 Overview

Hyena is a **multi-panel pluggable VPN client** designed for SaaS operations, featuring:

- 🔌 **Multi-Panel Support**: Unified adapter for xboard, v2board, sspanel, and more
- 🎨 **Brandable Skins**: Customize UI without touching business logic
- 🚀 **Pluggable Engine**: sing-box by default, easily swap or run multiple engines
- 🤖 **Automated Delivery**: CI/CD templates for one-click branded builds

## ✨ Features

### Core Capabilities

- **Panel Adapters**
  - ✅ Xboard (full support)
  - ✅ V2board (full support)
  - 🔄 SSPanel (planned)
  - Zero-invasion architecture for adding new panels

- **Protocol Support**
  - VLESS / VMess / Shadowsocks / Trojan / Hysteria2
  - Automatic node parsing from subscription URLs
  - Latency testing and smart node selection

- **Business Features**
  - Complete purchase flow: plans → orders → payment
  - Ticket system for customer support
  - Invite & commission tracking
  - Traffic statistics and visualization
  - Multi-language support (English, 简体中文)

- **Connection Management**
  - One-tap connect/disconnect
  - Routing mode switching (global/rules/direct)
  - Auto-reconnect with retry logic
  - Real-time traffic monitoring
  - Connection duration tracking

### Developer Experience

- **Clean Architecture**
  - Controller/View separation
  - Domain-driven design
  - Dependency injection with Provider
  - Type-safe routing

- **Skin System**
  - Theme token abstraction
  - Page-level customization via SkinPageFactory
  - Brand X example skin included

- **CI/CD Ready**
  - GitHub Actions workflows
  - Parameterized builds for multiple brands
  - Automated release pipeline

## 🚀 Quick Start

### Prerequisites

- Flutter 3.x
- Dart 3.x
- Android Studio / Xcode (for mobile platforms)
- Visual Studio 2022 (for Windows)

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/hyena.git
cd hyena

# Install dependencies
flutter pub get

# Generate localization files
flutter gen-l10n

# Run the app (development mode)
flutter run \
  --dart-define=PANEL_API_BASE=https://panel.example.com \
  --dart-define=PANEL_TYPE=xboard \
  --dart-define=SITE_ID=dev \
  --dart-define=SITE_NAME=HyenaVPN
```

### Build for Production

```bash
# Android APK
flutter build apk \
  --dart-define=PANEL_API_BASE=https://panel.example.com \
  --dart-define=PANEL_TYPE=xboard \
  --dart-define=SITE_ID=prod \
  --dart-define=SITE_NAME=YourBrand \
  --dart-define=SKIN_ID=default

# Windows
flutter build windows \
  --dart-define=PANEL_API_BASE=https://panel.example.com \
  --dart-define=PANEL_TYPE=xboard \
  --dart-define=SITE_ID=prod \
  --dart-define=SITE_NAME=YourBrand
```

## 📚 Documentation

- [Requirements Analysis](docs/requirements-analysis.md)
- [System Design](docs/system-design.md)
- [Development Plan](docs/development-plan.md)
- [Progress Tracking](docs/progress.md)
- [Skin Contract](docs/skin-contract.md)
- [Panel Adapter Development Guide](docs/guides/panel-adapter-development.md)

## 🏗️ Architecture

```
┌─────────────────────────────────────────┐
│  View Layer (Skin-replaceable)         │
│  ↓ Only accesses Controller API         │
├─────────────────────────────────────────┤
│  Controller Layer (Fixed API)           │
│  HomeController │ NodeController │ ...  │
│  ↓ Orchestrates UseCases                │
├─────────────────────────────────────────┤
│  Application Layer                      │
│  AuthUseCase │ NodeUseCase │ ...        │
│  ↓ Depends on abstractions              │
├─────────────────────────────────────────┤
│  Domain Layer                           │
│  PanelAdapter │ CoreEngine (interfaces) │
├─────────────────────────────────────────┤
│  Infrastructure Layer                   │
│  XboardAdapter │ V2boardAdapter         │
│  SingboxDriver │ Network │ Storage      │
└─────────────────────────────────────────┘
```

**Key Principles**:
- Business logic depends on abstractions, not implementations
- New panels/engines/skins added without modifying existing code
- UI layer completely decoupled from data sources

## 🎨 Customization

### Adding a New Panel Adapter

See [Panel Adapter Development Guide](docs/guides/panel-adapter-development.md) for detailed instructions.

```dart
// 1. Implement PanelAdapter interface
class YourPanelAdapter implements PanelAdapter {
  @override
  String get panelType => 'your_panel';
  
  // Implement all required methods...
}

// 2. Register in main.dart
void main() {
  final registry = PanelAdapterRegistry.instance;
  registry.register(YourPanelAdapter());
  // ...
}
```

### Creating a Custom Skin

```dart
// 1. Define theme tokens
const kYourSkinTokens = ThemeTokens(
  colorPrimary: Color(0xFF6366F1),
  colorBackground: Color(0xFF0F172A),
  // ... other tokens
);

// 2. Create page factory (optional)
class YourSkinPageFactory implements SkinPageFactory {
  @override
  Widget? buildHomePage(HomeController controller) {
    return YourCustomHomePage(controller: controller);
  }
  // ... other pages
}

// 3. Register skin
await SkinManager.instance.load('your_skin');
```

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/adapters/panel/xboard/node_normalizer_test.dart
```

**Current Test Coverage**:
- SkinManager: 8 test cases ✅
- NodeNormalizer: 11 test cases ✅
- Total: 19 test cases passing

## 🤝 Contributing

Contributions are welcome! Please read our [Contributing Guide](CONTRIBUTING.md) before submitting PRs.

### Development Workflow

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'feat: add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Standards

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Run `flutter analyze` and `dart format` before committing
- Write tests for new features
- Update documentation as needed

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [sing-box](https://github.com/SagerNet/sing-box) - Core proxy engine
- [Xboard](https://github.com/cedar2025/Xboard) - Panel reference implementation
- [V2board](https://github.com/v2board/v2board) - Panel reference implementation
- [MagicLamp](https://github.com/yourusername/MagicLamp) - libbox integration reference

## 📧 Contact

- Issues: [GitHub Issues](https://github.com/yourusername/hyena/issues)
- Discussions: [GitHub Discussions](https://github.com/yourusername/hyena/discussions)

---

<div align="center">
Made with ❤️ by the Hyena Team
</div>
