import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/home_controller.dart';
import '../../core/models/engine_state.dart';
import '../../l10n/app_localizations.dart';
import '../theme_token_provider.dart';

/// Brand X 自定义首页 — 温暖出行风格
///
/// 特点：
/// - 圆形大按钮 + 暖橙渐变连接图标
/// - 卡片式节点选择器
/// - 浅色背景 + 友好提示文案
/// - 仅通过 HomeController 交互，不直接访问 UseCase
class BrandXHomePage extends StatelessWidget {
  const BrandXHomePage({super.key, required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: controller,
      child: const _BrandXHomeView(),
    );
  }
}

class _BrandXHomeView extends StatelessWidget {
  const _BrandXHomeView();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<HomeController>();
    final s = S.of(context)!;
    final tokens = ThemeTokenProvider.of(context);

    return Scaffold(
      backgroundColor: tokens.colorBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 24),
              _BrandXTopBar(tokens: tokens, controller: c, s: s),
              const Spacer(),
              _BrandXConnectButton(tokens: tokens, controller: c, s: s),
              const SizedBox(height: 32),
              _BrandXStatusCard(tokens: tokens, controller: c, s: s),
              const Spacer(),
              _BrandXNodeCard(tokens: tokens, controller: c, s: s),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandXTopBar extends StatelessWidget {
  const _BrandXTopBar({
    required this.tokens,
    required this.controller,
    required this.s,
  });

  final ThemeTokens tokens;
  final HomeController controller;
  final S s;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          s.appName,
          style: TextStyle(
            color: tokens.colorPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: tokens.colorSurfaceVariant,
            borderRadius: BorderRadius.circular(tokens.radiusSmall),
          ),
          child: Row(
            children: [
              Icon(Icons.person_outline, size: 14, color: tokens.colorMuted),
              const SizedBox(width: 4),
              Text(
                controller.userEmail.isNotEmpty
                    ? controller.userEmail
                    : s.homeDefaultUser,
                style: TextStyle(
                  color: tokens.colorOnSurface,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BrandXConnectButton extends StatelessWidget {
  const _BrandXConnectButton({
    required this.tokens,
    required this.controller,
    required this.s,
  });

  final ThemeTokens tokens;
  final HomeController controller;
  final S s;

  @override
  Widget build(BuildContext context) {
    final isConnected = controller.engineState == EngineState.connected;
    final isLoading = controller.engineState == EngineState.connecting ||
        controller.engineState == EngineState.disconnecting;

    return GestureDetector(
      onTap: isLoading ? null : controller.toggleConnection,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        width: 180,
        height: 180,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: isConnected
                ? [
                    tokens.colorPrimary.withAlpha(230),
                    tokens.colorPrimary,
                  ]
                : [
                    tokens.colorSurface,
                    tokens.colorSurfaceVariant,
                  ],
          ),
          boxShadow: [
            BoxShadow(
              color: isConnected
                  ? tokens.colorPrimary.withAlpha(100)
                  : Colors.black.withAlpha(18),
              blurRadius: isConnected ? 40 : 12,
              spreadRadius: isConnected ? 8 : 0,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              CircularProgressIndicator(
                strokeWidth: 2,
                color: isConnected ? tokens.colorOnPrimary : tokens.colorPrimary,
              )
            else
              Icon(
                isConnected ? Icons.shield : Icons.shield_outlined,
                size: 48,
                color: isConnected ? tokens.colorOnPrimary : tokens.colorPrimary,
              ),
            const SizedBox(height: 8),
            Text(
              isLoading
                  ? (isConnected ? s.disconnecting : s.connecting)
                  : (isConnected ? s.connected : s.disconnected),
              style: TextStyle(
                color: isConnected ? tokens.colorOnPrimary : tokens.colorPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandXStatusCard extends StatelessWidget {
  const _BrandXStatusCard({
    required this.tokens,
    required this.controller,
    required this.s,
  });

  final ThemeTokens tokens;
  final HomeController controller;
  final S s;

  @override
  Widget build(BuildContext context) {
    final isConnected = controller.engineState == EngineState.connected;
    return AnimatedOpacity(
      opacity: isConnected ? 1.0 : 0.4,
      duration: const Duration(milliseconds: 300),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _StatChip(
            icon: Icons.upload_outlined,
            label: controller.uploadSpeed,
            tokens: tokens,
          ),
          const SizedBox(width: 20),
          _StatChip(
            icon: Icons.download_outlined,
            label: controller.downloadSpeed,
            tokens: tokens,
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.tokens,
  });

  final IconData icon;
  final String label;
  final ThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: tokens.colorSurfaceVariant,
        borderRadius: BorderRadius.circular(tokens.radiusMedium),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: tokens.colorMuted),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: tokens.colorOnSurface,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandXNodeCard extends StatelessWidget {
  const _BrandXNodeCard({
    required this.tokens,
    required this.controller,
    required this.s,
  });

  final ThemeTokens tokens;
  final HomeController controller;
  final S s;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed('/nodes'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: tokens.colorSurface,
          borderRadius: BorderRadius.circular(tokens.radiusMedium),
          border: Border.all(color: tokens.colorSurfaceVariant, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: tokens.colorPrimary.withAlpha(25),
                borderRadius: BorderRadius.circular(tokens.radiusSmall),
              ),
              child: Icon(
                Icons.location_on_outlined,
                color: tokens.colorPrimary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.selectedNode?.name ?? s.notSelectedNode,
                    style: TextStyle(
                      color: tokens.colorOnSurface,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  if (controller.selectedNode != null)
                    Text(
                      '${controller.selectedNode?.latencyMs ?? '--'} ms',
                      style: TextStyle(
                        color: tokens.colorMuted,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: tokens.colorMuted,
            ),
          ],
        ),
      ),
    );
  }
}
