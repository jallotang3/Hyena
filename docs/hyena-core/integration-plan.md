# HyenaCore 对接方案

> **命名约定**：Flutter 侧引擎目录为 `lib/adapters/engine/hyena/`，`CoreEngine` 实现类为 **`HyenaCoreEngine`**，`engineType` 为 **`hyena`**。原生动态库/框架仍称 **HyenaCore**。上游 Go 工程与 proto 仍来自 **`hiddify-core`** 仓库；`protoc` 生成的 Dart 里若出现 `ChangeHiddifySettings` 等名称，与 **gRPC 协议**一致，勿在生成代码中强行改名。

> **版本库**：`HyenaCore.xcframework`、`*.dylib`、`.aar`、`.dll` 等体积较大的二进制由 **`.gitignore`** 排除，需在本机或 CI 放入 `native/libs/` 对应路径后再构建。

## 1. 背景与现状

### 1.1 库文件现状

| 平台 | 文件 | 接口类型 |
|------|------|----------|
| Android | `native/libs/android/HyenaCore.aar` | gomobile bind → JNI (Java/Kotlin) |
| iOS | `native/libs/ios/HyenaCore.xcframework` | gomobile bind → Objective-C |
| macOS | `native/libs/macos/HyenaCore.dylib` + `desktop.h` | CGo c-shared → C FFI |
| Windows | `native/libs/windows/HyenaCore.dll`（依赖同目录 `libcronet.dll`，构建时由 CMake 复制到 exe 旁） | CGo c-shared → C FFI |

### 1.2 库暴露的两套接口

**桌面平台（macOS/Windows/Linux）— C FFI（`desktop.h`）**

```c
char* setup(char* baseDir, char* workingDir, char* tempDir,
            int mode, char* listen, char* secret,
            long long statusPort, GoUint8 debug);
char* start(char* configPath, GoUint8 disableMemoryLimit);
char* stop(void);
char* restart(char* configPath, GoUint8 disableMemoryLimit);
char* StartCoreGrpcServer(char* listenAddress);
char* GetServerPublicKey(void);
char* AddGrpcClientPublicKey(char* clientPublicKey);
void  closeGrpc(int mode);
void  freeString(char* str);
void  cleanup(void);
```

返回值约定：空字符串 `""` 表示成功，非空字符串为错误信息，调用方必须调用 `freeString` 释放。

**移动平台（Android/iOS）— gomobile bind**

```
// iOS (Objective-C)
MobileSetup(MobileSetupOptions, LibboxPlatformInterface) → error
MobileStart(configPath, configContent) → error
MobileStop() → error
MobilePause() / MobileWake()
MobileGetServerPublicKey() → NSData
MobileAddGrpcClientPublicKey(NSData) → error
MobileClose(mode)
```

Android 侧对应 Java 包 `com.HyenaCore.core`，方法签名相同。

### 1.3 gRPC 服务（桌面/后台模式）

库启动后可选择性地在本地 TCP 端口暴露 gRPC 服务，proto 定义见 `hiddify-core/v2/hcore/hcore_service.proto`：

```protobuf
service Core {
  rpc Start(StartRequest) returns (CoreInfoResponse);
  rpc Stop(Empty) returns (CoreInfoResponse);
  rpc Restart(StartRequest) returns (CoreInfoResponse);
  rpc Setup(SetupRequest) returns (Response);
  rpc GetSystemInfo(Empty) returns (SystemInfo);
  rpc GetSystemInfoStream(Empty) returns (stream SystemInfo);  // 实时流量
  rpc LogListener(LogRequest) returns (stream LogMessage);     // 实时日志
  rpc SelectOutbound(SelectOutboundRequest) returns (Response);
  rpc UrlTest(UrlTestRequest) returns (Response);
  rpc Parse(ParseRequest) returns (ParseResponse);
  rpc Close(CloseRequest) returns (Empty);
}
```

`SetupMode` 枚举：
- `OLD(0)` — 旧模式，无 gRPC，通过 statusPort 回调状态
- `GRPC_NORMAL(1)` — 前台 gRPC + mTLS
- `GRPC_BACKGROUND(2)` — 后台 gRPC + mTLS
- `GRPC_NORMAL_INSECURE(3)` — 前台 gRPC，无 TLS（调试用）
- `GRPC_BACKGROUND_INSECURE(4)` — 后台 gRPC，无 TLS

### 1.4 现有代码问题

当前 `libbox_ffi.dart` 调用的是 **原始 sing-box libbox 符号**（`LibboxSetup`、`LibboxNewService` 等），而 `HyenaCore.dylib` 暴露的是 **上游 Go 工程（hiddify-core）封装后的符号**（`setup`、`start`、`stop` 等）。两套符号完全不同，需要重写 FFI 绑定层。

---

## 2. 目标架构

```
Flutter UI
    │
    ▼
CoreEngine (接口)
    │
    ├── HyenaCoreEngine            ← 新增，替换 SingboxDriver
    │       │
    │       ├── [macOS/Win/Linux]  HyenaCoreDesktopFfi   ← C FFI 直调
    │       └── [Android/iOS]      HyenaCoreMobileBridge  ← MethodChannel（同通道名）
    │
    └── (保留 SingboxDriver 作为 stub/fallback)
```

gRPC 通道（可选，桌面后台模式）：

```
HyenaCoreEngine
    │  setup(mode=GRPC_NORMAL_INSECURE, listen="127.0.0.1:PORT")
    │
    ▼
HyenaCoreGrpcClient   ← grpc.dart 生成的 stub
    │
    ▼
HyenaCore.dylib (gRPC server on localhost:PORT)
```

---

## 3. 分阶段实施计划

### Phase 1 — macOS FFI 直调（最小可用）

**目标**：在 macOS 上用真实库替换 stub，实现 connect/disconnect。

#### 3.1.1 修正 FFI 绑定层

新建 `lib/adapters/engine/hyena/hyena_core_desktop_ffi.dart`，对应 `desktop.h` 的真实符号：

```dart
// 库加载
static ffi.DynamicLibrary _openLibrary() {
  if (Platform.isMacOS) {
    // 优先从 app bundle 旁边加载，开发期从 native/libs/macos 加载
    for (final path in [
      'HyenaCore.dylib',
      'native/libs/macos/HyenaCore.dylib',
    ]) {
      try { return ffi.DynamicLibrary.open(path); } catch (_) {}
    }
    throw Exception('HyenaCore.dylib not found');
  }
  // Windows: HyenaCore.dll（exe 旁或 native/libs/windows/；依赖 libcronet.dll 同目录）
  // Linux:   libHyenaCore.so
}

// setup(baseDir, workingDir, tempDir, mode, listen, secret, statusPort, debug) → char*
typedef _SetupNative = ffi.Pointer<ffi.Char> Function(
    ffi.Pointer<ffi.Char>, ffi.Pointer<ffi.Char>, ffi.Pointer<ffi.Char>,
    ffi.Int32, ffi.Pointer<ffi.Char>, ffi.Pointer<ffi.Char>,
    ffi.Int64, ffi.Uint8);
typedef _SetupDart = ffi.Pointer<ffi.Char> Function(
    ffi.Pointer<ffi.Char>, ffi.Pointer<ffi.Char>, ffi.Pointer<ffi.Char>,
    int, ffi.Pointer<ffi.Char>, ffi.Pointer<ffi.Char>,
    int, int);

// start(configPath, disableMemoryLimit) → char*
// stop() → char*
// restart(configPath, disableMemoryLimit) → char*
// freeString(char*)
```

关键点：
- 所有返回 `char*` 的函数，空字符串 = 成功，非空 = 错误
- 调用后必须 `freeString(ptr)`
- `setup` 的 `mode` 参数：Phase 1 用 `0`（OLD 模式），Phase 2 改为 gRPC 模式

#### 3.1.2 新建 HyenaCoreEngine

新建 `lib/adapters/engine/hyena/hyena_core_engine.dart`，实现 `CoreEngine` 接口：

```dart
class HyenaCoreEngine implements CoreEngine {
  @override String get engineType => 'hyena';

  Future<void> initialize() async {
    // 1. 加载动态库
    // 2. 调用 setup(basePath, workingDir, tempDir, mode=0, "", "", 0, false)
    // 3. 记录版本（暂无 version 符号，可跳过）
  }

  Future<void> connect(ProxyNode node, RoutingMode mode) async {
    // 1. 用 SingboxConfigBuilder 生成 sing-box JSON 配置
    // 2. 写入临时文件 workDir/current.json
    // 3. 调用 start(configPath, false)
    // 4. 检查返回值，非空则抛出异常
  }

  Future<void> disconnect() async {
    // 调用 stop()，检查返回值
  }
}
```

#### 3.1.3 macOS 工程配置

编辑 `macos/Runner/Info.plist`，添加网络权限（TUN 模式需要）。

在 `macos/Runner.xcodeproj` 中将 `HyenaCore.dylib` 加入 "Copy Files" Build Phase，目标为 `Frameworks`。

或者在 `macos/Podfile` 中通过脚本将 dylib 复制到 app bundle：

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    # ...
  end
  # 复制 HyenaCore.dylib 到 app bundle
  system("cp native/libs/macos/HyenaCore.dylib macos/Runner/")
end
```

#### 3.1.4 注册引擎

在 `lib/adapters/engine/registry.dart` 中注册 `HyenaCoreEngine`，替换或并列 `SingboxDriver`。

#### 3.1.5 Windows 工程配置

- **DLL 位置**：`native/libs/windows/HyenaCore.dll`、`libcronet.dll`（Cronet 等依赖，须与主 DLL 同目录）。
- **运行时加载**：`HyenaCoreDesktopFfi` 依次尝试 `HyenaCore.dll`（exe 同目录）、`native/libs/windows/HyenaCore.dll`（源码树开发期）。
- **CMake**：在 `windows/CMakeLists.txt` 的 `install()` 阶段将上述 DLL 复制到 `${INSTALL_BUNDLE_LIB_DIR}`（与 `hyena.exe` 同级），否则仅开发期能从源码路径加载，打包后无法解析依赖。

---

### Phase 2 — gRPC 模式（实时流量 + 日志）

**目标**：切换到 gRPC 通信，获取实时流量统计和日志流。

#### 3.2.1 添加 grpc 依赖

`pubspec.yaml` 新增：

```yaml
grpc: ^4.0.1
protobuf: ^3.1.0
```

#### 3.2.2 生成 Dart gRPC stub

从 `hiddify-core/v2/hcore/hcore_service.proto` 和 `hcore.proto` 生成 Dart 代码：

```bash
protoc \
  --dart_out=grpc:lib/adapters/engine/hyena/proto \
  --proto_path=../hiddify-core \
  v2/hcore/hcore_service.proto v2/hcore/hcore.proto v2/hcommon/common.proto
```

生成文件放入 `lib/adapters/engine/hyena/proto/`。

#### 3.2.3 修改 setup 调用

```dart
// 选择一个随机空闲端口
final port = await _findFreePort();
final listenAddr = '127.0.0.1:$port';

// mode = GRPC_NORMAL_INSECURE(3)，开发期无 TLS 简化调试
// 生产环境改为 GRPC_NORMAL(1) + mTLS
setup(basePath, workingDir, tempDir,
      mode: 3,  // GRPC_NORMAL_INSECURE
      listen: listenAddr,
      secret: '', statusPort: 0, debug: false);
```

#### 3.2.4 建立 gRPC 连接

```dart
final channel = ClientChannel('127.0.0.1', port: port,
    options: ChannelOptions(credentials: ChannelCredentials.insecure()));
final stub = CoreClient(channel);
```

#### 3.2.5 实时流量

```dart
// 替换 _startTrafficPolling() 中的 TODO
Stream<TrafficStats> _trafficStream() async* {
  await for (final info in stub.getSystemInfoStream(Empty())) {
    yield TrafficStats(
      uploadSpeed: info.uplink,
      downloadSpeed: info.downlink,
      uploadBytes: info.uplinkTotal,
      downloadBytes: info.downlinkTotal,
    );
  }
}
```

#### 3.2.6 实时日志

```dart
Stream<String> _logStream() async* {
  await for (final msg in stub.logListener(LogRequest(level: LogLevel.INFO))) {
    yield '[${msg.level.name}] ${msg.message}';
  }
}
```

---

### Phase 3 — Android 对接

**目标**：通过 gomobile bind 生成的 AAR 在 Android 上调用 HyenaCore。

#### 3.3.1 配置 Android 工程

`android/app/build.gradle.kts` 中引入本地 AAR：

```kotlin
dependencies {
    implementation(files("../../native/libs/android/HyenaCore.aar"))
}
```

#### 3.3.2 编写 MethodChannel 插件

新建 `android/app/src/main/kotlin/com/hyena/hyena/HyenaCorePlugin.kt`：

```kotlin
import com.HyenaCore.core.mobile.Mobile
import com.HyenaCore.core.mobile.SetupOptions  // gomobile 生成（Java 类名非 MobileSetupOptions）

class HyenaCorePlugin : MethodCallHandler {
    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "setup" -> {
                val opt = SetupOptions().apply {
                    basePath = call.argument("basePath")
                    workingDir = call.argument("workingDir")
                    tempDir = call.argument("tempDir")
                    mode = call.argument("mode") ?: 0
                    debug = call.argument("debug") ?: false
                }
                try {
                    Mobile.setup(opt, null)
                    result.success(null)
                } catch (e: Exception) {
                    result.error("SETUP_FAILED", e.message, null)
                }
            }
            "start" -> { /* Mobile.start(configPath, configContent) */ }
            "stop"  -> { /* Mobile.stop() */ }
        }
    }
}
```

#### 3.3.3 Flutter 侧移动平台 Bridge（Android / iOS 共用）

新建 `lib/adapters/engine/hyena/hyena_core_mobile_bridge.dart`：

```dart
class HyenaCoreMobileBridge {
  static const _channel = MethodChannel('com.hyena/core');

  static Future<void> setup({...}) =>
      _channel.invokeMethod('setup', {...});

  static Future<void> start({required String configPath, String configContent = ''}) =>
      _channel.invokeMethod('start', {...});

  static Future<void> stop() =>
      _channel.invokeMethod('stop');
}
```

---

### Phase 4 — iOS 对接

**目标**：通过 xcframework 在 iOS 上调用 HyenaCore。

#### 3.4.1 配置 iOS 工程

`ios/Podfile` 的 `Runner` target 中引入本地 pod（与 `native/libs/ios/HyenaCore.podspec` 配套）：

```ruby
target 'Runner' do
  use_frameworks!
  pod 'HyenaCore', :path => '../native/libs/ios'
  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
end
```

或直接在 Xcode 中将 `HyenaCore.xcframework` 拖入 "Frameworks, Libraries, and Embedded Content"。**模拟器 x86_64** 链接 Go 产物时通常需在 Runner 的 `OTHER_LDFLAGS` 增加 `-lresolv`（见工程 `project.pbxproj`）。

#### 3.4.2 编写 Swift MethodChannel 插件

新建 `ios/Runner/HyenaCorePlugin.swift`：

```swift
import HyenaCore  // xcframework

class HyenaCorePlugin: NSObject, FlutterPlugin {
    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "com.hyena/core",
                                           binaryMessenger: registrar.messenger())
        let instance = HyenaCorePlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "setup":
            let args = call.arguments as! [String: Any]
            let opt = MobileSetupOptions()
            opt.basePath = args["basePath"] as? String ?? ""
            opt.workingDir = args["workingDir"] as? String ?? ""
            opt.tempDir = args["tempDir"] as? String ?? ""
            opt.mode = args["mode"] as? Int ?? 0
            var error: NSError?
            MobileSetup(opt, nil, &error)
            if let e = error { result(FlutterError(code: "SETUP_FAILED", message: e.localizedDescription, details: nil)) }
            else { result(nil) }
        case "start":
            // MobileStart(configPath, configContent, &error)
        case "stop":
            // MobileStop(&error)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
```

---

## 4. 文件变更清单

### 新增文件

```
lib/adapters/engine/hyena/
├── hyena_core_engine.dart            # CoreEngine 实现（HyenaCoreEngine）
├── hyena_core_desktop_ffi.dart       # macOS/Win/Linux C FFI 绑定
├── hyena_core_mobile_bridge.dart     # Android + iOS MethodChannel
├── hyena_core_grpc_client.dart       # 桌面 gRPC 客户端
└── proto/                            # protoc 生成的 Dart gRPC stub（字段名与上游 hcore 一致）
    ├── hcore.pb.dart
    ├── hcore.pbenum.dart
    ├── hcore_service.pbgrpc.dart
    └── common.pb.dart

android/app/src/main/kotlin/com/hyena/hyena/
└── HyenaCorePlugin.kt

ios/Runner/
├── HyenaCorePlugin.swift
└── AppDelegate.swift                 # 注册 HyenaCorePlugin
```

### 修改文件

| 文件 | 变更内容 |
|------|----------|
| `lib/adapters/engine/registry.dart` | 注册 `HyenaCoreEngine`，按平台选择实现 |
| `lib/main.dart` | 桌面/移动使用 `HyenaCoreEngine`，其余 `SingboxDriver` |
| `ios/Runner.xcodeproj/project.pbxproj` | `OTHER_LDFLAGS` 含 `-lresolv`；嵌入 HyenaCore 等 |
| `lib/adapters/engine/singbox/libbox_ffi.dart` | 保留作为 stub，不再作为主路径 |
| `android/app/build.gradle.kts` | 引入 HyenaCore.aar |
| `macos/Runner.xcodeproj/project.pbxproj` | 添加 dylib 到 Copy Files |
| `windows/CMakeLists.txt` | `install(FILES … HyenaCore.dll libcronet.dll …)` 复制到 exe 旁 |
| `pubspec.yaml` | 添加 `grpc`、`protobuf` 依赖（Phase 2） |

---

## 5. 关键技术细节

### 5.1 内存管理（桌面 FFI）

所有返回 `char*` 的函数，调用方必须调用 `freeString` 释放，否则内存泄漏：

```dart
final ptr = _setupFn(...);
if (ptr.address != 0) {
  final errMsg = ptr.cast<Utf8>().toDartString();
  _freeStringFn(ptr);
  throw Exception(errMsg);
}
```

### 5.2 工作目录

`setup` 需要三个目录：
- `basePath`：应用资源目录（geoip.db 等规则文件）
- `workingDir`：可写数据目录（数据库、日志）
- `tempDir`：临时文件目录

macOS 建议：
```dart
basePath   = await getApplicationSupportDirectory() → .../Application Support/Hyena
workingDir = basePath + '/data'
tempDir    = Directory.systemTemp.path + '/hyena'
```

### 5.3 配置文件路径 vs 配置内容

- 桌面 FFI：`start(configPath, ...)` 只接受文件路径，需先将 JSON 写入文件
- 移动 gomobile：`MobileStart(configPath, configContent, ...)` 两者都支持，可直接传内容

### 5.4 SetupMode 选择策略

| 场景 | 推荐 Mode |
|------|-----------|
| 开发调试 | `GRPC_NORMAL_INSECURE(3)` |
| 生产前台 | `GRPC_NORMAL(1)` + mTLS |
| 生产后台服务 | `GRPC_BACKGROUND(2)` + mTLS |
| 移动端（无 gRPC 需求） | `OLD(0)` |

mTLS 流程（Mode 1/2）：
1. `setup()` 后调用 `GetServerPublicKey()` 获取服务端公钥
2. 生成客户端证书对，调用 `AddGrpcClientPublicKey(clientPubKey)` 注册
3. gRPC channel 使用双向 TLS

### 5.5 Android VPN Service

Android 上 TUN 模式需要 `VpnService`，gomobile bind 的 `LibboxPlatformInterface` 需要实现：
- `autoDetectInterfaceControl(fd)` — 保护 VPN socket 不被路由
- `findConnectionOwner(...)` — 进程归属查询

Phase 3 初期可传 `null` 跳过 TUN，仅使用 SOCKS/HTTP 代理模式。

### 5.6 iOS Network Extension

iOS TUN 模式需要 Network Extension entitlement，初期同样建议先用代理模式（`MobileStart` 传入仅含 mixed inbound 的配置）。

---

## 6. 验证步骤

### Phase 1 验证（macOS）

```bash
# 1. 确认 dylib 符号
nm -gU native/libs/macos/HyenaCore.dylib | grep -E "^_setup|^_start|^_stop"

# 2. 运行 Flutter macOS
flutter run -d macos

# 3. 检查日志
# 期望看到：HyenaCore setup 成功，start 返回空字符串
```

### Phase 1 验证（Windows）

```powershell
# 1. 确认 DLL 导出（在 Windows 或装有 VS 的环境）
dumpbin /EXPORTS native\libs\windows\HyenaCore.dll | findstr setup

# 2. 运行 Flutter Windows
flutter run -d windows

# 3. 构建输出目录中应存在 hyena.exe、HyenaCore.dll、libcronet.dll 同级
# 期望日志：HyenaCore 加载成功，setup/start 无错误字符串
```

### Phase 2 验证（gRPC）

```bash
# 用 grpcurl 验证本地 gRPC 服务
grpcurl -plaintext 127.0.0.1:PORT hcore.Core/GetSystemInfo
```

### Phase 3 验证（Android）

```bash
flutter run -d android
# adb logcat | grep HyenaCore
```

---

## 7. 风险与注意事项

1. **dylib 签名**：macOS 要求动态库经过代码签名，分发时需用开发者证书重签 `HyenaCore.dylib`。
2. **Windows DLL 与依赖**：`HyenaCore.dll` 已置于 `native/libs/windows/`，通常需同目录附带 `libcronet.dll` 等依赖；发布包须通过 CMake `install` 一并复制到 exe 旁，避免加载失败。
3. **iOS App Store**：xcframework 中的二进制需通过 Apple 审核，确认不含私有 API。
4. **Android 64-bit**：AAR 需包含 `arm64-v8a` 和 `x86_64` slice，确认 `HyenaCore.aar` 内 `jni/` 目录结构完整。
5. **gRPC 端口冲突**：动态选取端口时需处理端口被占用的情况，`hcore` 内部已有 `IsPortInUse` 检查，但 Flutter 侧也需重试逻辑。
6. **后台进程保活**：Android/iOS 后台 VPN 需要系统级权限，Phase 3/4 需要额外的 manifest/entitlement 配置。
7. **Android：Go `tls.ConnectionState` panic（上游构建）**：若 log 中出现  
   `panic: tls: ConnectionState is not equal to tls.ConnectionState: struct field mismatch ... HelloRetryRequest ... vs ... psiphon-tls`，  
   说明 **标准 `crypto/tls` 与 `github.com/Psiphon-Labs/psiphon-tls` 在同一进程内结构体布局冲突**，属于 **HyenaCore / hiddify-core 的 Go 依赖与编译方式问题**，需在 **重新编译 AAR** 时统一 TLS 实现，应用层无法修复。  
   **Flutter 侧临时规避**：默认 **不**在 Android 上启用 `HyenaCoreEngine`（使用 `SingboxDriver` stub），避免启动即调用 `Mobile.setup` 触发崩溃。若你确认 AAR 已修复，构建时加上：  
   `--dart-define=HYENA_CORE_ANDROID=true`  
   对应常量见 `lib/config/app_config.dart` 中的 `enableHyenaCoreAndroid`。
