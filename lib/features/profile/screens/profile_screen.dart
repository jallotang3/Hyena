import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../controllers/profile_controller.dart';
import '../../../l10n/app_localizations.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileController>().fetchUser();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.profile),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: Consumer<ProfileController>(
        builder: (_, ctrl, __) {
          if (ctrl.isLoading && ctrl.user == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return _ProfileContent(ctrl: ctrl);
        },
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({required this.ctrl});
  final ProfileController ctrl;

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    int i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < units.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(1)} ${units[i]}';
  }

  String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final theme = Theme.of(context);
    final u = ctrl.user;
    return RefreshIndicator(
      onRefresh: () async => ctrl.fetchUser(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    u?.email.isNotEmpty == true
                        ? u!.email[0].toUpperCase()
                        : '?',
                    style: theme.textTheme.headlineMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer),
                  ),
                ),
                const SizedBox(height: 8),
                Text(u?.email ?? '–', style: theme.textTheme.titleMedium),
                if (u != null && u.planName.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Chip(
                    label: Text(u.planName,
                        style: theme.textTheme.labelSmall),
                    backgroundColor: theme.colorScheme.secondaryContainer,
                    side: BorderSide.none,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (u != null) ...[
            _InfoCard(
              icon: Icons.data_usage,
              title: s.trafficUsage,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatBytes(u.trafficUsed),
                          style: theme.textTheme.titleLarge?.copyWith(
                              color: theme.colorScheme.primary)),
                      Text(
                        u.trafficTotal > 0
                            ? '/ ${_formatBytes(u.trafficTotal)}'
                            : '/ ∞',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: u.trafficTotal > 0
                          ? u.trafficUsedPercent.clamp(0.0, 1.0)
                          : 0,
                      minHeight: 8,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                    ),
                  ),
                  if (u.expireAt != null) ...[
                    const SizedBox(height: 6),
                    Text('${s.expireAt}: ${_formatDate(u.expireAt!)}',
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5))),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            _InfoCard(
              icon: Icons.account_balance_wallet_outlined,
              title: s.balance,
              child: Row(
                children: [
                  Expanded(
                    child: _BalanceTile(
                      label: s.accountBalance,
                      value: '¥${(u.balance / 100).toStringAsFixed(2)}',
                    ),
                  ),
                  const VerticalDivider(width: 16),
                  Expanded(
                    child: _BalanceTile(
                      label: s.commissionBalance,
                      value:
                          '¥${(u.commissionBalance / 100).toStringAsFixed(2)}',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          _MenuSection(items: [
            _MenuItem(
                icon: Icons.receipt_long_outlined,
                label: s.orders,
                onTap: () => context.push('/orders')),
            _MenuItem(
                icon: Icons.support_agent_outlined,
                label: s.tickets,
                onTap: () => context.push('/tickets')),
            _MenuItem(
                icon: Icons.people_alt_outlined,
                label: s.invite,
                onTap: () => context.push('/invite')),
          ]),
          const SizedBox(height: 12),
          _MenuSection(items: [
            _MenuItem(
                icon: Icons.lock_outline,
                label: s.changePassword,
                onTap: () => _showChangePassword(context, s)),
          ]),
          const SizedBox(height: 12),
          _MenuSection(items: [
            _MenuItem(
                icon: Icons.logout,
                label: s.logout,
                isDestructive: true,
                onTap: () => _logout(context, s)),
          ]),
        ],
      ),
    );
  }

  Future<void> _showChangePassword(BuildContext context, S s) async {
    final oldPw = TextEditingController();
    final newPw = TextEditingController();
    final confirmPw = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(s.changePassword),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: oldPw,
                obscureText: true,
                decoration: InputDecoration(
                    labelText: s.currentPassword,
                    border: const OutlineInputBorder(),
                    isDense: true)),
            const SizedBox(height: 8),
            TextField(
                controller: newPw,
                obscureText: true,
                decoration: InputDecoration(
                    labelText: s.newPassword,
                    border: const OutlineInputBorder(),
                    isDense: true)),
            const SizedBox(height: 8),
            TextField(
                controller: confirmPw,
                obscureText: true,
                decoration: InputDecoration(
                    labelText: s.confirmPassword,
                    border: const OutlineInputBorder(),
                    isDense: true)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(s.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(s.confirm)),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    if (newPw.text != confirmPw.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.passwordMismatch)),
      );
      return;
    }
    final profileCtrl = context.read<ProfileController>();
    final ok = await profileCtrl.changePassword(oldPw.text, newPw.text);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? s.passwordChanged : (profileCtrl.error ?? '')),
          backgroundColor: ok ? null : Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _logout(BuildContext context, S s) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(s.logout),
        content: Text(s.logoutConfirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(s.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(s.confirm)),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    await context.read<ProfileController>().logout();
    if (context.mounted) context.go('/login');
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard(
      {required this.icon, required this.title, required this.child});
  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Text(title, style: theme.textTheme.labelMedium),
            ]),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _BalanceTile extends StatelessWidget {
  const _BalanceTile({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(children: [
      Text(value,
          style: theme.textTheme.titleMedium
              ?.copyWith(color: theme.colorScheme.primary)),
      Text(label, style: theme.textTheme.labelSmall),
    ]);
  }
}

class _MenuSection extends StatelessWidget {
  const _MenuSection({required this.items});
  final List<_MenuItem> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: items
            .map((item) => ListTile(
                  leading: Icon(item.icon,
                      color: item.isDestructive
                          ? Theme.of(context).colorScheme.error
                          : null),
                  title: Text(item.label,
                      style: item.isDestructive
                          ? TextStyle(
                              color: Theme.of(context).colorScheme.error)
                          : null),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: item.onTap,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ))
            .toList(),
      ),
    );
  }
}

class _MenuItem {
  const _MenuItem(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.isDestructive = false});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;
}
