import 'package:flutter/services.dart';

/// HyenaCore 移动平台 — MethodChannel → Android JNI / iOS（gomobile mobile 包）
class HyenaCoreMobileBridge {
  HyenaCoreMobileBridge._();

  static const MethodChannel _channel = MethodChannel('com.hyena/core');

  static Future<void> setup({
    required String basePath,
    required String workingDir,
    required String tempDir,
    int mode = 0,
    String listen = '',
    String secret = '',
    bool debug = false,
  }) async {
    await _channel.invokeMethod<void>('setup', <String, Object?>{
      'basePath': basePath,
      'workingDir': workingDir,
      'tempDir': tempDir,
      'mode': mode,
      'listen': listen,
      'secret': secret,
      'debug': debug,
    });
  }

  static Future<void> start({
    required String configPath,
    String configContent = '',
  }) async {
    await _channel.invokeMethod<void>('start', <String, Object?>{
      'configPath': configPath,
      'configContent': configContent,
    });
  }

  static Future<void> stop() async {
    await _channel.invokeMethod<void>('stop');
  }
}
