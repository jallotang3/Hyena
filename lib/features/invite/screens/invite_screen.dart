import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../controllers/profile_controller.dart';
import '../../../l10n/app_localizations.dart';

class InviteScreen extends StatefulWidget {
  const InviteScreen({super.key});

  @override
  State<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends State<InviteScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileController>().fetchInviteSummary();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(s.invite)),
      body: Consumer<ProfileController>(
        builder: (_, ctrl, __) {
          if (ctrl.isLoading && ctrl.inviteSummary == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (ctrl.error != null && ctrl.inviteSummary == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(ctrl.error!),
                  const SizedBox(height: 16),
                  FilledButton.tonal(
                      onPressed: () => ctrl.fetchInviteSummary(),
                      child: Text(s.retry)),
                ],
              ),
            );
          }
          if (ctrl.inviteSummary == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return _InviteContent(ctrl: ctrl);
        },
      ),
    );
  }
}

class _InviteContent extends StatelessWidget {
  const _InviteContent({required this.ctrl});
  final ProfileController ctrl;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final theme = Theme.of(context);
    final summary = ctrl.inviteSummary!;
    return RefreshIndicator(
      onRefresh: () async => ctrl.fetchInviteSummary(),
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
                onPressed: () => ctrl.generateInviteCode(),
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
