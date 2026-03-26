import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:ffi/ffi.dart';
import '../../../infrastructure/logging/app_logger.dart';

// ── Native 函数签名 ────────────────────────────────────────────────────────

typedef _SetupNative = ffi.Pointer<ffi.Char> Function(
    ffi.Pointer<ffi.Char>, // baseDir
    ffi.Pointer<ffi.Char>, // workingDir
    ffi.Pointer<ffi.Char>, // tempDir
    ffi.Int32, // mode
    ffi.Pointer<ffi.Char>, // listen
    ffi.Pointer<ffi.Char>, // secret
    ffi.Int64, // statusPort
    ffi.Uint8); // debug
typedef _SetupDart = ffi.Pointer<ffi.Char> Function(
    ffi.Pointer<ffi.Char>,
    ffi.Pointer<ffi.Char>,
    ffi.Pointer<ffi.Char>,
    int,
    ffi.Pointer<ffi.Char>,
    ffi.Pointer<ffi.Char>,
    int,
    int);

typedef _StartNative = ffi.Pointer<ffi.Char> Function(
    ffi.Pointer<ffi.Char>, ffi.Uint8);
typedef _StartDart = ffi.Pointer<ffi.Char> Function(
    ffi.Pointer<ffi.Char>, int);

typedef _StopNative = ffi.Pointer<ffi.Char> Function();
typedef _StopDart = ffi.Pointer<ffi.Char> Function();

typedef _RestartNative = ffi.Pointer<ffi.Char> Function(
    ffi.Pointer<ffi.Char>, ffi.Uint8);
typedef _RestartDart = ffi.Pointer<ffi.Char> Function(
    ffi.Pointer<ffi.Char>, int);

typedef _FreeStringNative = ffi.Void Function(ffi.Pointer<ffi.Char>);
typedef _FreeStringDart = void Function(ffi.Pointer<ffi.Char>);

typedef _StartGrpcNative = ffi.Pointer<ffi.Char> Function(
    ffi.Pointer<ffi.Char>);
typedef _StartGrpcDart = ffi.Pointer<ffi.Char> Function(
    ffi.Pointer<ffi.Char>);

typedef _GetServerPublicKeyNative = ffi.Pointer<ffi.Char> Function();
typedef _GetServerPublicKeyDart = ffi.Pointer<ffi.Char> Function();

typedef _AddGrpcClientPublicKeyNative = ffi.Pointer<ffi.Char> Function(
    ffi.Pointer<ffi.Char>);
typedef _AddGrpcClientPublicKeyDart = ffi.Pointer<ffi.Char> Function(
    ffi.Pointer<ffi.Char>);

typedef _CloseGrpcNative = ffi.Void Function(ffi.Int32);
typedef _CloseGrpcDart = void Function(int);

typedef _CleanupNative = ffi.Void Function();
typedef _CleanupDart = void Function();

// ── FFI 绑定层 ─────────────────────────────────────────────────────────────

/// HyenaCore 桌面平台 C FFI 绑定
/// 对应 desktop.h 中导出的符号（CGo c-shared 构建产物）
class HyenaCoreDesktopFfi {
  static ffi.DynamicLibrary? _lib;

  static bool get isLoaded => _lib != null;

  static Future<bool> load() async {
    if (_lib != null) return true;
    try {
      _lib = _openLibrary();
      AppLogger.i('HyenaCore 加载成功', tag: LogTag.vpn);
      return true;
    } catch (e) {
      AppLogger.e('HyenaCore 加载失败: $e', tag: LogTag.vpn);
      return false;
    }
  }

  static ffi.DynamicLibrary _openLibrary() {
    if (Platform.isMacOS) {
      // 优先从 app bundle 同级目录加载（打包后），其次从源码 native/libs 加载（开发期）
      for (final path in [
        'HyenaCore.dylib',
        'native/libs/macos/HyenaCore.dylib',
      ]) {
        try {
          return ffi.DynamicLibrary.open(path);
        } catch (_) {}
      }
      throw Exception(
          'HyenaCore.dylib not found. Place it next to the app or in native/libs/macos/');
    } else if (Platform.isWindows) {
      for (final name in [
        'HyenaCore.dll',
        r'native\libs\windows\HyenaCore.dll',
        'native/libs/windows/HyenaCore.dll',
        r'native\libs\windows\x64\HyenaCore.dll',
        'native/libs/windows/x64/HyenaCore.dll',
      ]) {
        try {
          return ffi.DynamicLibrary.open(name);
        } catch (_) {}
      }
      throw Exception(
          'HyenaCore.dll not found. Place it next to hyena.exe or in native/libs/windows/');
    } else if (Platform.isLinux) {
      for (final name in ['libHyenaCore.so', 'native/libs/linux/libHyenaCore.so']) {
        try {
          return ffi.DynamicLibrary.open(name);
        } catch (_) {}
      }
      throw Exception('libHyenaCore.so not found.');
    }
    throw UnsupportedError('Unsupported desktop platform: ${Platform.operatingSystem}');
  }

  static void _ensureLoaded() {
    if (_lib == null) {
      throw StateError('HyenaCore not loaded. Call HyenaCoreDesktopFfi.load() first.');
    }
  }

  // ── 辅助：释放 C 字符串 ──────────────────────────────────────────────────

  static _FreeStringDart get _freeString =>
      _lib!.lookupFunction<_FreeStringNative, _FreeStringDart>('freeString');

  /// 将 char* 转为 Dart String 并释放，返回 null 表示成功（空字符串）
  static String? _consumeResult(ffi.Pointer<ffi.Char> ptr) {
    if (ptr.address == 0) return null;
    final str = ptr.cast<Utf8>().toDartString();
    _freeString(ptr);
    return str.isEmpty ? null : str;
  }

  // ── 核心 API ─────────────────────────────────────────────────────────────

  /// 初始化 HyenaCore 工作目录与运行模式
  ///
  /// [mode] 参见 SetupMode：0=OLD, 1=GRPC_NORMAL, 3=GRPC_NORMAL_INSECURE
  /// 返回 null 表示成功，非 null 为错误信息
  static String? setup({
    required String baseDir,
    required String workingDir,
    required String tempDir,
    int mode = 0,
    String listen = '',
    String secret = '',
    int statusPort = 0,
    bool debug = false,
  }) {
    _ensureLoaded();
    final fn = _lib!.lookupFunction<_SetupNative, _SetupDart>('setup');
    final b = baseDir.toNativeUtf8();
    final w = workingDir.toNativeUtf8();
    final t = tempDir.toNativeUtf8();
    final l = listen.toNativeUtf8();
    final s = secret.toNativeUtf8();
    try {
      final ptr = fn(b.cast(), w.cast(), t.cast(), mode, l.cast(), s.cast(),
          statusPort, debug ? 1 : 0);
      return _consumeResult(ptr);
    } finally {
      malloc.free(b);
      malloc.free(w);
      malloc.free(t);
      malloc.free(l);
      malloc.free(s);
    }
  }

  /// 启动 VPN，[configPath] 为 sing-box JSON 配置文件路径
  /// 返回 null 表示成功，非 null 为错误信息
  static String? start(String configPath, {bool disableMemoryLimit = false}) {
    _ensureLoaded();
    final fn = _lib!.lookupFunction<_StartNative, _StartDart>('start');
    final p = configPath.toNativeUtf8();
    try {
      final ptr = fn(p.cast(), disableMemoryLimit ? 1 : 0);
      return _consumeResult(ptr);
    } finally {
      malloc.free(p);
    }
  }

  /// 停止 VPN
  /// 返回 null 表示成功，非 null 为错误信息
  static String? stop() {
    _ensureLoaded();
    final fn = _lib!.lookupFunction<_StopNative, _StopDart>('stop');
    return _consumeResult(fn());
  }

  /// 重启 VPN（热重载配置）
  static String? restart(String configPath, {bool disableMemoryLimit = false}) {
    _ensureLoaded();
    final fn = _lib!.lookupFunction<_RestartNative, _RestartDart>('restart');
    final p = configPath.toNativeUtf8();
    try {
      final ptr = fn(p.cast(), disableMemoryLimit ? 1 : 0);
      return _consumeResult(ptr);
    } finally {
      malloc.free(p);
    }
  }

  /// 启动内嵌 gRPC 服务器（仅 OLD 模式需要手动调用，GRPC 模式由 setup 自动启动）
  static String? startCoreGrpcServer(String listenAddress) {
    _ensureLoaded();
    final fn = _lib!
        .lookupFunction<_StartGrpcNative, _StartGrpcDart>('StartCoreGrpcServer');
    final p = listenAddress.toNativeUtf8();
    try {
      return _consumeResult(fn(p.cast()));
    } finally {
      malloc.free(p);
    }
  }

  /// 获取 gRPC 服务端公钥（mTLS 用）
  static String? getServerPublicKey() {
    _ensureLoaded();
    final fn = _lib!.lookupFunction<_GetServerPublicKeyNative,
        _GetServerPublicKeyDart>('GetServerPublicKey');
    return _consumeResult(fn());
  }

  /// 注册 gRPC 客户端公钥（mTLS 用）
  static String? addGrpcClientPublicKey(String clientPublicKey) {
    _ensureLoaded();
    final fn = _lib!.lookupFunction<_AddGrpcClientPublicKeyNative,
        _AddGrpcClientPublicKeyDart>('AddGrpcClientPublicKey');
    final p = clientPublicKey.toNativeUtf8();
    try {
      return _consumeResult(fn(p.cast()));
    } finally {
      malloc.free(p);
    }
  }

  /// 关闭指定模式的 gRPC 服务器
  static void closeGrpc(int mode) {
    _ensureLoaded();
    final fn =
        _lib!.lookupFunction<_CloseGrpcNative, _CloseGrpcDart>('closeGrpc');
    fn(mode);
  }

  /// 清理资源（应用退出时调用）
  static void cleanup() {
    if (_lib == null) return;
    final fn =
        _lib!.lookupFunction<_CleanupNative, _CleanupDart>('cleanup');
    fn();
    _lib = null;
  }
}
