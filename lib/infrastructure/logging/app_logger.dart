import 'dart:developer' as developer;
import 'log_file_manager.dart';

enum LogTag { auth, node, vpn, adapter, skin, storage, network, ui, general }

enum LogLevel { debug, info, warn, error }

/// 结构化日志 — 脱敏规则：Token / 邮箱 / 明文 IP 不写入文件
class AppLogger {
  static bool _verbose = false;
  static const int _maxLogs = 200;
  static final List<String> _recentLogs = [];
  static bool _fileLoggingEnabled = false;

  static List<String> get recentLogs => List.unmodifiable(_recentLogs);

  static void setVerbose(bool value) => _verbose = value;

  static Future<void> enableFileLogging() async {
    await LogFileManager.instance.initialize();
    _fileLoggingEnabled = true;
  }

  static void d(String message, {LogTag tag = LogTag.general}) =>
      _log(LogLevel.debug, message, tag);

  static void i(String message, {LogTag tag = LogTag.general}) =>
      _log(LogLevel.info, message, tag);

  static void w(String message, {LogTag tag = LogTag.general}) =>
      _log(LogLevel.warn, message, tag);

  static void e(String message, {LogTag tag = LogTag.general, Object? error, StackTrace? stack}) {
    _log(LogLevel.error, message, tag);
    if (error != null) _log(LogLevel.error, '  Error: $error', tag);
    if (stack != null && _verbose) _log(LogLevel.error, '  Stack: $stack', tag);
  }

  static void _log(LogLevel level, String message, LogTag tag) {
    if (level == LogLevel.debug && !_verbose) return;

    final emoji = switch (level) {
      LogLevel.debug => '🔍',
      LogLevel.info => 'ℹ️',
      LogLevel.warn => '⚠️',
      LogLevel.error => '❌',
    };

    final sanitized = _sanitize(message);
    final formatted = '$emoji [${tag.name.toUpperCase()}] $sanitized';

    _recentLogs.add(formatted);
    if (_recentLogs.length > _maxLogs) _recentLogs.removeAt(0);
    if (_fileLoggingEnabled) {
      final ts = DateTime.now().toIso8601String().substring(11, 23);
      LogFileManager.instance.write('$ts $formatted');
    }
    developer.log(formatted, name: 'hyena', level: level.index * 300);
  }

  /// 脱敏：移除 Bearer Token、邮箱、常见私有 IP 段
  static String _sanitize(String message) {
    return message
        .replaceAll(RegExp(r'Bearer\s+\S+'), 'Bearer ***')
        .replaceAll(RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}'), '***@***')
        .replaceAll(RegExp(r'\b(?:10|172\.(?:1[6-9]|2\d|3[01])|192\.168)\.\d+\.\d+\b'), '[private-ip]');
  }
}
