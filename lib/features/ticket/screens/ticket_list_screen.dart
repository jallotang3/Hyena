import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../controllers/ticket_controller.dart';
import '../../../core/models/commercial/ticket.dart';
import '../../../l10n/app_localizations.dart';
import 'ticket_detail_screen.dart';

class TicketListScreen extends StatefulWidget {
  const TicketListScreen({super.key});

  @override
  State<TicketListScreen> createState() => _TicketListScreenState();
}

class _TicketListScreenState extends State<TicketListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TicketController>().fetchTickets();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(s.tickets)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context, s),
        icon: const Icon(Icons.add),
        label: Text(s.newTicket),
      ),
      body: Consumer<TicketController>(
        builder: (_, ctrl, __) {
          if (ctrl.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (ctrl.error != null) {
            return _ErrorRetry(
                message: ctrl.error!,
                onRetry: () => ctrl.fetchTickets());
          }
          if (ctrl.tickets.isEmpty) {
            return Center(child: Text(s.noTickets));
          }
          return RefreshIndicator(
            onRefresh: () => ctrl.fetchTickets(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: ctrl.tickets.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _TicketTile(
                ticket: ctrl.tickets[i],
                onTap: () => _openDetail(context, ctrl.tickets[i]),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openDetail(BuildContext context, Ticket ticket) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => TicketDetailScreen(ticketId: ticket.id),
    ));
    if (context.mounted) context.read<TicketController>().fetchTickets();
  }

  Future<void> _showCreateDialog(BuildContext context, S s) async {
    final subjectCtrl = TextEditingController();
    final messageCtrl = TextEditingController();
    TicketLevel level = TicketLevel.normal;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(s.newTicket),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: subjectCtrl,
                  decoration: InputDecoration(
                      labelText: s.ticketSubject,
                      border: const OutlineInputBorder(),
                      isDense: true),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<TicketLevel>(
                  initialValue: level,
                  decoration: InputDecoration(
                      labelText: s.ticketLevel,
                      border: const OutlineInputBorder(),
                      isDense: true),
                  items: TicketLevel.values
                      .map((l) => DropdownMenuItem(
                          value: l, child: Text(_levelLabel(l, s))))
                      .toList(),
                  onChanged: (v) => setS(() => level = v ?? level),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: messageCtrl,
                  maxLines: 4,
                  decoration: InputDecoration(
                      labelText: s.ticketMessage,
                      border: const OutlineInputBorder()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(s.cancel)),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(s.submit)),
          ],
        ),
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final ctrl = context.read<TicketController>();
    final ok = await ctrl.createTicket(
      subjectCtrl.text.trim(),
      level.code,
      messageCtrl.text.trim(),
    );
    if (context.mounted && !ok && ctrl.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ctrl.error!)),
      );
    }
  }

  String _levelLabel(TicketLevel l, S s) {
    switch (l) {
      case TicketLevel.normal:
        return s.ticketLevelNormal;
      case TicketLevel.high:
        return s.ticketLevelHigh;
      case TicketLevel.urgent:
        return s.ticketLevelUrgent;
    }
  }
}

class _TicketTile extends StatelessWidget {
  const _TicketTile({required this.ticket, required this.onTap});
  final Ticket ticket;
  final VoidCallback onTap;

  String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = S.of(context)!;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: ticket.isOpen
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          child: Icon(
            ticket.isOpen ? Icons.support_agent : Icons.check_circle_outline,
            size: 16,
            color: ticket.isOpen
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ),
        title: Text(ticket.subject, overflow: TextOverflow.ellipsis),
        subtitle: Text(_formatDate(ticket.updatedAt),
            style: theme.textTheme.labelSmall?.copyWith(
                color:
                    theme.colorScheme.onSurface.withValues(alpha: 0.5))),
        trailing: Chip(
          label: Text(ticket.isOpen ? s.ticketOpen : s.ticketClosed,
              style: theme.textTheme.labelSmall),
          backgroundColor: ticket.isOpen
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          side: BorderSide.none,
          padding: EdgeInsets.zero,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.support_agent, size: 48),
          const SizedBox(height: 12),
          Text(message),
          const SizedBox(height: 16),
          FilledButton.tonal(onPressed: onRetry, child: Text(s.retry)),
        ],
      ),
    );
  }
}
