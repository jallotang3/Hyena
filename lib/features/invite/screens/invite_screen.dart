import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/models/commercial/invite.dart';
import '../../../core/result.dart';
import '../../../l10n/app_localizations.dart';
import '../invite_use_case.dart';

class InviteScreen extends StatefulWidget {
  const InviteScreen({super.key});

  @override
  State<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends State<InviteScreen> {
  InviteSummary? _summary;
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
    final result =
        await context.read<InviteUseCase>().fetchInviteSummary();
    if (!mounted) return;
    if (result.isSuccess) {
      setState(() {
        _summary = result.value;
        _loading = false;
      });
    } else {
      setState(() {
        _error = (result as Failure).error.message;
        _loading = false;
      });
    }
  }

  Future<void> _generateCode() async {
    final result =
        await context.read<InviteUseCase>().generateInviteCode();
    if (!mounted) return;
    if (result.isSuccess) {
      await _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text((result as Failure).error.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(s.invite)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 16),
                      FilledButton.tonal(
                          onPressed: _load, child: Text(s.retry)),
                    ],
                  ),
                )
              : _InviteContent(
                  summary: _summary!,
                  onRefresh: _load,
                  onGenerate: _generateCode,
                ),
    );
  }
}

class _InviteContent extends StatelessWidget {
  const _InviteContent(
      {required this.summary,
      required this.onRefresh,
      required this.onGenerate});
  final InviteSummary summary;
  final VoidCallback onRefresh;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _StatItem(
                      label: s.inviteRegistered,
                      value: summary.registeredCount.toString()),
                  _StatItem(
                      label: s.commissionRate,
                      value:
                          '${(summary.commissionRate * 100).toStringAsFixed(0)}%'),
                  _StatItem(
                      label: s.commissionBalance,
                      value:
                          '¥${(summary.commissionBalance / 100).toStringAsFixed(2)}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(s.inviteCodes, style: theme.textTheme.titleSmall),
              TextButton.icon(
                onPressed: onGenerate,
                icon: const Icon(Icons.add, size: 16),
                label: Text(s.generate),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...summary.codes.map((code) => _CodeTile(code: code)),
        ],
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
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: theme.textTheme.titleLarge
                  ?.copyWith(color: theme.colorScheme.primary)),
          const SizedBox(height: 4),
          Text(label,
              style: theme.textTheme.labelSmall,
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _CodeTile extends StatelessWidget {
  const _CodeTile({required this.code});
  final InviteCode code;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = S.of(context)!;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        title: Text(code.code,
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontFamily: 'monospace')),
        subtitle: Text(
          code.isUsed ? s.inviteCodeUsed : s.inviteCodeUnused,
          style: theme.textTheme.labelSmall?.copyWith(
              color: code.isUsed
                  ? theme.colorScheme.onSurface.withValues(alpha: 0.4)
                  : Colors.green),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.copy, size: 18),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: code.code));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(s.copied)),
            );
          },
        ),
      ),
    );
  }
}
