import 'package:flutter/material.dart';
import '../../../controllers/node_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../../../skins/theme_token_provider.dart';

/// 移动端节点列表页（Material Design）
class MobileNodeListPage extends StatefulWidget {
  final NodeController controller;

  const MobileNodeListPage({required this.controller, super.key});

  @override
  State<MobileNodeListPage> createState() => _MobileNodeListPageState();
}

class _MobileNodeListPageState extends State<MobileNodeListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.load();
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
    final tokens = ThemeTokenProvider.tokensOf(context);
    final s = S.of(context)!;

    return Scaffold(
      backgroundColor: tokens.colorBackground,
      appBar: AppBar(
        backgroundColor: tokens.colorBackground,
        title: Text(s.nodes),
        actions: [
          // 测试所有节点
          ListenableBuilder(
            listenable: widget.controller,
            builder: (context, _) {
              return IconButton(
                icon: widget.controller.isTesting
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: tokens.colorPrimary,
                        ),
                      )
                    : Icon(Icons.speed, color: tokens.colorOnBackground),
                tooltip: s.nodesTestAll,
                onPressed: widget.controller.isTesting
                    ? null
                    : () => widget.controller.testAllNodes(),
              );
            },
          ),
          // 排序菜单
          PopupMenuButton<NodeSortMode>(
            icon: Icon(Icons.sort, color: tokens.colorOnBackground),
            tooltip: s.nodesSortLabel,
            onSelected: (mode) => widget.controller.setSortMode(mode),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: NodeSortMode.name,
                child: Text(s.nodesSortName),
              ),
              PopupMenuItem(
                value: NodeSortMode.latency,
                child: Text(s.nodesSortLatency),
              ),
              PopupMenuItem(
                value: NodeSortMode.group,
                child: Text(s.nodesSortGroup),
              ),
            ],
          ),
          // 刷新
          IconButton(
            icon: Icon(Icons.refresh, color: tokens.colorOnBackground),
            onPressed: () => widget.controller.load(forceRefresh: true),
          ),
        ],
      ),
      body: Column(
        children: [
          // 搜索栏
          _SearchBar(
            controller: _searchCtrl,
            nodeController: widget.controller,
            tokens: tokens,
          ),
          // Tab 栏
          Container(
            color: tokens.colorBackground,
            child: TabBar(
              controller: _tabs,
              labelColor: tokens.colorPrimary,
              unselectedLabelColor: tokens.colorMuted,
              indicatorColor: tokens.colorPrimary,
              tabs: [
                Tab(text: s.allNodes),
                Tab(text: s.favoriteNodes),
              ],
            ),
          ),
          // Tab 内容
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _NodeTab(
                  controller: widget.controller,
                  useAll: true,
                  tokens: tokens,
                ),
                _NodeTab(
                  controller: widget.controller,
                  useAll: false,
                  tokens: tokens,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.nodeController,
    required this.tokens,
  });

  final TextEditingController controller;
  final NodeController nodeController;
  final ThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: controller,
        onChanged: (v) => nodeController.setFilter(v),
        style: TextStyle(color: tokens.colorOnBackground),
        decoration: InputDecoration(
          hintText: s.searchNodes,
          hintStyle: TextStyle(color: tokens.colorMuted),
          prefixIcon: Icon(Icons.search, size: 20, color: tokens.colorMuted),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, size: 18, color: tokens.colorMuted),
                  onPressed: () {
                    controller.clear();
                    nodeController.setFilter('');
                  },
                )
              : null,
          isDense: true,
          filled: true,
          fillColor: tokens.colorSurface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(tokens.radiusSmall),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _NodeTab extends StatelessWidget {
  const _NodeTab({
    required this.controller,
    required this.useAll,
    required this.tokens,
  });

  final NodeController controller;
  final bool useAll;
  final ThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (controller.loadState == NodeLoadState.loading) {
          return Center(
            child: CircularProgressIndicator(color: tokens.colorPrimary),
          );
        }

        if (controller.loadState == NodeLoadState.error) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: tokens.colorError),
                const SizedBox(height: 16),
                Text(
                  controller.errorMessage ?? s.noNodes,
                  style: TextStyle(color: tokens.colorMuted),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => controller.load(forceRefresh: true),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final nodes = useAll ? controller.nodes : controller.favoriteNodes;

        if (nodes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  useAll ? Icons.dns_outlined : Icons.star_outline,
                  size: 64,
                  color: tokens.colorMuted,
                ),
                const SizedBox(height: 16),
                Text(
                  useAll ? s.noNodes : s.noFavoriteNodes,
                  style: TextStyle(color: tokens.colorMuted),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: nodes.length,
          itemBuilder: (context, index) {
            final node = nodes[index];
            return _NodeCard(
              node: node,
              controller: controller,
              tokens: tokens,
            );
          },
        );
      },
    );
  }
}

class _NodeCard extends StatelessWidget {
  const _NodeCard({
    required this.node,
    required this.controller,
    required this.tokens,
  });

  final ProxyNode node;
  final NodeController controller;
  final ThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    final isSelected = controller.selectedNode?.id == node.id;
    final isFavorite = controller.favoriteNodes.any((n) => n.id == node.id);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: tokens.colorSurface,
        borderRadius: BorderRadius.circular(tokens.radiusMedium),
        border: isSelected
            ? Border.all(color: tokens.colorPrimary, width: 2)
            : null,
      ),
      child: ListTile(
        onTap: () => controller.selectAndConnect(node),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isSelected
                ? tokens.colorPrimary.withValues(alpha: 0.1)
                : tokens.colorMuted.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.dns_rounded,
            color: isSelected ? tokens.colorPrimary : tokens.colorMuted,
            size: 20,
          ),
        ),
        title: Text(
          node.name,
          style: TextStyle(
            color: tokens.colorOnBackground,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        subtitle: node.latency != null
            ? Text(
                '${node.latency}ms',
                style: TextStyle(
                  color: _getLatencyColor(node.latency!, tokens),
                  fontSize: 12,
                ),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (node.latency != null)
              _LatencyIndicator(latency: node.latency!, tokens: tokens),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                isFavorite ? Icons.star : Icons.star_outline,
                color: isFavorite ? tokens.colorPrimary : tokens.colorMuted,
              ),
              onPressed: () => controller.toggleFavorite(node.id),
            ),
          ],
        ),
      ),
    );
  }

  Color _getLatencyColor(int latency, ThemeTokens tokens) {
    if (latency < 100) return tokens.colorSuccess;
    if (latency < 300) return tokens.colorPrimary;
    return tokens.colorError;
  }
}

class _LatencyIndicator extends StatelessWidget {
  const _LatencyIndicator({
    required this.latency,
    required this.tokens,
  });

  final int latency;
  final ThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    final bars = _getBarCount(latency);
    final color = _getColor(latency);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(4, (index) {
        return Container(
          width: 3,
          height: 8 + (index * 3),
          margin: const EdgeInsets.only(left: 2),
          decoration: BoxDecoration(
            color: index < bars ? color : tokens.colorMuted.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(1),
          ),
        );
      }),
    );
  }

  int _getBarCount(int latency) {
    if (latency < 50) return 4;
    if (latency < 100) return 3;
    if (latency < 300) return 2;
    return 1;
  }

  Color _getColor(int latency) {
    if (latency < 100) return tokens.colorSuccess;
    if (latency < 300) return tokens.colorPrimary;
    return tokens.colorError;
  }
}
