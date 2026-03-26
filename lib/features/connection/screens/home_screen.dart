import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../controllers/home_controller.dart';
import '../../../core/models/traffic_stats.dart';
import '../../../l10n/app_localizations.dart';
import '../../../skins/theme_token_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _bottomIndex = 0;

  String _formatBytes(double bytes) {
    if (bytes < 1024) {
      return '${bytes.toStringAsFixed(0)} B/s';
    }
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB/s';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB/s';
  }

  String _formatTotal(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokenProvider.tokensOf(context);
    final ctrl = context.watch<HomeController>();

    final s = S.of(context)!;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? s.homeGoodMorning
        : hour < 18
            ? s.homeGoodAfternoon
            : s.homeGoodEvening;

    return Scaffold(
      backgroundColor: tokens.colorBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(greeting,
                          style: TextStyle(
                              color: tokens.colorMuted,
                              fontSize: 11,
                              letterSpacing: 1.5)),
                      Text(
                        ctrl.userEmail?.split('@').first.toUpperCase() ??
                            s.homeDefaultUser,
                        style: TextStyle(
                            color: tokens.colorOnBackground,
                            fontSize: 18,
                            fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.settings_outlined,
                        color: tokens.colorMuted, size: 22),
                    onPressed: () => context.push('/settings'),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const SizedBox(height: 16),

                    // Connection button
                    StreamBuilder<EngineState>(
                      stream: ctrl.stateStream,
                      initialData: ctrl.connectionState,
                      builder: (context, snap) {
                        final state = snap.data ?? EngineState.idle;
                        return _ConnectButton(
                            state: state, ctrl: ctrl, tokens: tokens);
                      },
                    ),
                    const SizedBox(height: 28),

                    // Traffic stats
                    StreamBuilder<TrafficStats>(
                      stream: ctrl.trafficStream,
                      initialData: TrafficStats.zero,
                      builder: (context, snap) {
                        final stats = snap.data ?? TrafficStats.zero;
                        return Row(
                          children: [
                            _StatCard(
                              label: s.homeUpload,
                              value: _formatBytes(stats.uploadSpeed),
                              total: _formatTotal(stats.uploadBytes),
                              icon: Icons.arrow_upward_rounded,
                              color: tokens.colorPrimary,
                              tokens: tokens,
                            ),
                            const SizedBox(width: 12),
                            _StatCard(
                              label: s.homeDownload,
                              value: _formatBytes(stats.downloadSpeed),
                              total: _formatTotal(stats.downloadBytes),
                              icon: Icons.arrow_downward_rounded,
                              color: tokens.colorSuccess,
                              tokens: tokens,
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Connection duration
                    if (ctrl.connectedSince != null)
                      _ConnectionDurationChip(ctrl: ctrl, tokens: tokens),
                    if (ctrl.connectedSince != null) const SizedBox(height: 12),

                    // Current node card
                    _NodeCard(ctrl: ctrl, tokens: tokens),
                    const SizedBox(height: 16),

                    // Routing mode
                    _RoutingModeCard(ctrl: ctrl, tokens: tokens),
                  ],
                ),
              ),
            ),

            // Bottom nav
            _BottomNav(
              index: _bottomIndex,
              tokens: tokens,
              onTap: (i) {
                setState(() => _bottomIndex = i);
                switch (i) {
                  case 0:
                    break;
                  case 1:
                    context.push('/nodes');
                  case 2:
                    context.push('/settings');
                  case 3:
                    context.push('/profile');
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectButton extends StatelessWidget {
  const _ConnectButton(
      {required this.state, required this.ctrl, required this.tokens});
  final EngineState state;
  final HomeController ctrl;
  final ThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    final isConnected = state == EngineState.connected;
    final isBusy =
        state == EngineState.connecting || state == EngineState.disconnecting;

    final s = S.of(context)!;
    final statusLabel = switch (state) {
      EngineState.connected => s.homeConnected,
      EngineState.connecting => s.homeConnecting,
      EngineState.disconnecting => s.homeDisconnecting,
      EngineState.error => s.homeErrorState,
      _ => s.homeDisconnected,
    };

    final ringColor = isConnected
        ? tokens.colorPrimary
        : state == EngineState.error
            ? tokens.colorError
            : tokens.colorMuted;

    return GestureDetector(
      onTap: isBusy
          ? null
          : () async {
              if (isConnected) {
                await ctrl.disconnect();
              } else {
                // 无已选节点时，弹出节点列表
                if (ctrl.currentNode == null) {
                  context.push('/nodes');
                } else {
                  await ctrl.connect();
                }
              }
            },
      child: Container(
        width: 180,
        height: 180,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: tokens.colorSurface,
          border: Border.all(
              color: ringColor, width: isConnected ? 2.5 : 1.5),
          boxShadow: isConnected
              ? [
                  BoxShadow(
                      color: tokens.colorPrimary.withValues(alpha: 0.3),
                      blurRadius: 24,
                      spreadRadius: 4),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isBusy)
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: ringColor),
              )
            else
              Icon(
                isConnected ? Icons.shield : Icons.shield_outlined,
                color: ringColor,
                size: 48,
              ),
            const SizedBox(height: 12),
            Text(statusLabel,
                style: TextStyle(
                    color: ringColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5)),
            if (!isBusy) ...[
              const SizedBox(height: 4),
              Text(isConnected ? s.homeDisconnectButton : s.homeConnectButton,
                  style: TextStyle(
                      color: tokens.colorMuted,
                      fontSize: 9,
                      letterSpacing: 1)),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.total,
    required this.icon,
    required this.color,
    required this.tokens,
  });
  final String label, value, total;
  final IconData icon;
  final Color color;
  final ThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: tokens.colorSurface,
          borderRadius: BorderRadius.circular(tokens.radiusMedium),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          color: tokens.colorMuted,
                          fontSize: 9,
                          letterSpacing: 1)),
                  Text(value,
                      style: TextStyle(
                          color: tokens.colorOnSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                  Text(total,
                      style:
                          TextStyle(color: tokens.colorMuted, fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NodeCard extends StatelessWidget {
  const _NodeCard({required this.ctrl, required this.tokens});
  final HomeController ctrl;
  final ThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    final node = ctrl.currentNode;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.colorSurface,
        borderRadius: BorderRadius.circular(tokens.radiusMedium),
      ),
      child: Row(
        children: [
          Icon(Icons.language, color: tokens.colorPrimary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(S.of(context)!.homeCurrentNode,
                    style: TextStyle(
                        color: tokens.colorMuted,
                        fontSize: 10,
                        letterSpacing: 1)),
                const SizedBox(height: 2),
                Text(node?.name ?? S.of(context)!.notSelectedNode,
                    style: TextStyle(
                        color: tokens.colorOnSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
                if (node != null)
                  Text('${node.protocol.toUpperCase()} · ${node.address}',
                      style: TextStyle(
                          color: tokens.colorMuted, fontSize: 11)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(node != null ? Icons.star : Icons.star_border,
                color: ctrl.isNodeFavorite
                    ? const Color(0xFFFBBF24)
                    : tokens.colorMuted,
                size: 20),
            onPressed: node == null ? null : () => ctrl.toggleFavorite(),
          ),
          TextButton(
            onPressed: () => context.push('/nodes'),
            style: TextButton.styleFrom(
                foregroundColor: tokens.colorPrimary,
                textStyle: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600)),
            child: Text(S.of(context)!.homeChangeNode),
          ),
        ],
      ),
    );
  }
}

class _RoutingModeCard extends StatelessWidget {
  const _RoutingModeCard({required this.ctrl, required this.tokens});
  final HomeController ctrl;
  final ThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    final modes = [RoutingMode.rule, RoutingMode.global, RoutingMode.direct];
    final s = S.of(context)!;
    final labels = [s.homeRoutingRule, s.homeRoutingGlobal, s.homeRoutingDirect];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.colorSurface,
        borderRadius: BorderRadius.circular(tokens.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(S.of(context)!.homeRoutingMode,
              style: TextStyle(
                  color: tokens.colorMuted, fontSize: 10, letterSpacing: 1)),
          const SizedBox(height: 12),
          Row(
            children: List.generate(modes.length, (i) {
              final selected = ctrl.currentMode == modes[i];
              return Expanded(
                child: GestureDetector(
                  onTap: () => ctrl.switchRoutingMode(modes[i]),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    margin: EdgeInsets.only(right: i < modes.length - 1 ? 6 : 0),
                    decoration: BoxDecoration(
                      color: selected
                          ? tokens.colorPrimary.withValues(alpha: 0.15)
                          : tokens.colorSurfaceVariant,
                      borderRadius:
                          BorderRadius.circular(tokens.radiusSmall),
                      border: selected
                          ? Border.all(
                              color: tokens.colorPrimary.withValues(alpha: 0.5))
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(labels[i],
                        style: TextStyle(
                            color: selected
                                ? tokens.colorPrimary
                                : tokens.colorMuted,
                            fontSize: 12,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w400)),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav(
      {required this.index, required this.tokens, required this.onTap});
  final int index;
  final ThemeTokens tokens;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final items = [
      (Icons.home_outlined, Icons.home, s.navHome),
      (Icons.language_outlined, Icons.language, s.navNodes),
      (Icons.settings_outlined, Icons.settings, s.settings),
      (Icons.person_outline, Icons.person, s.navMy),
    ];

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: tokens.colorSurface,
        border: Border(top: BorderSide(color: tokens.colorSurfaceVariant)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final (iconOutlined, iconFilled, label) = items[i];
          final selected = index == i;
          return GestureDetector(
            onTap: () => onTap(i),
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 64,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(selected ? iconFilled : iconOutlined,
                      color: selected
                          ? tokens.colorPrimary
                          : tokens.colorMuted,
                      size: 22),
                  const SizedBox(height: 3),
                  Text(label,
                      style: TextStyle(
                          color: selected
                              ? tokens.colorPrimary
                              : tokens.colorMuted,
                          fontSize: 9,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w400,
                          letterSpacing: 0.5)),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _ConnectionDurationChip extends StatefulWidget {
  const _ConnectionDurationChip({required this.ctrl, required this.tokens});
  final HomeController ctrl;
  final ThemeTokens tokens;

  @override
  State<_ConnectionDurationChip> createState() =>
      _ConnectionDurationChipState();
}

class _ConnectionDurationChipState extends State<_ConnectionDurationChip> {
  late final Stream<int> _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Stream.periodic(const Duration(seconds: 1), (i) => i);
  }

  String _fmt(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final sec = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$sec';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _ticker,
      builder: (_, __) {
        final dur = widget.ctrl.connectionDuration;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: widget.tokens.colorSurface,
            borderRadius: BorderRadius.circular(widget.tokens.radiusSmall),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.timer_outlined,
                  size: 14, color: widget.tokens.colorMuted),
              const SizedBox(width: 6),
              Text(
                _fmt(dur),
                style: TextStyle(
                  color: widget.tokens.colorOnBackground,
                  fontFamily: 'monospace',
                  fontSize: 13,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
