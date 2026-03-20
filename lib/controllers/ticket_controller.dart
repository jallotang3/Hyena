import 'package:flutter/foundation.dart';

import '../core/models/commercial/ticket.dart';
import '../core/result.dart';
import '../features/ticket/ticket_use_case.dart';

/// TicketController — 工单列表/详情/新建的固定 API 边界
class TicketController extends ChangeNotifier {
  TicketController({required TicketUseCase ticketUseCase})
      : _useCase = ticketUseCase;

  final TicketUseCase _useCase;

  List<Ticket> _tickets = [];
  Ticket? _currentTicket;
  bool _isLoading = false;
  bool _isSending = false;
  String? _error;

  // ── 状态属性 ──
  List<Ticket> get tickets => _tickets;
  Ticket? get currentTicket => _currentTicket;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  String? get error => _error;

  // ── 操作方法 ──
  Future<void> fetchTickets() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _useCase.fetchTickets();
    _isLoading = false;

    switch (result) {
      case Success(value: final v):
        _tickets = v;
      case Failure(error: final e):
        _error = e.message;
    }
    notifyListeners();
  }

  Future<void> fetchTicketDetail(int ticketId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _useCase.fetchTicketDetail(ticketId: ticketId);
    _isLoading = false;

    switch (result) {
      case Success(value: final v):
        _currentTicket = v;
      case Failure(error: final e):
        _error = e.message;
    }
    notifyListeners();
  }

  Future<bool> createTicket(
    String subject,
    int level,
    String message,
  ) async {
    _isSending = true;
    _error = null;
    notifyListeners();

    final result = await _useCase.createTicket(
      request: TicketRequest(
        subject: subject,
        level: TicketLevel.fromCode(level),
        message: message,
      ),
    );
    _isSending = false;

    switch (result) {
      case Success():
        await fetchTickets();
        return true;
      case Failure(error: final e):
        _error = e.message;
        notifyListeners();
        return false;
    }
  }

  Future<bool> replyTicket(int ticketId, String message) async {
    _isSending = true;
    _error = null;
    notifyListeners();

    final result = await _useCase.replyTicket(ticketId: ticketId, message: message);
    _isSending = false;

    switch (result) {
      case Success():
        await fetchTicketDetail(ticketId);
        return true;
      case Failure(error: final e):
        _error = e.message;
        notifyListeners();
        return false;
    }
  }

  Future<bool> closeTicket(int ticketId) async {
    final result = await _useCase.closeTicket(ticketId: ticketId);
    switch (result) {
      case Success():
        await fetchTickets();
        return true;
      case Failure(error: final e):
        _error = e.message;
        notifyListeners();
        return false;
    }
  }
}
