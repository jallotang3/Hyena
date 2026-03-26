import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:ffi/ffi.dart';
import '../../../infrastructure/logging/app_logger.dart';

/// C Error 结构体（与 MagicLamp libbox_service.dart 中定义一致）
final class CError extends ffi.Struct {
  external ffi.Pointer<ffi.Char> message;

  @ffi.Int32()
  external int code;
}

/// libbox FFI 原始绑定层
/// 对应 MagicLamp: lib/services/vpn/libbox_service.dart
/// Windows/Linux 平台使用 FFI；Android 使用 AAR JNI；iOS/macOS 使用 MethodChannel
class LibboxFfi {
  static ffi.DynamicLibrary? _library;
  static ffi.Pointer<ffi.Void>? _serviceHandle;

  static bool get isLoaded => _library != null;

  /// 加载平台对应的 native 库
  static Future<bool> load() async {
    if (_library != null) return true;
    // gomobile 的 HyenaCore 通过 JNI（AAR）暴露，进程内不存在可 dlopen 的 libbox.so。
    // Android 上真实 VPN 应使用 [HyenaCoreEngine]，而非本 FFI。
    if (Platform.isAndroid) {
      AppLogger.i(
        'Android 无 libbox.so FFI；请使用 HyenaCoreEngine（默认开启 HYENA_CORE_ANDROID）',
        tag: LogTag.vpn,
      );
      return false;
    }
    try {
      _library = _openLibrary();
      AppLogger.i('libbox 加载成功', tag: LogTag.vpn);
      return true;
    } catch (e) {
      AppLogger.e('libbox 加载失败: $e', tag: LogTag.vpn);
      return false;
    }
  }

  static ffi.DynamicLibrary _openLibrary() {
    if (Platform.isWindows) {
      for (final name in ['libbox-amd64.dll', 'libbox.dll']) {
        try {
          return ffi.DynamicLibrary.open(name);
        } catch (_) {}
      }
      throw Exception('libbox DLL not found. Put libbox-amd64.dll in app directory.');
    } else if (Platform.isIOS || Platform.isMacOS) {
      return ffi.DynamicLibrary.process();
    } else if (Platform.isLinux) {
      return ffi.DynamicLibrary.open('libbox.so');
    }
    throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
  }

  static void _ensureLoaded() {
    if (_library == null) throw StateError('libbox not loaded. Call LibboxFfi.load() first.');
  }

  // ── 核心 API ──────────────────────────────────────────────────────────────

  /// LibboxSetup — 初始化 libbox 工作目录
  static ffi.Pointer<CError>? setup(String basePath, String workingPath, String tempPath) {
    _ensureLoaded();
    final fn = _library!.lookupFunction<
        ffi.Pointer<CError> Function(
            ffi.Pointer<ffi.Char>, ffi.Pointer<ffi.Char>, ffi.Pointer<ffi.Char>),
        ffi.Pointer<CError> Function(
            ffi.Pointer<ffi.Char>, ffi.Pointer<ffi.Char>, ffi.Pointer<ffi.Char>)>('LibboxSetup');

    final b = basePath.toNativeUtf8();
    final w = workingPath.toNativeUtf8();
    final t = tempPath.toNativeUtf8();
    final result = fn(b.cast(), w.cast(), t.cast());
    malloc.free(b);
    malloc.free(w);
    malloc.free(t);
    return result.address == 0 ? null : result;
  }

  /// LibboxVersion — 获取版本字符串
  static String? version() {
    _ensureLoaded();
    final fn = _library!.lookupFunction<ffi.Pointer<ffi.Char> Function(),
        ffi.Pointer<ffi.Char> Function()>('LibboxVersion');
    final ptr = fn();
    if (ptr.address == 0) return null;
    final v = ptr.cast<Utf8>().toDartString();
    freeString(ptr);
    return v;
  }

  /// LibboxNewService — 创建 BoxService 实例
  static ffi.Pointer<ffi.Void>? newService(String configJson) {
    _ensureLoaded();
    final fn = _library!.lookupFunction<
        ffi.Pointer<ffi.Void> Function(ffi.Pointer<ffi.Char>, ffi.Pointer<ffi.Void>),
        ffi.Pointer<ffi.Void> Function(ffi.Pointer<ffi.Char>, ffi.Pointer<ffi.Void>)>('LibboxNewService');
    final cfg = configJson.toNativeUtf8();
    final result = fn(cfg.cast(), ffi.nullptr);
    malloc.free(cfg);
    return result.address == 0 ? null : result;
  }

  /// LibboxStart — 启动服务
  static ffi.Pointer<CError>? start(ffi.Pointer<ffi.Void> handle) {
    _ensureLoaded();
    final fn = _library!.lookupFunction<
        ffi.Pointer<CError> Function(ffi.Pointer<ffi.Void>),
        ffi.Pointer<CError> Function(ffi.Pointer<ffi.Void>)>('LibboxStart');
    final result = fn(handle);
    return result.address == 0 ? null : result;
  }

  /// LibboxClose — 关闭服务
  static ffi.Pointer<CError>? close(ffi.Pointer<ffi.Void> handle) {
    _ensureLoaded();
    final fn = _library!.lookupFunction<
        ffi.Pointer<CError> Function(ffi.Pointer<ffi.Void>),
        ffi.Pointer<CError> Function(ffi.Pointer<ffi.Void>)>('LibboxClose');
    final result = fn(handle);
    return result.address == 0 ? null : result;
  }

  /// LibboxFreeString — 释放 C 字符串
  static void freeString(ffi.Pointer<ffi.Char> ptr) {
    _ensureLoaded();
    final fn = _library!.lookupFunction<ffi.Void Function(ffi.Pointer<ffi.Char>),
        void Function(ffi.Pointer<ffi.Char>)>('LibboxFreeString');
    fn(ptr);
  }

  /// LibboxFreeError — 释放 CError 结构体
  static void freeError(ffi.Pointer<CError> ptr) {
    _ensureLoaded();
    final fn = _library!.lookupFunction<ffi.Void Function(ffi.Pointer<CError>),
        void Function(ffi.Pointer<CError>)>('LibboxFreeError');
    fn(ptr);
  }

  // ── 高级封装 ──────────────────────────────────────────────────────────────

  static (bool, String?) startVpn(String configJson) {
    try {
      final handle = newService(configJson);
      if (handle == null) return (false, 'LibboxNewService returned null');
      _serviceHandle = handle;

      final errPtr = start(handle);
      if (errPtr != null) {
        final msg = errPtr.ref.message.cast<Utf8>().toDartString();
        freeError(errPtr);
        close(handle);
        _serviceHandle = null;
        return (false, msg);
      }
      return (true, null);
    } catch (e) {
      return (false, e.toString());
    }
  }

  static (bool, String?) stopVpn() {
    try {
      if (_serviceHandle == null) return (true, null);
      final errPtr = close(_serviceHandle!);
      _serviceHandle = null;
      if (errPtr != null) {
        final msg = errPtr.ref.message.cast<Utf8>().toDartString();
        freeError(errPtr);
        return (false, msg);
      }
      return (true, null);
    } catch (e) {
      return (false, e.toString());
    }
  }

  static bool get isRunning => _serviceHandle != null;
}
