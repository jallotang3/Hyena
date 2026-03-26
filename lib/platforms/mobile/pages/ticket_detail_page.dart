import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../controllers/ticket_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../../../skins/theme_token_provider.dart';

class MobileTicketDetailPage extends StatefulWidget {
  final TicketController controller;
  final int ticketId;

  const MobileTicketDetailPage({
    required this.controller,
    required this.ticketId,
    super.key,
  });

  @override
  State<MobileTicketDetailPage> createState() => _MobileTicketDetailPageState();
}

class _MobileTicketDetailPageState extends State<MobileTicketDetailPage> {
  final _replyCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;
  Timer? _pollTimer;
  int _lastMessageCount = 0;

  static const _pollInterval = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await widget.controller.fetchTicketDetail(widget.ticketId);
      _lastMessageCount = widget.controller.currentTicket?.messages?.length ?? 0;
      _scrollToBottom();
      _startPolling();
    });
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(_pollInterval, (_) => _poll());
  }

  Future<void> _poll() async {
    // 发送中跳过，避免状态冲突
    if (_sending || !mounted) return;
    final ticket = widget.controller.currentTicket;
    // 工单已关闭则停止轮询
    if (ticket != null && !ticket.isOpen) {
      _pollTimer?.cancel();
      return;
    }
    await widget.controller.fetchTicketDetail(widget.ticketId);
    if (!mounted) return;
    final newCount = widget.controller.currentTicket?.messages?.length ?? 0;
    if (newCount > _lastMessageCount) {
      _lastMessageCount = newCount;
      _scrollToBottom();
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _replyCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _replyCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    final ok = await widget.controller.replyTicket(widget.ticketId, text);
    if (!mounted) return;
    setState(() => _sending = false);
    if (ok) {
      _replyCtrl.clear();
      _lastMessageCount = widget.controller.currentTicket?.messages?.length ?? 0;
      _scrollToBottom();
    } else if (widget.controller.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.controller.error!)),
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
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(s.confirm),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final ok = await widget.controller.closeTicket(widget.ticketId);
    if (mounted && ok) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ThemeTokenProvider.tokensOf(context);
    final s = S.of(context)!;

    return Scaffold(
      backgroundColor: tokens.colorBackground,
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          final ticket = widget.controller.currentTicket;

          return Column(
            children: [
              // ── AppBar ──
              _ChatAppBar(
                title: ticket?.subject ?? s.ticketDetail,
                isOpen: ticket?.isOpen ?? false,
                tokens: tokens,
                onClose: () => _close(s),
              ),

              // ── 消息列表 ──
              Expanded(
                child: widget.controller.isLoading && ticket == null
                    ? Center(child: CircularProgressIndicator(color: tokens.colorPrimary))
                    : widget.controller.error != null && ticket == null
                        ? _ErrorView(
                            message: widget.controller.error!,
                            tokens: tokens,
                            onRetry: () => widget.controller.fetchTicketDetail(widget.ticketId),
                          )
                        : _MessageList(
                            messages: ticket?.messages ?? [],
                            scrollCtrl: _scrollCtrl,
                            tokens: tokens,
                          ),
              ),

              // ── 回复栏（仅 open 状态显示）──
              if (ticket?.isOpen ?? false)
                _ReplyBar(
                  controller: _replyCtrl,
                  sending: _sending,
                  tokens: tokens,
                  onSend: _send,
                ),
            ],
          );
        },
      ),
    );
  }
}

// ── AppBar ──────────────────────────────────────────────────────────────────

class _ChatAppBar extends StatelessWidget {
  const _ChatAppBar({
    required this.title,
    required this.isOpen,
    required this.tokens,
    required this.onClose,
  });

  final String title;
  final bool isOpen;
  final ThemeTokens tokens;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        color: tokens.colorSurface,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back, color: tokens.colorOnBackground),
              onPressed: () => context.pop(),
            ),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: tokens.colorOnBackground,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isOpen)
              TextButton(
                onPressed: onClose,
                child: Text(
                  'Close',
                  style: TextStyle(color: tokens.colorError, fontSize: 13),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── 消息列表 ─────────────────────────────────────────────────────────────────

class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.messages,
    required this.scrollCtrl,
    required this.tokens,
  });

  final List<TicketMessage> messages;
  final ScrollController scrollCtrl;
  final ThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline, size: 48, color: tokens.colorMuted),
            const SizedBox(height: 8),
            Text(
              'No messages yet',
              style: TextStyle(color: tokens.colorMuted, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: messages.length,
      itemBuilder: (_, i) {
        final msg = messages[i];
        final prevMsg = i > 0 ? messages[i - 1] : null;
        final showTime = prevMsg == null ||
            msg.createdAt.difference(prevMsg.createdAt).inMinutes > 5;
        return _BubbleItem(msg: msg, showTime: showTime, tokens: tokens);
      },
    );
  }
}

class _BubbleItem extends StatelessWidget {
  const _BubbleItem({
    required this.msg,
    required this.showTime,
    required this.tokens,
  });

  final TicketMessage msg;
  final bool showTime;
  final ThemeTokens tokens;

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays >= 1) {
      return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isMe = msg.isMe;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showTime)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: Text(
                _formatTime(msg.createdAt),
                style: TextStyle(color: tokens.colorMuted, fontSize: 11),
              ),
            ),
          ),
        Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe) ...[
                // 客服头像
                Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.only(right: 6, bottom: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: tokens.colorPrimary.withValues(alpha: 0.15),
                  ),
                  child: Icon(Icons.support_agent, size: 16, color: tokens.colorPrimary),
                ),
              ],
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.68,
                ),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isMe
                        ? tokens.colorPrimary
                        : tokens.colorSurface,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(14),
                      topRight: const Radius.circular(14),
                      bottomLeft: Radius.circular(isMe ? 14 : 2),
                      bottomRight: Radius.circular(isMe ? 2 : 14),
                    ),
                  ),
                  child: Text(
                    msg.message,
                    style: TextStyle(
                      color: isMe ? tokens.colorOnPrimary : tokens.colorOnBackground,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
              if (isMe) ...[
                // 用户头像
                Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.only(left: 6, bottom: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: tokens.colorPrimary.withValues(alpha: 0.15),
                  ),
                  child: Icon(Icons.person, size: 16, color: tokens.colorPrimary),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ── 回复栏 ───────────────────────────────────────────────────────────────────

class _ReplyBar extends StatelessWidget {
  const _ReplyBar({
    required this.controller,
    required this.sending,
    required this.tokens,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final ThemeTokens tokens;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        color: tokens.colorSurface,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: tokens.colorBackground,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.newline,
                  style: TextStyle(color: tokens.colorOnBackground, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Type a reply...',
                    hintStyle: TextStyle(color: tokens.colorMuted, fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: sending ? null : onSend,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: sending
                      ? tokens.colorPrimary.withValues(alpha: 0.5)
                      : tokens.colorPrimary,
                ),
                child: sending
                    ? Padding(
                        padding: const EdgeInsets.all(10),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: tokens.colorOnPrimary,
                        ),
                      )
                    : Icon(Icons.send_rounded, color: tokens.colorOnPrimary, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 错误视图 ─────────────────────────────────────────────────────────────────

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
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: tokens.colorError),
          const SizedBox(height: 12),
          Text(message, style: TextStyle(color: tokens.colorMuted), textAlign: TextAlign.center),
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
