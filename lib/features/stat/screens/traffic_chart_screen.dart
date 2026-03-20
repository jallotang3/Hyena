import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/commercial/notice.dart';
import '../../../core/result.dart';
import '../../../l10n/app_localizations.dart';
import '../stat_use_case.dart';

class TrafficChartScreen extends StatefulWidget {
  const TrafficChartScreen({super.key});

  @override
  State<TrafficChartScreen> createState() => _TrafficChartScreenState();
}

class _TrafficChartScreenState extends State<TrafficChartScreen> {
  List<TrafficRecord> _records = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final uc = context.read<StatUseCase>();
    final result = await uc.fetchTrafficLog();
    if (!mounted) return;
    if (result.isSuccess) {
      setState(() {
        _records = result.value;
        _loading = false;
      });
    } else {
      setState(() {
        _error = (result as Failure).error.message;
        _loading = false;
      });
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)}KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)}GB';
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(s.trafficUsage)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 16),
                      FilledButton.tonal(onPressed: _load, child: Text(s.retry)),
                    ],
                  ),
                )
              : _records.isEmpty
                  ? Center(child: Text(s.noTrafficData))
                  : _buildChart(theme),
    );
  }

  Widget _buildChart(ThemeData theme) {
    final maxTotal = _records.fold<int>(
        0, (prev, r) => r.totalBytes > prev ? r.totalBytes : prev);
    final maxHeight = maxTotal > 0 ? maxTotal.toDouble() : 1.0;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SummaryCard(records: _records, theme: theme),
          const SizedBox(height: 16),
          SizedBox(
            height: 240,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _records.map((r) {
                final upRatio = r.uploadBytes / maxHeight;
                final downRatio = r.downloadBytes / maxHeight;
                final day = r.date.day.toString();
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                height: (upRatio * 200).clamp(1, 200),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary
                                      .withValues(alpha: 0.7),
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(2)),
                                ),
                              ),
                              Container(
                                height: (downRatio * 200).clamp(1, 200),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.7),
                                  borderRadius: const BorderRadius.vertical(
                                      bottom: Radius.circular(2)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(day,
                            style: theme.textTheme.labelSmall
                                ?.copyWith(fontSize: 8)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(
                  color: theme.colorScheme.primary.withValues(alpha: 0.7),
                  label: S.of(context)!.homeUpload),
              const SizedBox(width: 16),
              _LegendDot(
                  color: Colors.green.withValues(alpha: 0.7),
                  label: S.of(context)!.homeDownload),
            ],
          ),
          const SizedBox(height: 16),
          ..._records.reversed.map((r) => ListTile(
                dense: true,
                title: Text('${r.date.month}/${r.date.day}'),
                subtitle: Text(
                    '↑ ${_formatBytes(r.uploadBytes)}  ↓ ${_formatBytes(r.downloadBytes)}'),
                trailing: Text(_formatBytes(r.totalBytes),
                    style: theme.textTheme.labelMedium),
              )),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.records, required this.theme});
  final List<TrafficRecord> records;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final totalUp = records.fold<int>(0, (s, r) => s + r.uploadBytes);
    final totalDown = records.fold<int>(0, (s, r) => s + r.downloadBytes);
    final total = totalUp + totalDown;
    final s = S.of(context)!;

    String fmt(int bytes) {
      if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
      if (bytes < 1024 * 1024 * 1024) {
        return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
      }
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatItem(label: s.homeUpload, value: fmt(totalUp)),
            _StatItem(label: s.homeDownload, value: fmt(totalDown)),
            _StatItem(label: s.trafficUsage, value: fmt(total)),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}
