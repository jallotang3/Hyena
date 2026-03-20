import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/proxy_node.dart';
import '../../../features/connection/connection_notifier.dart';
import '../../../infrastructure/storage/preferences.dart';
import '../../../l10n/app_localizations.dart';
import '../node_notifier.dart';

class NodeListScreen extends StatefulWidget {
  const NodeListScreen({super.key});

  @override
  State<NodeListScreen> createState() => _NodeListScreenState();
}

class _NodeListScreenState extends State<NodeListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NodeNotifier>().load();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.nodes),
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: s.allNodes),
            Tab(text: s.favoriteNodes),
          ],
        ),
        actions: [
          Consumer<NodeNotifier>(
            builder: (_, notifier, __) => IconButton(
              icon: notifier.isTesting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.speed),
              tooltip: s.nodesTestAll,
              onPressed: notifier.isTesting
                  ? null
                  : () => notifier.testAllNodes(),
            ),
          ),
          PopupMenuButton<NodeSortMode>(
            icon: const Icon(Icons.sort),
            tooltip: s.nodesSortLabel,
            onSelected: (mode) =>
                context.read<NodeNotifier>().setSortMode(mode),
            itemBuilder: (_) => [
              PopupMenuItem(
                  value: NodeSortMode.name, child: Text(s.nodesSortName)),
              PopupMenuItem(
                  value: NodeSortMode.latency,
                  child: Text(s.nodesSortLatency)),
              PopupMenuItem(
                  value: NodeSortMode.group, child: Text(s.nodesSortGroup)),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                context.read<NodeNotifier>().load(forceRefresh: true),
          ),
        ],
      ),
      body: Column(
        children: [
          _SearchBar(controller: _searchCtrl),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _NodeTab(useAll: true),
                _NodeTab(useAll: false),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 搜索栏 ─────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: TextField(
        controller: controller,
        onChanged: (v) => context.read<NodeNotifier>().setFilter(v),
        decoration: InputDecoration(
          hintText: s.searchNodes,
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    controller.clear();
                    context.read<NodeNotifier>().setFilter('');
                  },
                )
              : null,
          isDense: true,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none),
          filled: true,
        ),
      ),
    );
  }
}

// ── 节点分组列表 Tab ───────────────────────────────────────────────────────

class _NodeTab extends StatelessWidget {
  const _NodeTab({required this.useAll});
  final bool useAll;

  @override
  Widget build(BuildContext context) {
    return Consumer<NodeNotifier>(builder: (_, notifier, __) {
      if (notifier.loadState == NodeLoadState.loading) {
        return const Center(child: CircularProgressIndicator());
      }
      if (notifier.loadState == NodeLoadState.error) {
        return _ErrorView(message: notifier.errorMessage ?? '');
      }

      final allNodes = useAll ? notifier.nodes : notifier.favoriteNodes;
      if (allNodes.isEmpty) {
        return _EmptyView(isFavorite: !useAll);
      }

      // 按 group 分组
      final groups = <String, List<ProxyNode>>{};
      for (final n in allNodes) {
        final s = S.of(context)!;
        groups.putIfAbsent(n.group.isNotEmpty ? n.group : s.nodesFilterAll, () => []).add(n);
      }

      return RefreshIndicator(
        onRefresh: () =>
            context.read<NodeNotifier>().load(forceRefresh: true),
        child: ListView(
          children: groups.entries.map((entry) {
            return _GroupSection(group: entry.key, nodes: entry.value);
          }).toList(),
        ),
      );
    });
  }
}

// ── 分组区块 ───────────────────────────────────────────────────────────────

class _GroupSection extends StatelessWidget {
  const _GroupSection({required this.group, required this.nodes});
  final String group;
  final List<ProxyNode> nodes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            group,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.primary, letterSpacing: 1),
          ),
        ),
        ...nodes.map((n) => _NodeTile(node: n)),
        const Divider(height: 1),
      ],
    );
  }
}

// ── 节点卡片 ───────────────────────────────────────────────────────────────

class _NodeTile extends StatelessWidget {
  const _NodeTile({required this.node});
  final ProxyNode node;

  Color _latencyColor(int? latency) {
    if (latency == null) return Colors.grey;
    if (latency < 200) return Colors.green;
    if (latency < 500) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notifier = context.read<NodeNotifier>();
    final conn = context.read<ConnectionNotifier>();

    final isActive = conn.currentNode?.id == node.id;

    return ListTile(
      onTap: () async {
        await notifier.setFavoriteAware(node.id);
        if (context.mounted) {
          await conn.connectToNode(node);
          if (context.mounted) Navigator.of(context).pop();
        }
      },
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: isActive
            ? theme.colorScheme.primary
            : theme.colorScheme.surfaceContainerHighest,
        child: Icon(
          isActive ? Icons.check : Icons.dns_outlined,
          size: 16,
          color: isActive
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.onSurface,
        ),
      ),
      title: Text(
        node.name,
        style: theme.textTheme.bodyMedium
            ?.copyWith(fontWeight: isActive ? FontWeight.bold : null),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        node.protocol.toUpperCase(),
        style: theme.textTheme.labelSmall
            ?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (node.latency != null)
            Text(
              '${node.latency}ms',
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: _latencyColor(node.latency)),
            ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              node.isFavorite ? Icons.star : Icons.star_outline,
              size: 20,
              color: node.isFavorite ? Colors.amber : null,
            ),
            onPressed: () => notifier.toggleFavorite(node.id),
          ),
        ],
      ),
    );
  }
}

// ── 错误 / 空状态 ─────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, size: 48),
          const SizedBox(height: 12),
          Text(message),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: () => context.read<NodeNotifier>().load(),
            child: Text(s.retry),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.isFavorite});
  final bool isFavorite;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isFavorite ? Icons.star_border : Icons.dns_outlined,
              size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(isFavorite ? s.noFavoriteNodes : s.noNodes),
        ],
      ),
    );
  }
}

extension NodeNotifierExt on NodeNotifier {
  Future<void> setFavoriteAware(String nodeId) async {
    await AppPreferences.instance.setLastNodeId(nodeId);
  }
}
