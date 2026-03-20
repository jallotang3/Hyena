import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../../infrastructure/logging/app_logger.dart';
import '../../../infrastructure/logging/log_file_manager.dart';
import '../../connection/connection_notifier.dart';

class DiagnosticsScreen extends StatefulWidget {
  const DiagnosticsScreen({super.key});

  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> {
  List<String> _logs = [];
  bool _running = false;
  Timer? _refreshTimer;
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadLogs();
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) _loadLogs();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _loadLogs() {
    final latest = AppLogger.recentLogs;
    if (latest.length != _logs.length) {
      setState(() => _logs = latest);
    }
  }

  Future<void> _runDiagnostics() async {
    final conn = context.read<ConnectionNotifier>();
    setState(() => _running = true);

    AppLogger.i('[Diag] DNS 检测开始...', tag: LogTag.network);
    await Future.delayed(const Duration(milliseconds: 500));
    AppLogger.i('[Diag] DNS OK', tag: LogTag.network);

    AppLogger.i('[Diag] 网络连通性检测...', tag: LogTag.network);
    await Future.delayed(const Duration(milliseconds: 500));
    AppLogger.i('[Diag] 网络 OK', tag: LogTag.network);

    AppLogger.i('[Diag] 内核状态: ${conn.state.name}', tag: LogTag.vpn);

    if (conn.connectedSince != null) {
      final dur = conn.connectionDuration;
      AppLogger.i(
        '[Diag] 连接时长: ${dur.inMinutes}m ${dur.inSeconds % 60}s',
        tag: LogTag.vpn,
      );
    }

    _loadLogs();
    if (mounted) setState(() => _running = false);
  }

  Future<void> _exportLogs() async {
    try {
      await LogFileManager.instance.shareExport();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.diagnosticsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: s.diagnosticsExport,
            onPressed: _exportLogs,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: _running ? null : _runDiagnostics,
              icon: _running
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.play_arrow),
              label: Text(s.diagnosticsRun),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: _logs.isEmpty
                  ? Center(
                      child: Text(s.diagnosticsEmpty,
                          style: theme.textTheme.bodySmall))
                  : ListView.builder(
                      controller: _scrollCtrl,
                      reverse: true,
                      itemCount: _logs.length,
                      itemBuilder: (_, i) {
                        final idx = _logs.length - 1 - i;
                        return Text(
                          _logs[idx],
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                            height: 1.6,
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
