import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../controllers/ticket_controller.dart';
import '../../../l10n/app_localizations.dart';

class TicketDetailScreen extends StatefulWidget {
  const TicketDetailScreen({super.key, required this.ticketId});
  final int ticketId;

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  Ticket? _ticket;
  bool _loading = true;
  String? _error;
  final _replyCtrl = TextEditingController();
  bool _sending = false;
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _replyCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final ctrl = context.read<TicketController>();
    await ctrl.fetchTicketDetail(widget.ticketId);
    if (!mounted) return;
    setState(() {
      _ticket = ctrl.currentTicket;
      _error = ctrl.error;
      _loading = false;
    });
    if (_ticket != null) _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
      }
    });
  }

  Future<void> _send() async {
    final text = _replyCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    final ctrl = context.read<TicketController>();
    final ok = await ctrl.replyTicket(widget.ticketId, text);
    if (!mounted) return;
    setState(() => _sending = false);
    if (ok) {
      _replyCtrl.clear();
      await _load();
    } else if (ctrl.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ctrl.error!)),
      );
    }
  }

  Future<void> _close(S s) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(s.closeTicket),
        content: Text(s.closeTicketConfirm),
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
    if (confirm != true || !mounted) return;
    final ctrl = context.read<TicketController>();
    final ok = await ctrl.closeTicket(widget.ticketId);
    if (mounted) {
      if (ok) {
        Navigator.of(context).pop();
      } else if (ctrl.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ctrl.error!)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final ticket = _ticket;
    return Scaffold(
      appBar: AppBar(
        title: Text(ticket?.subject ?? s.ticketDetail),
        actions: [
          if (ticket != null && ticket.isOpen)
            TextButton(
              onPressed: () => _close(s),
              child: Text(s.closeTicket,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.error)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : Column(
                  children: [
                    Expanded(
                      child: _MessageList(
                        messages: ticket?.messages ?? [],
                        scrollCtrl: _scrollCtrl,
                      ),
                    ),
                    if (ticket != null && ticket.isOpen)
                      _ReplyBar(
                        controller: _replyCtrl,
                        sending: _sending,
                        onSend: _send,
                      ),
                  ],
                ),
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({required this.messages, required this.scrollCtrl});
  final List<TicketMessage> messages;
  final ScrollController scrollCtrl;

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return const Center(child: Icon(Icons.chat_bubble_outline, size: 48));
    }
    return ListView.builder(
      controller: scrollCtrl,
      padding: const EdgeInsets.all(12),
      itemCount: messages.length,
      itemBuilder: (_, i) => _Bubble(msg: messages[i]),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.msg});
  final TicketMessage msg;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMe = msg.isMe;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(isMe ? 12 : 2),
            bottomRight: Radius.circular(isMe ? 2 : 12),
          ),
        ),
        child: Text(msg.message,
            style: theme.textTheme.bodyMedium?.copyWith(
                color: isMe
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurface)),
      ),
    );
  }
}

class _ReplyBar extends StatelessWidget {
  const _ReplyBar(
      {required this.controller,
      required this.sending,
      required this.onSend});
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: s.replyHint,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20)),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            sending
                ? const SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : IconButton.filled(
                    onPressed: onSend, icon: const Icon(Icons.send)),
          ],
        ),
      ),
    );
  }
}
