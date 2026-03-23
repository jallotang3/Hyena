import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../controllers/ticket_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../../../skins/theme_token_provider.dart';

/// 移动端工单列表页（Material Design）
class MobileTicketListPage extends StatefulWidget {
  final TicketController controller;

  const MobileTicketListPage({required this.controller, super.key});

  @override
  State<MobileTicketListPage> createState() => _MobileTicketListPageState();
}

class _MobileTicketListPageState extends State<MobileTicketListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.fetchTickets();
    });
  }

  void _showCreateDialog(BuildContext context, S s, ThemeTokens tokens) {
    final subjectCtrl = TextEditingController();
    final messageCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.newTicket),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: subjectCtrl,
              decoration: InputDecoration(
                labelText: s.ticketSubject,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageCtrl,
              decoration: InputDecoration(
                labelText: s.ticketMessage,
                border: const OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () async {
              if (subjectCtrl.text.isEmpty || messageCtrl.text.isEmpty) {
                return;
              }
              final success = await widget.controller.createTicket(
                subjectCtrl.text,
                0, // level: 0 = low priority
                messageCtrl.text,
              );
              if (success && context.mounted) {
                Navigator.pop(context);
                widget.controller.fetchTickets();
              }
            },
            child: Text(s.submit),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokenProvider.tokensOf(context);
    final s = S.of(context)!;

    return Scaffold(
      backgroundColor: tokens.colorBackground,
      appBar: AppBar(
        backgroundColor: tokens.colorBackground,
        title: Text(s.tickets),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context, s, tokens),
        backgroundColor: tokens.colorPrimary,
        foregroundColor: tokens.colorOnPrimary,
        icon: const Icon(Icons.add),
        label: Text(s.newTicket),
      ),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          if (widget.controller.isLoading) {
            return Center(
              child: CircularProgressIndicator(color: tokens.colorPrimary),
            );
          }

          if (widget.controller.error != null) {
            return _ErrorView(
              message: widget.controller.error!,
              tokens: tokens,
              onRetry: () => widget.controller.fetchTickets(),
            );
          }

          if (widget.controller.tickets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.support_agent_outlined,
                    size: 64,
                    color: tokens.colorMuted,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    s.noTickets,
                    style: TextStyle(color: tokens.colorMuted),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => widget.controller.fetchTickets(),
            color: tokens.colorPrimary,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: widget.controller.tickets.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _TicketCard(
                ticket: widget.controller.tickets[i],
                tokens: tokens,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.tokens,
    required this.onRetry,
  });

  final String message;
  final ThemeTokens tokens;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: tokens.colorError),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: tokens.colorMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: tokens.colorPrimary,
              foregroundColor: tokens.colorOnPrimary,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({
    required this.ticket,
    required this.tokens,
  });

  final Ticket ticket;
  final ThemeTokens tokens;

  Color _statusColor(TicketStatus status) {
    switch (status) {
      case TicketStatus.closed:
        return tokens.colorMuted;
      case TicketStatus.open:
        return tokens.colorPrimary;
    }
  }

  String _statusLabel(TicketStatus status, S s) {
    switch (status) {
      case TicketStatus.open:
        return s.ticketOpen;
      case TicketStatus.closed:
        return s.ticketClosed;
    }
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;

    return GestureDetector(
      onTap: () => context.push('/tickets/${ticket.id}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: tokens.colorSurface,
          borderRadius: BorderRadius.circular(tokens.radiusMedium),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题和状态
            Row(
              children: [
                Expanded(
                  child: Text(
                    ticket.subject,
                    style: TextStyle(
                      color: tokens.colorOnBackground,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(ticket.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(tokens.radiusSmall),
                  ),
                  child: Text(
                    _statusLabel(ticket.status, s),
                    style: TextStyle(
                      color: _statusColor(ticket.status),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 消息预览（显示主题）
            Text(
              ticket.subject,
              style: TextStyle(
                color: tokens.colorMuted,
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),

            // 时间和箭头
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: tokens.colorMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDate(ticket.createdAt),
                  style: TextStyle(
                    color: tokens.colorMuted,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.chevron_right,
                  color: tokens.colorMuted,
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
