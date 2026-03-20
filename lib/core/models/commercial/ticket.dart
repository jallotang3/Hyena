/// 工单优先级
enum TicketLevel {
  normal(1),
  high(2),
  urgent(3);

  const TicketLevel(this.code);
  final int code;

  static TicketLevel fromCode(int code) =>
      TicketLevel.values.firstWhere((e) => e.code == code, orElse: () => TicketLevel.normal);
}

/// 工单状态
enum TicketStatus {
  open(0),
  closed(1);

  const TicketStatus(this.code);
  final int code;

  static TicketStatus fromCode(int code) =>
      TicketStatus.values.firstWhere((e) => e.code == code, orElse: () => TicketStatus.open);
}

/// 工单领域模型
class Ticket {
  const Ticket({
    required this.id,
    required this.subject,
    required this.level,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.messages,
  });

  final int id;
  final String subject;
  final TicketLevel level;
  final TicketStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// 仅详情页填充
  final List<TicketMessage>? messages;

  bool get isOpen => status == TicketStatus.open;
}

/// 工单消息（气泡对话）
class TicketMessage {
  const TicketMessage({
    required this.id,
    required this.message,
    required this.isMe,
    required this.createdAt,
  });

  final int id;
  final String message;

  /// true = 当前用户发出（右侧气泡），false = 客服（左侧气泡）
  final bool isMe;
  final DateTime createdAt;
}

/// 新建工单请求
class TicketRequest {
  const TicketRequest({
    required this.subject,
    required this.level,
    required this.message,
  });

  final String subject;
  final TicketLevel level;
  final String message;
}
