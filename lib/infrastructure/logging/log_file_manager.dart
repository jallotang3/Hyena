import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'app_logger.dart';

/// 日志文件管理 — 滚动写入 + 脱敏导出
class LogFileManager {
  LogFileManager._();
  static final LogFileManager instance = LogFileManager._();

  static const int _maxFileSize = 2 * 1024 * 1024; // 2 MB
  static const int _maxFiles = 3;

  File? _currentFile;
  IOSink? _sink;

  Future<void> initialize() async {
    try {
      final dir = await _logDir();
      _currentFile = File('${dir.path}/hyena.log');
      _sink = _currentFile!.openWrite(mode: FileMode.append);
      AppLogger.i('日志文件: ${_currentFile!.path}', tag: LogTag.storage);
    } catch (e) {
      AppLogger.e('日志文件初始化失败: $e', tag: LogTag.storage);
    }
  }

  void write(String line) {
    _sink?.writeln(line);
    _rotateIfNeeded();
  }

  Future<void> _rotateIfNeeded() async {
    if (_currentFile == null) return;
    try {
      final stat = await _currentFile!.stat();
      if (stat.size > _maxFileSize) {
        await _sink?.flush();
        await _sink?.close();
        await _rotate();
        _sink = _currentFile!.openWrite(mode: FileMode.append);
      }
    } catch (_) {}
  }

  Future<void> _rotate() async {
    final dir = await _logDir();
    for (var i = _maxFiles - 1; i >= 1; i--) {
      final old = File('${dir.path}/hyena.$i.log');
      final target = File('${dir.path}/hyena.${i + 1}.log');
      if (await old.exists()) {
        if (i + 1 >= _maxFiles) {
          await old.delete();
        } else {
          await old.rename(target.path);
        }
      }
    }
    if (await _currentFile!.exists()) {
      await _currentFile!.rename('${dir.path}/hyena.1.log');
    }
    _currentFile = File('${dir.path}/hyena.log');
  }

  /// 导出日志（脱敏后合并所有文件，返回 XFile 路径）
  Future<String> exportLogs() async {
    await _sink?.flush();
    final dir = await _logDir();
    final exportFile = File('${dir.path}/hyena_export_${DateTime.now().millisecondsSinceEpoch}.log');

    final buffer = StringBuffer();
    buffer.writeln('=== Hyena Log Export ===');
    buffer.writeln('Time: ${DateTime.now().toIso8601String()}');
    buffer.writeln('');

    for (var i = _maxFiles; i >= 1; i--) {
      final f = File('${dir.path}/hyena.$i.log');
      if (await f.exists()) {
        buffer.writeln(await f.readAsString());
      }
    }
    if (_currentFile != null && await _currentFile!.exists()) {
      buffer.writeln(await _currentFile!.readAsString());
    }

    await exportFile.writeAsString(buffer.toString());
    return exportFile.path;
  }

  /// 使用系统分享
  Future<void> shareExport() async {
    final path = await exportLogs();
    await Share.shareXFiles([XFile(path)], text: 'Hyena VPN Logs');
  }

  Future<void> dispose() async {
    await _sink?.flush();
    await _sink?.close();
  }

  Future<Directory> _logDir() async {
    final appDoc = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDoc.path}/hyena_logs');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }
}
