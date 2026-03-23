# Changelog

All notable changes to the Hyena project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- V2board panel adapter with full API support
- Panel adapter development guide documentation
- NodeNormalizer unit tests (11 test cases)
- SkinManager unit tests (8 test cases)
- Brand X example skin demonstrating customization capabilities

### Changed
- Updated progress documentation to reflect P6 completion
- Enhanced error handling in panel adapters

### Fixed
- Color value precision issue in skin manager tests

## [0.1.0] - 2026-03-20

### Added - Phase 1-5 (V1 Core Delivery)

#### Phase 1: Architecture Foundation
- Flutter project initialization with complete dependency configuration
- Multi-language support (en, zh_CN, zh) with ARB files
- Core infrastructure: DioClient, SecureStorage, CacheStorage, AppLogger
- Domain layer interfaces: PanelAdapter, CoreEngine
- XboardAdapter with full authentication and subscription support
- SingboxDriver with stub mode for UI development
- SkinManager framework with ThemeTokenProvider
- Default skin with "Terminal Minimal" dark theme

#### Phase 2: Business Loop
- Complete Xboard API integration (47 methods)
- Store module: plan listing, order creation, payment flow
- Order center: order history, detail view, status tracking
- Ticket system: create, reply, close tickets
- User profile: account info, subscription details, settings
- Invite system: invite codes, commission tracking
- Settings page with language switching
- Hive cache layer for offline support

#### Phase 3: Node Management & Connection
- Node latency testing (single and batch)
- Node sorting (by name, latency, group)
- Routing mode hot-switching (global/rules/direct)
- Auto-connect on startup
- Real-time traffic rate display
- Connection duration tracking
- Log collection with file rotation
- Traffic chart visualization
- Auto-reconnect with retry logic

#### Phase 4: Controller/View Separation
- 13 ScreenControllers extracted from business logic
- SkinPageFactory framework for page-level customization
- Complete i18n coverage (180+ keys in en/zh_CN)
- Skin contract documentation (v1.1)
- Controller API documentation for UI designers
- All screens refactored to use Controllers only

#### Phase 5: CI/CD Pipeline
- GitHub Actions CI workflow (analyze, format, test)
- Parameterized build workflow for Android and Windows
- Brand parameter injection via dart-define
- Android signing configuration with R8 obfuscation
- Release workflow with automatic changelog generation
- Build artifact archiving (14-day retention)

### Technical Highlights
- Zero-invasion multi-panel architecture
- Pluggable engine system (sing-box default)
- Skin system with theme token abstraction
- Comprehensive error handling and logging
- Offline-first with cache fallback
- Type-safe routing with go_router

### Supported Panels
- Xboard (full support)
- V2board (full support)

### Supported Protocols
- VLESS
- VMess
- Shadowsocks
- Trojan
- Hysteria2

### Platforms
- Android (API 21+)
- Windows (10 1903+)
- macOS (planned)
- iOS (planned)

## [0.0.1] - 2026-03-01

### Added
- Initial project setup
- Basic project structure
