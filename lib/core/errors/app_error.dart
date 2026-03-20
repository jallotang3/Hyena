/// 统一异常体系 — 所有业务异常继承此基类
sealed class AppError implements Exception {
  const AppError(this.message);
  final String message;
  @override
  String toString() => '$runtimeType: $message';
}

/// Token 失效、账号密码错误等认证相关异常
class AuthException extends AppError {
  const AuthException(super.message, {this.code});
  final int? code;
}

/// 需要重新登录（Token 无法静默刷新）
class AuthExpiredException extends AuthException {
  const AuthExpiredException() : super('登录已过期，请重新登录');
}

/// 面板 API 超时 / 5xx 等不可用异常
class PanelUnavailableException extends AppError {
  const PanelUnavailableException(super.message, {this.statusCode});
  final int? statusCode;
}

/// 节点订阅解析失败
class NodeParseException extends AppError {
  const NodeParseException(super.message, {this.raw});
  final String? raw;
}

/// 内核启动失败
class EngineStartException extends AppError {
  const EngineStartException(super.message);
}

/// 内核停止失败
class EngineStopException extends AppError {
  const EngineStopException(super.message);
}

/// 皮肤加载失败
class SkinLoadException extends AppError {
  const SkinLoadException(super.message, {this.skinId});
  final String? skinId;
}

/// 网络不可达
class NetworkException extends AppError {
  const NetworkException(super.message);
}

/// 未注册的面板类型
class UnsupportedPanelException extends AppError {
  const UnsupportedPanelException(String panelType)
      : super('未注册的面板类型: $panelType');
}

/// API 参数校验失败（422）
class ApiValidationException extends AppError {
  const ApiValidationException(super.message, {this.errors});
  final Map<String, List<String>>? errors;
}

/// 通用存储异常
class StorageException extends AppError {
  const StorageException(super.message);
}
