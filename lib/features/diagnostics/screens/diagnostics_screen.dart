import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../controllers/diag_controller.dart';
import '../../../l10n/app_localizations.dart';

class DiagnosticsScreen extends StatefulWidget {
  const DiagnosticsScreen({super.key});

  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> {
  bool _running = false;
  Timer? _refreshTimer;
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) context.read<DiagController>().refreshLogs();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _runDiagnostics() async {
    setState(() => _running = true);
    await context.read<DiagController>().runDiagnostics();
    if (mounted) setState(() => _running = false);
  }

  Future<void> _exportLogs() async {
    try {
      await context.read<DiagController>().exportLogs();
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
            child: Consumer<DiagController>(
              builder: (_, ctrl, __) {
                final logs = ctrl.logs;
                return Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: logs.isEmpty
                      ? Center(
                          child: Text(s.diagnosticsEmpty,
                              style: theme.textTheme.bodySmall))
                      : ListView.builder(
                          controller: _scrollCtrl,
                          reverse: true,
                          itemCount: logs.length,
                          itemBuilder: (_, i) {
                            return Text(
                              logs[i],
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontFamily: 'monospace',
                                height: 1.6,
                              ),
                            );
                          },
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
