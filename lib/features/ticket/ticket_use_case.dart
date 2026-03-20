import '../../core/errors/app_error.dart';
import '../../core/interfaces/panel_adapter.dart';
import '../../core/models/panel_site.dart';
import '../../core/models/commercial/ticket.dart';
import '../../core/result.dart';
import '../../infrastructure/storage/secure_storage.dart';

class TicketUseCase {
  TicketUseCase({required PanelAdapter adapter, required PanelSite site})
      : _adapter = adapter,
        _site = site;

  final PanelAdapter _adapter;
  final PanelSite _site;

  Future<Result<List<Ticket>>> fetchTickets() async {
    try {
      final auth = await SecureStorage.instance.readAuthContext();
      if (auth == null) return Failure(const AuthException('未登录'));
      final tickets = await _adapter.fetchTickets(_site, auth);
      return Success(tickets);
    } catch (e) {
      return Failure(_toAppError(e));
    }
  }

  Future<Result<Ticket>> fetchTicketDetail({required int ticketId}) async {
    try {
      final auth = await SecureStorage.instance.readAuthContext();
      if (auth == null) return Failure(const AuthException('未登录'));
      final ticket = await _adapter.fetchTicketDetail(_site, auth, ticketId);
      return Success(ticket);
    } catch (e) {
      return Failure(_toAppError(e));
    }
  }

  Future<Result<bool>> createTicket({required TicketRequest request}) async {
    try {
      final auth = await SecureStorage.instance.readAuthContext();
      if (auth == null) return Failure(const AuthException('未登录'));
      final ok = await _adapter.createTicket(_site, auth, request);
      return Success(ok);
    } catch (e) {
      return Failure(_toAppError(e));
    }
  }

  Future<Result<bool>> replyTicket({
    required int ticketId,
    required String message,
  }) async {
    try {
      final auth = await SecureStorage.instance.readAuthContext();
      if (auth == null) return Failure(const AuthException('未登录'));
      final ok = await _adapter.replyTicket(_site, auth, ticketId, message);
      return Success(ok);
    } catch (e) {
      return Failure(_toAppError(e));
    }
  }

  Future<Result<bool>> closeTicket({required int ticketId}) async {
    try {
      final auth = await SecureStorage.instance.readAuthContext();
      if (auth == null) return Failure(const AuthException('未登录'));
      final ok = await _adapter.closeTicket(_site, auth, ticketId);
      return Success(ok);
    } catch (e) {
      return Failure(_toAppError(e));
    }
  }

  AppError _toAppError(Object e) {
    if (e is AppError) return e;
    return PanelUnavailableException(e.toString());
  }
}
