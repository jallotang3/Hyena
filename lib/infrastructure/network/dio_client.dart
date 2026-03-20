import 'package:dio/dio.dart';
import '../logging/app_logger.dart';
import '../../core/errors/app_error.dart';

/// Dio 封装 — 统一拦截器：认证头注入、超时、错误码转换
class DioClient {
  DioClient._();
  static final DioClient instance = DioClient._();

  late final Dio _dio;

  void initialize({
    required String baseUrl,
    String? authData,
    Duration connectTimeout = const Duration(seconds: 15),
    Duration receiveTimeout = const Duration(seconds: 30),
  }) {
    _dio = Dio(
      BaseOptions(
        baseUrl: '$baseUrl/api/v1',
        connectTimeout: connectTimeout,
        receiveTimeout: receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.addAll([
      _AuthInterceptor(authData: authData),
      _LoggingInterceptor(),
      _ErrorInterceptor(),
    ]);
  }

  /// 更新 auth token（登录后调用）
  void updateAuthData(String? authData) {
    _dio.interceptors.removeWhere((i) => i is _AuthInterceptor);
    _dio.interceptors.insert(0, _AuthInterceptor(authData: authData));
  }

  Dio get dio => _dio;

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? queryParameters}) =>
      _dio.get(path, queryParameters: queryParameters);

  Future<Response<T>> post<T>(String path, {dynamic data}) =>
      _dio.post(path, data: data);
}

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor({this.authData});
  final String? authData;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (authData != null && authData!.isNotEmpty) {
      options.headers['Authorization'] = authData;
    }
    handler.next(options);
  }
}

class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    AppLogger.d('→ ${options.method} ${options.path}', tag: LogTag.network);
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    AppLogger.d('← ${response.statusCode} ${response.requestOptions.path}',
        tag: LogTag.network);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    AppLogger.e('✗ ${err.requestOptions.path}: ${err.message}', tag: LogTag.network);
    handler.next(err);
  }
}

class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final appError = _mapError(err);
    handler.reject(DioException(
      requestOptions: err.requestOptions,
      error: appError,
      type: err.type,
    ));
  }

  AppError _mapError(DioException err) {
    final statusCode = err.response?.statusCode;
    final message = _extractMessage(err.response?.data) ?? err.message ?? 'Unknown error';

    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout) {
      return PanelUnavailableException('请求超时: $message', statusCode: statusCode);
    }

    return switch (statusCode) {
      401 => const AuthExpiredException(),
      422 => ApiValidationException(message),
      _ when (statusCode ?? 0) >= 500 =>
        PanelUnavailableException('服务器错误: $message', statusCode: statusCode),
      _ when err.type == DioExceptionType.connectionError =>
        NetworkException('网络连接失败: $message'),
      _ => PanelUnavailableException(message, statusCode: statusCode),
    };
  }

  String? _extractMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['message']?.toString() ?? data['msg']?.toString();
    }
    return data?.toString();
  }
}
