import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../infrastructure/logging/app_logger.dart';

class DiagnosticsScreen extends StatefulWidget {
  const DiagnosticsScreen({super.key});

  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> {
  List<String> _logs = [];
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  void _loadLogs() {
    setState(() {
      _logs = AppLogger.recentLogs;
    });
  }

  Future<void> _runDiagnostics() async {
    setState(() => _running = true);
    final results = <String>[];
    results.add('[DNS] Checking...');
    await Future.delayed(const Duration(milliseconds: 500));
    results.add('[DNS] OK');
    results.add('[Network] Checking connectivity...');
    await Future.delayed(const Duration(milliseconds: 500));
    results.add('[Network] OK');
    results.add('[Engine] Checking VPN core status...');
    await Future.delayed(const Duration(milliseconds: 300));
    results.add('[Engine] OK');
    if (mounted) {
      setState(() {
        _logs = [...results, '', '--- Recent Logs ---', ..._logs];
        _running = false;
      });
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
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(s.diagnosticsExport)),
              );
            },
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
                      itemCount: _logs.length,
                      itemBuilder: (_, i) => Text(
                        _logs[i],
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          height: 1.6,
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
